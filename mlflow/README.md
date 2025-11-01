# MLflow Stack

MLflow tracking server with the auth plugin enabled, storing metadata in PostgreSQL and artifacts in MinIO. Designed to run on the NAS alongside storage services.

## Dependencies
- PostgreSQL database dedicated to MLflow (`PSQL_MLFLOW_DB`) with matching user/password.
- MinIO bucket (for example `mlflow-artifacts`) and credentials matching `MINIO_ROOT_USER`/`MINIO_ROOT_PASSWORD`.
- `auth_config.ini` populated with a real admin user and connection string.

## Credentials
- **PostgreSQL:** Set `PSQL_MLFLOW_USER`, `PSQL_MLFLOW_PASSWORD`, `PSQL_MLFLOW_DB`, `POSTGRESS_HOSTNAME`, and `POSTGRESS_HOSTNAME_PORT` in `mlflow/docker-compose.yml`. Provision this database/user using the approach in [`../postgresql/README.md`](../postgresql/README.md#credentials).
- **MinIO:** Provide `MINIO_ROOT_USER` and `MINIO_ROOT_PASSWORD` (or a dedicated MLflow user) as environment variables. Populate `MLFLOW_ARTIFACTS_DESTINATION` with the bucket path created in [`../minio/README.md`](../minio/README.md#credentials).
- **MLflow auth:** Edit `auth_config.ini` to define `database_uri`, `admin_username`, and `admin_password`. Keep a copy of this file outside source control if you store real credentials.
- **Flask secret key:** Set `MLFLOW_FLASK_SERVER_SECRET_KEY` via environment variable or secret manager to secure session cookies.

## Preparation
1. **Auth configuration:** Edit `auth_config.ini`:
   - Set `database_uri` to the MLflow metadata database (e.g., `postgresql+psycopg2://mlflow_user:secret@<nas-host>:5434/mlflow_db`).
   - Provide `admin_username` and `admin_password` for the default MLflow admin account.
2. **Environment variables:** Export the values referenced in `docker-compose.yml`:
   - `MLFLOW_FLASK_SERVER_SECRET_KEY`
   - `PSQL_MLFLOW_USER`, `PSQL_MLFLOW_PASSWORD`, `PSQL_MLFLOW_DB`
   - `POSTGRESS_HOSTNAME`, `POSTGRESS_HOSTNAME_PORT`
   - `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD`, `AWS_REGION`
3. **Buckets:** Ensure the MinIO bucket named in `MLFLOW_ARTIFACTS_DESTINATION` exists and the service account has read/write access.
4. **Ports:** Port `6000` is published for the MLflow UI; adjust if needed to avoid clashes on the NAS.

## Start & Stop
```bash
docker compose -f mlflow/docker-compose.yml up -d
# tear down
docker compose -f mlflow/docker-compose.yml down
```

## Validation
- Visit `http://<nas-host>:6000` and log in with the admin credentials defined in `auth_config.ini`.
- Run a quick tracking test:
  ```bash
  export MLFLOW_TRACKING_URI=http://<nas-host>:6000
  mlflow experiments list
  ```
- Confirm artifacts for a sample run land in the MinIO bucket under `/mlruns`.

## Operations
- To rotate credentials, update `auth_config.ini` and the relevant environment variables, then restart the container.
- Use the `scripts/entrypoint.sh` as a reference if you need to customise gunicorn flags or worker counts (`MLFLOW_WORKERS_NB`).
