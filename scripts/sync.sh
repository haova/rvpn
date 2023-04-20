#!/bin/bash

HOME_ROOT="$HOME/.rvpn"
TEMP_DATABASE_FILE="$HOME_ROOT/.db.tmp"
DATABASE_FILE="$HOME_ROOT/db"
SYNC_PORT=42913

while true; do
  echo "[Sync] Waiting for file"
  ncat -l -p $SYNC_PORT > $TEMP_DATABASE_FILE
  echo "[Sync] Received"
  cp $TEMP_DATABASE_FILE $DATABASE_FILE
  echo "[Sync] Updated"

  echo "[Sync] Try to connect to unknown peer"
done