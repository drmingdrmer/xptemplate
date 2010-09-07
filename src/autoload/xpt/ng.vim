" File Description {{{
" =============================================================================
" Core Engine for munipulating any machenism supporting snippets.
"
"                                                  by drdr.xp
"                                                     drdr.xp@gmail.com
" Usage :
"
" =============================================================================
" }}}
if exists( "g:__AL_XPT_NG_VIM__" ) && g:__AL_XPT_NG_VIM__ >= XPT#ver
    finish
endif
let g:__AL_XPT_NG_VIM__ = XPT#ver




let s:oldcpo = &cpo
set cpo-=< cpo+=B






let &cpo = s:oldcpo
