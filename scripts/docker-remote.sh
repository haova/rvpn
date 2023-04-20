#!/bin/bash
CONTAINER_NAME="$1"
REMOTE_SCRIPT="$2"

if [[ -z "$REMOTE_SCRIPT" ]]; then
  REMOTE_SCRIPT="/bin/bash"
fi

docker exec -it "$CONTAINER_NAME" "$REMOTE_SCRIPT" $3