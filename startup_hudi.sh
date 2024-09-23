#!/bin/bash
# Clone and setup Hudi project
cd /home && \
git clone https://github.com/apache/hudi.git && \
cd hudi && \
git checkout release-1.0.0-beta2 && \
mvn clean package -DskipTests -Dspark3.4

# Keep the container running after setup
tail -f /dev/null
