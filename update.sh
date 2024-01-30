#!/bin/bash

SCRIPTDIR=$(dirname $0)
git pull
su ubuntu -l -c "cd simplestream-server;git pull"
echo {} | curl -X PUT -d@- localhost:8080/config
cat unit_config.json | curl -X PUT -d@- localhost:8080/config
