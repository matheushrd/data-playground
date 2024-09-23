FROM python:3.10-slim

# Instalar dependências
RUN apt-get update && apt-get install -y     python3-venv     build-essential     && apt-get clean

# Criar e ativar ambiente virtual
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Instalar pacotes necessários
RUN pip install --upgrade pip
RUN pip install pandas apache-airflow-providers-postgres[amazon] psycopg2-binary

# Configurações do Airflow
ENV AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=postgresql://admin:admin@localhost:5432/airflowdb
ENV AIRFLOW__CORE__EXECUTOR=LocalExecutor
ENV AIRFLOW__WEBSERVER__SECRET_KEY=eQ+f1e06XhEbr2n5bHINjzLywTXxycEI
ENV AIRFLOW__WEBSERVER__BASE_URL=http://localhost:8080/airflow
ENV AIRFLOW__WEBSERVER__ENABLE_PROXY_FIX=True


# Expor a porta do Airflow
EXPOSE 6060

# Comando para iniciar o Airflow
CMD bash -c "airflow db init && airflow webserver --port 6060 --host localhost"
