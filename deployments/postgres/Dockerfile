FROM postgres:18-bookworm

RUN apt-get update \
    && apt-get -y install --no-install-recommends \
    postgresql-18-cron \
    postgresql-18-postgis-3 \
    && rm -rf /var/lib/apt/lists/*
