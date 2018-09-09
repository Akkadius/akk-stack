#!/usr/bin/env bash

CWD=$(pwd)
source $CWD/.env

cd /tmp/

if [ -z "${DROPBOX_OAUTH_ACCESS_TOKEN}" ]; then
    echo "DROPBOX_OAUTH_ACCESS_TOKEN is not set; run dropbox_uploader.sh to initialize Dropbox API"
    exit;
fi

#############################################
# mysqldump
#############################################
echo "# Dumping database and compressing"
MYSQL_BACKUP_NAME=${MARIADB_DATABASE}-$(date +"%m-%d-%Y")
mysqldump --lock-tables=false -u${MARIADB_USER} -p${MARIADB_PASSWORD} -h mariadb ${MARIADB_DATABASE} > /tmp/${MYSQL_BACKUP_NAME}.sql
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
OUTPUT=`dropbox_uploader.sh list ${BACKUP_PATH} | grep -v "Listing" | cut -d " " -f 4- | sort -r | tail -n +${BACKUP_RETENTION} | awk '{$1=$1};1'`
for x in $OUTPUT; do dropbox_uploader.sh delete ${BACKUP_PATH}/$x; done

#############################################
# cleanup
#############################################
echo "# Cleaning up..."
sudo rm -rf /tmp/${MYSQL_BACKUP_NAME}.*
