#!/bin/bash

# Функция проверки готовности базы данных
check_db_ready() {
  pg_isready -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" > /dev/null 2>&1
  return $?
}

# Ожидаем, пока база данных будет доступна
until check_db_ready; do
  echo "Waiting for database to be ready..."
  sleep 2
done

echo "Database is ready!"

# Устанавливаем расширение pgvector
PGPASSWORD=${POSTGRES_PASSWORD} psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c 'CREATE EXTENSION IF NOT EXISTS vector;'
if [ $? -eq 0 ]; then
  echo "Extension 'vector' created successfully."
else
  echo "Failed to create extension 'vector'."
  exit 1
fi

# Устанавливаем расширение postgis
PGPASSWORD=${POSTGRES_PASSWORD} psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c 'CREATE EXTENSION IF NOT EXISTS postgis;'
if [ $? -eq 0 ]; then
  echo "Extension 'postgis' created successfully."
else
  echo "Failed to create extension 'postgis'."
  exit 1
fi
