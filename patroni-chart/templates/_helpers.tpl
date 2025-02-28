{{/*
Expand the name of the chart.
*/}}
{{- define "patroni-chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "patroni-chart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "patroni-chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "patroni-chart.labels" -}}
helm.sh/chart: {{ include "patroni-chart.chart" . }}
{{ include "patroni-chart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "patroni-chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "patroni-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "patroni-chart.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "patroni-chart.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{- define "init-job-script" -}}
#!/bin/bash

check_db_ready() {
    pg_isready -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -h ${POSTGRES_HOST} > /dev/null 2>&1
    return $?
}

# Ожидаем, пока база данных будет доступна
until check_db_ready; do
  echo "Waiting for database to be ready..."
  sleep 2
done

echo "Database is ready!"

# Устанавливаем расширение pgvector
PGPASSWORD=${POSTGRES_PASSWORD} psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -h ${POSTGRES_HOST} -c 'CREATE EXTENSION IF NOT EXISTS vector;'
if [ $? -eq 0 ]; then
  echo "Extension 'vector' created successfully."
else
  echo "Failed to create extension 'vector'."
  exit 1
fi

# Устанавливаем расширение postgis
PGPASSWORD=${POSTGRES_PASSWORD} psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -h ${POSTGRES_HOST} -c 'CREATE EXTENSION IF NOT EXISTS postgis;'
if [ $? -eq 0 ]; then
  echo "Extension 'postgis' created successfully."
else
  echo "Failed to create extension 'postgis'."
  exit 1
fi
{{- end }}








{{- define "init-generator-script" -}}
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

SERVICE_NAME=postgres

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

PARTNERS=$(seq 0 2 | grep -v "$MY_POD_INDEX" | xargs -I{} sh -c 'echo "postgres-{}.'$SERVICE_NAME'.'$POD_NAMESPACE'.svc.cluster.local:222$((2 + {}))"')

cat <<EOF >> ./config.yml
raft:
  data_dir: raft
  self_addr: postgres-${MY_POD_INDEX}.${SERVICE_NAME}.${POD_NAMESPACE}.svc.cluster.local:222$((2 + MY_POD_INDEX))
  partner_addrs:
$(echo "$PARTNERS" | sed 's/^/  - /')

EOF

# Restapi field

API_PORT=$((8000 + MY_POD_INDEX))

cat <<EOF >> ./config.yml
restapi:
  listen: 0.0.0.0:$API_PORT
  connect_address: postgres-${MY_POD_INDEX}.${SERVICE_NAME}.${POD_NAMESPACE}.svc.cluster.local:$API_PORT

EOF

# Postgres field

echo "superuser creds: "
echo "Using password: $POSTGRES_PASSWORD"
echo "Using user: $POSTGRES_USER"

echo "replication creds: "
echo "Using password: $REPLICATION_PASSWORD"

echo "rewind creds: "
echo "Using password: $REWIND_PASSWORD"
echo "Using user: $REWIND_USER"

POSTGRES_PORT=$((5432 + MY_POD_INDEX))

cat <<EOF >> ./config.yml
postgresql:
  listen: 0.0.0.0:$POSTGRES_PORT
  connect_address: postgres-${MY_POD_INDEX}.${SERVICE_NAME}.${POD_NAMESPACE}.svc.cluster.local:$POSTGRES_PORT
  data_dir: data/postgresql${MY_POD_INDEX}
  pgpass: /tmp/pgpass${MY_POD_INDEX}
  authentication:
    replication:
      username: replicator
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


mkdir -p /home/venv/config/ /home/venv/data/postgresql${MY_POD_INDEX} && \
cp ./config.yml /home/venv/config/config.yml && \
chmod -R 700 /home/venv/data/postgresql${MY_POD_INDEX} && \
chown -R 1001:1001 /home/venv/data && \
chmod 700 /home/venv/config.yml && \
chmod 700 /home/venv/config/config.yml && \
chown 1001:1001 /home/venv/config.yml && \
chown 1001:1001 /home/venv/config/config.yml

echo "Created data and config directories"
echo "Config path /home/venv/config/config.yml"

cat  /home/venv/config/config.yml

{{- end -}}


{{- define "baseconfig" -}}
bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      pg_hba:
        - host replication replicator 0.0.0.0/0 md5
        - host all all 0.0.0.0/0 md5
      parameters:
  initdb:
  - encoding: UTF8
  - data-checksums

tags:
    noloadbalance: false
    clonefrom: false
    nostream: false
{{- end -}}