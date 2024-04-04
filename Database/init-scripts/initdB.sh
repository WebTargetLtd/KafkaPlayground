#!/bin/bash
set -e

adminsql="psql -d postgres "
sql="psql -d $PGDATABASE "
# PGDATABASE="POOP"

res=`${adminsql} -t -c "SELECT count(*) FROM pg_database WHERE datname = '$PGDATABASE';"`

if [ ${res} -gt 0 ]; then
    echo "DB ${PGDATABASE} Exists"
else
    echo "DB ${PGDATABASE} doesn't exist"
    echo "SELECT 'CREATE DATABASE $PGDATABASE' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$PGDATABASE')\gexec" | $adminsql
fi;

echo "CREATE SCHEMA IF NOT EXISTS bips;" | $sql
cat /Scripts/Populate/destructuredTable.sql | $sql
echo 'ALTER TABLE bips.t_bips REPLICA IDENTITY FULL;' | $sql
cat /Scripts/Populate/rawTable.sql | $sql
cat /Scripts/Populate/functions.sql | $sql

rawCount=`${sql} -t -c "SELECT count(*) FROM bips.t_raw;"`    
if [ ${rawCount} == 0 ]; then
    echo "Importing data"
    echo "\copy bips.t_raw from program 'zcat /Scripts/Populate/landingBips.sql.gz' DELIMITER ',' CSV HEADER" | $sql
    echo "Data imported"
fi;
