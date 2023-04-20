#!/bin/bash
PSK_PATH=".psk"

# generate preshared key
if [ ! -f "$PSK_PATH" ]; then
  echo "[Init] Generate Preshared Key"
  wg genpsk > "$PSK_PATH"
fi

if [[ -z $1 ]]; then
  echo "USAGE: sudo ./rvpn.sh <command> [args]"
  echo ""
  echo "Commands"
  echo "  start                  Start VPN."
  echo "  stop                   Stop VPN."
  echo "  docker <subcommand>    Run docker commands."    
  echo "    clean                          Clean docker containers."
  echo "    stop                           Stop docker containers."
  echo "    create <name>                  Create a new peer VPN."
  echo "    remote <name> [script] [args]  Enter and remote VPN peer."
  echo "    detach <name> [script] [args]  Run script in background."
  echo "  test <test-case>       Run a test case. For more information, visit ./test directory."
else
  case $1 in
    docker)
      "scripts/$1-$2.sh" $3 $4 $5
      exit 1
      ;;
    test)
      "test/$2.sh" $3 $4 $5
      exit 1
      ;;
    *)
      "scripts/$1.sh" $2 $3 $4 $5
      exit 1
      ;;
  esac
fi