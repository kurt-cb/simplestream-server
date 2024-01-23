#!/bin/bash
set -x
set -e
SERVER=$(uname -n)

# create a self-signed server certificate
if [ ! -f key.pem ]; then
    openssl req -subj "/CN=$SERVER/O=simpleserver/C=US" \
      -new -newkey rsa:2048 -sha256 -days 365 -nodes -x509 \
      -keyout key.pem -out cert.pem
fi

lxc launch images:ubuntu/18.04 simplestream
TMPDIR=$(mktemp -d)
DIRMOUNT=1

# copy this project into the container
if [ $DIRMOUNT ]; then
   lxc config add  simplestream  webdir disk source=$(pwd) path=/root/lxd-image-server
   lxc config device add simplestream server2 proxy connect="tcp:127.0.0.1:8843" listen="tcp:0.0.0.0:8843"
else
   tar cjf $TMPDIR/files.tar.bz2 .
   lxc file push $TMPDIR/files.tar.bz2 simplestream/root/files.tar.bz2
   rm -rf $TMPDIR
   lxc exec simplestream -- bash -c "mkdir -p lxd-image-server;cd lxd-image-server; tar xf ../files.tar.bz2"
fi
# configure the container with nginx and install the python code
lxc exec simplestream -- bash -c lxd-image-server/scripts/config_container.sh
