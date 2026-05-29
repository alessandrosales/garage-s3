#!/bin/sh
set -eu

METADATA_DIR="${GARAGE_METADATA_DIR:-/var/lib/garage/meta}"
DATA_DIR="${GARAGE_DATA_DIR:-/var/lib/garage/data}"
CREDENTIALS_FILE="${GARAGE_CREDENTIALS_FILE:-$DATA_DIR/credentials.env}"
RPC_SECRET="${GARAGE_RPC_SECRET:?GARAGE_RPC_SECRET is required}"
GARAGE_DOMAIN="${GARAGE_DOMAIN:-${RAILWAY_PUBLIC_DOMAIN:-garage-s3-dev.up.railway.app}}"

rand_hex() {
  bytes="$1"
  head -c "$bytes" /dev/urandom | od -An -tx1 | tr -d ' \n'
}

mkdir -p "$METADATA_DIR" "$DATA_DIR" /etc

CLUSTER_EXISTS=false
if [ -f "$METADATA_DIR/db.sqlite" ]; then
  CLUSTER_EXISTS=true
fi

if [ -n "${GARAGE_DEFAULT_ACCESS_KEY:-}" ] && [ -n "${GARAGE_DEFAULT_SECRET_KEY:-}" ]; then
  export GARAGE_DEFAULT_BUCKET="${GARAGE_DEFAULT_BUCKET:-garage-bucket}"
elif [ -f "$CREDENTIALS_FILE" ]; then
  # shellcheck disable=SC1090
  . "$CREDENTIALS_FILE"
elif [ "$CLUSTER_EXISTS" = false ]; then
  export GARAGE_DEFAULT_ACCESS_KEY="GK$(rand_hex 16)"
  export GARAGE_DEFAULT_SECRET_KEY="$(rand_hex 32)"
  export GARAGE_DEFAULT_BUCKET="${GARAGE_DEFAULT_BUCKET:-garage-bucket}"
  umask 077
  cat > "$CREDENTIALS_FILE" <<EOF
GARAGE_DEFAULT_ACCESS_KEY=$GARAGE_DEFAULT_ACCESS_KEY
GARAGE_DEFAULT_SECRET_KEY=$GARAGE_DEFAULT_SECRET_KEY
GARAGE_DEFAULT_BUCKET=$GARAGE_DEFAULT_BUCKET
EOF
else
  echo "WARNING: Cluster already exists but credentials were not found."
  echo "Set GARAGE_DEFAULT_ACCESS_KEY and GARAGE_DEFAULT_SECRET_KEY in Railway,"
  echo "or create a new key with: garage key create my-key"
fi

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

if [ -n "${GARAGE_DEFAULT_ACCESS_KEY:-}" ] && [ -n "${GARAGE_DEFAULT_SECRET_KEY:-}" ]; then
  echo "Garage S3 credentials:"
  echo "  GARAGE_DEFAULT_ACCESS_KEY=$GARAGE_DEFAULT_ACCESS_KEY"
  echo "  GARAGE_DEFAULT_SECRET_KEY=$GARAGE_DEFAULT_SECRET_KEY"
  echo "  GARAGE_DEFAULT_BUCKET=${GARAGE_DEFAULT_BUCKET:-garage-bucket}"
  echo "  AWS_ENDPOINT_URL=https://$GARAGE_DOMAIN"
fi

if [ "$CLUSTER_EXISTS" = false ]; then
  exec /garage server --single-node --default-bucket
else
  exec /garage server
fi
