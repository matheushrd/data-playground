#!/bin/bash

# Define the name of the Spark image in lowercase
spark_image_name="glue-spark"

# Create a Dockerfile with the necessary configurations using the AWS Glue image
cat <<EOF > Dockerfile
# Use AWS Glue libraries image
FROM docker.io/amazon/aws-glue-libs:glue_libs_4.0.0_image_01

# Set up the entry point for the container
ENTRYPOINT ["/home/glue_user/spark/bin/spark-class"]
CMD ["org.apache.spark.deploy.history.HistoryServer"]
EOF

# Build the Spark image with Podman
echo "Building the Spark image with Podman..."
podman build -t $spark_image_name .

# Remove any existing Spark container (if you want to ensure a clean state)
echo "Removing existing Spark container if exists..."
podman rm -f $spark_image_name

# Run the Spark container in detached mode
echo "Starting the Spark container in detached mode..."
podman run -d \
    --name $spark_image_name \
    -p 4040:4040 \
    $spark_image_name

echo "The Spark container has been successfully started."
