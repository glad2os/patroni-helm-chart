# Patroni High-Availability PostgreSQL Cluster with Raft

## Overview
This Helm chart deploys a highly available PostgreSQL cluster using Patroni with Raft as the distributed configuration store. The setup includes PostgreSQL plugins: pgvector and PostGIS.

## Prerequisites
- Kubernetes cluster (tested on v1.32.0)
- Helm 3.x
- Default storage class
- Image repository access for Patroni

## Build

You may use my Docker image or build it yourself using this approach

```sh
% docker buildx build --platform=linux/amd64,linux/arm64 -t glad2os/patroni:v0.0.1 --push .
```

## Configuration values.yaml

| Key | Default Value | Description |
|-----|---------------|-------------|
| POSTGRES_PASSWORD | `postgres` | Password for PostgreSQL superuser |
| POSTGRES_USER | `postgres` | PostgreSQL superuser username |
| REPLICATION_PASSWORD | `replication` | Password for replication user |
| REPLICATION_USER | `replication` | Username for replication |
| REWIND_PASSWORD | `rewind` | Password for rewind user |
| REWIND_USER | `rewind` | Username for rewind |
| image.repository | `glad2os/patroni:v0.0.1` | Docker image repository |
| image.pullPolicy | `Always` | Image pull policy |
| imagePullSecrets | `[]` | Secrets for private image registry |
| pvc.storageClassName | `longhorn-default` | Storage class for PVC |
| pvc.postgres.resources.requests.storage | `1Gi` | Storage request for PostgreSQL PVC |
| pvc.raft.resources.requests.storage | `1Gi` | Storage request for Raft PVC |
| replicaCount | `3` | Number of replicas for Patroni |
| podAnnotations.app | `patroni` | Annotations for the Pod |
| podLabels.app | `patroni` | Labels for the Pod |
| initContainers.command | `['sh', '-c', 'mkdir -p /home/venv/ && cd /home/venv/ && sh ./generator.sh']` | Command for init containers |
| patroni.command | `['/home/venv/bin/patroni', '/home/venv/config/config.yml']` | Command for Patroni container |
| securityContext.global.fsGroup | `1001` | File system group for security context |
| securityContext.global.fsGroupChangePolicy | `Always` | Policy for fsGroup changes |
| securityContext.initContainers.runAsUser | `0` | Run as user for init containers |
| securityContext.patroni.runAsUser | `1001` | Run as user for Patroni |
| securityContext.patroni.runAsGroup | `1001` | Run as group for Patroni |
| service.type | `ClusterIP` | Service type |
| service.annotations | `[]` | Additional service annotations |
| service.extraPorts | `[]` | Additional service ports |
| serviceAccount.create | `true` | Create service account |
| serviceAccount.automount | `true` | Automount service account token |
| extraVolumes | `[]` | Additional volumes |
| extraVolumeMounts | `[]` | Additional volume mounts |
| affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key | `node-role.kubernetes.io/production` | Affinity rule for production nodes |
| affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator | `Exists` | Affinity operator |

## Installation

```bash
git clone git@github.com:glad2os/patroni-helm-chart.git
cd patroni-helm-chart
helm upgrade --install patroni -n postgresql .
```

## Accessing the Cluster
After deployment, you can connect to the PostgreSQL cluster using the service name:

```bash
kubectl exec -it sts/postgres -- ./bin/patronictl -c config/config.yml topology postgres-${POD_NAMESPACE}

kubectl exec -it sts/postgres -- psql -U postgres -h 0.0.0.0 -d postgres
```

## Debugging
To debug the init container or the Patroni service, view logs with:

```bash
kubectl logs postgres-0 -c init-data-dir
kubectl logs postgres-0 -c patroni
```

## Uninstallation
```bash
helm uninstall patroni-cluster
```

## License
MIT
