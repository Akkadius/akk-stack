#!/usr/bin/env bash

CWD=$(pwd)
source $CWD/.env

if [ ! -f ".dropbox_uploader" ]; then
  echo "[.dropbox_uploader] config file does not exist"
  echo "Option 1) Run dropbox_uploader.sh in container to initialize Dropbox API"
  echo "Option 2) [make backup-dropbox-init] from the top level"
  dropbox_uploader.sh
else
  echo "# Backup cron booting..."

  while inotifywait -e modify ./backup/*.cron; do bash -c "cat ./backup/*.cron > /tmp/crontab && crontab /tmp/crontab && rm /tmp/crontab; sudo pkill cron; echo '# Installing changed crons...' > /proc/1/fd/1 2>/proc/1/fd/2; sudo cron -f &"; done >/dev/null 2>&1 &

  echo "# Installing crons..."
  cat ./backup/*.cron >/tmp/crontab && crontab /tmp/crontab && rm /tmp/crontab && sudo cron -f
fi
