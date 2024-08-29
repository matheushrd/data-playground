#!/bin/bash

podman rm -f zookeeper
podman rm -f initialize-pulsar-cluster-metadata
podman rm -f bookie
podman rm -f broker
podman rm -f manager-pulsar

# Define the Pulsar version
pulsar_version="docker.io/apachepulsar/pulsar-all:latest"

podman network create pulsar 2>/dev/null || echo "Network 'pulsar' already exists"

# Step 3: Create and start containers

# Helper function to remove existing container if it exists
remove_if_exists() {
    existing_container=$(podman ps -a | grep $1 | awk '{print $1}')
    if [ ! -z "$existing_container" ]; then
        echo "Removing existing $1 container..."
        podman rm -f $existing_container
    fi
}
# Step 1: Pull the Pulsar image
podman pull $pulsar_version

# Step 2: Create a network
podman network create pulsar
# Step 3: Create and start containers

# Create a ZooKeeper container
echo "Starting ZooKeeper container..."
podman run -d -p 2181:2181 --network pulsar \
    -e metadataStoreUrl=zk:zookeeper:2181 \
    -e cluster-name=cluster-a -e managedLedgerDefaultEnsembleSize=1 \
    -e managedLedgerDefaultWriteQuorum=1 \
    -e managedLedgerDefaultAckQuorum=1 \
    --name zookeeper --hostname zookeeper \
    docker.io/apachepulsar/pulsar-all:latest \
    /bin/bash -c "bin/apply-config-from-env.py conf/zookeeper.conf && bin/generate-zookeeper-config.sh conf/zookeeper.conf && exec bin/pulsar zookeeper"


# Initialize the cluster metadata
echo "Initializing cluster metadata..."
podman run --network pulsar \
    --name initialize-pulsar-cluster-metadata \
    docker.io/apachepulsar/pulsar-all:latest\
    /bin/bash -c "bin/pulsar initialize-cluster-metadata \
    --cluster cluster-a \
    --zookeeper zookeeper:2181 \
    --configuration-store zookeeper:2181 \
    --web-service-url http://broker:8080 \
    --broker-service-url pulsar://broker:6650"

# Create a bookie container
echo "Starting Bookie container..."
podman run -d -e clusterName=cluster-a \
    -e zkServers=zookeeper:2181 --network pulsar \
    -e metadataServiceUri=metadata-store:zookeeper:2181 \
    --name bookie --hostname bookie \
    docker.io/apachepulsar/pulsar-all:latest\
    /bin/bash -c "bin/apply-config-from-env.py conf/bookkeeper.conf && exec bin/pulsar bookie"

# Create a broker container
echo "Starting Broker container..."
podman run -d -p 6650:6650 -p 8080:8080 --network pulsar \
    -e metadataStoreUrl=zk:zookeeper:2181 \
    -e zookeeperServers=zookeeper:2181 \
    -e clusterName=cluster-a \
    -e managedLedgerDefaultEnsembleSize=1 \
    -e managedLedgerDefaultWriteQuorum=1 \
    -e managedLedgerDefaultAckQuorum=1 \
    --name broker --hostname broker \
    docker.io/apachepulsar/pulsar-all:latest \
    /bin/bash -c "bin/apply-config-from-env.py conf/broker.conf && exec bin/pulsar broker"

echo "Pulsar cluster has been successfully started."

podman cp config-postgres-debezium.yml broker:/pulsar/bin/

# Build the custom Pulsar Manager image with Podman
echo "Starting Pulsar Manager..."
podman run -d \
    --network pulsar \
    --name manager-pulsar \
    -p 9527:9527  \
    -p 7750:7750 \
    -e SPRING_CONFIGURATION_FILE=/pulsar-manager/pulsar-manager/application.properties  \
    -v $PWD/bkvm.conf:/pulsar-manager/pulsar-manager/bkvm.conf \
    docker.io/apachepulsar/pulsar-manager:latest

echo "Pulsar Manager has been successfully started."
echo "Access Pulsar Manager at http://localhost:9527"

sleep 10
# Update superuser credentials in Pulsar Manager
echo "Updating superuser credentials..."
CSRF_TOKEN=$(curl -s http://localhost:7750/pulsar-manager/csrf-token)
bash curl -s \
   -H 'X-XSRF-TOKEN: $CSRF_TOKEN' \
   -H 'Cookie: XSRF-TOKEN=$CSRF_TOKEN;' \
   -H "Content-Type: application/json" \
   -X PUT http://localhost:7750/pulsar-manager/users/superuser \
   -d '{"name": "admin", "password": "apachepulsar", "description": "test", "email": "username@test.org"}'

echo "Superuser credentials updated."


echo "Starting Debezium Connector for PostgreSQL using JSON configuration..."
podman exec -it broker /bin/bash -c "cd /pulsar/bin && ./pulsar-admin source localrun --source-config-file /pulsar/bin/config-postgres-debezium.yml"