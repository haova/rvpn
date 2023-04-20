#!/bin/bash
IMAGE_NAME=rvpn:v1

container_ids=$(docker ps -a -q --filter ancestor=$IMAGE_NAME)
if [[ ! -z $container_ids ]]; then
  docker stop $container_ids
  docker rm $container_ids
fi