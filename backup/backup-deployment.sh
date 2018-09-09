#!/usr/bin/env bash

CWD=$(pwd)
source $CWD/.env

cd /tmp/

if [ -z "${DROPBOX_OAUTH_ACCESS_TOKEN}" ]; then
    echo "DROPBOX_OAUTH_ACCESS_TOKEN is not set; run dropbox_uploader.sh to initialize Dropbox API"
    exit;
fi

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
OUTPUT=`dropbox_uploader.sh list ${BACKUP_PATH} | grep -v "Listing" | cut -d " " -f 4- | sort -r | tail -n +${BACKUP_RETENTION} | awk '{$1=$1};1'`
for x in $OUTPUT; do dropbox_uploader.sh delete ${BACKUP_PATH}/$x; done

#############################################
# cleanup
#############################################
echo "# Cleaning up..."
sudo rm -rf /tmp/${DEPLOYMENT_BACKUP_NAME}.tar.gz
