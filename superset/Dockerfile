FROM apache/superset:latest@sha256:6f6c9982bd64d81797bd4f33834f2ce4a4653c8ac8322f1e5f9df9b0332d092a
# Switching to root to install the required packages
USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    wget curl \
    bzip2 unzip \
    git \
    dnsutils \
    iputils-ping \
    gfortran gcc \
    openssh-client \
    default-libmysqlclient-dev \
    unixodbc unixodbc-dev \
    libpq-dev libsasl2-dev libkrb5-dev \
    libldap2-dev libssl-dev \
    ca-certificates tzdata \
    pkg-config \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir --upgrade pip

# Example: installing the MySQL driver to connect to the metadata database
# if you prefer Postgres, you may want to use `psycopg2-binary` instead
# Ref: https://superset.apache.org/docs/configuration/databases
RUN pip install --no-cache-dir \
    flask-limiter \
    redis \
    mysqlclient \
    psycopg2-binary \
    sqlalchemy-trino trino \
    "PyHive[hive]" thrift thrift_sasl sasl \
    duckdb \ 
    clickhouse-connect \
    authlib python-ldap \
    pandas numpy pyarrow \
    boto3 s3fs minio

# Updating Superset configuration
# https://superset.apache.org/docs/configuration/configuring-superset/
COPY --chown=superset superset_config.py /app/
ENV SUPERSET_CONFIG_PATH /app/superset_config.py

# Switching back to using the `superset` user
USER superset