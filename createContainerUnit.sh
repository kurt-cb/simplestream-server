#!/bin/bash

# this script is used to create a lxd container
# that encorporates several services provided
# by nginx's unit framework and python

set -x
set -e
SERVER=$(uname -n)


function addUserToContainer() {
    local CONTAINER_NAME="$1"

    # collect uid and gid of current user
    myUid=$(id -u)
    myGid=$(id -g)
    myName=$(id -un)
    myGroup=$(id -gn)
    myFullName=$(getent passwd $myName | cut -d : -f 5 | cut -d , -f 1)

    printf "%s:%d uid           :%s\n" "$(basename ${BASH_SOURCE[0]})" $LINENO "$myUid"
    printf "%s:%d gid           :%s\n" "$(basename ${BASH_SOURCE[0]})" $LINENO "$myGid"
    printf "%s:%d name          :%s\n" "$(basename ${BASH_SOURCE[0]})" $LINENO "$myName"
    printf "%s:%d group         :%s\n" "$(basename ${BASH_SOURCE[0]})" $LINENO "$myGroup"
    printf "%s:%d fullname      :%s\n" "$(basename ${BASH_SOURCE[0]})" $LINENO "$myFullName"

    # add user group
    printf "%s:%d lxc exec $CONTAINER_NAME -- addgroup -q --gid $myGid $myGroup\n" "$(basename ${BASH_SOURCE[0]})" $LINENO
    USERLIST=$(lxc exec $CONTAINER_NAME -- cat /etc/passwd)
    for x in $USERLIST; do
        found=$(echo $x | grep $myUid\:$myGid)
        if [ ! -z "$found" ]; then
            break
        fi
    done

    if [ -z "$found" ]; then
        lxc exec $CONTAINER_NAME -- addgroup -q --gid $myGid $myGroup

        # create matching username in container to match the host machine with matching uid and gid
        printf "%s:%d lxc exec $CONTAINER_NAME -- adduser -q --uid $myUid --ingroup $myGroup --disabled-password --gecos \"$myFullName,,,,\" $myName\n" "$(basename ${BASH_SOURCE[0]})" $LINENO
        lxc exec $CONTAINER_NAME -- adduser -q --uid $myUid --ingroup $myGroup --disabled-password --gecos "$myFullName,,,," $myName
    else
        CUR_ID_USER=($(echo $found | tr ':' ' '))
        lxc exec $CONTAINER_NAME --  bash -c "usermod -l $myName $CUR_ID_USER;sudo usermod -d /home/$myName -m $myName;groupmod --new-name $myName $CUR_ID_USER"
    fi
}


# create a self-signed server certificate
if [ ! -f key.pem ]; then
    openssl req -subj "/CN=$SERVER/O=simpleserver/C=US" \
      -new -newkey rsa:2048 -sha256 -days 365 -nodes -x509 \
      -keyout key.pem -out cert.pem
fi

lxc launch images:ubuntu/18.04 simplestream $CONTAINER_OPTS
TMPDIR=$(mktemp -d)
DIRMOUNT=0

# copy this project into the container
if [ $DIRMOUNT == 1 ]; then
   # configure this user as root in the container
   printf "uid $(id -u) 0\ngid $(id -g) 4" | lxc config set simplestream raw.idmap -
   lxc restart simplestream
   lxc config device add simplestream webdir  disk source=$(pwd) path=/opt/lxd-image-server
   lxc config device add simplestream s proxy connect="tcp:127.0.0.1:8000" listen="tcp:0.0.0.0:8000"
else
   tar cjf $TMPDIR/files.tar.bz2 .
   lxc file push $TMPDIR/files.tar.bz2 simplestream/opt/files.tar.bz2
   rm -rf $TMPDIR
   lxc exec simplestream -- bash -c "cd /opt;mkdir -p lxd-image-server;cd lxd-image-server; tar xf  ../files.tar.bz2 --no-same-owner;chown root:adm -R /opt "
fi
# configure the container with nginx and install the python code
mkdir -m 777 -p images

lxc config device add simplestream images disk source=$(pwd)/images path=/mnt/images
printf "uid $(id -u) 0\ngid $(id -g) 0" | lxc config set simplestream raw.idmap -
lxc exec simplestream -- bash -c /opt/lxd-image-server/scripts/config_container_unit.sh $(uname -n)

cat <<EOF
echo run this command to open port on host:

lxc config device add simplestream http proxy connect="tcp:127.0.0.1:8443" listen="tcp:0.0.0.0:8443"
lxc config device add simplestream https proxy connect="tcp:127.0.0.1:8000" listen="tcp:0.0.0.0:8000"
EOF
