#!/bin/bash

# Remove any existing Trino container
podman rm -f trino

# Trino configurations
TRINO_VERSION="latest"
TRINO_PORT=7070

# Create a directory for the Trino project and configuration
PROJECT_DIR=$(pwd)/trino_project
mkdir -p "$PROJECT_DIR/etc"

# Create the config properties file
cat << EOF > "$PROJECT_DIR/etc/config.properties"
http-server.process-forwarded=true
http-server.http.port=$TRINO_PORT
discovery.uri=http://127.0.0.1:$TRINO_PORT
coordinator=true
node-scheduler.include-coordinator=true
query.max-memory=5GB 
query.max-memory-per-node=1GB
web-ui.enabled=true
http-server.authentication.allow-insecure-over-http=true
EOF

# Start the Trino container
echo "Starting Trino in a container on port $TRINO_PORT..."
podman run -d \
    --name trino \
    --network host \
    -p $TRINO_PORT:$TRINO_PORT \
    -v "$PROJECT_DIR/etc/config.properties:/etc/trino/config.properties" \
    -e CATALOG_MANAGEMENT=dynamic \
    docker.io/trinodb/trino:$TRINO_VERSION

echo "Trino has been successfully started and is available at http://localhost:$TRINO_PORT"
