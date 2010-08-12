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


let s:charsPatternTable = {}
fun! s:GetUnescapeCharPattern( chars ) "{{{
    " remove all '\'.
    let chars = substitute( a:chars, '\\', '', 'g' )

    " let pattern = s:unescapeHead . '\(\[' . escape( chars, '\]-^' ) . ']\)'
    let pattern = s:unescapeHead . '\ze\[' . escape( chars, '\]-^' ) . ']'
    let s:charsPatternTable[ a:chars ] = pattern

    return pattern
endfunction "}}}

fun! xpt#util#UnescapeChar( str, chars ) "{{{
    " unescape only chars started with several '\' 

    if has_key( s:charsPatternTable, a:chars )
        let pattern = s:charsPatternTable[ a:chars ]
    else
        let pattern = s:GetUnescapeCharPattern( a:chars )
    endif

    " return substitute( a:str, pattern, '\1\2', 'g' )
    return substitute( a:str, pattern, '\1', 'g' )

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

fun! xpt#util#NearestSynName() "{{{
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


fun! xpt#util#ExpandTab( text ) "{{{
    if stridx( a:text, "	" ) < 0
        return a:text
    endif
    
    let str = "\n" . a:text

    let tabspaces = repeat( ' ', &tabstop )

    let last = ''
    while str != last
        let last = str
        let str = substitute( str, '\n	*\zs	', tabspaces, 'g' )
    endwhile

    return str[ 1 : ]

endfunction "}}}

fun! xpt#util#convertSpaceToTab( text ) "{{{
    " NOTE: line-break followed by space

    if ( "\n" . a:text ) !~ '\V\n ' || &expandtab
        return a:text
    else

        let tabspaces = repeat( ' ',  &tabstop )
        let lines = split( a:text, '\V\n', 1 )
        let newlines = []
        for line in lines
            let newline = join( split( line, '\V\^\%(' . tabspaces . '\)', 1 ), '	' )
            let newlines += [ newline ]
        endfor

        return join( newlines, "\n" )

    endif
endfunction "}}}

fun! xpt#util#Fallback( fbs ) "{{{
    let fbs = a:fbs
    if len( fbs ) > 0
        let [ key, flag ] = fbs[ 0 ]
        call remove( fbs, 0 )
        if flag == 'feed'
            call feedkeys( key, 'mt' )
            return ''
        else
            " flag == 'expr'
            return key
        endif
    else
        return ''
    endif
endfunction "}}}

fun! xpt#util#getIndentNr( ln, col ) "{{{

    let line = matchstr( getline(a:ln), '\V\^\s\*' )
    let line = ( a:col == 1 ) ? '' : line[ 0 : a:col - 1 - 1 ]

    let tabspaces = repeat( ' ', &l:tabstop )

    return len( substitute( line, '	', tabspaces, 'g' ) )

endfunction "}}}

fun! xpt#util#getPreferedIndentNr( ln ) "{{{
    if &indentexpr == ''
        return -1
    else
        let indentexpr = substitute( &indentexpr, '\Vv:lnum', a:ln, '' )
        try
            return  eval( indentexpr )
        catch /.*/
            return -1
        endtry
    endif
    
endfunction "}}}

fun! xpt#util#getCmdOutput( cmd ) "{{{
    let l:a = ""

    redir => l:a
    exe a:cmd
    redir END

    return l:a
endfunction "}}}





" OO support 
fun! xpt#util#class( sid, proto ) "{{{
    let clz = deepcopy( a:proto )

    let funcs = split( xpt#util#getCmdOutput( 'silent function /' . a:sid ), "\n" )
    call map( funcs, 'matchstr( v:val, "' . a:sid . '\\zs.*\\ze(" )' )

    for name in funcs
        if name !~ '\V\^_'
            let clz[ name ] = function( '<SNR>' . a:sid . name )
        endif
    endfor

    " wrapper
    let clz.__init__ = get( clz, 'New', function( 'xpt#util#classVoidInit' ) )
    let clz.New = function( 'xpt#util#classNew' )

    return clz
endfunction "}}}

fun! xpt#util#classNew( ... ) dict "{{{
    let inst = copy( self )
    call call( inst.__init__, a:000, inst )
    let inst.__class__ = self
    return inst
endfunction "}}}

fun! xpt#util#classVoidInit( ... ) dict "{{{
endfunction "}}}



let &cpo = s:oldcpo
