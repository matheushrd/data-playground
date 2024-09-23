#!/bin/bash

# Remover qualquer container DBT existente
podman rm -f dbt-server

# Definir a porta da web interface do DBT
DBT_WEB_PORT=5050

# Criar um diretório para o projeto DBT
PROJECT_DIR=$(pwd)/dbt_project
mkdir -p $PROJECT_DIR

# Criar um Dockerfile para containerizar o ambiente DBT com as versões específicas dos pacotes
cat <<EOL > $PROJECT_DIR/Dockerfile
# Usar a imagem Python 3.10
FROM python:3.10-slim

# Definir o diretório de trabalho
WORKDIR /dbt

# Atualizar e instalar git (necessário para instalação de pacotes)
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# Instalar dbt-core e os plugins específicos
RUN pip install --no-cache-dir \
    psycopg2-binary \
    dbt-core==1.8.1 \
    dbt-athena-community==1.8.1 \
    dbt-redshift==1.8.1 \
    --no-binary dbt-postgres==1.8.1 \
    dbt-trino==1.8.1

# Copiar seu projeto dbt existente para o container
# Nota: Assegure-se de que seu projeto DBT esteja neste diretório
COPY . /dbt

# Definir variáveis de ambiente para a configuração do dbt
ENV DBT_PROFILES_DIR=/dbt/config
ENV DBT_PROJECT_DIR=/dbt

# Porta padrão onde a web interface do DBT será exposta
EXPOSE $DBT_WEB_PORT

# Comando para iniciar a web interface do DBT
CMD ["dbt", "docs", "generate"]
EOL

# Construir a imagem do container DBT com Podman
echo "Construindo a imagem do container DBT com Podman..."
podman build -t dbt-server:latest $PROJECT_DIR

# Iniciar o container DBT
echo "Iniciando o container DBT na porta $DBT_WEB_PORT..."
podman run -d \
    --name dbt-server \
    --network host \
    -p $DBT_WEB_PORT:$DBT_WEB_PORT \
    dbt-server:latest

echo "DBT iniciado com sucesso e a web interface está disponível na porta $DBT_WEB_PORT"
