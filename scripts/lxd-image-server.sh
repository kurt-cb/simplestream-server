#!/bin/bash

export $(dbus-launch)
/home/ubuntu/ss-env/bin/lxd-image-server $@