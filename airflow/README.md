# Airflow Stack

Celery-based Apache Airflow deployment that mirrors AWS MWAA behaviour for orchestrating Spark workloads against the Iceberg catalog. Runs on the Proxmox compute host so it can reach Spark locally while persisting metadata in PostgreSQL and datasets in MinIO.

## Dependencies
- PostgreSQL instance from `postgresql/` with an Airflow database/user (`PSQL_AIRFLOW_DB`, `PSQL_AIRFLOW_USER`, `PSQL_AIRFLOW_PASSWORD`).
- Redis reachable at `<redis-hostname>:6379` for the Celery broker (update the compose file to point at your DNS entry or IP).
- MinIO credentials (`MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD`) and region (`AWS_REGION`).
- Spark master service from `spark/` reachable on the LAN (`SPARK_MASTER_HOST`, `SPARK_MASTER_WEBUI_PORT`, `SPARK_MASTER_URL`).
- Iceberg REST catalog and Hive Metastore already online.

## Credentials
- **PostgreSQL:** Supply `POSTGRESS_HOSTNAME`, `POSTGRESS_HOSTNAME_PORT`, `PSQL_AIRFLOW_USER`, `PSQL_AIRFLOW_PASSWORD`, and `PSQL_AIRFLOW_DB` in the `environment` block of `airflow/docker-compose.yml` (or through an `.env` file sitting beside the compose file). Create the matching user/database following the steps in [`../postgresql/README.md`](../postgresql/README.md#credentials).
- **MinIO:** Export `MINIO_ROOT_USER` and `MINIO_ROOT_PASSWORD` (or a dedicated service account) for both the Airflow workers and Spark tasks. Update `airflow/docker-compose.yml` and fill the `spark.hadoop.fs.s3a.access.key` / `spark.hadoop.fs.s3a.secret.key` entries inside `airflow/spark-defaults.conf`. See [`../minio/README.md`](../minio/README.md#credentials) for generating additional keys.
- **Redis:** If you run Redis externally, set `AIRFLOW__CELERY__BROKER_URL` to your custom URL. When using credentials, embed them in the URL (`redis://:password@host:port/0`) and keep them out of source control by leveraging environment variable substitution.

## Preparation
1. **Host folders:** Create `/home/admin/airflow/airflow-resources/{dags,plugins,logs,config,spark-events}` and `/mnt/nfs/dockers/spark/scripts` (or equivalent paths on your compute host). Align ownership so UID `1024` can write (matches the container user).
2. **Spark defaults:** Edit `airflow/spark-defaults.conf` with the correct Spark master address and populate the MinIO access/secret keys so Airflow-triggered Spark jobs can talk to the warehouse.
3. **Environment variables:** Export the variables referenced in `docker-compose.yml`, especially:
   - `AIRFLOW_HOSTNAME`
   - `POSTGRESS_HOSTNAME`, `POSTGRESS_HOSTNAME_PORT`
   - `PSQL_AIRFLOW_USER`, `PSQL_AIRFLOW_PASSWORD`, `PSQL_AIRFLOW_DB`
   - `SPARK_MASTER_HOST`, `SPARK_MASTER_WEBUI_PORT`, `SPARK_MASTER_URL`, `SPARK_LOCAL_IP`
   - `AWS_REGION`, `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD`
4. **Optional Python deps:** If DAGs require extra packages, add them under `/home/admin/airflow/airflow-resources/plugins` or bake them into a custom image.

## Start & Stop
```bash
docker compose -f airflow/docker-compose.yml up airflow-init
docker compose -f airflow/docker-compose.yml up -d
```
Stopping the stack:
```bash
docker compose -f airflow/docker-compose.yml down
```

## Validation
- Navigate to `http://<proxmox-airflow-host>:8080` and confirm the webserver loads.
- Check `docker compose ps` to ensure `airflow-scheduler`, `airflow-worker`, `airflow-triggerer`, and `flower` are healthy.
- Inspect the worker logs under `/home/admin/airflow/airflow-resources/logs` to verify Celery connections to Redis and PostgreSQL succeed.
- From Jupyter, trigger a DAG that submits a Spark job and confirm the `spark-events` folder captures event logs.

## Operations
- Use `./airflow/airflow.sh info` for ad-hoc CLI access without manually entering containers.
- DAGs live in `/home/admin/airflow/airflow-resources/dags`; update this path via NFS if you author DAGs from another workstation.
- Flower runs on port `5555` (host network). Expose it via reverse proxy if you need remote access.
