#!/bin/sh
set -eu

METADATA_DIR="${GARAGE_METADATA_DIR:-/var/lib/garage/meta}"
DATA_DIR="${GARAGE_DATA_DIR:-/var/lib/garage/data}"
RPC_SECRET="${GARAGE_RPC_SECRET:?GARAGE_RPC_SECRET is required}"
GARAGE_DOMAIN="${GARAGE_DOMAIN:-${RAILWAY_PUBLIC_DOMAIN:-garage-s3-dev.up.railway.app}}"

mkdir -p "$METADATA_DIR" "$DATA_DIR" /etc

#region agent log
printf '{"sessionId":"271075","runId":"post-fix","hypothesisId":"H6","location":"start.sh:config","message":"Generating garage.toml","data":{"metadataDir":"%s","dataDir":"%s","garageDomain":"%s","hasRpcSecret":true},"timestamp":%s}\n' \
  "$METADATA_DIR" "$DATA_DIR" "$GARAGE_DOMAIN" "$(date +%s000)" >> /tmp/debug-271075.log 2>/dev/null || true
#endregion

cat <<EOF > /etc/garage.toml
metadata_dir = "$METADATA_DIR"
data_dir = "$DATA_DIR"
db_engine = "sqlite"
replication_factor = 1

rpc_secret = "$RPC_SECRET"
rpc_bind_addr = "0.0.0.0:3901"
rpc_public_addr = "$GARAGE_DOMAIN:3901"

[s3_api]
s3_region = "garage"
api_bind_addr = "0.0.0.0:3900"
root_domain = ".$GARAGE_DOMAIN"

[s3_web]
bind_addr = "0.0.0.0:3902"
root_domain = ".$GARAGE_DOMAIN"
index = "index.html"
EOF

#region agent log
printf '{"sessionId":"271075","runId":"post-fix","hypothesisId":"H7","location":"start.sh:launch","message":"Starting garage server","data":{"configFile":"/etc/garage.toml","s3Endpoint":"https://%s"},"timestamp":%s}\n' \
  "$GARAGE_DOMAIN" "$(date +%s000)" >> /tmp/debug-271075.log 2>/dev/null || true
#endregion

exec /garage server
