if exists("g:__XPT_VIM__")
    " finish
endif
let g:__XPT_VIM__ = 1



let s:oldcpo = &cpo
set cpo-=< cpo+=B

let XPT#ver = 3

let XPT#let_sid = 'map <Plug>xsid <SID>|let s:sid=matchstr(maparg("<Plug>xsid"), "\\d\\+_")|unmap <Plug>xsid'

let XPT#nullDict = {}
let XPT#nullList = []
let XPT#nonEscaped =
      \   '\%('
      \ .     '\%(\[^\\]\|\^\)'
      \ .     '\%(\\\\\)\*'
      \ . '\)'
      \ . '\@<='



fun! XPT#default(k, v) "{{{
    if !exists( a:k )
        exe "let" a:k "=" string( a:v )
    endif
endfunction "}}}

" Some information utils
fun! XPT#warn( msg ) "{{{
    echohl WarningMsg
    echom a:msg
    echohl
endfunction "}}}
fun! XPT#info( msg ) "{{{
    echom a:msg
endfunction "}}}
fun! XPT#error( msg ) "{{{
    echohl ErrorMsg
    echom a:msg
    echohl
endfunction "}}}


fun! XPT#Assert( toBeTrue, msg ) "{{{
    if !a:toBeTrue
        call XPT#warn( a:msg )
        if g:xpt_test_on_error == 'stop'
            throw "XPT_TEST: fail: " . a:msg
        endif
    endi
endfunction "}}}
fun! XPT#AssertEq( a, b, msg ) "{{{
    call xpt#Assert( a:a == a:b, a:msg )
endfunction "}}}
let &cpo = s:oldcpo
