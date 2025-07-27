FROM apache/superset:latest@sha256:51a90d11a59ac522172642cece4bd8047917253e13d884293fcd0cd48419939c
# Switching to root to install the required packages
USER root

RUN pip install --upgrade pip

# Example: installing the MySQL driver to connect to the metadata database
# if you prefer Postgres, you may want to use `psycopg2-binary` instead
# Ref: https://superset.apache.org/docs/configuration/databases
RUN pip install flask-limiter
RUN pip install redis
RUN pip install mysqlclient
RUN pip install psycopg2-binary
RUN pip install sqlalchemy-trino
RUN pip install pyhive
RUN pip install trino

# Updating Superset configuration
# https://superset.apache.org/docs/configuration/configuring-superset/
COPY --chown=superset superset_config.py /app/
ENV SUPERSET_CONFIG_PATH /app/superset_config.py

# Switching back to using the `superset` user
USER superset