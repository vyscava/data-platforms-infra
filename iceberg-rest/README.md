# Iceberg REST Catalog Stack

Exposes the Apache Iceberg REST catalog interface backed by PostgreSQL and MinIO so Spark and Trino can share table metadata just like they would with AWS Glue. Runs on the NAS alongside MinIO and PostgreSQL.

## Dependencies
- PostgreSQL database and credentials dedicated to the catalog (`PSQL_ICEBERG_DB`, `PSQL_ICEBERG_USER`, `PSQL_ICEBERG_PASSWORD`).
- MinIO endpoint reachable at `http://<nas-host>:9000` (or your chosen hostname) with access keys.
- Iceberg warehouse bucket already created in MinIO (value of `ICEBERG_WAREHOUSE`).
- Hive Metastore service online when engines also need legacy Hive tables.

## Credentials
- **PostgreSQL:** Provide `PSQL_ICEBERG_USER`, `PSQL_ICEBERG_PASSWORD`, `PSQL_ICEBERG_DB`, `POSTGRESS_HOSTNAME`, and `POSTGRESS_HOSTNAME_PORT` in the environment block of `iceberg-rest/docker-compose.yml`. Create the matching database/user using the guidance in [`../postgresql/README.md`](../postgresql/README.md#credentials).
- **MinIO:** Set `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD`, and `MINIO_ENDPOINT` (or substitute a dedicated service account) in `docker-compose.yml`. If you prefer not to store credentials in compose files, reference them via environment variables sourced from your shell. See [`../minio/README.md`](../minio/README.md#credentials) to provision keys.
- **Warehouse bucket:** Ensure the value of `ICEBERG_WAREHOUSE` matches the MinIO path you created during the MinIO setup.

## Preparation
1. In MinIO, create the bucket that matches `ICEBERG_WAREHOUSE` (for example `iceberg-data/warehouse`) and apply a read/write policy for platform users.
2. Export the environment variables referenced in `docker-compose.yml`:
   - `ICEBERG_CATALOG_NAME`
   - `ICEBERG_WAREHOUSE`
   - `MINIO_ENDPOINT`
   - `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD`, `AWS_REGION`
   - `POSTGRESS_HOSTNAME`, `POSTGRESS_HOSTNAME_PORT`
   - `PSQL_ICEBERG_USER`, `PSQL_ICEBERG_PASSWORD`, `PSQL_ICEBERG_DB`
3. Confirm PostgreSQL has the Iceberg database and the user has `CONNECT`, `CREATE`, and `USAGE` privileges.

## Start & Stop
```bash
docker compose -f iceberg-rest/docker-compose.yml up -d
# tear down
docker compose -f iceberg-rest/docker-compose.yml down
```

## Validation
- `curl http://<nas-host>:8181/v1/config` should return the catalog configuration payload.
- From Spark: `spark.sql("SHOW NAMESPACES IN iceberg")` to ensure the catalog responds.
- From Trino: set up the `iceberg` catalog and run `SHOW SCHEMAS FROM iceberg;`.

## Operations
- New database namespaces map to folders inside the MinIO warehouse bucket; keep lifecycle or backup policies aligned with your retention goals.
- Rotate MinIO credentials by updating the Docker Compose environment and restarting the service—Spark and Trino configs must be updated at the same time.
