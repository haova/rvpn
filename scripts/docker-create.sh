#!/bin/bash
IMAGE_NAME=rvpn:v1
CONTAINER_NAME="$1"

if [[ -z "$CONTAINER_NAME" ]]; then
  echo "Container name must not be empty"
  exit 1
fi

docker build -t "$IMAGE_NAME" .
docker run --name "$CONTAINER_NAME" -itd --cap-add CAP_SYS_ADMIN --cap-add=NET_ADMIN --security-opt apparmor=unconfined "$IMAGE_NAME"