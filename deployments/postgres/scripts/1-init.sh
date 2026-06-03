#!/usr/bin/env bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
CREATE DATABASE tasksdb;
\c tasksdb;

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

CREATE SCHEMA IF NOT EXISTS pgtasks;

CREATE ROLE taskbackend WITH NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT LOGIN PASSWORD 'taskbackend';

GRANT USAGE ON SCHEMA pgtasks TO taskbackend GRANTED BY postgres;

CREATE TYPE pgtasks.task_status AS ENUM ('pending', 'completed');

CREATE TYPE pgtasks.task_priority AS ENUM ('low', 'medium', 'high');

CREATE TYPE pgtasks.task_icon AS ENUM (
    'mark', 'home',
    'job', 'supermarket',
    'cafe', 'activity',
    'drive', 'flight',
    'star', 'flag',
    'hospital', 'outdoor'
);

CREATE TABLE IF NOT EXISTS pgtasks.task (
    id UUID NOT NULL,
    owner_id UUID NOT NULL,
    group_id UUID,
    title TEXT NOT NULL CHECK (LENGTH(title) BETWEEN 1 AND 200),
    description TEXT NOT NULL CHECK (LENGTH(description) BETWEEN 1 AND 10000),
    location GEOGRAPHY(Point, 4326),
    is_favorite BOOLEAN NOT NULL DEFAULT FALSE,
    priority pgtasks.task_priority NOT NULL DEFAULT 'low',
    status pgtasks.task_status NOT NULL DEFAULT 'pending',
    icon pgtasks.task_icon NOT NULL DEFAULT 'mark',
    deadline TIMESTAMPTZ,
    notify_at TIMESTAMPTZ[],
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    purge_at TIMESTAMPTZ,
    title_lang regconfig NOT NULL DEFAULT 'simple'::regconfig,
    description_lang regconfig NOT NULL DEFAULT 'simple'::regconfig,
    search_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector(title_lang, title), 'A') ||
        setweight(to_tsvector(description_lang, description), 'B')
    ) STORED,
    PRIMARY KEY (id, owner_id)
);

CREATE INDEX pgtasks_owner_task_index ON pgtasks.task (owner_id);
CREATE INDEX pgtasks_group_task_index ON pgtasks.task (group_id) WHERE group_id IS NOT NULL;
CREATE INDEX pgtasks_purge_task_index ON pgtasks.task (purge_at) WHERE purge_at IS NOT NULL;
CREATE INDEX pgtasks_fts_task_index ON pgtasks.task USING GIN(search_vector);
CREATE INDEX pgtasks_geo_task_index ON pgtasks.task USING GIST(location);

GRANT SELECT, INSERT, UPDATE, DELETE ON pgtasks.task TO taskbackend GRANTED BY postgres;

EOSQL
