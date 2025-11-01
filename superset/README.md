# Superset Stack

Apache Superset configured for analytics dashboards backed by Trino and other data sources. Runs on the NAS with Redis for caching and rate limiting.

## Dependencies
- PostgreSQL metadata database (`PSQL_SUPERSET_DB`) created in the `postgresql/` stack with its own user/password.
- MinIO/Trino/Hive services online so you can register them as databases once Superset is running.
- `superset_config.py` populated with valid credentials and a non-empty `SECRET_KEY`.

## Credentials
- **PostgreSQL:** Set `POSTGRESS_HOSTNAME`, `POSTGRESS_HOSTNAME_PORT`, `PSQL_SUPERSET_USER`, `PSQL_SUPERSET_PASSWORD`, and `PSQL_SUPERSET_DB` in `superset/docker-compose.yml`. Create the database and user as described in [`../postgresql/README.md`](../postgresql/README.md#credentials).
- **Superset secret key:** Update `superset_config.py` with a strong `SECRET_KEY` and optionally export `SUPERSET_SECRET_KEY` in your environment to override it in production.
- **External data sources:** When adding Trino or MinIO-backed connections via the UI, use the credential guidance in [`../trino/README.md`](../trino/README.md#credentials) and [`../minio/README.md`](../minio/README.md#credentials).
- **Redis (optional):** If you secure Redis with a password, modify the `redis` URL in `superset_config.py` to include the credentials, or source them from environment variables to keep secrets out of version control.

## Preparation
1. Copy `superset_config.py` to `/volume2/dockers/superset/superset_config.py` (or adjust the compose volume to match your preferred path).
2. Edit the config file:
   - Set `SECRET_KEY` to a strong value.
   - Verify the PostgreSQL connection string points to `postgresql://<user>:<password>@<host>:5434/<db>`.
   - Update any Redis endpoints if they differ.
3. Export the environment variables used in `docker-compose.yml`:
   - `POSTGRESS_HOSTNAME`, `POSTGRESS_HOSTNAME_PORT`
   - `PSQL_SUPERSET_USER`, `PSQL_SUPERSET_PASSWORD`, `PSQL_SUPERSET_DB`
4. Ensure volumes `superset-data` and `redis-data` either exist or let Docker create them.

## Start & Stop
```bash
docker compose -f superset/docker-compose.yml up -d
# tear down
docker compose -f superset/docker-compose.yml down
```

## Initialisation
After the containers are healthy, initialise Superset:
```bash
cd superset
./bootstrap-superset.sh
```
The script creates an admin user, runs database migrations, and performs the initial bootstrap.

## Validation
- Browse to `http://<nas-host>:8088` and log in with the credentials set during bootstrap.
- Under *Settings → Database Connections*, add Trino using the installed `sqlalchemy-trino` driver (e.g., `trino://user@<compute-host>:8080?catalog=iceberg&schema=default`).
- Confirm Redis is connected by checking the application logs for rate limiter warnings.

## Operations
- When you change Python dependencies, bake a new image or install packages at runtime before restarting the container.
- The `superset-data` volume holds uploaded dashboards and config; back it up periodically via NAS snapshots.
