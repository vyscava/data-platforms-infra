FROM python:3.11-bullseye@sha256:df0bd610af061603b29d63eb82027b64d5a3f15506e39270422b10b2a55079fc

# Installing basic dependencies other dependencies
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
      sudo \
      wget curl \
      vim nano less \
      bzip2 unzip \
      openjdk-17-jdk \
      build-essential \
      software-properties-common \
      netbase net-tools iproute2 \
      ca-certificates ca-certificates-java \
      locales tzdata \
      procps \
      lsof \
      gnupg \
      git \
      cm-super \
      ffmpeg \
      xclip \
      texlive-xetex texlive-fonts-recommended texlive-plain-generic \
      fonts-dejavu fonts-liberation \
      pandoc \
      gfortran gcc \
      openssh-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    echo "C.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen

# Installing NodeJS 20 as it is required by Jupyter
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt install -y nodejs && \
    npm install -g yarn && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
 && unzip awscliv2.zip \
 && ./aws/install \
 && rm awscliv2.zip \
 && rm -rf aws/

# Install MLFlow and other python deps
RUN pip3 install --no-cache-dir --upgrade pip
RUN pip3 install --no-cache-dir \
    mlflow[extras,auth] \
    sqlalchemy psycopg2-binary \
    boto3 s3fs minio

# Copy entrypoint script
COPY scripts/entrypoint.sh /usr/local/bin/
RUN chmod u+x /usr/local/bin/entrypoint.sh

# non-root user
RUN groupadd --gid 10001 mlflow  \
    && useradd --uid 10001 --gid mlflow --shell /bin/bash --create-home mlflow

USER 10001

WORKDIR /home/mlflow

# Setting defaults for Env Variables

# Port to expose MLFlow service
ENV MLFLOW_PORT=5000

# S3 Path for MLFlow to store artifacts
ENV MLFLOW_ARTIFACTS_DESTINATION=s3://mlflow-artifacts

# Number of Workers for the MLFlow Server
ENV MLFLOW_WORKERS_NB=4

# Where the Auth File should be placed for MLFlow to load it
ENV MLFLOW_AUTH_CONFIG_PATH=/home/mlflow/auth_config.ini

# Copying Auth Config utilized by MLFlow Auth Module
COPY auth_config.ini ${MLFLOW_AUTH_CONFIG_PATH}

# Expose MLflow default port
EXPOSE ${MLFLOW_PORT}

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]