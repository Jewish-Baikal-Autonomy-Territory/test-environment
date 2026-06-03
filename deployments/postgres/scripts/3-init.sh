#!/usr/bin/env bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL

CREATE DATABASE authdb;
\c authdb;

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE ROLE authbackend WITH NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT LOGIN PASSWORD 'authbackend';

GRANT ALL PRIVILEGES ON SCHEMA public TO authbackend GRANTED BY postgres;

SET ROLE authbackend;

CREATE TABLE users (
                       id             UUID PRIMARY KEY             DEFAULT gen_random_uuid(),
                       password       VARCHAR(60)         NULL,
                       email          VARCHAR(255) UNIQUE NOT NULL,
                       phone_number   VARCHAR(255) UNIQUE NULL,
                       first_name     VARCHAR(255)        NOT NULL,
                       last_name      VARCHAR(255)        NOT NULL,
                       middle_name    VARCHAR(255)        NULL,
                       created_at     TIMESTAMP           NOT NULL DEFAULT CURRENT_TIMESTAMP,
                       updated_at     TIMESTAMP           NULL,
                       role           VARCHAR(50)         NOT NULL,
                       is_verificated BOOLEAN             NOT NULL
);

CREATE TABLE jwt (
                     id         UUID PRIMARY KEY   DEFAULT gen_random_uuid(),
                     token      TEXT      NOT NULL,
                     user_id    UUID      NOT NULL,
                     created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                     updated_at TIMESTAMP NULL,
                     FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE TABLE verification
(
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email             VARCHAR(255) NOT NULL UNIQUE,
    verification_code VARCHAR(10)  NOT NULL,
    FOREIGN KEY (email) REFERENCES users (email) ON DELETE CASCADE
);

CREATE TABLE refresh_tokens
(
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token       TEXT      NOT NULL UNIQUE,
    user_id     UUID      NOT NULL,
    expiry_date TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE INDEX idx_jwt_user_id ON jwt(user_id);
CREATE INDEX idx_verification_user_email ON verification(email);
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens (user_id);
CREATE INDEX idx_refresh_tokens_token ON refresh_tokens (token);
CREATE INDEX idx_users_email ON users (email);

EOSQL