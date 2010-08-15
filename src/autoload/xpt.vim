if exists( "g:__XPT_UTILS_VIM__" )
    finish
endif
let g:__XPT_UTILS_VIM__ = 1





call XPT#default( 'g:xpt_test_on_error', 'stop' )

fun! xpt#Assert( toBeTrue, msg ) "{{{
    if !a:toBeTrue
        call XPT#warn( a:msg )
        if g:xpt_test_on_error == 'stop'
            throw "XPT_TEST: fail: " . a:msg
        endif
    endi
endfunction "}}}


fun! xpt#AssertEq( a, b, msg ) "{{{
    call xpt#Assert( a:a == a:b, a:msg )
endfunction "}}}
