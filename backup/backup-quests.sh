#!/usr/bin/env bash

CWD=$(pwd)
source $CWD/.env

cd /tmp/

if [ -z "${DROPBOX_OAUTH_ACCESS_TOKEN}" ]; then
    echo "DROPBOX_OAUTH_ACCESS_TOKEN is not set; run dropbox_uploader.sh to initialize Dropbox API"
    exit;
fi

#############################################
# quest
#############################################
echo "# Dumping quest and compressing"
DEPLOYMENT_BACKUP_NAME=quests-$(date +"%m-%d-%Y")
sudo tar -zcvf ${DEPLOYMENT_BACKUP_NAME}.tar.gz -C ~/server/quests .

#############################################
# upload
#############################################
echo "# Uploading quest snapshot"
dropbox_uploader.sh upload ${DEPLOYMENT_BACKUP_NAME}.tar.gz ${DEPLOYMENT_NAME:-backups}/quest-snapshots/${DEPLOYMENT_BACKUP_NAME}.tar.gz

#############################################
# prune snapshots
#############################################
BACKUP_RETENTION=${BACKUP_RETENTION_DAYS_QUEST_SNAPSHOTS:-7}
BACKUP_PATH=${DEPLOYMENT_NAME:-backups}/quest-snapshots
echo "# Truncating ${BACKUP_PATH} days back ${BACKUP_RETENTION}"
OUTPUT=`dropbox_uploader.sh list ${BACKUP_PATH} | grep -v "Listing" | cut -d " " -f 4- | sort -r | tail -n +${BACKUP_RETENTION} | awk '{$1=$1};1'`
for x in $OUTPUT; do dropbox_uploader.sh delete ${BACKUP_PATH}/$x; done

#############################################
# cleanup
#############################################
echo "# Cleaning up..."
sudo rm -rf /tmp/${DEPLOYMENT_BACKUP_NAME}.tar.gz
