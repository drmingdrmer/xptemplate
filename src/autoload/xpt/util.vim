" File Description {{{
" =============================================================================
" Low level utilities which depend on nothing else
"
"                                                  by drdr.xp
"                                                     drdr.xp@gmail.com
" Usage :
"
" =============================================================================
" }}}
if exists("g:__UTIL_VIM__") && g:__UTIL_VIM__ >= XPT#ver
    finish
endif
let g:__UTIL_VIM__ = XPT#ver



let s:oldcpo = &cpo
set cpo-=< cpo+=B



let s:log = xpt#debug#Logger( 'warn' )
" let s:log = xpt#debug#Logger( 'debug' )



let s:unescapeHead          = '\v(\\*)\1\\?\V'

fun! xpt#util#UnescapeChar( str, chars ) "{{{
    " unescape only chars started with several '\' 

    " remove all '\'.
    let chars = substitute( a:chars, '\\', '', 'g' )

    
    let pattern = s:unescapeHead . '\(\[' . escape( chars, '\]-^' ) . ']\)'
    " call s:log.Log( 'to unescape pattern='.pattern )
    let unescaped = substitute( a:str, pattern, '\1\2', 'g' )
    " call s:log.Log( 'unescaped ='.unescaped )
    return unescaped

endfunction "}}}

fun! xpt#util#DeepExtend( to, from ) "{{{
    for key in keys( a:from )

        if type( a:from[ key ] ) == 4
            " dict 
            if has_key( a:to, key )
                call xpt#util#DeepExtend( a:to[ key ], a:from[ key ] )
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

fun! xpt#util#getCurrentOrPreviousSynName() "{{{
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

fun! xpt#util#RemoveDuplicate( list ) "{{{
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




let &cpo = s:oldcpo
