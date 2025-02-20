FROM pgvector/pgvector:pg17 AS builder

RUN apt-get update && \
    apt-get -y upgrade && \
    DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y \
    python3.11 \
    python3.11-venv \
    python3-pip \
    python3-psycopg2 && \
    python3.11 -m venv /home/venv && \
    /home/venv/bin/pip install --upgrade pip && \
    /home/venv/bin/pip install patroni[raft,psycopg3]

WORKDIR /home/venv

RUN chown -R postgres:postgres /home/venv
USER postgres

ENTRYPOINT ["/home/venv/bin/patroni"]
