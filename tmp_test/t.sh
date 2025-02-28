#!/bin/bash

MY_POD_INDEX=0
POD_NAMESPACE=default

PARTNERS=$(seq 0 2 | grep -v "$MY_POD_INDEX" | xargs -I{} sh -c 'echo "postgres-{}.postgres.$1.svc.cluster.local:222$((2 + {}))"' -- "${POD_NAMESPACE}")

cat <<EOF >> ./config.yml
raft:
  data_dir: raft
  self_addr: postgres-${MY_POD_INDEX}.postgres.${POD_NAMESPACE}.svc.cluster.local:222$((2 + MY_POD_INDEX))
  partner_addrs:
$(echo "$PARTNERS" | sed 's/^/  - /')

EOF