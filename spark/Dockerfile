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

# Install Jupyter and other python deps
COPY requirements.txt .
RUN pip3 install --no-cache-dir --upgrade pip
RUN pip3 install -r requirements.txt

# Add scala kernel via spylon-kernel
RUN python3 -m spylon_kernel install

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

# Download AWS SDK bundle
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

# Start setting up folders to use in spark and jupyter
RUN mkdir -p /home/iceberg/notebooks /home/iceberg/spark-events /home/iceberg

# Install common LSP servers for DE/DS
# Ref: https://jupyterlab-lsp.readthedocs.io/en/latest/Language%20Servers.html
# RUN npm init -y
RUN npm install -g \
    pyright \
    sql-language-server \
    yaml-language-server \
    unified-language-server \
    vscode-json-languageserver-bin

# Building Jupyter Lab
RUN jupyter lab build

WORKDIR /home/iceberg

COPY scripts/entrypoint.sh .
RUN chmod u+x ./entrypoint.sh

COPY scripts/run.sh .
RUN chmod u+x ./run.sh

ENTRYPOINT ["./entrypoint.sh"]
CMD ["./run.sh"]