FROM docker.io/trinodb/trino:latest

# Install Java 21
# RUN yum install java-21-openjdk

# Set up the Trino configuration directory and create config.properties
WORKDIR /etc/trino
RUN echo "coordinator=true" > config.properties &&     echo "node-scheduler.include-coordinator=true" >> config.properties &&     echo "http-server.http.port=5555" >> config.properties &&     echo "query.max-memory=5GB" >> config.properties &&     echo "query.max-memory-per-node=1GB" >> config.properties &&     echo "discovery-server.enabled=true" >> config.properties &&     echo "discovery.uri=http://localhost:5555" >> config.properties

# Change to the Trino bin directory
WORKDIR /usr/lib/trino/bin

# Add Trino bin to PATH
ENV PATH="/usr/lib/trino/bin:/home/damasceno/data_engineering_pipeline/myenv/bin:/home/damasceno/.vscode-server/bin/fee1edb8d6d72a0ddff41e5f71a671c23ed924b9/bin/remote-cli:/mnt/c/Users/MatheusDamasceno/Desktop/integrating_systems/myenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/usr/lib/wsl/lib:/mnt/c/Program Files (x86)/Razer/ChromaBroadcast/bin:/mnt/c/Program Files/Razer/ChromaBroadcast/bin:/mnt/c/Program Files (x86)/Common Files/Oracle/Java/javapath:/mnt/c/Windows/system32:/mnt/c/Windows:/mnt/c/Windows/System32/Wbem:/mnt/c/Windows/System32/WindowsPowerShell/v1.0/:/mnt/c/Windows/System32/OpenSSH/:/mnt/c/Program Files (x86)/NVIDIA Corporation/PhysX/Common:/mnt/c/Program Files/NVIDIA Corporation/NVIDIA NvDLISR:/mnt/c/WINDOWS/system32:/mnt/c/WINDOWS:/mnt/c/WINDOWS/System32/Wbem:/mnt/c/WINDOWS/System32/WindowsPowerShell/v1.0/:/mnt/c/WINDOWS/System32/OpenSSH/:/mnt/c/java/bin:/mnt/c/Program Files/Docker/Docker/resources/bin:/mnt/c/Program Files/Git/cmd:/mnt/c/WINDOWS/system32/config/systemprofile/AppData/Local/Microsoft/WindowsApps:/mnt/c/Users/MatheusDamasceno/AppData/Local/Programs/Python/Python310/Scripts/:/mnt/c/Users/MatheusDamasceno/AppData/Local/Programs/Python/Python310/:/mnt/c/Users/MatheusDamasceno/AppData/Local/Microsoft/WindowsApps:/mnt/c/Users/MatheusDamasceno/AppData/Local/Programs/Microsoft VS Code/bin:/mnt/c/Users/MatheusDamasceno/AppData/Local/Programs/oh-my-posh/bin:/mnt/c/Program Files/heroku/bin:/mnt/c/Users/MatheusDamasceno/AppData/Local/Programs/Ollama:/snap/bin"

# Expose the Trino port
EXPOSE 5555
