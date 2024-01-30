#!/bin/bash
set -x 
openssl s_client -showcerts -connect localhost:8443 </dev/null 2>/dev/null | openssl x509 -outform PEM > my-lxd-image-server.crt
cp my-lxd-image-server.crt /usr/local/share/ca-certificates
update-ca-certificates
systemctl restart lxd
