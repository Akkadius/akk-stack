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
# deployment folder
#############################################
echo "# Backing up entire deployment..."
DEPLOYMENT_BACKUP_NAME=deployment-$(date +"%m-%d-%Y")
sudo tar -zcvf ${DEPLOYMENT_BACKUP_NAME}.tar.gz -C ~/ .
echo "# Uploading entire deployment..."
dropbox_uploader.sh upload ${DEPLOYMENT_BACKUP_NAME}.tar.gz ${DEPLOYMENT_NAME:-backups}/deployment-backups/${DEPLOYMENT_BACKUP_NAME}.tar.gz

IFS='
'

#############################################
# prune deployments
#############################################
BACKUP_RETENTION=${BACKUP_RETENTION_DAYS_DEPLOYMENT:-10}
BACKUP_PATH=${DEPLOYMENT_NAME:-backups}/deployment-backups
echo "# Truncating ${BACKUP_PATH} days back ${BACKUP_RETENTION}"
OUTPUT=$($CWD/backup/dropbox-list-truncation-files.pl ${BACKUP_PATH} ${BACKUP_RETENTION})
for x in $OUTPUT; do dropbox_uploader.sh delete ${BACKUP_PATH}/$x; done

#############################################
# cleanup
#############################################
echo "# Cleaning up..."
sudo rm -rf /tmp/${DEPLOYMENT_BACKUP_NAME}.tar.gz
