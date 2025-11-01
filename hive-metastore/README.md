# Hive Metastore Stack

Standalone Hive Metastore service that preserves legacy Hive catalog compatibility for engines like Trino and Spark. Lives on the NAS so it can share configuration with Trino while using PostgreSQL for metadata.

## Dependencies
- PostgreSQL database dedicated to the metastore (for example `metastore_db`) with username/password matching the values filled in the shared configuration.
- MinIO endpoint (e.g., `http://<nas-host>:9000`) with access credentials inserted into the Hadoop config files.
- Shared configuration directory on the NAS (`/volume2/dockers/hive_metastore/configuration/shared`) populated with the XML files from this repository (adjust the path if your storage appliance uses different mount points).

## Credentials
- **PostgreSQL:** Open `configuration/shared/metastore-site.xml` and set the `javax.jdo.option.ConnectionUserName` and `javax.jdo.option.ConnectionPassword` values. The JDBC URL should point at the database you created in the [`../postgresql/README.md`](../postgresql/README.md#credentials) section.
- **MinIO:** In `configuration/shared/core-site.xml` and `configuration/shared/metastore-site.xml`, populate `fs.s3a.access.key` and `fs.s3a.secret.key` (or mount a `core-site.xml` that sources them from environment variables). Generate these keys via the steps in [`../minio/README.md`](../minio/README.md#credentials).
- **Environment variables:** Update `docker.compose.yml` with the `HIVE_CONF_*` variables. Use an `.env` file kept outside version control to safely store any secrets referenced there.

## Preparation
1. Copy `configuration/shared/core-site.xml` and `configuration/shared/metastore-site.xml` from the repo into `/volume2/dockers/hive_metastore/configuration/shared` on the NAS.
2. Edit those XML files to include the correct MinIO access and secret keys as well as the PostgreSQL username/password for the metastore connection.
3. Place JDBC drivers under `/volume2/dockers/hive_metastore/configuration/metastore/jdbc_drivers/` (the compose file expects `postgresql-42.5.1.jar` and `mysql-connector-java-8.0.30.jar`).
4. Export environment variables referenced in `docker.compose.yml`:
   - `HIVE_CONF_SERVICE_NAME`
   - `HIVE_CONF_DB_DRIVER`
   - `HIVE_CONF_HIVE_CUSTOM_CONF_DIR` (typically `/hive_custom_conf`)
   - `HIVE_CONF_HADOOP_CLASSPATH`

## Start & Stop
```bash
docker compose -f hive-metastore/docker.compose.yml up -d
# tear down
docker compose -f hive-metastore/docker.compose.yml down
```

## Validation
- From the NAS host, run `docker compose -f hive-metastore/docker.compose.yml logs hive-metastore` and confirm it reports `Started the object store` without schema errors.
- From Trino, execute `SHOW SCHEMAS FROM minio;` (or your catalog name) to verify the metastore responds.
- Use `nc <nas-host> 9083` to ensure the Thrift port is open.

## Operations
- When you modify the shared XML config or jar versions, restart the container to reload them.
- Keep the metastore database vacuumed in PostgreSQL; Iceberg REST uses a separate database and is unaffected.
