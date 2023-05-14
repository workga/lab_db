#!/bin/bash

docker stop lab_container

set -ex

docker run --rm -d \
-p 6432:5432 \
--name lab_container \
-e POSTGRES_USER=postgres \
-e POSTGRES_HOST_AUTH_METHOD=trust \
postgres

sleep 1

psql -h localhost -p 6432 -U postgres -f ./lab.sql
psql -h localhost -p 6432 -U postgres lab_db