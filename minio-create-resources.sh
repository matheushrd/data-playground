#!/bin/bash

# Nome do container MinIO
MINIO_CONTAINER_NAME="minio"
echo "Iniciando MinIO"
mkdir -p minio_data
MINIO_PORT=9500

# Iniciar o MinIO com as configurações apropriadas
podman run -d \
    --network host \
    --name minio \
    -v minio_data:/data \
    -e "MINIO_ROOT_USER=admin" \
    -e "MINIO_ROOT_PASSWORD=#Mud@r12345" \
    quay.io/minio/minio server /data --console-address ":9090" --address ":$MINIO_PORT"

# Crie os buckets dentro do container MinIO
podman exec -it $MINIO_CONTAINER_NAME /bin/sh -c "
    mc alias set myminio http://localhost:9500 admin '#Mud@r12345' &&
    mc mb myminio/datalake &&
    mc mb myminio/datalake-replica &&
    mc mb myminio/datalake-raw &&
    mc mb myminio/datalake-assets
"

# Crie um novo usuário com acesso limitado
NEW_USER="replica_user"
NEW_USER_PASSWORD="Replica@123"

podman exec -it $MINIO_CONTAINER_NAME /bin/sh -c "
    mc admin user add myminio $NEW_USER $NEW_USER_PASSWORD
"

# Crie uma política personalizada para acesso somente ao bucket datalake-replica
READ_WRITE_POLICY_JSON='{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketLocation",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::datalake-replica"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucketMultipartUploads"
            ],
            "Resource": [
                "arn:aws:s3:::datalake-replica"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:AbortMultipartUpload",
                "s3:DeleteObject",
                "s3:GetObject",
                "s3:ListMultipartUploadParts",
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::datalake-replica/*"
            ]
        }
    ]
}'

# Salve a política personalizada em um arquivo temporário
echo "$READ_WRITE_POLICY_JSON" > readwrite_policy.json

# Copie o arquivo de política para dentro do container
podman cp readwrite_policy.json $MINIO_CONTAINER_NAME:/readwrite_policy.json

# Adicione a política personalizada ao MinIO e associe ao novo usuário
podman exec -it $MINIO_CONTAINER_NAME /bin/sh -c "
    mc admin policy create myminio replica-write-read-policy /readwrite_policy.json &&
    mc admin policy attach myminio replica-write-read-policy --user $NEW_USER
"

# Limpe o arquivo temporário local
rm readwrite_policy.json

echo "Buckets criados e usuário configurado com sucesso."
