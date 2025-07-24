import argparse
import yaml
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, year, coalesce, to_date, try_to_timestamp, lit


def parse_args():
    parser = argparse.ArgumentParser(description="PySpark ETL for Sales Analysis")
    parser.add_argument(
        "--config",
        required=True,
        help="Path to the YAML configuration file (e.g. config/config.yaml)",
    )
    return parser.parse_args()


def load_config(path: str) -> dict:
    with open(path, "r") as f:
        return yaml.safe_load(f)


def main():
    # 1) Parse CLI args and load config
    args = parse_args()
    cfg = load_config(args.config)

    raw_path = cfg["etl"]["raw_data_path"]
    processed_path = cfg["etl"]["processed_data_path"]

    # 2) Initialize Spark
    spark = SparkSession.builder \
        .appName("SalesAnalysisETL") \
        .getOrCreate()

    # 3) Extract: read all source CSVs
    city_df = spark.read.csv(f"{raw_path}/city.csv", header=True, inferSchema=True)
    customer_df = spark.read.csv(f"{raw_path}/customer.csv", header=True, inferSchema=True)
    product_df = spark.read.csv(f"{raw_path}/product.csv", header=True, inferSchema=True)
    category_df = spark.read.csv(f"{raw_path}/product_category.csv", header=True, inferSchema=True)
    install_df = spark.read.csv(f"{raw_path}/installation.csv", header=True, inferSchema=False)

    # 4) Transform: parse mixed-format timestamps into a single column
    # Use lit() to ensure format strings are treated as literals
    dt_iso = try_to_timestamp(col("date"), lit("yyyy-MM-dd HH:mm:ss"))
    dt_us  = try_to_timestamp(col("date"), lit("MM-dd-yyyy HH:mm:ss"))
    install_ts_df = install_df.withColumn("install_ts", coalesce(dt_iso, dt_us))

    # 5) Filter to installations in the year 2024
    installs_2024 = install_ts_df.filter(year(col("install_ts")) == 2024)

    # 6) Join dimensions to form the base fact table
    base = (
        installs_2024
        .join(customer_df, install_ts_df.customer_id == customer_df.id)
        .join(city_df,     customer_df.city_id       == city_df.id)
        .join(product_df,  installs_2024.product_id  == product_df.id)
        .join(category_df, product_df.category_id    == category_df.id)
        .select(
            installs_2024.id.alias("installation_id"),
            customer_df.id.alias("customer_id"),
            customer_df.email,
            city_df.id.alias("city_id"),
            product_df.price.alias("revenue"),
            to_date(col("install_ts")).alias("install_date")
        )
    )

    # 7) Load: write the transformed base table out as Parquet
    base.write.mode("overwrite").parquet(f"{processed_path}/base_table.parquet")

    # 8) Clean up
    spark.stop()


if __name__ == "__main__":
    main()