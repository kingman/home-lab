#!/bin/sh

name="dnsmasq"

if [ ! "$(docker ps -q -f name=$name)" ]; then
  echo "Starting $name container"
  docker run \
    -d \
    --hostname=$name \
    --name=$name \
    --net=host \
    --privileged \
    --restart=always \
    ferrarimarco/home-lab-dnsmasq:1.0.0
else
  echo "$name container is already running"
fi
