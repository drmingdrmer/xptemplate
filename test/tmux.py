#!/usr/bin/env python
# coding: utf-8

import util

class Tmux(object):

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
        ret = _tmux( "capture-pane", "-p", "-t", self.sess )
        return ret[1]

    def sendkeys( self, *args ):
        _tmux( "send-key", "-l", "-t", self.sess, "".join(args) )


def _tmux( *args ):
    return util.sh( 'tmux', *args )
