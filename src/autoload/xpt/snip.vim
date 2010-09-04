if exists( "g:__AL_XPT_SNIP_VIM__" ) && g:__AL_XPT_SNIP_VIM__ >= XPT#ver
    finish
endif
let g:__AL_XPT_SNIP_VIM__ = XPT#ver




let s:oldcpo = &cpo
set cpo-=< cpo+=B

let s:log = xpt#debug#Logger( 'warn' )
let s:log = xpt#debug#Logger( 'debug' )


fun! xpt#snip#DefExt( name, setting, lines ) "{{{

    call xpt#st#Extend( a:setting )

    call XPTdefineSnippet( a:name, a:setting, a:lines )

endfunction "}}}

fun! xpt#snip#New( name, ftScope, snipText, prio, setting, patterns ) "{{{
    return {
          \ 'name'        : a:name,
          \ 'parsed'      : 0,
          \ 'ftScope'     : a:ftScope,
          \ 'rawSnipText' : a:snipText,
          \ 'snipText'    : a:snipText,
          \ 'priority'    : a:prio,
          \ 'setting'     : a:setting,
          \ 'ptn'         : a:patterns,
          \ }
endfunction "}}}












let &cpo = s:oldcpo
