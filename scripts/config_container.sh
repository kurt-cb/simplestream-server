set -x

ROOTDIR=/opt/lxd-image-server
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
apt-get install $OPTIONS gnupg2 apt-transport-https ca-certificates
echo "NGINX SETUP"
NGINX_GPGKEY=573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62
found=''
for server in \
		ha.pool.sks-keyservers.net \
		hkp://keyserver.ubuntu.com:80 \
		hkp://p80.pool.sks-keyservers.net:80 \
		pgp.mit.edu \
; do
    echo "Fetching GPG key $NGINX_GPGKEY from $server";
    apt-key adv --no-tty --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$NGINX_GPGKEY" && found=yes && break;
done
useradd nginx
test -z "$found" && echo >&2 "error: failed to fetch GPG key $NGINX_GPGKEY" && exit 1
echo "deb https://nginx.org/packages/mainline/ubuntu/ bionic nginx" >> /etc/apt/sources.list.d/nginx.list
apt-get update -qq
apt-get install - $OPTIONS nginx
#sed -i -E -e 's@^\s*user\s+.*;@@' /etc/nginx/nginx.conf

touch /var/run/nginx.pid
chown -R nginx:nginx /var/cache/nginx /var/run/nginx.pid /var/log/nginx
apt-get install $OPTIONS python3 python3-setuptools python3-pip net-tools
echo "Installing 'supervisor'"
apt-get install $OPTIONS python3-bottle gunicorn3

echo "Installing debugging tools"
apt-get install $OPTIONS strace curl wget netcat nano
apt-get install $OPTIONS git patch
echo "Installing lxd-image-server"
useradd webserver -G adm,nginx,users,ubuntu -m -r
mkdir /var/www
chown nginx:nginx /var/www
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
