#!/bin/bash

# This file is sourced by the start.sh script. Changes made to environment
# variables or adding environment variables will take effect in the shell
# postgres is running in. Anything added to this file will be executed
# after the database has been started.

echo_info "Executing post-start-hook.." # add below this line

echo "Waiting for PostgreSQL to start.."
while true; do
    pg_isready \
    --host=${PG_PRIMARY_HOST} \
    --port=${PG_PRIMARY_PORT} \
    --username=${PG_PRIMARY_USER?} \
    --timeout=2
    if [ $? -eq 0 ]; then
        echo "The database is ready."
        break
    fi
    sleep 2
done

# Create the oereb database
psql -d postgres \
-v PG_DATABASE=$PG_DATABASE \
-v PG_USER=$PG_USER \
-v PG_WRITE_USER=$PG_WRITE_USER \
-v PG_WRITE_PASSWORD=$PG_WRITE_PASSWORD \
-v PG_READ_USER=$PG_READ_USER \
-v PG_READ_PASSWORD=$PG_READ_PASSWORD \
-f /pgconf/setup_oereb_db.sql

# Create tables in the oereb database
psql -d $PG_DATABASE --single-transaction \
-c "SET ROLE $PG_USER" \
-f /pgconf/agi_avdpool.sql \
-f /pgconf/agi_plzortschaft.sql

# Grant permissions on schemas and tables of the oereb database
psql -d $PG_DATABASE --single-transaction \
-v PG_WRITE_USER=$PG_WRITE_USER \
-v PG_READ_USER=$PG_READ_USER \
-f /pgconf/postscript.sql

echo_info "Executing post-start-hook finished. Database is ready for use."
