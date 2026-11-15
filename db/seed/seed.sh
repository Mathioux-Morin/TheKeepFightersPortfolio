#!/bin/sh
# Loads the development seed data. NEVER run in production.
#   1. copies the demo files of db/seed/media/ into uploads/ (UPLOADS_DIR to change it);
#   2. runs dev_seed.sql in one transaction: through DATABASE_URL when it is set, otherwise
#      in the container of db/compose.yaml.
# Can be run again: it creates no duplicates.
set -eu

SEED_DIR=$(cd "$(dirname "$0")" && pwd)
UPLOADS_DIR=${UPLOADS_DIR:-"$SEED_DIR/../../uploads"}

mkdir -p "$UPLOADS_DIR"
cp "$SEED_DIR"/media/* "$UPLOADS_DIR"/
echo "Demo files copied into $UPLOADS_DIR"

if [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" --single-transaction -v ON_ERROR_STOP=1 -f "$SEED_DIR/dev_seed.sql"
else
    docker compose -f "$SEED_DIR/../compose.yaml" exec -T db \
        sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" --single-transaction -v ON_ERROR_STOP=1 -f -' \
        < "$SEED_DIR/dev_seed.sql"
fi
echo "Seed data loaded"
