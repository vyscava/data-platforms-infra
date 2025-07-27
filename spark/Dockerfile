# FROM bitnami/spark:4.0.0@sha256:b3628303f812df47600b51fc632de017cac86e685255b5461d3914e7eaa6da82
FROM bitnami/spark:3.5.6@sha256:353e23d86c7952781042b4e91d1e2b018335f565430e449fff017269a273097f

USER root
# Set environment for consistent user identity
ENV NB_USER=datapro \
    NB_UID=0 \
    NB_GID=0 \
    HOME=/home/datapro

# Create a fake home for root with proper ownership
RUN mkdir -p /home/datapro && \
    ln -sfn /home/datapro ${HOME} && \
    chmod 755 /home/datapro

USER root

RUN install_packages curl

# Installing other dependencies
RUN mkdir -p /var/lib/apt/lists/partial
RUN apt update
RUN apt install -y net-tools iproute2 curl procps lsof gnupg git zip

# Install Node.js (required for JupyterLab extension building)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt install -y nodejs && \
    npm install -g yarn && \
    apt clean && rm -rf /var/lib/apt/lists/*

# Updating PiP
RUN pip install --no-cache-dir --upgrade pip

# Installing LSP Server to help lint and intellisense on Jupyter
RUN pip install 'python-lsp-server[all]'
RUN pip install 'python-language-server[all]'

# Install common LSP servers
RUN npm install -g --save-dev \
    bash-language-server \
    dockerfile-language-server-nodejs \
    javascript-typescript-langserver \
    pyright \
    sql-language-server \
    vscode-langservers-extracted \
    vscode-json-languageserver \
    vscode-html-languageserver-bin \
    vscode-css-languageserver-bin \
    yaml-language-server

# Install Jupyter and other Python Deps
# RUN pip install --no-cache-dir \
RUN pip install \
        jupyterlab \
        ipywidgets \
        jupyterlab-vim \
        jupyterlab-spellchecker \
        jupyterlab-git \
        jupyterlab-lsp \
        parso jedi \
        pandas numpy pyarrow \
        shap lime altair folium geopandas networkx \
        matplotlib seaborn plotly \
        openpyxl xlrd requests tqdm rich \
        torch torchvision torchaudio tensorflow keras transformers accelerate \
        datasets sentence-transformers fastai flax optuna mlflow \
        findspark hdfs \
        pyspark scikit-learn xgboost lightgbm statsmodels \
        duckdb duckdb-engine sqlalchemy \
        langchain llama-index sentence-transformers \
        transformers accelerate \
        faiss-cpu chromadb \
        psycopg2-binary pymongo mysql-connector-python \
        boto3 s3fs minio \
        openlineage-integration-common openlineage-python polars && \
    jupyter labextension install @jupyter-widgets/jupyterlab-manager && \
    jupyter lab build

# Install R and system dependencies for R packages
# RUN apt-get update && apt-get install -y \
#     r-base \
#     libcurl4-openssl-dev \
#     libssl-dev \
#     libxml2-dev && \
#     R -e "install.packages('IRkernel', repos='https://cloud.r-project.org/')" && \
#     R -e "IRkernel::installspec(user = FALSE)"

# RUN R -e "install.packages(c('tidyverse', 'data.table', 'caret', 'randomForest', 'xgboost', 'ggplot2', 'readxl'), repos='https://cloud.r-project.org/')"

########################################
# INSTALLING S3 Supporting files

# Safe for Spark 3.5.6 and Hadoop 3.3.x
RUN curl -sSL https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.603/aws-java-sdk-bundle-1.12.603.jar \
  -o /opt/bitnami/spark/jars/aws-java-sdk-bundle-1.12.603.jar

########################################
# INSTALLING Iceberg Support

# https://iceberg.apache.org/docs/latest/spark-getting-started/

# Spark 3.5
RUN curl https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-3.5_2.12/1.9.2/iceberg-spark-runtime-3.5_2.12-1.9.2.jar \
 --output /opt/bitnami/spark/jars/iceberg-spark-runtime-3.5_2.12-1.9.2.jar

RUN curl https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-aws-bundle/1.9.2/iceberg-aws-bundle-1.9.2.jar \
 --output /opt/bitnami/spark/jars/iceberg-aws-bundle-1.9.2.jar


########################################
# INSTALLING Database Drivers

 # Any Version
RUN curl https://repo1.maven.org/maven2/org/postgresql/postgresql/42.7.3/postgresql-42.7.3.jar \
 --output /opt/bitnami/spark/jars/postgresql-42.7.3.jar

########################################
# INSTALLING OpenLineage Support

RUN curl https://repo1.maven.org/maven2/io/openlineage/openlineage-spark_2.13/1.36.0/openlineage-spark_2.13-1.36.0.jar \
 --output /opt/bitnami/spark/jars/openlineage-spark_2.13-1.36.0.jar

#  Creating temp folder for Spark Logs
RUN mkdir -p /tmp/spark-events && \
 chown -R ${NB_UID}:${NB_GID} /tmp/spark-events

# Making sure permissions of jar files are correct
RUN chown -R ${NB_UID}:${NB_GID} /opt/bitnami/spark/jars
RUN chmod 755 /opt/bitnami/spark/jars

USER root
WORKDIR ${HOME}
