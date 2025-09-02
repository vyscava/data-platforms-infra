FROM apache/airflow:3.0.6@sha256:235a362ae98882d21c9f6bfa0b9cdd5da8f36c94b5d58c397cf7a9674509be35

USER root

RUN apt-get update && apt-get install -y \
    wget curl \
    bzip2 unzip \
    git \
    dnsutils \
    iputils-ping \
    gfortran gcc \
    openssh-client \
    openjdk-17-jdk ant \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Creating JAVA_HOME so Airflow can use Spark Submit
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="$JAVA_HOME/bin:$PATH"

# Getting Ready to install Spark
ENV SPARK_HOME=${SPARK_HOME:-"/opt/spark"}
# Adding Py4j that will be installed together with Spark so Jupyter knows how to use PySpark
ENV PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.9.7-src.zip:$PYTHONPATH

WORKDIR ${SPARK_HOME}

# Iceberg at the moment only works w Spark 3.5.6, not 4
ENV SPARK_VERSION=3.5.6
ENV SPARK_MAJOR_VERSION=3.5
ENV ICEBERG_VERSION=1.9.0

# Download spark
RUN mkdir -p ${SPARK_HOME} \
 && curl https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz -o spark-${SPARK_VERSION}-bin-hadoop3.tgz \
 && tar xvzf spark-${SPARK_VERSION}-bin-hadoop3.tgz --directory /opt/spark --strip-components 1 \
 && rm -rf spark-${SPARK_VERSION}-bin-hadoop3.tgz

# Download iceberg spark runtime
RUN curl https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-${SPARK_MAJOR_VERSION}_2.12/${ICEBERG_VERSION}/iceberg-spark-runtime-${SPARK_MAJOR_VERSION}_2.12-${ICEBERG_VERSION}.jar \
    -Lo /opt/spark/jars/iceberg-spark-runtime-${SPARK_MAJOR_VERSION}_2.12-${ICEBERG_VERSION}.jar

# Download AWS bundle
RUN curl -s https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-aws-bundle/${ICEBERG_VERSION}/iceberg-aws-bundle-${ICEBERG_VERSION}.jar \
    -Lo /opt/spark/jars/iceberg-aws-bundle-${ICEBERG_VERSION}.jar

# Download Hadoop AWS & SDK bundle
RUN curl -sSL https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar \
    -Lo /opt/spark/jars/hadoop-aws-3.3.4.jar

RUN curl -sSL https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.603/aws-java-sdk-bundle-1.12.603.jar \
    -Lo /opt/spark/jars/aws-java-sdk-bundle-1.12.603.jar

# Download Posgres Driver
RUN curl https://repo1.maven.org/maven2/org/postgresql/postgresql/42.7.3/postgresql-42.7.3.jar \
 -Lo /opt/spark/jars/postgresql-42.7.3.jar

# Download OpenLineage Support for Spark
RUN curl https://repo1.maven.org/maven2/io/openlineage/openlineage-spark_2.13/1.36.0/openlineage-spark_2.13-1.36.0.jar \
 -Lo /opt/spark/jars/openlineage-spark_2.13-1.36.0.jar

# Finishing setting up spark
COPY spark-defaults.conf /opt/spark/conf
ENV PATH="/opt/spark/sbin:/opt/spark/bin:${PATH}"

RUN chmod u+x /opt/spark/sbin/* && \
    chmod u+x /opt/spark/bin/*

USER airflow

# Creating a place for the Spark Events logs
RUN mkdir -p /opt/airflow/spark-events

RUN pip install --no-cache-dir \
    apache-airflow[celery,postgres,redis,dbt,slack,amazon]==3.0.3 \
    # PySpark needs to be the same version as the Spark Server
    pyspark==3.5.6 \
    apache-airflow-providers-trino \
    apache-airflow-providers-apache-spark \
    apache-airflow-providers-common-compat \
    pandas numpy pyarrow \
    boto3 s3fs minio \
    psycopg2-binary requests \
    trino \
    findspark

# /opt/airflow
WORKDIR ${AIRFLOW_HOME}