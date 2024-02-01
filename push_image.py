#!/usr/bin/env pyton3

from pylxd import Client
from requests_toolbelt.multipart import decoder

c = Client(endpoint="https://localhost:8001", cert=('/home/ubuntu/.config/lxc/client.crt', '/home/ubuntu/.config/lxc/client.key'), verify='/home/ubuntu/.config/lxc/servercerts/local_http.crt')
images = c.images.all()

img = images[0]

# returns a multipart stream
meta = img.export()
boundry = meta.readline().decode('utf-8').strip()[2:]
meta.seek(0)


d = decoder.MultipartDecoder(meta.read(), f'multipart/form-data; boundary={boundry}')
del meta

files = []
for part in d.parts:
    cd = part.headers[b'Content-Disposition'].decode('utf-8').strip()
    start=cd.find('filename=')
    filename = cd[start+10:]
    with open(filename,'wb') as f:
        f.write(part.content)
    files.append(filename)
del d


