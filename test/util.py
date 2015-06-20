#!/usr/bin/env python
# coding: utf-8

import os
import threading
import time
import subprocess

class ShellError(Exception): pass

def sh( *args ):

    args = [str(x) for x in args]

    subproc = subprocess.Popen( args,
                             close_fds = True,
                             stdout = subprocess.PIPE,
                             stderr = subprocess.PIPE, )


    out, err = subproc.communicate()
    subproc.wait()
    rst = [ subproc.returncode, out, err ]

    if subproc.returncode != 0:
        raise ShellError( args, rst )

    return rst

def fwrite( fn, cont ):
    with open(fn, 'w') as f:
        f.write( cont )

def fread( *args ):
    fn = os.path.join( *args )

    try:
        with open(fn, 'r') as f:
            content = f.read()
    except (OSError, IOError):
        return None

    if content.endswith('\n'):
        content = content[:-1]

    return content

def delay(n=2):
    time.sleep(n)

def _path( *args ):
    return os.path.join( *args )

def _thread(func, args):
    th = threading.Thread(target=func, args=args)
    th.daemon = True
    th.start()
    return th

