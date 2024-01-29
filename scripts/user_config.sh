set -x
set -e

cd ~
python3.7 -m pip install virtualenv==20.14.1
python3.7 -m virtualenv --no-pip --no-setuptools ss-env
source ss-env/bin/activate
curl -sSL https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python get-pip.py "pip==23.3.2" "setuptools==41.0.1" "wheel==0.37.1"
rm get-pip.py
pip config set global.disable-pip-version-check true

pip install bottle uwsgi click inotify cryptography confight encodings