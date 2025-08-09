FROM apache/superset:latest@sha256:31d965435b462361d2b8207595eff28f54492778d0afd53768da5e763cc16ce7
# Switching to root to install the required packages
USER root

RUN pip install --no-cache-dir --upgrade pip

# Example: installing the MySQL driver to connect to the metadata database
# if you prefer Postgres, you may want to use `psycopg2-binary` instead
# Ref: https://superset.apache.org/docs/configuration/databases
RUN pip install --no-cache-dir \
    flask-limiter \
    redis \
    mysqlclient \
    psycopg2-binary \
    sqlalchemy-trino \
    pyhive \
    trino

# Updating Superset configuration
# https://superset.apache.org/docs/configuration/configuring-superset/
COPY --chown=superset superset_config.py /app/
ENV SUPERSET_CONFIG_PATH /app/superset_config.py

# Switching back to using the `superset` user
USER superset