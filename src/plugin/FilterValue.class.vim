if exists( "g:__FILTERVALUE_CLASS_VIM__" )
    finish
endif
let g:__FILTERVALUE_CLASS_VIM__ = 1



let s:oldcpo = &cpo
set cpo-=< cpo+=B

let s:proto = {
      \ }

fun! s:New( nIndent, text ) dict "{{{
    let self.nIndent = a:nIndent
    let self.text    = a:text
endfunction "}}}


exe XPT#let_sid
let g:FilterValue = XPT#class( s:sid, s:proto )

let &cpo = s:oldcpo
