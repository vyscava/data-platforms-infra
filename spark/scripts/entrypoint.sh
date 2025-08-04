#!/bin/bash

set -e  # Exit on first error

########################################
# Spark Configuration
# Env Variables Ref: https://spark.apache.org/docs/latest/spark-standalone.html
########################################

# master, worker, or none
export SPARK_MODE="${SPARK_MODE:-none}"
export SPARK_MASTER_HOST="${SPARK_MASTER_HOST:-none}"
export SPARK_MASTER_URL="${SPARK_MASTER_URL:-spark://spark-master:7077}"
export SPARK_MASTER_WEBUI_PORT="${SPARK_MASTER_WEBUI_PORT:-8080}"
export SPARK_HOME="${SPARK_HOME:-/opt/spark}"

########################################
# Jupyter/Jupyverse Configuration
########################################

export JUPYTER_MODE="${JUPYTER_MODE:-none}"                     # master or none

export JUPYTER_NOTEBOOK_DIR="${JUPYTER_NOTEBOOK_DIR:-/home/iceberg/notebooks}"
export JUPYTER_IP="${JUPYTER_IP:-0.0.0.0}"
export JUPYTER_PORT="${JUPYTER_PORT:-8888}"
export JUPYTER_TOKEN="${JUPYTER_TOKEN:-''}"                     # Blank = disable auth
export JUPYTER_PASSWORD="${JUPYTER_PASSWORD:-''}"               # Not recommended for prod
export JUPYTER_ALLOW_ROOT="${JUPYTER_ALLOW_ROOT:-true}"

########################################
# Environment Summary (for logging)
########################################

echo "========== CONFIGURATION =========="
echo "SPARK_MODE:                 $SPARK_MODE"
echo "SPARK_MASTER_URL:           $SPARK_MASTER_URL"
echo "SPARK_MASTER_WEBUI_PORT:    $SPARK_MASTER_WEBUI_PORT"
echo "SPARK_HOME:                 $SPARK_HOME"
echo ""
echo "JUPYTER_MODE:               $JUPYTER_MODE"
echo "JUPYTER_NOTEBOOK_DIR:       $JUPYTER_NOTEBOOK_DIR"
echo "JUPYTER_IP:                 $JUPYTER_IP"
echo "JUPYTER_PORT:               $JUPYTER_PORT"
echo "JUPYTER_TOKEN:              $JUPYTER_TOKEN"
echo "JUPYTER_PASSWORD:           $JUPYTER_PASSWORD"
echo "JUPYTER_ALLOW_ROOT:         $JUPYTER_ALLOW_ROOT"
echo "==================================="

# Pass control to CMD from Dockerfile or provided by user
exec "$@"