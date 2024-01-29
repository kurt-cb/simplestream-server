set -x
set -e

python3 -m pip install virtualenv==20.14.1
python3 -m virtualenv --no-pip --no-setuptools ss-env
source ss-env/activate
curl -sSL https://bootstrap.pypa.io/get-pip.py -o get-pip.py
rm get-pip.py
pip config set global.disable-pip-version-check true

pip install bottle uwsgi click inotify cryptography confight