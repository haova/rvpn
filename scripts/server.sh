#!/bin/bash

HOME_ROOT="$HOME/.rvpn"
DATABASE_FILE="$HOME_ROOT/db"

function serve() {
  PORT=8080

  while true; do 
    ncat -l -p $PORT -e "./server.sh handle"
  done
}

function handle() {
  # ip
  localIp="$(ip addr show wg0 | grep 'inet\b' | awk '{print $2}' | cut -d/ -f1)"

  # peers
  dbContent=$(cat "$DATABASE_FILE")

  # info

  # Get the output of the 'free' command
  free_output=$(free)

  # Extract the second line of the output, which contains the RAM usage information
  ram_usage=$(echo "$free_output" | sed -n '2p')

  # Extract the total, used, and free RAM values from the line
  total_ram=$(echo "$ram_usage" | awk '{print $2}')
  used_ram=$(echo "$ram_usage" | awk '{print $3}')


  echo -e "HTTP/1.1 200 OK\nAccess-Control-Allow-Origin: *\nAccess-Control-Allow-Methods: *\nAccess-Control-Allow-Headers: *\n\nServer IP Address: $localIp\nClient Ip Address: $NCAT_REMOTE_ADDR\nServer Memory: $used_ram/$total_ram\n$dbContent"
}

"$1"
