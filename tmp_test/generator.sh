#!/bin/bash

# Validate input

if [ -z "$MY_POD_INDEX" ]; then
  echo "MY_POD_INDEX is not set"
  exit 1
fi

if [ -z "$POD_NAMESPACE" ]; then
  echo "POD_NAMESPACE is not set"
  exit 1
fi

# Create and clean up config.yml
touch ./config.yml
echo "" > ./config.yml

# Name field

cat <<EOF >> ./config.yml
name: postgres-${MY_POD_INDEX}
EOF

echo "MY_POD_INDEX=${MY_POD_INDEX}"
echo "POD_NAMESPACE=${POD_NAMESPACE}"

# Scope field

cat <<EOF >> ./config.yml
scope: postgres-${POD_NAMESPACE}

EOF

PARTNERS=$(seq 0 2 | grep -v "$MY_POD_INDEX" | xargs -I{} sh -c 'echo "postgres-{}.postgres.$1.svc.cluster.local:222$((2 + {}))"' -- "${POD_NAMESPACE}")

cat <<EOF >> ./config.yml
raft:
  data_dir: raft
  self_addr: postgres-${MY_POD_INDEX}.postgres.${POD_NAMESPACE}.svc.cluster.local:222$((2 + MY_POD_INDEX))
  partner_addrs:
$(echo "$PARTNERS" | sed 's/^/    - /')

EOF

# Restapi field

API_PORT=$((8000 + MY_POD_INDEX))

cat <<EOF >> ./config.yml
restapi:
  listen: 0.0.0.0:$API_PORT
  connect_address: postgres-${MY_POD_INDEX}.postgres.${POD_NAMESPACE}.svc.cluster.local:$API_PORT

EOF

# Postgres field

echo "superuser creds: "
echo "Using password: $POSTGRES_PASSWORD"
echo "Using user: $POSTGRES_USER"

echo "replication creds: "
echo "Using password: $REPLICATION_PASSWORD"
echo "Using user: $REPLICATION_USER"

echo "rewind creds: "
echo "Using password: $REWIND_PASSWORD"
echo "Using user: $REWIND_USER"

POSTGRES_PORT=$((5432 + MY_POD_INDEX))

cat <<EOF >> ./config.yml
postgresql:
  listen: 0.0.0.0:$POSTGRES_PORT
  connect_address: postgres-${MY_POD_INDEX}.postgres.${POD_NAMESPACE}.svc.cluster.local:$POSTGRES_PORT
  data_dir: data/postgresql${MY_POD_INDEX}
  pgpass: /tmp/pgpass${MY_POD_INDEX}
  authentication:
    replication:
      username: $REPLICATION_USER
      password: $REPLICATION_PASSWORD
    superuser:
      username: $POSTGRES_USER
      password: $POSTGRES_USER
    rewind:
      username: $REWIND_USER
      password: $REWIND_PASSWORD
  parameters:
    unix_socket_directories: '..'
EOF

# Copy base config into config.yml

cat ./baseconfig.yml >> ./config.yml

echo "Generated config.yml"

mkdir -p /home/venv/data/pg_data && \
chmod -R 700 /home/venv/data/postgresql0 && \
chmod -R 700 /home/venv/data/pg_data && chown -R 1001:1001 /home/venv/data && \
chmod 700 /home/venv/config.yml && chown 1001:1001 /home/venv/config.yml

echo "Created data and config directories"