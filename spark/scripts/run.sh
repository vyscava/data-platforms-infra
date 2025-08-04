#!/bin/bash

set -e

export SPARK_NO_DAEMONIZE=true

# Start Spark
case "$SPARK_MODE" in
    master)
        echo "Starting Spark Master..."
        exec start-master.sh
        ;;
    worker)
        echo "Starting Spark Worker..."
        exec start-worker.sh
        ;;
    *)
        echo "SPARK_MODE is not set to 'master' or 'worker'. Skipping Spark startup."
        ;;
esac

# Start JupyterLab if requested
if [[ "$JUPYTER_MODE" == "master" ]]; then
    # echo "Building JupyterLab..."
    # jupyter lab build
    
    echo "Starting JupyterLab..."
    jupyter-lab \
        --notebook-dir="$JUPYTER_NOTEBOOK_DIR" \
        --ip="$JUPYTER_IP" \
        --NotebookApp.token="$JUPYTER_TOKEN" \
        --NotebookApp.password="$JUPYTER_PASSWORD" \
        --port="$JUPYTER_PORT" \
        --no-browser \
        --allow-root &
fi

# Wait for backgrounded processes (like JupyterLab)
# wait