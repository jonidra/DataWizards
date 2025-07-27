#!/usr/bin/env bash
set -e

echo "🔄 Starting dimension load sequence..."

# 1) Ensure DB is running
docker-compose up -d db

# 2) Truncate staging + dimension tables (except installation)
echo "⚠️  Truncating city_staging, product_staging and all dims except installation..."
docker-compose exec -T db psql -U user -d sales -c "\
  TRUNCATE city_staging, city, customer, product_category, product_staging, product \
    RESTART IDENTITY CASCADE;\
"

# 3) Load & dedupe city
echo "⏳ Loading city.csv into city_staging..."
docker-compose exec -T db psql -U user -d sales -c "\
  COPY city_staging(lat, lon, city, country_code, continent, capital, id) \
    FROM '/data/raw/city.csv' CSV HEADER;\
"
echo "⏳ Deduplicating into city..."
docker-compose exec -T db psql -U user -d sales -c "\
  INSERT INTO city(lat, lon, city, country_code, continent, capital, id) \
    SELECT DISTINCT ON (id) lat, lon, city, country_code, continent, capital, id \
    FROM city_staging ORDER BY id;\
"
echo "⏳ Populating city.geom..."
docker-compose exec -T db psql -U user -d sales -c "\
  UPDATE city \
    SET geom = ST_SetSRID(ST_MakePoint(lon, lat), 4326) \
    WHERE geom IS NULL;\
"

# 4) Disable FK on customer for bulk load
echo "⏳ Disabling triggers on customer..."
docker-compose exec -T db psql -U user -d sales -c "ALTER TABLE customer DISABLE TRIGGER ALL;"

# 5) Load customer & product_category
echo "⏳ Loading customer.csv..."
docker-compose exec -T db psql -U user -d sales -c "\
  COPY customer FROM '/data/raw/customer.csv' CSV HEADER;\
"
echo "⏳ Loading product_category.csv..."
docker-compose exec -T db psql -U user -d sales -c "\
  COPY product_category FROM '/data/raw/product_category.csv' CSV HEADER;\
"

# 6) Product staging → cleanse → insert
echo "⏳ Loading product.csv into product_staging..."
docker-compose exec -T db psql -U user -d sales -c "\
  COPY product_staging(id, reference, name, category_id, price_raw) \
    FROM '/data/raw/product.csv' CSV HEADER;\
"
echo "⏳ Inserting valid products into product..."
docker-compose exec -T db psql -U user -d sales -c "\
  INSERT INTO product(id, reference, name, category_id, price) \
    SELECT id, reference, name, category_id, \
      CASE WHEN price_raw ~ '^[0-9]+(\\.[0-9]+)?$' \
           THEN price_raw::numeric ELSE NULL END \
    FROM product_staging;\
"

# 7) Re‑enable FK triggers on customer
echo "⏳ Re-enabling triggers on customer..."
docker-compose exec -T db psql -U user -d sales -c "ALTER TABLE customer ENABLE TRIGGER ALL;"

echo "✅ Dimension load completed successfully."
