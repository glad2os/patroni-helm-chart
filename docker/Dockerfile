FROM pgvector/pgvector:pg17

RUN apt-get update && \
    apt-get -y upgrade && \
    DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y --no-install-recommends \
    python3.11 \
    python3.11-venv \
    python3-pip \
    python3-psycopg2 \
    postgis \
    postgresql-17-postgis-3 \
    postgresql-17-postgis-3-scripts && \
    python3.11 -m venv /home/venv && \
    /home/venv/bin/pip install --upgrade pip && \
    /home/venv/bin/pip install patroni[raft,psycopg3] && \
    apt-get purge -y --auto-remove && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd -g 1001 venv && \
    useradd -ms /bin/bash -g venv -u 1001 1001

WORKDIR /home/venv

RUN mkdir -p /home/venv/data/postgresql0 /home/venv/data/postgresql1 /home/venv/data/postgresql2 /home/venv/raft && \
    chown -R 1001:1001 /home/venv && \
    chmod -R 700 /home/venv/data /home/venv/raft

USER 1001

ENTRYPOINT ["/home/venv/bin/patroni"]