require('dotenv').config()

const db = require('sqlite')
const express = require('express')
const r2 = require('r2')

let app = express()

app.use(express.static(`${__dirname}/public`))

app.get('/topics', async (request, response, next) => {
  const topics = await db.all('SELECT id, name FROM topic');
  response.json(topics)
})

app.get('/gifs', async (request, response, next) => {
  const { topic } = request.query

  const { name } = await db.get('SELECT name FROM topic WHERE id = $id', { $id: topic }) || {}

  const json = await r2(`https://api.giphy.com/v1/gifs/random?tag=${name}&api_key=${process.env.GIPHY_API_KEY}`).json

  const { id: giphyId, url, image_url: embedUrl } = json.data

  let { id } = await db.get('SELECT id FROM gif WHERE giphy_id = $giphyId', { $giphyId: giphyId }) || {}

  if (!id) {
    const { lastID } = await db.run(
      'INSERT INTO gif (giphy_id, url, embed_url, topic_id) VALUES ($giphyId, $url, $embedUrl, $topicId)',
      { $giphyId: giphyId, $url: url, $embedUrl: embedUrl, $topicId: topic }
    )

    id = lastID
  }

  response.json({ id, url, embedUrl })
})

const gifExists = async id => db.get('SELECT id FROM gif WHERE id = $id', { $id: id })

app.post('/gifs/:id/upvotes', async (request, response, next) => {
  const id = +request.params.id

  if (!await gifExists(id)) {
    return response.status(404).json()
  }

  db.run('INSERT INTO upvote (gif_id) VALUES ($id)', { $id: id })

  response.status(201).json({ id })
})

app.post('/gifs/:id/downvotes', async (request, response, next) => {
  const id = +request.params.id

  if (!await gifExists(id)) {
    return response.status(404).json()
  }

  db.run('INSERT INTO downvote (gif_id) VALUES ($id)', { $id: id })

  response.status(201).json({ id })
})

db.open(`${__dirname}/db.sqlite`)
.then(_ => db.migrate({
  force: process.env.NODE_ENV === 'production' ? false : 'last'
}))
.then(_ => app.listen(3000))
.catch(err => console.error(err))
