#!/bin/bash

sed -n "/CREATE TABLE /,/;/p" ./lab.sql | sed s/~\ \'.*\'/LIKE\ \'\'/ > ./generated_lab.sql