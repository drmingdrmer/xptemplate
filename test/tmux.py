#!/usr/bin/env python
# coding: utf-8

import threading
import util

class Tmux(object):
    lock = threading.RLock()

    def __init__(self, sessname):
        self.sessname = sessname
        # first pane of first window of target session
        self.sess = sessname + ":0.0"

    def try_kill(self):
        try:
            self.kill()
        except util.ShellError:
            pass

    def kill(self):
        _tmux('kill-session', '-t', self.sessname)

    def start(self, shstring):
        _tmux("new",
              "-s", self.sessname,
              "-x", '80',
              "-y", '20',
              '-d',
              shstring)

    def capture(self):
        # tmux sessions share one set of buffers
        with self.lock:
            _tmux( "capture-pane", "-t", self.sess, "-b", '1' )
            ret = _tmux( "show-buffer", "-b", '1' )

        return ret[1]

    # def cleanup():
    #     _tmux( "kill-pane", "-t", self.sess )

    def sendkeys( self, *args ):
        _tmux( "send-key", "-l", "-t", self.sess, "".join(args) )


def _tmux( *args ):
    return util.sh( 'tmux', *args )
