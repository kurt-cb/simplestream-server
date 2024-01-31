#!/bin/bash

#
# this script runs inside of a newly created ubuntu 18.04 image
# and installs everything to get unit (nginx) and the lxd simplestreams
# server running
# Part of the initialization is in userland (ubuntu user) and
# configures a user based python venv to run the python code
# in this package
#
# venv location: /home/ubuntu/ss-env
#

PARENT_HOSTNAME=$1
PASSWORD="$2"

set -x

ROOTDIR=/opt/lxd-image-server

hostname ${PARENT_HOSTNAME}
cat <<EOF >/etc/hostname
${PARENT_HOSTNAME}
EOF

# wait until ubuntu is up
while : ; do
    UP=$(ping -c 1 archive.ubuntu.com)
    if [ "$?" == "0" ]; then
        break
    fi
    sleep 1
done

#OPTIONS="-o Dpkg::Options::=--force-unsafe-io"
OPTIONS="$OPTIONS --no-install-recommends --no-install-suggests -yqq"
set -e
apt-get update -qq
apt-get install $OPTIONS \
   gnupg2 apt-transport-https ca-certificates curl wget \
   strace curl wget netcat nano git patch net-tools build-essential \
   cmake lxd

sudo curl --output /usr/share/keyrings/nginx-keyring.gpg  \
      https://unit.nginx.org/keys/nginx-keyring.gpg

cat <<EOF > /etc/apt/sources.list.d/unit.list
deb [signed-by=/usr/share/keyrings/nginx-keyring.gpg] https://packages.nginx.org/unit/ubuntu/ bionic unit
deb-src [signed-by=/usr/share/keyrings/nginx-keyring.gpg] https://packages.nginx.org/unit/ubuntu/ bionic unit
EOF

apt update
apt install $OPTIONS unit unit-dev uwsgi python3-pip \
    python3.7-venv python3.7-dev unit-python3.7
#sudo apt install $OPTIONS unit-dev unit-jsc8 unit-jsc11 unit-perl  \
#      unit-php unit-python2.7 unit-python3.6 unit-python3.7 unit-ruby uwsgi python3-pip

cat <<EOF >/etc/default/unit
DAEMON_ARGS=--control 127.0.0.1:8080
EOF

sudo systemctl restart unit

echo "Installing debugging tools"
apt-get install $OPTIONS strace curl wget netcat nano git patch

git clone https://github.com/kurt-cb/simplestream-server.git
cd simplestream-server
git checkout unit

mkdir -p /var/www/logs
cp upload_server.conf /etc

cp -r upload_server /var/www
cp -r html /var/www
mkdir -p /var/www/simplestreams
chown -R unit:unit /var/www
chmod -R g+s /var/www/simplestreams
chmod -R g+w /var/www
cp scripts/user_config.sh /home/ubuntu
cd ..

# put ubuntu in unit group
usermod -G adm,unit,lxd ubuntu
chgrp unit /home/ubuntu
chmod g+s /home/ubuntu

# create venv
chown ubuntu /home/ubuntu/user_config.sh
su ubuntu -c "~/user_config.sh"

# map in images directory
ln -sf /mnt/images /var/www/simplestreams

# create service
cp $ROOTDIR/scripts/lxd-image-server.service /etc/systemd/system
systemctl enable lxd-image-server
systemctl start lxd-image-server

# configure certificate bundle
cat $ROOTDIR/cert.pem $ROOTDIR/key.pem >bundle.pem
curl -X PUT --data-binary @bundle.pem localhost:8080/certificates/bundle

# now activate the server config
cat simplestream-server/unit_config.json | curl -X PUT -d@- localhost:8080/config

cat <<EOF | lxd init --preseed
config:
  core.https_address: '[::]:8001'
  core.trust_password: ${PASSWORD}
  images.auto_update_interval: "0"
networks: []
storage_pools:
- config: {}
  description: ""
  name: default
  driver: dir
profiles:
- config:
    security.privileged: "true"
  description: ""
  devices:
    root:
      path: /
      pool: default
      type: disk
  name: default
cluster: null
EOF
