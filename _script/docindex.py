#!/usr/bin/env python
# coding: utf-8

import os

outfn = os.path.join( "doc", "xpt", "options.txt" )
outf = open( outfn, "w" )

def make_option_index( indent="	"*2 ):
    base = os.path.join( "doc", "xpt", "options" )
    fns = os.listdir( base )
    fns.sort()

    for fn in fns:
        optname = fn.split(".")[0]
        out( indent + "|g:xptemplate_" + optname + "|" )

def update_help_tags():
    os.system( 'vim -c "helptags ./doc" -c "qa!"' )

def out( *msgs ):
    for msg in msgs:
        outf.write(msg + "\n" )

if __name__ == "__main__":

    option_header = [
            '								 *xpt-option*',
            '	Options:',
    ]

    for line in option_header:
        out( line )

    make_option_index()

    out( "" )
    out( '" vi''m: tw=78:ts=8:sw=8:sts=8:noet:ft=help:norl:' )

    outf.close()

    update_help_tags()
