if exists("g:__XPT_VIM__")
    finish
endif
let g:__XPT_VIM__ = 1



let s:oldcpo = &cpo
set cpo-=< cpo+=B

let XPT#let_sid = 'map <Plug>xsid <SID>|let s:sid=matchstr(maparg("<Plug>xsid"), "\\d\\+_")|unmap <Plug>xsid'



fun! XPT#getCmdOutput( cmd ) "{{{
    let l:a = ""

    redir => l:a
    exe a:cmd
    redir END

    return l:a
endfunction "}}}

fun! XPT#getIndentNr( ln, col ) "{{{
    let line = matchstr( getline(a:ln), '\V\^\s\*' )
    let line = a:col == 1 ? '' : line[ : a:col - 1 ]

    let sts = &l:softtabstop
    let ts  = &l:tabstop

    if 0 == sts 
        let sts = ts
    endif

    let tabspaces = repeat( ' ', ts )

    return len( substitute( line, '	', tabspaces, 'g' ) )


endfunction "}}}



fun! XPT#class( sid, proto ) "{{{
    let clz = deepcopy( a:proto )

    let funcs = split( XPT#getCmdOutput( 'silent function /' . a:sid ), "\n" )
    call map( funcs, 'matchstr( v:val, "' . a:sid . '\\zs.*\\ze(" )' )

    for name in funcs
        if name !~ '\V\^_'
            let clz[ name ] = function( '<SNR>' . a:sid . name )
        endif
    endfor

    " wrapper
    let clz.__init__ = get( clz, 'New', function( 'XPT#classVoidInit' ) )
    let clz.New = function( 'XPT#classNew' )

    return clz
endfunction "}}}

fun! XPT#classNew( ... ) dict "{{{
    let inst = copy( self )
    call call( inst.__init__, a:000, inst )
    let inst.__class__ = self
    return inst
endfunction "}}}

fun! XPT#classVoidInit( ... ) dict "{{{
endfunction "}}}


let &cpo = s:oldcpo
