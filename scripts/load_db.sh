#!/usr/bin/env bash
set -e

# 1) Ensure the DB container is running
docker-compose up -d db

# 2) Execute init.sql *inside* the Postgres container
#    -T disables pseudo‑TTY allocation so it works on Windows
docker-compose exec -T db bash -lc "psql -U user -d sales -f /docker-entrypoint-initdb.d/init.sql"

echo "✅ Database schema initialized."
