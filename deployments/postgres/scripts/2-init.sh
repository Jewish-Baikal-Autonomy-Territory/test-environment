#!/usr/bin/env bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL

\c postgres

CREATE EXTENSION IF NOT EXISTS pg_cron;

SELECT cron.schedule_in_database(
  'purge-expired-tasks-job',
  '0 0 * * 0',
  'DELETE FROM pgtasks.task WHERE purge_at <= NOW()',
  'tasksdb'
);

EOSQL
