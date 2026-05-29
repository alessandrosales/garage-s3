#!/bin/sh

# Gera o arquivo .toml injetando a ENV do Railway dinamicamente em tempo de execução
cat <<EOF > /etc/garage.toml
[metadata_dir]
metadata_dir = "/var/lib/garage/meta"

[data_dir]
data_dir = "/var/lib/garage/data"

[rpc_secret]
rpc_secret = "${GARAGE_RPC_SECRET}"

[rpc_bind_addr]
rpc_bind_addr = "0.0.0.0:3901"

[s3_api]
api_bind_addr = "0.0.0.0:3900"

[s3_web]
api_bind_addr = "0.0.0.0:3902"
EOF

# Inicia o servidor Garage usando o arquivo gerado
exec /garage server