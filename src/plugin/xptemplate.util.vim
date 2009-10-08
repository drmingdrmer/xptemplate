if exists("g:__XPTEMPLATE_UTIL_VIM__")
  finish
endif
let g:__XPTEMPLATE_UTIL_VIM__ = 1


runtime plugin/debug.vim


let s:log = CreateLogger( 'warn' )
" let s:log = CreateLogger( 'debug' )



com! XPTutilGetSID let s:sid =  matchstr("<SID>", '\zs\d\+_\ze')
XPTutilGetSID
delc XPTutilGetSID



let s:unescapeHead          = '\v(\\*)\1\\?\V'



fun! g:XPclassPrototype( sid, ...) "{{{
    let p = {}
    for name in a:000
        let p[ name ] = function( '<SNR>' . a:sid . name )
    endfor

    return p
endfunction "}}}


fun! s:UnescapeChar( str, chars ) "{{{
    " unescape only chars started with several '\' 

    " remove all '\'.
    let chars = substitute( a:chars, '\\', '', 'g' )

    
    let pattern = s:unescapeHead . '\(\[' . escape( chars, '\]-^' ) . ']\)'
    call s:log.Log( 'to unescape pattern='.pattern )
    let unescaped = substitute( a:str, pattern, '\1\2', 'g' )
    call s:log.Log( 'unescaped ='.unescaped )
    return unescaped
endfunction "}}}

fun! s:DeepExtend( to, from ) "{{{
    for key in keys( a:from )

        if type( a:from[ key ] ) == 4
            " dict 
            if has_key( a:to, key )
                call g:xptutil.DeepExtend( a:to[ key ], a:from[ key ] )
            else
                let a:to[ key ] = a:from[key]
            endif

        elseif type( a:from[key] ) == 3
            " list 

            if has_key( a:to, key )
                call extend( a:to[ key ], a:from[key] )
            else
                let a:to[ key ] = a:from[key]
            endif
        else
            let a:to[ key ] = a:from[key]
        endif

    endfor
endfunction "}}}

let g:xptutil =  g:XPclassPrototype( s:sid, 
            \    'UnescapeChar', 
            \    'DeepExtend', 
            \ )




" vim:tw=78:ts=8:sw=4:sts=4:et:norl:fdm=marker:fmr={{{,}}}
