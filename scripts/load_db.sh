#!/usr/bin/env bash
set -e

export PGPASSWORD="${DB_PASSWORD:-pass}"

psql \
  --host="${DB_HOST:-localhost}" \
  --username="${DB_USER:-user}" \
  --dbname="${DB_NAME:-sales}" \
  --file="db/init.sql"
