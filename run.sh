#!/bin/bash

target=$1

docker stop lab_container

set -ex

docker run --rm -d \
-p 6432:5432 \
--name lab_container \
-e POSTGRES_USER=postgres \
-e POSTGRES_HOST_AUTH_METHOD=trust \
postgres

sleep 2

psql -h localhost -p 6432 -U postgres -f ./init_db.sql
if [[ "$target" = "procedures" ]]; then
	psql -h localhost -p 6432 -U postgres -d lab_db -f ./run_procedures.sql
elif [[ "$target" = "selects" ]]; then
	psql -h localhost -p 6432 -U postgres -d lab_db -f ./run_selects.sql
else
	echo "Please, set target (procedures or selects)"
	exit 1
fi

psql -h localhost -p 6432 -U postgres -d lab_db
