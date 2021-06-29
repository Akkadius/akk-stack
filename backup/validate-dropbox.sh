#!/usr/bin/env bash

if [ ! -f "$HOME/.dropbox_uploader" ]; then
  echo "[$HOME/.dropbox_uploader] config file does not exist!"
  echo "Option 1) Run dropbox_uploader.sh in container to initialize Dropbox API"
  echo "Option 2) [make backup-dropbox-init] from the top level"
  exit 1
fi
