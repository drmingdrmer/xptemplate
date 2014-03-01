if exists( "g:__PARSER_VIM__" )
    finish
endif
let g:__PARSER_VIM__ = 1


fun! xpt#test#parser#TestCompact() "{{{
    let inp = [
          \ 'XPTemplate prio=personal',
          \ '',
          \ '',
          \ 'XPT a',
          \ '123',
          \ '',
          \ '..XPT',
          \ '',
          \ 'XPT b " what',
          \ '123',
          \ '',
          \ 'XPT c',
          \ '123',
          \ 'XPT d',
          \ 'XPT e',
          \ '',
          \]
    let expected = [
          \ 'XPTemplate prio=personal',
          \ 'XPT a',
          \ '123',
          \ '',
          \ 'XPT b " what',
          \ '123',
          \ 'XPT c',
          \ '123',
          \ 'XPT d',
          \ 'XPT e',
          \]


    call XPT#AssertEq( expected, xpt#parser#Compact( inp ), 'compact snippet' )

    let o = xpt#parser#Compact( inp )
    for ln in o
        echom '-' . ln
    endfor

endfunction "}}}


