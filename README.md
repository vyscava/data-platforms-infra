# Home Lab Data Lake Infrastructure

An opinionated blueprint for showcasing modern data engineering on commodity hardware. The stack mirrors familiar AWS analytics services with fully open-source components so you can demo end-to-end pipelines, ML workflows, and BI storytelling from your homelab.

## Reference Architecture

```
Data Sources  -->  Airflow (orchestrates jobs) -----------------------------+
                   |                                                        |
                   v                                                        |
            Spark + Jupyter (ETL & notebooks)                               |
                   |        \                                               |
                   v         \--> MLflow (experiments & artifacts)          |
             Iceberg REST Catalog (metadata)                                |
                   |                                                        |
                   v                                                        |
            MinIO Object Storage  <---------  Hive Metastore (legacy tables)|
                   |                                                        |
                   v                                                        |
     Trino (SQL lakehouse)  -->  Superset (dashboards & storytelling)       |
                   |
                   v
           Stakeholder insights
```

See [`docs/architecture.md`](docs/architecture.md) for a deeper dive, sequence diagrams, and recommended variations for different audiences.

## Component Map
| Service | Role | AWS Analogue | Preferred Host | Default Endpoint |
| --- | --- | --- | --- | --- |
| MinIO | Object storage for raw/curated data and ML artifacts | S3 | NAS or storage appliance (`<nas-host>`) | 9000 (API), 9001 (console) |
| PostgreSQL | Metadata backing store for platform services | RDS/Aurora | NAS (`<nas-host>`) | 5434 (SQL), 8280 (pgAdmin) |
| Hive Metastore | Legacy catalog backing Trino/Spark | AWS Glue Metastore | NAS (`<nas-host>`) | 9083 |
| Iceberg REST | Iceberg REST catalog backed by Postgres | AWS Glue Catalog | NAS (`<nas-host>`) | 8181 |
| Spark + Jupyter | Interactive compute for ELT & notebooks | Glue jobs / SageMaker Studio | Proxmox or x86 compute node (`<compute-host>`) | 7077, 8081, 8888 |
| Airflow | Workflow orchestration (Celery executor) | AWS MWAA | Proxmox or x86 compute node (`<compute-host>`) | 8080 |
| Trino | SQL query engine over object storage | Athena | Proxmox or x86 compute node (`<compute-host>`) | 8080 |
| MLflow | Experiment tracking & artifact registry | SageMaker MLflow | NAS (`<nas-host>`) | 6000 |
| Superset | BI exploration and dashboards | QuickSight | NAS (`<nas-host>`) | 8088 |

> **Reference host layout:** Storage-heavy, stateful services (MinIO, MLflow, Hive, Iceberg catalog, Superset, PostgreSQL) stay close to shared disks. Compute-heavy services (Spark, Jupyter, Trino, Airflow) sit on the Proxmox cluster or any node with additional CPU headroom. Replace `<nas-host>` and `<compute-host>` with the addresses that map to your homelab.

## Typical Workflows
- **Data Engineer persona**
  1. Use Airflow to schedule ingestion from on-prem or cloud sources into landing buckets on MinIO.
  2. Develop transformation notebooks in Jupyter, committing Iceberg tables via the REST catalog.
  3. Validate datasets with Trino SQL checks before handing them over to downstream teams.
- **Business Intelligence persona**
  1. Query curated Iceberg tables through Trino or build semantic models in Superset.
  2. Publish dashboards that combine operational metrics with ML predictions stored in MinIO.
  3. Schedule refreshes or anomaly detection DAGs in Airflow to keep visuals up to date.
- **Machine Learning persona**
  1. Iterate on feature engineering notebooks in Spark.
  2. Track experiments, parameters, and artifacts in MLflow pointing at the same object store.
  3. Promote approved models and expose them to BI through MinIO-hosted prediction outputs.

## Prerequisites
- Docker Engine 24+ and Compose V2 on each host that will run containers.
- A reachable NAS or storage appliance (for example `192.168.50.2`) exporting the directories referenced in the compose files (e.g., `/volume2/dockers/...`). Swap in your own paths if your NAS uses different mount points.
- Internal DNS or `/etc/hosts` entries so containers can resolve service hostnames. Replace sample values like `airflow-redis.local.example.com` with names from your environment.
- Outbound internet on the build hosts the first time images are built (Spark and MLflow Dockerfiles download dependencies).
- PostgreSQL credentials with privileges to create separate databases per service.
- Buckets in MinIO for Iceberg (`ICEBERG_WAREHOUSE`) and MLflow artifacts (`mlflow-artifacts`) created ahead of time.

## Network & Storage Alignment
- Many compose files mount absolute paths (`/home/admin/...`, `/volume2/dockers/...`). Adjust these paths to match the mount points on each host.
- Several services use `network_mode: host` to simplify cross-host communication. Open the listed ports on the LAN firewalls for the machines that run those containers.
- Replace the sample DNS resolver IPs (e.g., `192.168.50.4`) with the address of your own DNS server or local resolver.
- Validate NFS or SMB mounts backing the shared folders are mounted before running `docker compose up` so the containers do not start with empty directories.

## Environment Configuration
Define the environment variables referenced by the compose files in your shell session, compose overrides, or host-specific secret storage before starting each service.

**Core data services**
- `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`
- `PGADMIN_USER_EMAIL`, `PGADMIN_PASSWORD`
- `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD`, `AWS_REGION`, `MINIO_ENDPOINT`

**Catalog & storage**
- `ICEBERG_CATALOG_NAME`, `ICEBERG_WAREHOUSE`, `PSQL_ICEBERG_USER`, `PSQL_ICEBERG_PASSWORD`, `PSQL_ICEBERG_DB`, `POSTGRESS_HOSTNAME`, `POSTGRESS_HOSTNAME_PORT`
- `HIVE_CONF_SERVICE_NAME`, `HIVE_CONF_DB_DRIVER`, `HIVE_CONF_HIVE_CUSTOM_CONF_DIR`, `HIVE_CONF_HADOOP_CLASSPATH`

**Compute & orchestration**
- `SPARK_MASTER_HOST`, `SPARK_MASTER_WEBUI_PORT`, `SPARK_MASTER_URL`, `SPARK_LOCAL_IP`
- `AIRFLOW_HOSTNAME`, `PSQL_AIRFLOW_USER`, `PSQL_AIRFLOW_PASSWORD`, `PSQL_AIRFLOW_DB`
- `SPARK_LOCAL_IP`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` (inherited from MinIO credentials)

**Analytics & ML tooling**
- `PSQL_MLFLOW_USER`, `PSQL_MLFLOW_PASSWORD`, `PSQL_MLFLOW_DB`, `MLFLOW_FLASK_SERVER_SECRET_KEY`
- `PSQL_SUPERSET_USER`, `PSQL_SUPERSET_PASSWORD`, `PSQL_SUPERSET_DB`, `SUPERSET_SECRET_KEY`

Fill the matching S3 credentials in Trino `catalog_configuration/*.properties`, Spark `spark-defaults.conf`, Airflow `spark-defaults.conf`, and Hive configuration files so every engine can talk to MinIO.

## Bring-Up Order
Bringing services up in dependency order helps avoid connection churn:
1. **postgresql/** – `docker compose -f postgresql/docker-compose.yml up -d`
2. **minio/** – `docker compose -f minio/docker-compose.yml up -d`
3. **hive-metastore/** – `docker compose -f hive-metastore/docker.compose.yml up -d`
4. **iceberg-rest/** – `docker compose -f iceberg-rest/docker-compose.yml up -d`
5. **spark/** – `docker compose -f spark/docker-compose.yml up -d`
6. **airflow/** – `docker compose -f airflow/docker-compose.yml up -d`
7. **trino/** – `docker compose -f trino/docker-compose.yml up -d`
8. **mlflow/** – `docker compose -f mlflow/docker-compose.yml up -d`
9. **superset/** – `docker compose -f superset/docker-compose.yml up -d`

Run the collations helper in `postgresql/docker-compose-collation.yml` whenever the host locale changes to ensure PostgreSQL databases stay in sync.

## Sanity Checks After Deployment
- Sign in to the MinIO Console (e.g., `http://<nas-host>:9001`) and confirm the Iceberg and MLflow buckets exist.
- Confirm Iceberg REST catalog (`http://<nas-host>:8181/v1/config`) responds and lists the configured warehouse.
- In pgAdmin (`http://<nas-host>:8280`), verify each service database is reachable.
- From the Spark JupyterLab (`http://<compute-host>:8888`), run a notebook that lists Iceberg tables.
- In Trino CLI or Web UI, query the Iceberg catalog to confirm connectivity.
- Use Superset to register the Trino connection and visualize a sample dataset.
- Validate MLflow UI (`http://<nas-host>:6000`) loads with authentication.

## Repository Layout
- `airflow/`, `spark/`, `trino/` – compute and orchestration running on the Proxmox data node.
- `minio/`, `hive-metastore/`, `iceberg-rest/`, `mlflow/`, `superset/`, `postgresql/` – storage-focused services anchored to the NAS.
- `common-jars/` – shared JDBC drivers and Iceberg bundles to copy into services when needed.

Each service directory now has its own README covering host-specific adjustments, credentials, and validation steps. Start there whenever you need to modify or troubleshoot a component.
