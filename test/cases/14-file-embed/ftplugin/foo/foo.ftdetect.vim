if exists("b:_FOO_FTDETECT_VIM__")
    finish
endif
let b:_FOO_FTDETECT_VIM__ = 1

fun! XPT_fooFiletypeDetect() "{{{
    let line = getline(line("."))
    if strpart(line, 0, 1) == '#'
        return 'comment'
    else
        return 'foo'
    end
endfunction "}}}

if exists( 'b:XPTfiletypeDetect' )
    unlet b:XPTfiletypeDetect
endif
let b:XPTfiletypeDetect = function( 'XPT_fooFiletypeDetect' )

