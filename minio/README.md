# MinIO Stack

Self-hosted object storage that backs the whole data lake: raw files, Iceberg table warehouse, and MLflow artifacts. Runs on the Synology NAS to keep data close to disks while exposing S3-compatible APIs on the LAN.

## Dependencies
- Dedicated directory on the NAS for data (`/volume3/files/Minio`) and configuration (`/volume2/dockers/minio/config`). Swap these paths for your storage appliance if it mounts locations differently.
- Credentials exported via `MINIO_ROOT_USER` and `MINIO_ROOT_PASSWORD`.
- Optional DNS entry so clients can hit `http://<nas-host>:9000` without hardcoding IPs.

## Credentials
- **Root credentials:** Set `MINIO_ROOT_USER` and `MINIO_ROOT_PASSWORD` in the environment section of `minio/docker-compose.yml` (consider using a `.env` file next to the compose file to avoid committing secrets).
- **Service accounts:** Create per-service access keys from the MinIO Console or via `mc admin user add` once the stack is online. Document the generated keys and plug them into dependent applications (see the credential sections in [`../spark/README.md`](../spark/README.md#credentials) or [`../airflow/README.md`](../airflow/README.md#credentials)).
- **Policies:** Apply least-privilege policies to each user. Keep the JSON policy files under version control if you plan to reuse them.

## Preparation
1. Create the folders referenced in the compose file. Retain NAS ownership so the container process can read/write (`root` inside the container).
2. Decide on bucket names for:
   - Iceberg warehouse (`ICEBERG_WAREHOUSE`, e.g., `iceberg-data/warehouse`)
   - MLflow artifacts (`mlflow-artifacts`)
   - Any raw or curated zones you plan to mount in Spark or Trino
3. Update dependent configuration files (Spark, Hive, Trino) with the MinIO endpoint (for example `http://<nas-host>:9000`) and access keys.

## Start & Stop
```bash
docker compose -f minio/docker-compose.yml up -d
# tear down
docker compose -f minio/docker-compose.yml down
```

## Post-Launch Tasks
- Access the console at `http://<nas-host>:9001` with the root credentials.
- Create the buckets noted earlier and set policies (`ReadWrite` for compute users, `ReadOnly` for BI).
- If you use the MinIO Client (`mc`), bootstrap it once:
  ```bash
  mc alias set homelab http://<nas-host>:9000 $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD
  mc mb homelab/iceberg-data
  mc policy set homelab/iceberg-data none
  ```
  Adjust policy levels depending on who accesses the bucket.

## Validation
- `curl http://<nas-host>:9000/minio/health/live` should return `OK`.
- From another service (Spark, Trino, MLflow), list buckets to confirm credentials propagate correctly.
- Monitor NAS disk usage; MinIO writes directly to the mounted `/volume3/files/Minio` path.
