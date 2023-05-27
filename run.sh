#!/bin/bash

target=$1

docker stop lab_container

set -ex

if [ ! -f "./run_$target.sql" ]; then
	echo "Wrong target"
	exit 1
fi

docker run --rm -d \
-p 6432:5432 \
--name lab_container \
-e POSTGRES_USER=postgres \
-e POSTGRES_HOST_AUTH_METHOD=trust \
postgres

sleep 2

psql -h localhost -p 6432 -U postgres -f ./init_db.sql
psql -h localhost -p 6432 -U postgres -d lab_db -f "./run_$target.sql"
psql -h localhost -p 6432 -U postgres -d lab_db
