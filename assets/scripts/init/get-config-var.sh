#!/usr/bin/env bash

cat ~/server/eqemu_config.json | jq "$1" | tr -d '\"'
