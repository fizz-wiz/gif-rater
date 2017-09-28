require('dotenv').config()
const express = require('express')
const r2 = require('r2')

let app = express()

app.use(express.static(__dirname + '/public'))

app.get('/gifs', async (request, response, next) => {
  const { topic } = request.query
  const json = await r2(`https://api.giphy.com/v1/gifs/random?tag=${topic}&api_key=${process.env.GIPHY_API_KEY}`).json
  const { id, url, image_url: embedUrl } = json.data

  response.json({ id: 1, url, embedUrl })
})

app.post('/gifs/:id/upvotes', async (request, response, next) => {
  const id = +request.params.id
  response.status(201).json({ id })
})

app.post('/gifs/:id/downvotes', async (request, response, next) => {
  const id = +request.params.id
  response.status(201).json({ id })
})

const server = app.listen(3000)
