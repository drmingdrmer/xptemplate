" File Description {{{
" =============================================================================
" SnippetScope
"                                                  by drdr.xp
"                                                     drdr.xp@gmail.com
" Usage :
"
" =============================================================================
" }}}
if exists( "g:__AL_XPT_SNPSC_VIM__" ) && g:__AL_XPT_SNPSC_VIM__ >= XPT#ver
    finish
endif
let g:__AL_XPT_SNPSC_VIM__ = XPT#ver




let s:oldcpo = &cpo
set cpo-=< cpo+=B

let s:log = xpt#debug#Logger( 'warn' )
let s:log = xpt#debug#Logger( 'debug' )









let &cpo = s:oldcpo
