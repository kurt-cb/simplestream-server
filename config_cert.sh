#!/bin/bash

set -x
SERVER_file=$(echo $1 | tr ':' '-')
SERVER=$1

openssl s_client -showcerts -connect %SERVER </dev/null 2>/dev/null | openssl x509 -outform PEM > my-lxd-image-$SERVER_file.crt
cp my-lxd-image-$SERVER_file.crt /usr/local/share/ca-certificates
update-ca-certificates
systemctl restart lxd
