FROM pgvector/pgvector:pg17 AS builder

FROM ubuntu:latest

RUN apt-get update && \
    apt-get -y upgrade && \
    DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y python3-psycopg2 && \
    apt-get install -y pip python3.12-venv && \
    mkdir -p /home/venv && \
    python3 -m venv /home/venv && \
    /home/venv/bin/pip install patroni[raft,psycopg3]

# TODO run as a specific user

ENTRYPOINT ["/home/venv/bin/patroni"]
