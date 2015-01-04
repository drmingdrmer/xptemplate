if exists( "g:__FILTERVALUE_VIM__" ) && g:__FILTERVALUE_VIM__ >= XPT#ver
    finish
endif
let g:__FILTERVALUE_VIM__ = XPT#ver



let s:oldcpo = &cpo
set cpo-=< cpo+=B

let g:EmptyFilter = {}

let s:proto = {}

fun! s:New( nIndent, text, ... ) dict "{{{
    let self.nIndent = a:nIndent
    let self.text    = a:text

    " force to use this
    let self.force   = a:0 == 1 && a:1
    let self.marks   = 'innerMarks'

    let self.rc      = 1 " right status. 0 means nothing should be updated.
    let self.toBuild = 0
endfunction "}}}

exe XPT#let_sid
let g:FilterValue = XPT#class( s:sid, s:proto )

let &cpo = s:oldcpo
