set -x

ROOTDIR=/opt/lxd-image-server

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
   strace curl wget netcat nano git patch net-tools build-essential

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

mkdir -p /var/www

cp -r bottle_test /var/www
cp -r upload_server /var/www
cp -r html /var/www
mkdir -p /var/www/simplestreams
chown -R unit:unit /var/www
chmod -R g+s /var/www/simplestreams
chmod -R g+w /var/www
cp scripts/user_config.sh /home/ubuntu
cd ..

# put ubuntu in unit group
usermod -G adm,unit ubuntu
chgrp unit /home/ubuntu
chmod g+s /home/ubuntu

# create venv
chown ubuntu /home/ubuntu/user_config.sh
su ubuntu -c "~/user_config.sh"

# create service
cp $ROOTDIR/scripts/lxd-image-server.service /etc/systemd/system
su unit -c "/usr/local/bin/lxd-image-server --log-file STDOUT init --nginx_skip"

# now activate the server config
cat simplestream-server/unit_config.json | curl -X PUT -d@- localhost:8080/config


return 0

echo "Installing lxd-image-server"
useradd webserver -G adm,nginx,users,ubuntu -m -r
mkdir /var/www
chown unit:unit /var/www
ln -s $ROOTDIR /var/www/lxd-image-server
chmod -R g+w $ROOTDIR
pip3 install --upgrade pip
pip3 install supervisor
pip3 install $ROOTDIR

cp $ROOTDIR/resources/nginx/includes/lxd-image-server.pkg.conf /etc/nginx/lxd-image-server.conf
mkdir -p /etc/nginx/ssl
cp $ROOTDIR/key.pem /etc/nginx/ssl/nginx.pem
cp $ROOTDIR/cert.pem /etc/nginx/ssl/nginx_cert.pem
chown -R nginx:nginx /etc/nginx/ssl
mkdir /etc/nginx/sites-enabled/
touch /etc/nginx/sites-enabled/simplestreams.conf
mkdir /etc/lxd-image-server
mkdir -p /var/www/simplestreams
chown -R nginx:nginx /var/www/simplestreams
cp $ROOTDIR/index.html /var/www/simplestreams
cp $ROOTDIR/cert.pem /var/www/simplestreams
su nginx -c "/usr/local/bin/lxd-image-server --log-file STDOUT init"
cp $ROOTDIR/scripts/site.conf /etc/nginx/conf.d/default.conf
cp $ROOTDIR/scripts/upload-server.service /etc/systemd/system
cp $ROOTDIR/scripts/lxd-image-server.service /etc/systemd/system
#systemctl enable lxd-image-server.service
#systemctl enable upload-server.service
systemctl enable nginx
#systemctl start lxd-image-server.service
#systemctl start upload-server.service
systemctl start nginx


#clean up
apt-get purge -y $OPTIONS git patch
apt-get purge -y $OPTIONS gnupg2 apt-transport-https ca-certificates
apt-get purge -y $OPTIONS command-not-found command-not-found-data man-db manpages python3-commandnotfound python3-update-manager update-manager-core
apt-get purge -y --auto-remove
apt-get clean -q
rm -f /etc/dpkg/dpkg.cfg.d/02apt-speedup || true
rm -rf /var/lib/apt/lists/*
