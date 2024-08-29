
# Escolha uma porta não utilizada, por exemplo, 9500
# Configurações do PostgreSQL
POSTGRES_USER="admin"
POSTGRES_PASSWORD="admin"
POSTGRES_DB="mydatabase"
POSTGRES_PORT=5432
POSTGRES_AIRFLOW_DB="airflowdb"
AIRFLOW_USER="airflow_user"
AIRFLOW_PASSWORD="airflow_password"
CONTAINER_NAME="postgres"

# Criar e iniciar o container do PostgreSQL com Podman
echo "Iniciando PostgreSQL"
podman run -d \
    --name postgres \
    --network pulsar \
    -e POSTGRES_USER=$POSTGRES_USER \
    -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
    -e POSTGRES_DB=$POSTGRES_DB \
    -p $POSTGRES_PORT:5432 \
    docker.io/library/postgres:15

echo "Aguardando a inicialização do PostgreSQL..."
sleep 10
podman exec -i postgres psql -U admin -d mydatabase -c "ALTER SYSTEM SET wal_level = logical;"
podman stop postgres
podman start postgres

echo "finalizou wal_level"
echo "Configurando o banco de dados do PostgreSQL e o banco de dados do Airflow..."

cat <<EOL > init.sql
-- Configuração inicial do banco de dados
ALTER SYSTEM SET max_replication_slots = 4;
ALTER SYSTEM SET max_wal_senders = 4;

DO \$$
BEGIN
   IF NOT EXISTS (
      SELECT
      FROM   pg_catalog.pg_user
      WHERE  usename = 'debezium_user') THEN

      CREATE USER debezium_user WITH REPLICATION PASSWORD 'debezium_password';
   END IF;
END
\$$;

-- Garantir que o usuário tiene as permissões necessárias
GRANT ALL PRIVILEGES ON DATABASE mydatabase TO debezium_user;

-- Criação das tabelas

CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    telefone VARCHAR(20),
    endereco VARCHAR(255)
);

CREATE TABLE itens (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    preco DECIMAL(10, 2) NOT NULL
);

CREATE TABLE pedidos (
    id SERIAL PRIMARY KEY,
    cliente_id INT REFERENCES clientes(id),
    data_pedido TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valor_total DECIMAL(10, 2) NOT NULL
);

CREATE TABLE itens_pedidos (
    pedido_id INT REFERENCES pedidos(id),
    item_id INT REFERENCES itens(id),
    quantidade INT NOT NULL,
    PRIMARY KEY (pedido_id, item_id)
);

-- Criar uma publication para todas as tabelas
CREATE PUBLICATION my_publication FOR ALL TABLES;

-- Criar o slot de replicação Debezium (opcional, pode ser criado automaticamente pelo Debezium)
SELECT * FROM pg_create_logical_replication_slot('debezium_slot', 'pgoutput');
EOL
echo "Configuração do PostgreSQL concluída com sucesso"

# Executar o script SQL de inicialização
echo "Executando o script SQL airflow de inicialização..."
podman exec -i postgres psql -U $POSTGRES_USER -d $POSTGRES_DB < init.sql


# Iniciar o container PostgreSQL com Podman
#podman run --name $CONTAINER_NAME -e POSTGRES_USER=$POSTGRES_USER -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD -e POSTGRES_DB=$POSTGRES_DB -d postgres

# Aguardar o PostgreSQL iniciar
# echo "Aguardando o PostgreSQL iniciar..."
# sleep 10

# Criar o script SQL para configuração
echo "Iniciando grants do airflow no postgres..."
cat <<EOL > init2.sql

-- Criação do banco de dados e usuário do Airflow
CREATE DATABASE $POSTGRES_AIRFLOW_DB;
-- Garantir que o usuário tiene as permissões necessárias
GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO debezium_user;


CREATE USER $AIRFLOW_USER WITH PASSWORD '$AIRFLOW_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_AIRFLOW_DB TO $AIRFLOW_USER;

-- Conectar ao banco de dados do Airflow e conceder privilégios
\connect $POSTGRES_AIRFLOW_DB;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $AIRFLOW_USER;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $AIRFLOW_USER;
EOL

# Executar o script SQL dentro do container
echo "Executando o script SQL no PostgreSQL AIRFLOW..."
podman exec -i $CONTAINER_NAME psql -U $POSTGRES_USER -d $POSTGRES_DB -f /dev/stdin < init2.sql

# Limpar o arquivo SQL
rm init2.sql
rm init.sql
echo "Configuração do PostgreSQL e banco de dados do Airflow concluída."
