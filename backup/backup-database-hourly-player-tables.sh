#!/usr/bin/env bash

# Fetch hostname deployment directory and format into backup prepend
# DEPLOYMENT_NAME=$HOST_NAME/$(basename $HOST_DIR)

CWD=$(pwd)
source $CWD/.env

export TZ

if [ -z "${BACKUP_RETENTION_HOURLY_PLAYER_DB_SNAPSHOTS}" ]; then
  echo "Error: BACKUP_RETENTION_HOURLY_PLAYER_DB_SNAPSHOTS is not set. Exiting."
  exit 1
fi

# get player tables from github, we can't hit world from the backup-cron container without duplicating the eqemu-server container and its dependencies
player_tables=$(curl -s "https://raw.githubusercontent.com/EQEmu/Server/refs/heads/master/common/database_schema.h" | \
awk '/GetPlayerTables\(\)/,/\}/' | \
grep -oP '"\K[^"]+' | \
tr '\n' ' ' | sed 's/,//g' | xargs)

cd /tmp/

# validate
set -e
"$CWD/backup/validate-dropbox.sh"
set +e

#############################################
# mysqldump
#############################################
echo "# Dumping database and compressing"
MYSQL_BACKUP_NAME=${MARIADB_DATABASE}-player-data-$(date +"%m-%d-%Y_h%H-m%M")
mysqldump --lock-tables=false -u${MARIADB_USER} -p${MARIADB_PASSWORD} -h mariadb ${MARIADB_DATABASE} ${player_tables} >/tmp/${MYSQL_BACKUP_NAME}.sql
tar -zcvf ${MYSQL_BACKUP_NAME}.tar.gz ${MYSQL_BACKUP_NAME}.sql

#############################################
# upload
#############################################
echo "# Uploading database snapshot"
dropbox_uploader.sh upload ${MYSQL_BACKUP_NAME}.tar.gz ${DEPLOYMENT_NAME:-backups}/database-player-hourly-snapshots/${MYSQL_BACKUP_NAME}.tar.gz

#############################################
# prune snapshots
#############################################
BACKUP_RETENTION=${BACKUP_RETENTION_HOURLY_PLAYER_DB_SNAPSHOTS:-48}
BACKUP_PATH=${DEPLOYMENT_NAME:-backups}/database-player-hourly-snapshots
echo "# Truncating ${BACKUP_PATH} hours back ${BACKUP_RETENTION}"
OUTPUT=$($CWD/backup/dropbox-list-truncation-files-hourly.pl ${BACKUP_PATH} ${BACKUP_RETENTION})
for x in $OUTPUT; do dropbox_uploader.sh delete ${BACKUP_PATH}/$x; done

#############################################
# cleanup
#############################################
echo "# Cleaning up..."
sudo rm -rf /tmp/${MYSQL_BACKUP_NAME}.*
