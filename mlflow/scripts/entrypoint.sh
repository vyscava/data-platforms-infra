#!/usr/bin/env bash
set -e

# Start MLflow server
exec mlflow server \
    --app-name basic-auth \
    --host 0.0.0.0 --port ${MLFLOW_PORT} \
    --backend-store-uri "${MLFLOW_BACKEND_STORE_URI}" \
    --artifacts-destination "${MLFLOW_ARTIFACTS_DESTINATION}" \
    --serve-artifacts \
    --workers ${MLFLOW_WORKERS_NB} \
    --gunicorn-opts="--timeout=120 --forwarded-allow-ips=*"