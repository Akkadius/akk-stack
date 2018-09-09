#!/usr/bin/env bash

database_password=$(cat ~/server/eqemu_config.json | jq '.server.database.password' | tr -d '\"')

mysql -h mariadb -ueqemu -p$database_password -e "DROP DATABASE IF EXISTS peq; CREATE DATABASE peq"
