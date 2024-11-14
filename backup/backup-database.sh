#!/usr/bin/env bash

# Fetch hostname deployment directory and format into backup prepend
# DEPLOYMENT_NAME=$HOST_NAME/$(basename $HOST_DIR)

CWD=$(pwd)
source $CWD/.env

export TZ

cd /tmp/

# validate
set -e
"$CWD/backup/validate-dropbox.sh"
set +e

#############################################
# mysqldump
#############################################
echo "# Dumping database and compressing"
MYSQL_BACKUP_NAME=${MARIADB_DATABASE}-$(date +"%m-%d-%Y")
mysqldump --lock-tables=false -u${MARIADB_USER} -p${MARIADB_PASSWORD} -h mariadb ${MARIADB_DATABASE} >/tmp/${MYSQL_BACKUP_NAME}.sql
tar -zcvf ${MYSQL_BACKUP_NAME}.tar.gz ${MYSQL_BACKUP_NAME}.sql

#############################################
# upload
#############################################
echo "# Uploading database snapshot"
dropbox_uploader.sh upload ${MYSQL_BACKUP_NAME}.tar.gz ${DEPLOYMENT_NAME:-backups}/database-snapshots/${MYSQL_BACKUP_NAME}.tar.gz

#############################################
# prune snapshots
#############################################
BACKUP_RETENTION=${BACKUP_RETENTION_DAYS_DB_SNAPSHOTS:-7}
BACKUP_PATH=${DEPLOYMENT_NAME:-backups}/database-snapshots
echo "# Truncating ${BACKUP_PATH} days back ${BACKUP_RETENTION}"
OUTPUT=$($CWD/backup/dropbox-list-truncation-files.pl ${BACKUP_PATH} ${BACKUP_RETENTION})
for x in $OUTPUT; do dropbox_uploader.sh delete ${BACKUP_PATH}/$x; done

#############################################
# cleanup
#############################################
echo "# Cleaning up..."
sudo rm -rf /tmp/${MYSQL_BACKUP_NAME}.*
