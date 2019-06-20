#!/bin/sh

echo "run aggregator revision [$GIT_REVISION]"

export PGPASSWORD=$KPI_DATABASE_PASSWORD

echo connect to [$KPI_DATABASE_HOST] with user [$KPI_DATABASE_USER] to database [$KPI_DATABASE_NAME]

psql -h $KPI_DATABASE_HOST -U $KPI_DATABASE_USER -d $KPI_DATABASE_NAME -f /tmp/aggregator.sql
