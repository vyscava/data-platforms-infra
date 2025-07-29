FROM apache/airflow:3.0.3@sha256:66d35503f78e8c87de2db43f0a3311efd26a5d34584599509a8bd90fb308adc7

USER root

RUN apt-get update && apt-get install -y \
    curl \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

USER airflow

RUN pip install --no-cache-dir \
    apache-airflow[celery,postgres,redis,dbt,slack,amazon]==3.0.3 \
    pandas numpy pyarrow \
    boto3 s3fs minio \
    psycopg2-binary requests \
    trino \
    findspark