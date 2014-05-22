if exists( "g:__XPTEMPLATE_UTIL_VIM__" ) && g:__XPTEMPLATE_UTIL_VIM__ >= XPT#ver
    finish
endif
let g:__XPTEMPLATE_UTIL_VIM__ = XPT#ver


let s:oldcpo = &cpo
set cpo-=< cpo+=B

runtime plugin/debug.vim


let s:log = CreateLogger( 'warn' )
" let s:log = CreateLogger( 'debug' )

fun! s:XPTgetCurrentOrPreviousSynName() "{{{
    let pos = [ line( "." ), col( "." ) ]
    let synName = synIDattr(synID(pos[0], pos[1], 1), "name")

    if synName == ''
        let prevPos = searchpos( '\S', 'bWn' )
        if prevPos == [0, 0]
            return synName
        endif

        let synName = synIDattr(synID(prevPos[0], prevPos[1], 1), "name")
        if synName == ''
            " an empty syntax char
            return &filetype
        endif
    endif

    return synName

endfunction "}}}

exe XPT#let_sid
let g:xptutil = XPT#class( s:sid, {} )

let &cpo = s:oldcpo

