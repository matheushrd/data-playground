#!/bin/bash

# Remover qualquer container Airflow e PostgreSQL existente
podman rm -f airflow

# Configurações do PostgreSQL
POSTGRES_USER="admin"
POSTGRES_PASSWORD="admin"
POSTGRES_DB="airflowdb"
POSTGRES_HOST="localhost"
POSTGRES_PORT=5432
AIRFLOW_PORT=6060 


# Criar um diretório para o projeto
PROJECT_DIR=$(pwd)/airflow_project
mkdir -p $PROJECT_DIR

# Criar um Dockerfile para containerizar o ambiente Airflow
cat <<EOL > $PROJECT_DIR/Dockerfile
FROM python:3.10-slim

# Instalar dependências
RUN apt-get update && apt-get install -y \
    python3-venv \
    build-essential \
    && apt-get clean

# Criar e ativar ambiente virtual
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:\$PATH"

# Instalar pacotes necessários
RUN pip install --upgrade pip
RUN pip install pandas apache-airflow-providers-postgres[amazon] psycopg2-binary

# Configurações do Airflow
ENV AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DB
ENV AIRFLOW__CORE__EXECUTOR=LocalExecutor
ENV AIRFLOW__WEBSERVER__SECRET_KEY=$(openssl rand -base64 24)
ENV AIRFLOW__WEBSERVER__BASE_URL=http://localhost:8080/airflow
ENV AIRFLOW__WEBSERVER__ENABLE_PROXY_FIX=True


# Expor a porta do Airflow
EXPOSE $AIRFLOW_PORT

# Comando para iniciar o Airflow
CMD bash -c "airflow db init && airflow webserver --port 6060 --host localhost"
EOL

# Construir o container com Podman
echo "Construindo o container com Podman..."

podman build -t airflow_container $PROJECT_DIR
# Iniciar o Airflow no container

echo "Iniciando o Airflow no container na porta $AIRFLOW_PORT..."
podman run -d \
    --name airflow \
    --network host \
    -p $AIRFLOW_PORT:6060 \
    airflow_container

# Inicializar o banco de dados do Airflow
echo "Inicializando o banco de dados do Airflow..."

podman exec -it airflow airflow db migrate

# Criar o usuário admin do Airflow
echo "Criando usuário admin do Airflow..."
podman exec -it airflow airflow users create \
    --username admin \
    --firstname Admin \
    --lastname User \
    --role Admin \
    --email admin@example.com \
    --password admin

echo "Airflow iniciado com sucesso e disponível em http://localhost:$AIRFLOW_PORT"
