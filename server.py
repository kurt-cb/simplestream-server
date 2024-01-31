import logging

logger = logging.getLogger('lxd-image-server')

import rpyc

class UpdateService(rpyc.Service):

    def __init__(self, handler):
        self._handler = handler

    def on_connect(self, conn):
        # code that runs when a connection is created
        # (to init the service, if needed)
        pass

    def on_disconnect(self, conn):
        # code that runs after the connection has already closed
        # (to finalize the service, if needed)
        pass

    def exposed_file_notify(self, path): # this is an exposed method
        self._handler(path=path)
        return "ok"

    def run(self):
        from rpyc.utils.server import ThreadedServer
        t = ThreadedServer(self, port=11886)
        t.start()


def main():
    def msg_handler(*args, **keywords):
        try:
            msg = str(keywords['path'])

            print("DBus message: %s" % msg)

        except BaseException as e:
            logger.error('Execption %s', e)
            pass
    UpdateService(msg_handler).run()

logging.basicConfig(level=logging.DEBUG)
main()
