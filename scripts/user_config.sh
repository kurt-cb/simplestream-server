#!/bin/bash

# This script is used to configure a virtual environment in user space during container setup
# it is called in the context of the default user

set -x
set -e
PASSWORD="$1"

cd ~
python3.7 -m pip install virtualenv==20.14.1
python3.7 -m virtualenv --no-pip --no-setuptools ss-env
source ss-env/bin/activate
curl -sSL https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python get-pip.py "pip==23.3.2" "setuptools==41.0.1" "wheel==0.37.1"
rm get-pip.py
pip config set global.disable-pip-version-check true

pip install bottle uwsgi click inotify cryptography \
    confight configargparse rpyc pylxd

git clone https://github.com/kurt-cb/simplestream-server.git
cd simplestream-server
git checkout unit

pip install -e .

alias spython='sudo $(printenv VIRTUAL_ENV)/bin/python3'
cd ..

lxd-image-server --log-file STDOUT  init --nginx_skip
sudo chown -R unit:unit /var/www/simplestreams

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

# now generate client certificate for local comms
lxd remote add local_http https://localhost:8001 --password ${PASSWORD} --accept-certificate
