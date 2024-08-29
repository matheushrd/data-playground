# Use AWS Glue libraries image
FROM docker.io/amazon/aws-glue-libs:glue_libs_4.0.0_image_01

# Set up the entry point for the container
ENTRYPOINT ["/home/glue_user/spark/bin/spark-class"]
CMD ["org.apache.spark.deploy.history.HistoryServer"]
