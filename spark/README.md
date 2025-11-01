# Spark + Jupyter Stack

Custom Apache Spark 3.5.6 image with JupyterLab, Iceberg runtime, and OpenLineage support baked in. Provides the interactive compute plane for ETL jobs and experimentation, similar to AWS Glue jobs or SageMaker notebooks. Deployed on the Proxmox compute host.

## Dependencies
- Access to MinIO at `http://<nas-host>:9000` (or equivalent hostname) with credentials for S3A.
- Iceberg REST catalog online at `http://<nas-host>:8181`.
- Hive Metastore available at `thrift://<nas-host>:9083` for legacy table support.
- Host directories (adjust paths to match your compute node):
  - `/home/admin/spark-custom/` containing the Dockerfile, configs, and scripts from this repository.
  - `/mnt/nfs/dockers/jupyter` shared location for notebooks.
- Exported environment variables: `SPARK_MASTER_HOST`, `SPARK_MASTER_WEBUI_PORT`, `SPARK_MASTER_URL`, `SPARK_LOCAL_IP`, `AWS_REGION`, `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD`.

## Credentials
- **MinIO/S3 access:** Fill `spark.hadoop.fs.s3a.access.key` and `spark.hadoop.fs.s3a.secret.key` inside `spark/spark-defaults.conf`. When running on workers launched by the same compose stack, also set `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` (or the MinIO root credentials) in `spark/docker-compose.yml`. Generate or rotate keys following [`../minio/README.md`](../minio/README.md#credentials).
- **Iceberg catalog:** Ensure `spark.sql.catalog.iceberg` properties match the catalog name and endpoint configured in [`../iceberg-rest/README.md`](../iceberg-rest/README.md#credentials).
- **Hive metastore:** Update `spark.hadoop.hive.metastore.uris` if your metastore runs on a different host or port. Refer to [`../hive-metastore/README.md`](../hive-metastore/README.md#credentials) for the expected URI structure.

## Preparation
1. **Sync sources:** Copy everything under `spark/` to the host path referenced in the compose file (`/home/admin/spark-custom`). Adjust `docker-compose.yml` if you prefer another path.
2. **Configure Spark defaults:** Edit `spark/spark-defaults.conf` to:
   - Set `spark.master` to the master node address (or comment it if using standalone discovery).
   - Populate the MinIO access and secret keys.
   - Confirm Iceberg warehouse settings match the MinIO bucket created earlier.
3. **Jupyter settings:** Update `jupyter_server_config.py` if you want to enforce tokens or passwords. The Dockerfile installs common LSP servers and Python tooling already.
4. **Notebook storage:** Ensure `/mnt/nfs/dockers/jupyter` exists and is writable so Jupyter sessions persist notebooks across restarts.

## Start & Stop
```bash
docker compose -f spark/docker-compose.yml up -d
# tear down
docker compose -f spark/docker-compose.yml down
```

The compose file starts one master and two workers. Adjust the `deploy.replicas` or resource limits to match available CPUs/RAM.

## Validation
- Visit `http://<spark-host>:8888` to access JupyterLab. Disable the blank token by setting `JUPYTER_TOKEN` before launch if you need authentication.
- Visit `http://<spark-host>:8081` for the Spark master UI (host networking exposes it directly).
- Run a notebook that executes:
  ```python
  spark.sql("SHOW NAMESPACES IN iceberg").show()
  ```
  to confirm the Iceberg catalog is wired up.
- Check `/home/iceberg/spark-events` inside the container (mapped to host via Airflow) to ensure event logging is active.

## Operations
- Use the provided `scripts/entrypoint.sh` and `scripts/run.sh` to customise how Spark and Jupyter start (for example to add history server).
- To add extra jars, drop them into `/home/admin/spark-custom/jars` and extend the Dockerfile with additional `curl` statements or mount a folder at runtime.
