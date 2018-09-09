#!/usr/bin/env bash

CWD=$(pwd)
source $CWD/.env

if [ -z "$DROPBOX_OAUTH_ACCESS_TOKEN" ]; then
  echo "DROPBOX_OAUTH_ACCESS_TOKEN is not set; run dropbox_uploader.sh to initialize Dropbox API"
  dropbox_uploader.sh
else
  echo "# Injecting Dropbox Access Token"
  echo "OAUTH_ACCESS_TOKEN=$DROPBOX_OAUTH_ACCESS_TOKEN" | sudo tee ~/.dropbox_uploader

  echo "# Backup cron booting..."

  while inotifywait -e modify ./backup/*.cron; do bash -c "cat ./backup/*.cron > /tmp/crontab && crontab /tmp/crontab && rm /tmp/crontab; sudo pkill cron; echo '# Installing changed crons...' > /proc/1/fd/1 2>/proc/1/fd/2; sudo cron -f &"; done >/dev/null 2>&1 &

  echo "# Installing crons..."
  cat ./backup/*.cron >/tmp/crontab && crontab /tmp/crontab && rm /tmp/crontab && sudo cron -f
fi
