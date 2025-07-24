#!/usr/bin/env bash
set -e

# make sure data dirs exist
mkdir -p data/processed

spark-submit \
  --master local[*] \
  etl/etl.py \
  --config config/config.yaml
