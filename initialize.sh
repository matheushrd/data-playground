#!/bin/bash

# Criar o diretório de dados do MinIO
#sudo apt-get -y install podman
podman rm -f minio
podman rm -f nginx_minio
podman rm -f postgres
podman rm -f trino
podman rm -f spark

bash postgres_init.sh

sleep 5

bash airflow_init.sh

sleep 5

bash trino_init.sh

sleep 5

bash glue_init.sh


sleep 5
# Criar um arquivo de configuração do Nginx para o proxy reverso
cat <<EOL > nginx_minio.conf
server {
    listen 8080;

    location /minio-console/ {
        proxy_pass http://localhost:$MINIO_PORT/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Port 8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

        # Reescrever os links e cabeçalhos de redirecionamento
        sub_filter_types 'text/html';
        sub_filter 'href="/' 'href="/minio-console/';
        sub_filter 'action="/' 'action="/minio-console/';
        sub_filter_once off;

        proxy_redirect http://localhost:9090/ /minio/;
        proxy_redirect http://localhost:$MINIO_PORT/ /minio-console/;

    }

    location /minio/ {
        proxy_pass http://localhost:9090/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Port 8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

        # Reescrever os links e cabeçalhos de redirecionamento
        sub_filter_types 'text/html';
        sub_filter 'href="/' 'href="/minio/';
        sub_filter 'action="/' 'action="/minio/';
        sub_filter_once off;

        proxy_redirect http://localhost:9090/ /minio/;
        proxy_redirect http://localhost:$MINIO_PORT/ /minio-console/;

    }

    # Evitar redirecionamentos indevidos

    location /airflow/ {
        proxy_pass http://localhost:6060;
        proxy_set_header Host \$http_host;
        proxy_redirect off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }


    location /trino/ {
        proxy_pass http://localhost:7070/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Port 8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

        sub_filter_types 'text/html' 'application/json' 'text/css' 'application/javascript';
        sub_filter 'href="/' 'href="/trino/';
        sub_filter 'action="/' 'action="/trino/';
        sub_filter 'src="/' 'src="/trino/';
        sub_filter_once off;

        proxy_redirect http://localhost:7070/ /trino/;
        proxy_redirect off;
    }

    location ~* ^/trino/ui/(.*) {
        proxy_pass http://localhost:7070/ui/\$1\$is_args\$args;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_http_version 1.1;
    }
}
EOL

echo "Configuração do Nginx criada com sucesso"

# Iniciar o Nginx com Podman na rede host
# podman run \
#     --network host \
#     --name nginx_minio \
#     -v $(pwd)/nginx_minio.conf:/etc/nginx/conf.d/default.conf:ro \
#     -d docker.io/library/nginx:latest

echo "MinIO e MinIO Console iniciados com sucesso e configurados para acesso via proxy reverso Nginx em http://localhost:8080/minio-console e http://localhost:8080/minio"
echo "Airflow iniciado com sucesso e configurado para acesso via proxy reverso Nginx em http://localhost:8080/airflow"
echo "Trino iniciado com sucesso e configurado para acesso via proxy reverso Nginx em http://localhost:7070/trino"