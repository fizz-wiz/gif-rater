-- Up

CREATE TABLE gif (
  id INTEGER PRIMARY KEY,
  giphy_id TEXT UNIQUE NOT NULL,
  url TEXT NOT NULL,
  embed_url TEXT NOT NULL,
  topic_id INTEGER NOT NULL,
  date_added TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  gif_ignore INTEGER DEFAULT 0 NOT NULL,
  FOREIGN KEY(topic_id) REFERENCES topic(id)
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

CREATE TABLE topic (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL
);

INSERT INTO topic (name)
VALUES ("Dogs"), ("Cats"), ("Sea Otters"), ("Guinea Pigs");

-- Down

DROP TABLE gif;
DROP TABLE upvote;
DROP TABLE downvote;
DROP TABLE topic;
