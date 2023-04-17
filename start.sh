#!/bin/bash

ROOT="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
HOME_ROOT="$HOME/.rvpn"
PRIVATE_PATH="$HOME_ROOT/private"
PSK_PATH="$HOME_ROOT/psk"
ENDPOINT="$1"
INTERFACE_NAME="wg0"
DATABASE_FILE="$HOME_ROOT/db"
IP_NET="10.0.0"

function db_clear() {
  rm -f "$DATABASE_FILE"
}
 
function db_set() {
  echo "$1,$2" >> "$DATABASE_FILE"
}
 
function db_get() {
  grep "^$1," "$DATABASE_FILE" | sed -e "s/^$1,//" | tail -n 1
}
 
function db_remove() {
  db_set $1 ""
}

if [ ! -f "$DATABASE_FILE" ]; then
  echo "" > "$DATABASE_FILE"
fi

if [[ -z $NCAT_REMOTE_ADDR ]]; then
  # generate private key
  if [ ! -f "$PRIVATE_PATH" ]; then
    echo "[Init] Generate Private Key"
    wg genkey > "$PRIVATE_PATH"
  fi

  # generate preshared key
  if [ ! -f "$PSK_PATH" ]; then
    echo "[Init] Generate Preshared Key"
    wg genpsk > "$PSK_PATH"
  fi

  # create interface
  if ip link show $INTERFACE_NAME >/dev/null 2>&1; then
    echo "[Init] Interface $INTERFACE_NAME exists"
  else
    echo "[Init] Create interface $INTERFACE_NAME"

    ip link add dev wg0 type wireguard
    wg set wg0 listen-port 51820 private-key "$PRIVATE_PATH"
    ip link set wg0 up
  fi

  publicKey="$(wg show wg0 private-key | wg pubkey)"

  # connect to peer
  if [ ! -z "$ENDPOINT" ]; then
    echo "[IO] Connect to endpoint $ENDPOINT"

    exec 3<>"/dev/tcp/$ENDPOINT/42912"
    echo "conn $publicKey" >&3
    IFS=" " read -r internal_ip server_pubkey <&3
    ip address add dev wg0 "$internal_ip/24"
    wg set wg0 peer "$server_pubkey" allowed-ips 0.0.0.0/0 preshared-key "$PSK_PATH" endpoint "$ENDPOINT:51820"
  else
    for ((i=1; i<=254; i++)); do
      key="$(db_get $i)"
      if [ ! -z "$key" ]; then
        if [ "$key" == "$publicKey" ]; then
          ip address add dev wg0 "$IP_NET.$i/24"
          break
        fi
      else
        db_set "$i" "$publicKey"
        ip address add dev wg0 "$IP_NET.$i/24"
        break
      fi
    done
  fi

  # open server to read
  if ! command -v ncat >/dev/null 2>&1; then
    echo "[Error] ncat is not installed"
    exit 1
  fi

  exec ncat -e "$(readlink -f "$0")" -k -l -p 42912 -v
fi

publicKey="$(wg show wg0 private-key | wg pubkey)"
IFS=' '
read -r command data
if [ "$command" == "conn" ]; then
  matchIndex=""
  matchKey=""
  emptyIndex=""

  for ((i=1; i<=254; i++)); do
    key="$(db_get $i)"
    if [ ! -z "$key" ]; then
      if [ "$key" == "$data" ]; then
        matchIndex="$i"    
        matchKey="$key"
        break
      fi
    else
      emptyIndex="$i"
    fi
  done

  currentIp=""
  if [ "$matchIndex" == "" ]; then
    db_set "$emptyIndex" "$data"
    currentIp="$IP_NET.$emptyIndex"
  else
    currentIp="$IP_NET.$matchIndex"
  fi

  echo "$currentIp $publicKey"
  wg set wg0 peer "$data" allowed-ips "$currentIp/32" preshared-key "$PSK_PATH"
fi