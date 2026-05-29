#!/bin/sh
set -eu

METADATA_DIR="${GARAGE_METADATA_DIR:-/var/lib/garage/meta}"
DATA_DIR="${GARAGE_DATA_DIR:-/var/lib/garage/data}"
RPC_SECRET="${GARAGE_RPC_SECRET:?GARAGE_RPC_SECRET is required}"
GARAGE_DOMAIN="${GARAGE_DOMAIN:-${RAILWAY_PUBLIC_DOMAIN:-garage-s3-dev.up.railway.app}}"

rand_hex() {
  bytes="$1"
  head -c "$bytes" /dev/urandom | od -An -tx1 | tr -d ' \n'
}

export GARAGE_DEFAULT_ACCESS_KEY="${GARAGE_DEFAULT_ACCESS_KEY:-GK$(rand_hex 16)}"
export GARAGE_DEFAULT_SECRET_KEY="${GARAGE_DEFAULT_SECRET_KEY:-$(rand_hex 32)}"
export GARAGE_DEFAULT_BUCKET="${GARAGE_DEFAULT_BUCKET:-garage-bucket}"

mkdir -p "$METADATA_DIR" "$DATA_DIR" /etc

#region agent log
printf '{"sessionId":"271075","runId":"cluster-fix","hypothesisId":"H8","location":"start.sh:config","message":"Generating garage.toml","data":{"metadataDir":"%s","dataDir":"%s","garageDomain":"%s","singleNode":true},"timestamp":%s}\n' \
  "$METADATA_DIR" "$DATA_DIR" "$GARAGE_DOMAIN" "$(date +%s000)" >> /tmp/debug-271075.log 2>/dev/null || true
#endregion

cat <<EOF > /etc/garage.toml
metadata_dir = "$METADATA_DIR"
data_dir = "$DATA_DIR"
db_engine = "sqlite"
replication_factor = 1

rpc_secret = "$RPC_SECRET"
rpc_bind_addr = "0.0.0.0:3901"

[s3_api]
s3_region = "garage"
api_bind_addr = "0.0.0.0:3900"
root_domain = ".$GARAGE_DOMAIN"

[s3_web]
bind_addr = "0.0.0.0:3902"
root_domain = ".$GARAGE_DOMAIN"
index = "index.html"
EOF

echo "Garage S3 credentials (save these):"
echo "  GARAGE_DEFAULT_ACCESS_KEY=$GARAGE_DEFAULT_ACCESS_KEY"
echo "  GARAGE_DEFAULT_SECRET_KEY=$GARAGE_DEFAULT_SECRET_KEY"
echo "  GARAGE_DEFAULT_BUCKET=$GARAGE_DEFAULT_BUCKET"
echo "  AWS_ENDPOINT_URL=https://$GARAGE_DOMAIN"

#region agent log
printf '{"sessionId":"271075","runId":"cluster-fix","hypothesisId":"H9","location":"start.sh:launch","message":"Starting garage server with single-node","data":{"bucket":"%s"},"timestamp":%s}\n' \
  "$GARAGE_DEFAULT_BUCKET" "$(date +%s000)" >> /tmp/debug-271075.log 2>/dev/null || true
#endregion

exec /garage server --single-node --default-bucket
