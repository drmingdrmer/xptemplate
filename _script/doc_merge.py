#!/usr/bin/env python
# coding: utf-8

import os

def out( f, *msgs ):
    for msg in msgs:
        f.write(msg + "\n" )

def fnlist( section ):
    base = os.path.join( "doc", "xpt", section )
    fns = os.listdir( base )
    fns.sort()
    anony = [x for x in fns
             if x.startswith('_')]
    chapters = [x for x in fns
                if not x.startswith('_')]
    return anony + chapters

def fread( fn ):
    with open( fn, 'r' ) as f:
        cont = f.read()
    lines = cont.split( "\n" )
    lines = [ x for x in lines
              if not x.startswith( '" vi''m:' ) ]
    return '\n'.join( lines )

def merge_doc( section, prefix ):

    width = 78
    title ='*xpt-' + section + '*'
    title = title.rjust(width)
    header = [
            title,
            '=' * width,
            '',
            'Table of Content ~',
            '',
    ]

    fns = fnlist( section )

    fn = os.path.join( "doc", "xpt", section + ".txt" )
    with open( fn, "w" ) as f:

        out( f, *header )

        indent = "	"
        for fn in fns:
            optname = fn.split(".")[0]
            if not optname.startswith('_'):
                out( f, indent + "|" + prefix + optname + "|" )

        out( f, "" )

        for fn in fns:
            cont = fread( os.path.join( "doc", "xpt", section, fn ) )
            out( f, cont )

        out( f, "" )
        out( f, '" vi''m: tw='+str(width)+':ts=8:sw=8:sts=8:noet:ft=help:norl:' )

if __name__ == "__main__":

    merge_doc( 'option', 'g:xptemplate_' )
    merge_doc( 'snippet-function', '' )
