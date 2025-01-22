CREATE TABLE "Artists" (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    origin VARCHAR(255) NOT NULL
);

CREATE TABLE "Genres" (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE "Subscriptions" (
    id SERIAL PRIMARY KEY,
    plan VARCHAR(255) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    original_price NUMERIC
);

CREATE TABLE "Albums" (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    artist_id INT NOT NULL,
    release_date DATE NOT NULL,
    FOREIGN KEY ("artist_id") REFERENCES "Artists" ("id")
);

CREATE TABLE "Songs" (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    artist_id INT NOT NULL,
    genre_id INT NOT NULL,
    album_id INT NOT NULL,
    duration INT NOT NULL,
    release_date DATE NOT NULL,
    FOREIGN KEY ("artist_id") REFERENCES "Artists" ("id"),
    FOREIGN KEY ("genre_id") REFERENCES "Genres" ("id"),
    FOREIGN KEY ("album_id") REFERENCES "Albums" ("id")
);

CREATE TABLE "Users" (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    subscription_id INT NOT NULL,
    FOREIGN KEY ("subscription_id") REFERENCES "Subscriptions" ("id")
);

CREATE TABLE "StreamingHistory" (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    song_id INT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY ("user_id") REFERENCES "Users" ("id"),
    FOREIGN KEY ("song_id") REFERENCES "Songs" ("id")
);

CREATE TABLE "Ratings" (
    id SERIAL PRIMARY KEY,
    song_id INT NOT NULL,
    user_id INT NOT NULL,
    rating INT NOT NULL,
    FOREIGN KEY ("song_id") REFERENCES "Songs" ("id"),
    FOREIGN KEY ("user_id") REFERENCES "Users" ("id")
);

CREATE TABLE "Playlists" (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    FOREIGN KEY ("user_id") REFERENCES "Users" ("id")
);

CREATE TABLE "PlaylistSongs" (
    playlist_id INT NOT NULL,
    song_id INT NOT NULL,
    FOREIGN KEY ("playlist_id") REFERENCES "Playlists" ("id"),
    FOREIGN KEY ("song_id") REFERENCES "Songs" ("id")
);

CREATE TABLE "SubscriptionDiscount" (
    id SERIAL PRIMARY KEY,
    subscription_id INT NOT NULL,
    discount_percentage NUMERIC(5, 2) NOT NULL,
    price_before_discount NUMERIC(10, 2) NOT NULL,
    price_after_discount NUMERIC(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY ("subscription_id") REFERENCES "Subscriptions" ("id")
);

COPY "Artists"(id, name, origin)
FROM '/tables/artists.csv'
DELIMITER ','
CSV HEADER;

COPY "Genres"(id, name)
FROM '/tables/genres.csv'
DELIMITER ','
CSV HEADER;

COPY "Albums"(id, title, artist_id, release_date)
FROM '/tables/albums.csv'
DELIMITER ','
CSV HEADER;

COPY "Subscriptions"(id, plan, start_date, end_date, price, original_price)
FROM '/tables/subscriptions.csv'
DELIMITER ','
CSV HEADER;

COPY "Users"(id, username, email, subscription_id)
FROM '/tables/users.csv'
DELIMITER ','
CSV HEADER;

COPY "Songs"(id, title, artist_id, genre_id, album_id, duration, release_date)
FROM '/tables/songs.csv'
DELIMITER ','
CSV HEADER;

COPY "StreamingHistory"(id, user_id, song_id, timestamp)
FROM '/tables/streaming_history.csv'
DELIMITER ','
CSV HEADER;

COPY "Ratings"(id, song_id, user_id, rating)
FROM '/tables/ratings.csv'
DELIMITER ','
CSV HEADER;

COPY "Playlists"(id, user_id, name, description)
FROM '/tables/playlists.csv'
DELIMITER ','
CSV HEADER;

COPY "PlaylistSongs"(playlist_id, song_id)
FROM '/tables/playlist_songs.csv'
DELIMITER ','
CSV HEADER;

COPY "SubscriptionDiscount"(id, subscription_id, discount_percentage, price_before_discount, price_after_discount, created_at, updated_at)
FROM '/tables/subscription_discount.csv'
DELIMITER ','
CSV HEADER;
