#!/bin/bash

ROOT="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
HOME_ROOT="$HOME/.rvpn"
PRIVATE_PATH="$HOME_ROOT/private"
PSK_PATH="$HOME_ROOT/psk"
ENDPOINT="$1"
INTERFACE_NAME="wg0"
DATABASE_FILE="$HOME_ROOT/db"
LOG_FILE="$HOME_ROOT/log.txt"
IP_NET="10.0.0"
COMMAND_PORT=42912
SYNC_PORT=42913

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

# create directories and files
if [ ! -d "$HOME_ROOT" ]; then
  echo "[Init] Create Home Root"
  mkdir "$HOME_ROOT"
fi

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

    iptables -A FORWARD -i wg0 -j ACCEPT
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    ip6tables -A FORWARD -i wg0 -j ACCEPT
    ip6tables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
  fi

  publicKey="$(wg show wg0 private-key | wg pubkey)"
  localIp="$(ip addr show wg0 | grep 'inet\b' | awk '{print $2}' | cut -d/ -f1)"

  # connect to peer
  if [ ! -z "$ENDPOINT" ]; then
    echo "[IO] Connect to endpoint $ENDPOINT"

    exec 3<>"/dev/tcp/$ENDPOINT/$COMMAND_PORT"
    echo "conn $publicKey" >&3
    IFS=" " read -r internalIp serverPubkey localEndpoint <&3
    ip address add dev wg0 "$internalIp/24"
    wg set wg0 peer "$serverPubkey" allowed-ips 0.0.0.0/0 preshared-key "$PSK_PATH" endpoint "$ENDPOINT:51820"

    # ping to connect and sync db
    echo "[IO] Ping to $localEndpoint" >> $LOG_FILE
    ping -c 1 $localEndpoint
    exec 3<>"/dev/tcp/$localEndpoint/$COMMAND_PORT"
    echo "sync" >&3
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

  echo "Serve server"
  exec ncat -e "$(readlink -f "$0")" -k -l -p $COMMAND_PORT -v
fi

publicKey="$(wg show wg0 private-key | wg pubkey)"
IFS=' '
read -r command data
localIp="$(ip addr show wg0 | grep 'inet\b' | awk '{print $2}' | cut -d/ -f1)"

# add new conn to peer
if [ "$command" == "conn" ]; then
  # find exist peer
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

  # check peer
  currentIp=""
  if [ "$matchIndex" == "" ]; then
    db_set "$emptyIndex" "$data"
    currentIp="$IP_NET.$emptyIndex"
  else
    currentIp="$IP_NET.$matchIndex"
  fi

  # response ip
  echo "$currentIp $publicKey $localIp"
  wg set wg0 peer "$data" allowed-ips "$currentIp/32" preshared-key "$PSK_PATH"

  exit 1
fi

if [ "$command" == "sync" ]; then
  # broadcast db
  for ((i=1; i<=254; i++)); do
    key="$(db_get $i)"
    currentIp="$IP_NET.$i"
    if [ ! -z "$key" ]; then
      echo "[Conn] Sync db to $currentIp" >> $LOG_FILE
      nc "$currentIp" $SYNC_PORT < $DATABASE_FILE
    fi
  done
fi