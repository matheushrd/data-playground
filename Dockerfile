FROM docker.io/apachepulsar/pulsar:3.3.1
# Set environment variables for username and password
ENTRYPOINT ["bin/pulsar"]
CMD ["standalone"]
