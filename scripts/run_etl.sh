#!/usr/bin/env bash
set -e

# 1) Rebuild & start only the Spark service (in detached mode, so we can run commands against it)
docker-compose up --build -d spark

# 2) Run the ETL inside a fresh Spark container, with the service’s environment & volumes
docker-compose run --rm spark \
  spark-submit \
    --master local[*] \
    etl/etl.py \
    --config config/config.yaml

echo "✅ ETL job completed; check data/processed/base_table.parquet"
