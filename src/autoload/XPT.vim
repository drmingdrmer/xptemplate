if exists("g:__XPT_VIM__")
    " finish
endif
let g:__XPT_VIM__ = 1



let s:oldcpo = &cpo
set cpo-=< cpo+=B

let XPT#ver = 3

let XPT#let_sid = 'map <Plug>xsid <SID>|let s:sid=matchstr(maparg("<Plug>xsid"), "\\d\\+_")|unmap <Plug>xsid'

let XPT#nullDict = {}
let XPT#nullList = []
let XPT#nonEscaped =
      \   '\%('
      \ .     '\%(\[^\\]\|\^\)'
      \ .     '\%(\\\\\)\*'
      \ . '\)'
      \ . '\@<='



fun! XPT#default(k, v) "{{{
    if !exists( a:k )
        exe "let" a:k "=" string( a:v )
    endif
endfunction "}}}

" Some information utils
fun! XPT#warn( msg ) "{{{
    echohl WarningMsg
    echom a:msg
    echohl
endfunction "}}}
fun! XPT#info( msg ) "{{{
    echom a:msg
endfunction "}}}
fun! XPT#error( msg ) "{{{
    echohl ErrorMsg
    echom a:msg
    echohl
endfunction "}}}


fun! XPT#Assert( toBeTrue, msg ) "{{{
    if !a:toBeTrue
        call XPT#warn( a:msg )
        if g:xpt_test_on_error == 'stop'
            throw "XPT_TEST: fail: " . a:msg
        endif
    endi
endfunction "}}}

fun! XPT#AssertEq( a, b, msg ) "{{{
    call xpt#Assert( a:a == a:b, a:msg )
endfunction "}}}

fun! XPT#convertSpaceToTab( text ) "{{{
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

fun! XPT#SpaceToTab( lines ) "{{{
    " NOTE: line-break followed by space

    if ! &expandtab && match( a:lines, '\v^ ' ) > -1

        let cmd = 'join( split( v:val, ''\v^%('' . repeat( '' '',  &tabstop ) . '')'', 1 ), ''	'' )'
        call map( a:lines, cmd )

    endif

    return a:lines

endfunction "}}}
fun! XPT#SpaceToTabExceptFirstLine( lines ) "{{{
    " NOTE: line-break followed by space

    if ! &expandtab && len( a:lines ) > 1 && match( a:lines, '\v^ ', 1 ) > -1

        let line0 = a:lines[ 0 ]

        let cmd = 'join( split( v:val, ''\v^%('' . repeat( '' '',  &tabstop ) . '')'', 1 ), ''	'' )'
        call map( a:lines, cmd )

        let a:lines[ 0 ] = line0

    endif

    return a:lines

endfunction "}}}

fun! XPT#TextBetween( posList ) "{{{
    return join(XPT#LinesBetween( a:posList ), "\n")
endfunction " }}}

fun! XPT#TextInLine( ln, s, e ) "{{{

    if a:s >= a:e
        return ""
    endif

    return getline(a:ln)[ a:s - 1 : a:e - 2 ]

endfunction "}}}

fun! XPT#LinesBetween( posList ) "{{{

    let [ s, e ] = a:posList

    if s[0] > e[0]
        return ""
    endif

    if s[0] == e[0]
        if s[1] == e[1]
            return ""
        else
            call s:log.Log( "content between " . string( [s, e] ) . ' is :' . getline(s[0])[ s[1] - 1 : e[1] - 2] )
            return getline(s[0])[ s[1] - 1 : e[1] - 2 ]
        endif
    endif


    let r = [ getline(s[0])[s[1] - 1:] ] + getline(s[0]+1, e[0]-1)

    if e[1] > 1
        let r += [ getline(e[0])[:e[1] - 2] ]
    else
        let r += ['']
    endif

    call s:log.Log( "content between " . string( [s, e] ) . ' is :'.join( r, "\n" ) )

    return r

endfunction "}}}

let &cpo = s:oldcpo
