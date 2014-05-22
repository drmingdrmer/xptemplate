#!/usr/bin/env python
# coding: utf-8

import os
import sys
import fcntl
import subprocess
import logging
import logging.handlers
import stat
import time
import fnmatch

class TestError( Exception ): pass

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
        except OSError, e:
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

def make_logger():
    logname = 'xpt-test'
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
    stdhandler.setLevel( logging.INFO )

    logger.addHandler( stdhandler )

    return logger

logger = make_logger()

key = {
        "cr":  "\r",
        "tab": "	",
        "esc": "",
        "c_v": "",
        "c_l": "",
        "c_c": "",
        "c_o": "",
}


def main( pattern ):
    logger.info("start...")
    tmux_setup()
    try:
        run_all( pattern )
    except TestError as e:
        # with TestError, stop and see what happened
        ex, ac = e[1], e[2]

        for i in range( len(ex) ):
            if i >= len(ac) or ex[i] != ac[i]:
                logger.info( ( i+1, ex[i], ac[i] ) )

        # for l in ['>>Expected:'] + e[1] + ['>>Actual:'] + e[2]:
        #     logger.info( repr(l) )
        raise
    except Exception as e:
        # with other error, close it
        tmux_cleanup()
        raise
    tmux_cleanup()

def run_all( pattern ):

    base = os.path.join( ".", "test", "cases" )

    cases = os.listdir( base )
    cases.sort()

    for c in cases:
        if not os.path.isdir( os.path.join( "test", "cases", c ) ):
            continue

        if fnmatch.fnmatch( c, pattern ):
            run_case( c )

    logger.info("all test passed")

def run_case( cname ):

    logger.info( "running " + cname + "..." )

    base = os.path.join( ".", "test", "cases", cname )

    try:
        os.unlink( os.path.join( base, 'rst' ) )
    except OSError as e:
        pass

    vimrcfn = os.path.join( base, "vimrc" )
    if not os.path.exists( vimrcfn ):
        vimrcfn = os.path.join( ".", "test", "core_vimrc" )

    vim_start( vimrcfn )
    vim_add_rtp( base )
    vim_so_fn( os.path.join( base, "setting.vim" ) )
    vim_load_content( os.path.join( base, "context" ) )
    tmux_keys( "s" )
    vim_key_sequence( os.path.join( base, "keys" ) )
    vim_save_to( os.path.join( base, "rst" ) )

    check_result( base )

    vim_close()

def vim_start( vimrcfn ):
    tmux_keys( "vim -u " + vimrcfn + key["cr"] )
    logger.debug( "vim started with vimrc: " + repr(vimrcfn) )

def vim_close():
    tmux_keys( key["esc"], ":qa!", key["cr"] )
    logger.debug( "vim closed" )

def vim_load_content( fn ):

    if not os.path.exists( fn ):
        return

    content = fread( fn )

    tmux_keys( ":append", key['cr'] )
    tmux_keys( content, key['cr'] )
    tmux_keys( key['c_c'] )
    tmux_keys( '/', key['c_v'], key['c_l'], key['cr'] )

    logger.debug( "vim content loaded: " + repr( content ) )

def vim_so_fn( fn ):
    if not os.path.exists( fn ):
        return

    tmux_keys( ":so " + fn, key['cr'] )
    logger.debug( "vim setting loaed: " + repr(fn) )

def vim_add_rtp( path ):
    if not os.path.exists( path ):
        return

    tmux_keys( ":set rtp+=", path, key['cr'] )
    logger.debug( "additional rtp: " + repr( path ) )

def vim_key_sequence( fn ):

    if not os.path.exists(fn):
        return

    content = fread( fn )

    logger.debug( "loaded key sequence: " + repr(content) )
    lines = content.split("\n")
    for line in lines:
        if line == '':
            continue
        tmux_keys( line )

    logger.debug( "end of key sequence" )

def vim_save_to( fn ):

    tmux_keys( key['esc']*2, ":w " + fn, key['cr'] )

    while not os.path.exists( os.path.join( fn ) ):
        time.sleep(0.01)

    logger.debug( "rst saved to " + repr(fn))

def check_result( base ):

    expected = fread( base, "expected" )
    rst = fread( base, "rst" )
    if expected != rst:
        raise TestError( base, expected.split("\n"), rst.split("\n") )

    os.unlink( os.path.join( base, "rst" ) )

def tmux_setup():
    _tmux( "split-window", "-h" )
    _tmux( "select-pane", "-t", 0 )

def tmux_cleanup():
    _tmux( "kill-pane", "-t", 1 )

def tmux_keys( *args ):
    _tmux( "send-key", "-l", "-t", 1, "".join(args) )
    if args[-1][-1] == key['cr']:
        logger.debug( "wait for cr to complete" )
        time.sleep(0.1)
    time.sleep(0.2)

def _tmux( *args ):
    sh( 'tmux', *args )

def fread( *args ):
    fn = os.path.join( *args )
    with open(fn, 'r') as f:
        content = f.read()

    if content.endswith('\n'):
        content = content[:-1]

    return content

def sh( *args, **argkv ):

    args = [str(x) for x in args]
    logger.debug( "Command: " + repr( args ) )

    subproc = subprocess.Popen( args,
                             close_fds = True,
                             stdout = subprocess.PIPE,
                             stderr = subprocess.PIPE, )


    out, err = subproc.communicate()
    subproc.wait()
    rst = [ subproc.returncode, out, err ]

    if subproc.returncode != 0:
        raise Exception( rst )

    return rst

if __name__ == "__main__":
    args = sys.argv
    if len(args) > 1:
        main(args[1])
    else:
        main("*")
