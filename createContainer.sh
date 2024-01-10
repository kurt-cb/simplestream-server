#!/bin/bash
set -x
set -e

lxc launch images:ubuntu/18.04 simplestream
TMPDIR=$(mktemp -d)

# copy this project into the container
tar cjf $TMPDIR/files.tar.bz2 .
lxc file push $TMPDIR/files.tar.bz2 simplestream/root/files.tar.bz2
rm -rf $TMPDIR
lxc exec simplestream -- bash -c "mkdir -p lxd-image-server;cd lxd-image-server; tar xf ../files.tar.bz2"

# configure the container with nginx and install the python code
lxc exec simplestream -- bash -c lxd-image-server/scripts/config_container.sh
