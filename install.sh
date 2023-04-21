#!/bin/bash

ROOT="$HOME/.rvpn"
SOURCE_DIR="$ROOT/rvpn-master"

if [[ ! -d "$ROOT" ]]
then
  mkdir "$ROOT"
fi

if [[ -d "$SOURCE_DIR" ]]
then
  rm -rf "$SOURCE_DIR"
fi

cd "$ROOT"
curl -L https://github.com/haova/rvpn/archive/refs/heads/master.zip --output master.zip
unzip master.zip
cd "$SOURCE_DIR"
chmod +x ./scripts/*