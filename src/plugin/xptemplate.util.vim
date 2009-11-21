if exists("g:__XPTEMPLATE_UTIL_VIM__")
  finish
endif
let g:__XPTEMPLATE_UTIL_VIM__ = 1

let s:oldcpo = &cpo
set cpo-=< cpo+=B

runtime plugin/debug.vim


let s:log = CreateLogger( 'warn' )
" let s:log = CreateLogger( 'debug' )





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
    " call s:log.Log( 'to unescape pattern='.pattern )
    let unescaped = substitute( a:str, pattern, '\1\2', 'g' )
    " call s:log.Log( 'unescaped ='.unescaped )
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

fun! s:RemoveDuplicate( list ) "{{{
    let dict = {}
    let newList = []
    for e in a:list
        if !has_key( dict, e )
            call add( newList, e )
        endif
        let dict[ e ] = 1
    endfor

    return newList
endfunction "}}}

exe XPT#let_sid
let g:xptutil = XPT#class( s:sid, {} )

let &cpo = s:oldcpo

