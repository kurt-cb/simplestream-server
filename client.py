#!/usr/bin/env python

import rpyc

c = rpyc.connect("localhost", port=11886)
print(c.root.file_notify('abc/123.fil'))
