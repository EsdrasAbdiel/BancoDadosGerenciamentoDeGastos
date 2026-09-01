#!/bin/bash

set -e

echo "Iniciando migrations..."

psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<'SQL'
CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(255) PRIMARY KEY,
    applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
SQL

for file in scripts/migrations/*.sql; do
    version=$(basename "$file" .sql)

    if psql "$DATABASE_URL" -tAc \
        "SELECT 1 FROM schema_migrations WHERE version = '$version'" | grep -q 1; then
        echo "Pulando: $version"
        continue
    fi

    echo "Executando migration: $version"

    psql "$DATABASE_URL" \
        -v ON_ERROR_STOP=1 \
        -f "$file"

    psql "$DATABASE_URL" -v ON_ERROR_STOP=1 \
        -c "INSERT INTO schema_migrations (version) VALUES ('$version');"

done

echo "Migrations concluídas!"