#!/bin/bash

# Create a network with peers: pc00, .., pc_n
# In each peer: pc_i -> pc00

CLEAN_PEERS="./scripts/docker-clean.sh"
CREATE_PEER="./scripts/docker-create.sh"
REMOTE_PEER="./scripts/docker-remote.sh"
DETACH_PEER="./scripts/docker-detach.sh"

"$CLEAN_PEERS"

function is_ready() {
  nc -z "$1" 42912
  if [ $? -eq 0 ]; then
    return 0 # success
  else
    return 1 # failure
  fi
}

function get_ip() {
  container_id=$(docker ps -qf "name=$1")
  container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_id")
  echo "$container_ip"
}

# generate peers
peers=()

n=$1
if [ -z "$n" ]; then
  n=3
fi

count=0
for i in 0 1 2 3 4 5 6 7 8 9
do
  for j in 0 1 2 3 4 5 6 7 8 9
  do
    (( count++ ))
    peers+=("pc$i$j")
    if [ $count -ge $n ]; then
      break
    fi
  done

  if [ $count -ge $n ]; then
    break
  fi
done

endpoint=""

for peer in "${peers[@]}"
do
  echo "[Test] Deploy peer $peer"
  "$CREATE_PEER" "$peer"
  currentIp=$(get_ip "$peer")

  "$DETACH_PEER" "$peer" /app/sync.sh

  if [ ! -z "$endpoint" ]; then
    echo "[Test] Connect $peer to endpoint $endpoint"
    "$DETACH_PEER" "$peer" /app/start.sh "$endpoint"
  else
    echo "[Test] Select $peer for endpoint"
    "$DETACH_PEER" "$peer" /app/start.sh
    endpoint="$currentIp"
  fi

  echo "[Test] $peer is running at $currentIp"
done

# create event loop to confirm all peers are ready
while true; do
  count=$n

  echo "[Test] Check peer ready..."
  for peer in "${peers[@]}"
  do
    currentIp=$(get_ip "$peer")
    if is_ready "$currentIp"; then
      (( count-- ))
    fi
  done

  if [ $count -eq 0 ]; then
    break
  fi

  sleep 1
done

echo "[Test] All peers are ready"

for peer in "${peers[@]}"
do
  "$DETACH_PEER" "$peer" /app/server.sh serve
done