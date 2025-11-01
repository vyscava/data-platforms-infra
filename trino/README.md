# Trino Stack

Distributed SQL engine wired to MinIO, Hive Metastore, and Iceberg REST so you can query the lakehouse with ANSI SQL similar to AWS Athena. Designed to run on the Proxmox compute host.

## Dependencies
- Hive Metastore (`thrift://<nas-host>:9083`) and Iceberg REST (`http://<nas-host>:8181`) services online.
- MinIO credentials with access to the data buckets.
- Host directories (update paths to match your compute node):
  - `/home/admin/trino/coordinator/etc/trino`
  - `/home/admin/trino/worker/etc/trino`
  - `/home/admin/trino/catalog_configuration`
  - `/home/admin/trino/shared`
  These should contain the configuration files from this repository or your customised copies.

## Credentials
- **MinIO:** Edit `catalog_configuration/iceberg.properties` and `catalog_configuration/minio.properties`, filling `s3.aws-access-key`, `s3.aws-secret-key`, or use environment-driven placeholders. Create dedicated keys via [`../minio/README.md`](../minio/README.md#credentials) so each catalog has its own access.
- **Hive Metastore:** Update `shared/metastore-site.xml` with the PostgreSQL username/password that match the Hive metastore database. Coordinate with [`../hive-metastore/README.md`](../hive-metastore/README.md#credentials) to keep settings aligned.
- **PostgreSQL (metastore backend):** Ensure the JDBC URL in `shared/metastore-site.xml` references the database created using the instructions in [`../postgresql/README.md`](../postgresql/README.md#credentials).
- **Node identity (optional):** Populate `/home/admin/trino/coordinator/etc/trino/password-authenticator.properties` or other auth files if you enable security; store credentials outside source control.

## Preparation
1. Copy the contents of `trino/catalog_configuration` and `trino/shared` into the matching host paths. Update the compose file if you prefer different mount points.
2. Edit the catalog property files:
   - `catalog_configuration/iceberg.properties`
   - `catalog_configuration/minio.properties`
   Insert MinIO access/secret keys and adjust endpoints if your NAS IP changes.
3. Update `shared/core-site.xml` and `shared/metastore-site.xml` with the same credentials and JDBC connection details for the Hive Metastore database.
4. Export any extra environment variables referenced by your configs (for example service principals or TLS overrides if you add them later).
5. Adjust `deploy.replicas` under `trino-worker` to match the number of workers you want to run.

## Start & Stop
```bash
docker compose -f trino/docker-compose.yml up -d
# tear down
docker compose -f trino/docker-compose.yml down
```

## Validation
- Access the Web UI at `http://<trino-coordinator-host>:8080` to confirm the cluster is active and sees its workers.
- From a workstation with the Trino CLI installed:
  ```bash
  trino --server http://<trino-coordinator-host>:8080 --catalog iceberg --schema default -e "SHOW TABLES"
  ```
- Query `system.runtime.nodes` to ensure the expected number of worker nodes registered.

## Operations
- Any change to catalog or Hadoop configs requires a container restart (`docker compose -f trino/docker-compose.yml restart`).
- Keep the catalog files in source control (`trino/catalog_configuration`) and sync to the host via rsync or CI so changes are tracked.
