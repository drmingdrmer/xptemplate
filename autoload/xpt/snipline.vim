" File Description {{{
" =============================================================================
" One line of snippet
"                                                  by drdr.xp
"                                                     drdr.xp@gmail.com
" Usage :
"
" =============================================================================
" }}}
if exists( "g:__AL_XPT_SNIPLINE_VIM__" ) && g:__AL_XPT_SNIPLINE_VIM__ >= XPT#ver
    finish
endif
let g:__AL_XPT_SNIPLINE_VIM__ = XPT#ver




let s:oldcpo = &cpo
set cpo-=< cpo+=B

let s:log = xpt#debug#Logger( 'warn' )
" let s:log = xpt#debug#Logger( 'debug' )


fun! xpt#snipline#New( elts ) "{{{
    if len( a:elts ) == 0 || type( a:elts[ 0 ] ) == type( {} )
        let nIndent = 0
    else
        let nIndent = len( matchstr( a:elts[ 0 ], '\V\^ \*' ) )
    endif
    return { 'nIndent' : nIndent, 'elts' : a:elts }
endfunction "}}}

let &cpo = s:oldcpo
