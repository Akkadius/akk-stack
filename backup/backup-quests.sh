#!/usr/bin/env bash

# Fetch hostname deployment directory and format into backup prepend
# DEPLOYMENT_NAME=$HOST_NAME/$(basename $HOST_DIR)

CWD=$(pwd)
source $CWD/.env

cd /tmp/

# validate
set -e
"$CWD/backup/validate-dropbox.sh"
set +e

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
OUTPUT=$($CWD/backup/dropbox-list-truncation-files.pl ${BACKUP_PATH} ${BACKUP_RETENTION})
for x in $OUTPUT; do dropbox_uploader.sh delete ${BACKUP_PATH}/$x; done

#############################################
# cleanup
#############################################
echo "# Cleaning up..."
sudo rm -rf /tmp/${DEPLOYMENT_BACKUP_NAME}.tar.gz
