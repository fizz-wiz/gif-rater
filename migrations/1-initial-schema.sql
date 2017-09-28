-- Up

CREATE TABLE gif (
  id INTEGER PRIMARY KEY,
  giphy_id TEXT UNIQUE NOT NULL,
  url TEXT NOT NULL,
  embed_url TEXT NOT NULL,
  date_added TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  gif_ignore INTEGER DEFAULT 0 NOT NULL
);

CREATE TABLE upvote (
  id INTEGER PRIMARY KEY,
  gif_id INTEGER NOT NULL,
  -- user_id INTEGER
  date_added TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  FOREIGN KEY(gif_id) REFERENCES gif(id)
);

CREATE TABLE downvote (
  id INTEGER PRIMARY KEY,
  gif_id INTEGER NOT NULL,
  -- user_id INTEGER
  date_added TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  FOREIGN KEY(gif_id) REFERENCES gif(id)
);

-- Down

DROP TABLE gif;
DROP TABLE upvote;
DROP TABLE downvote;