if exists("g:__XPPUM_VIM__")
    finish
endif
let g:__XPPUM_VIM__ = 1



let s:oldcpo = &cpo
set cpo-=< cpo+=B


exe XPT#let_sid



fun! XPpum#completeFunc( first, base )
    if !exists( 'b:__xppum' )
        if a:first
            return col( "." )
        else
            return []
        endif
    endif

    if a:first
        return b:__xppum.col
    else
        return b:__xppum.list
    endif
endfunction

fun! XPpum#complete( col, list ) "{{{
    let b:__xppum = { 'col' : a:col, 'list' : a:list, 'oldcfu' : &completefunc }
    set completefunc=XPpum#completeFunc

    " 1) trigger user-defined pum
    " 2) restore old 'completefunc' setting
    " 3) force refreshing pum
    return "\<C-x>\<C-u>\<C-r>=<SNR>" . s:sid . "RestoreCommpletefunc()\<CR>\<C-n>\<C-p>"
endfunction "}}}

fun! s:RestoreCommpletefunc() "{{{
    if !exists( 'b:__xppum' )
        return ''
    endif

    let &completefunc = b:__xppum.oldcfu
    unlet b:__xppum
    return ''
endfunction "}}}

let &cpo = s:oldcpo
