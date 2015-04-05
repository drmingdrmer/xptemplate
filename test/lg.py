#!/usr/bin/env python
# coding: utf-8

import os
import sys
import stat
import fcntl
import logging
import logging.handlers

class XPTLogHandler( logging.handlers.WatchedFileHandler ):

    def _open( self ):
        _stream = logging.handlers.WatchedFileHandler._open( self )
        fd = _stream.fileno()

        r = fcntl.fcntl( fd, fcntl.F_GETFD, 0 )
        r = fcntl.fcntl( fd, fcntl.F_SETFD, r | fcntl.FD_CLOEXEC )
        return _stream

    def emit(self, record):

        try:
            st = os.stat(self.baseFilename)
            changed = (st[stat.ST_DEV] != self.dev) or (st[stat.ST_INO] != self.ino)
        except OSError:
            st = None
            changed = 1

        if changed and self.stream is not None:
            self.stream.flush()
            self.stream.close()
            self.stream = self._open()
            if st is None:
                st = os.stat(self.baseFilename)
            self.dev, self.ino = st[stat.ST_DEV], st[stat.ST_INO]
        logging.FileHandler.emit(self, record)

def make_logger(logname, stdoutlvl='info'):

    filename = logname + ".log"

    logger = logging.getLogger( logname )
    logger.setLevel( logging.DEBUG )

    handler = XPTLogHandler( filename )

    fmt = "[%(asctime)s,%(process)d-%(thread)d,%(filename)s,%(lineno)d,%(levelname)s] %(message)s"

    _formatter = logging.Formatter( fmt )

    handler.setFormatter(_formatter)

    logger.handlers = []
    logger.addHandler( handler )

    stdhandler = logging.StreamHandler( sys.stdout )
    stdhandler.setFormatter( logging.Formatter( "[%(asctime)s,%(filename)s,%(lineno)d] %(message)s" ) )

    if stdoutlvl == 'info':
        stdhandler.setLevel( logging.INFO )
    elif stdoutlvl == 'debug':
        stdhandler.setLevel( logging.DEBUG )


    logger.addHandler( stdhandler )

    return logger
