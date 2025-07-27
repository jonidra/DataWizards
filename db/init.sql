-- Enable PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE IF NOT EXISTS city (
  id SERIAL PRIMARY KEY,
  lat DOUBLE PRECISION NOT NULL,
  lon DOUBLE PRECISION NOT NULL,
  city VARCHAR(255) NOT NULL,
  country_code CHAR(2),
  continent VARCHAR(50),
  capital VARCHAR(50),
  geom GEOGRAPHY(Point,4326)
);

CREATE TABLE IF NOT EXISTS customer (
  id INTEGER PRIMARY KEY,
  name VARCHAR(255),
  email VARCHAR(255),
  city_id INTEGER REFERENCES city(id),
  premium_customer BOOLEAN
);

CREATE TABLE IF NOT EXISTS product_category (
  id INTEGER PRIMARY KEY,
  name VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS product (
  id INTEGER PRIMARY KEY,
  reference VARCHAR(100),
  name VARCHAR(255),
  category_id INTEGER REFERENCES product_category(id),
  price NUMERIC
);

CREATE TABLE IF NOT EXISTS installation (
  id INTEGER PRIMARY KEY,
  description TEXT,
  product_id INTEGER REFERENCES product(id),
  customer_id INTEGER REFERENCES customer(id),
  date TIMESTAMP
);

CREATE TABLE IF NOT EXISTS fact_installation (
  installation_id INTEGER PRIMARY KEY,
  customer_id INTEGER,
  email VARCHAR(255),
  city_id INTEGER,
  revenue NUMERIC,
  install_date DATE
);

CREATE INDEX IF NOT EXISTS idx_city_geom ON city USING GIST (geom);

CREATE UNLOGGED TABLE IF NOT EXISTS city_staging (
  lat DOUBLE PRECISION,
  lon DOUBLE PRECISION,
  city VARCHAR(255),
  country_code CHAR(2),
  continent VARCHAR(50),
  capital VARCHAR(50),
  id INTEGER
);

CREATE UNLOGGED TABLE IF NOT EXISTS product_staging (
  id INTEGER,
  reference VARCHAR(100),
  name VARCHAR(255),
  category_id INTEGER,
  price_raw TEXT
);

CREATE UNLOGGED TABLE IF NOT EXISTS installation_staging (
  id INTEGER,
  description TEXT,
  product_id INTEGER,
  customer_id INTEGER,
  date_raw TEXT
);
