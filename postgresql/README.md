# PostgreSQL Stack

Single PostgreSQL 17 instance (plus pgAdmin) that backs Airflow, Superset, MLflow, Iceberg REST, Hive Metastore, and any other metadata services. Runs on the NAS for durability and low-latency access from co-located services.

## Dependencies
- Persistent storage directory on the NAS (`/volume2/dockers/postgres`) with adequate disk space.
- Credentials exported for:
  - `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` (bootstrap database)
  - `PGADMIN_USER_EMAIL`, `PGADMIN_PASSWORD`
- Network access from Proxmox nodes to port `5434`.

## Credentials
- **Bootstrap user:** Define `POSTGRES_USER`, `POSTGRES_PASSWORD`, and `POSTGRES_DB` in `postgresql/docker-compose.yml` (preferably sourced from an `.env` file kept out of git). This superuser can create the downstream service databases.
- **Service databases:** For each component (Airflow, Superset, MLflow, Iceberg, Hive), create dedicated users with limited privileges. Capture the usernames/passwords and plug them into the respective READMEs: [`../airflow/README.md`](../airflow/README.md#credentials), [`../superset/README.md`](../superset/README.md#credentials), [`../mlflow/README.md`](../mlflow/README.md#credentials), [`../iceberg-rest/README.md`](../iceberg-rest/README.md#credentials), [`../hive-metastore/README.md`](../hive-metastore/README.md#credentials).
- **pgAdmin access:** Set `PGADMIN_USER_EMAIL` and `PGADMIN_PASSWORD` for the administrative UI; store them in your secret manager if you expose pgAdmin beyond your LAN.
- **Persisting secrets:** Consider using Docker secrets or a password manager to store copies of each credential so you can rebuild the stack quickly.

## Preparation
1. Create the storage path (`/volume2/dockers/postgres`) and ensure it is owned by the NAS system user that runs containers.
2. Decide on database names for each service. Suggested layout:
   - Airflow → `airflow_db`
   - Superset → `superset_db`
   - MLflow → `mlflow_db`
   - Iceberg catalog → `iceberg_catalog`
   - Hive Metastore → `metastore_db`
3. Create corresponding users with appropriate privileges either through pgAdmin, `psql`, or automation once the container is online.

## Start & Stop
```bash
docker compose -f postgresql/docker-compose.yml up -d
# tear down
docker compose -f postgresql/docker-compose.yml down
```

pgAdmin becomes available at `http://<nas-host>:8280`.

## Collation Maintenance
When upgrading NAS locales or after host OS updates, run the collation fixer to keep databases consistent:
```bash
docker compose -f postgresql/docker-compose-collation.yml up --build
```
The helper script connects to each database and refreshes collations when mismatches are detected.

## Validation
- `psql -h <nas-host> -p 5434 -U <user> -d <db> -c '\conninfo'` should succeed from other hosts.
- pgAdmin should list all service databases once credentials are saved.
- Monitor `docker compose logs postgres` to confirm it applied WAL settings and health checks pass.

## Operations
- Use pgAdmin or scheduled jobs to run VACUUM and backups (pg_dump or NAS snapshots).
- Keep service accounts scoped to their databases to limit risk if credentials leak.
