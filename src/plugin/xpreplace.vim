if exists( "g:__XPREPLACE_VIM__" ) && g:__XPREPLACE_VIM__ >= XPT#ver
    finish
endif
let g:__XPREPLACE_VIM__ = XPT#ver


let s:oldcpo = &cpo
set cpo-=< cpo+=B

runtime plugin/debug.vim
runtime plugin/xpmark.vim
runtime plugin/classes/SettingSwitch.vim

" TODO xpreplace line start with <tab> leaving a ';', ada:beg snippet
" TODO use gp to paste and leave cursor after pasted content
"
" test range
    " s
" 000000000000000000000000000000000000000
" 111111111111111111111111111111111111111
" 222222222222222222222222222222222222222
" 333333333333333333333333333333333333333
" 444444444444444444444444444444444444444
" 555555555555555555555555555555555555555
"


let s:log = CreateLogger( 'warn' )
let s:log = CreateLogger( 'debug' )



fun! s:InitBuffer() "{{{
    if exists( 'b:__xpr_init' )
        return
    endif

    let b:__xpr_init = { 'settingSwitch' : g:SettingSwitch.New() }
    " NOTE: bug! if 'virtualedit'=all, and 'selection'=exclusive, visual mode
    " deletion leaves the last char in selection
    call b:__xpr_init.settingSwitch.AddList( 
          \ [ '&l:textwidth', '0' ],
          \ [ '&l:virtualedit', 'onemore' ],
          \ [ '&l:whichwrap'  , 'b,s,h,l,<,>,~,[,]' ],
          \ [ '&l:selection'  , 'exclusive' ],
          \ [ '&l:selectmode' , '' ],
          \)

endfunction "}}}


fun! XPRstartSession() "{{{

    call s:InitBuffer()

    if exists( 'b:_xpr_session' )
        throw "xpreplace session already pushed"
        return
    endif

    let b:_xpr_session = {}

    call b:__xpr_init.settingSwitch.Switch()

    let b:_xpr_session.savedReg = @"
    let @" = 'XPreplaceInited'

endfunction "}}}

fun! XPRendSession() "{{{
    if !exists( 'b:_xpr_session' )
        throw "no setting pushed"
        return
    endif

    let @" = b:_xpr_session.savedReg

    call b:__xpr_init.settingSwitch.Restore()
    
    unlet b:_xpr_session
endfunction "}}}

" no option parameter, marks are always updated
fun! XPreplaceByMarkInternal( startMark, endMark, replacement ) "{{{
    let [ start, end ] = [ XPMpos( a:startMark ), XPMpos( a:endMark ) ]
    if start == [0, 0] || end == [0, 0]
        throw 'XPM:' . ' ' . a:startMark . ' or ' . a:endMark . 'is invalid'
    endif

    call s:log.Debug( 'XPreplaceByMarkInternal parameters:' . string( [ a:startMark, a:endMark, a:replacement ] ) )

    " call s:log.Debug( 'before replacing', join( getline( 1, '$' ), "\n" ) )
    let pos = XPreplaceInternal( start, end, a:replacement, { 'doJobs' : 0 } )
    " call s:log.Debug( 'after replacing', join( getline( 1, '$' ), "\n" ) )

    call XPMupdateWithMarkRangeChanging( a:startMark, a:endMark, start, pos )

    return pos
endfunction "}}}

" let s:ii = 0


fun! s:ConvertSpaceToTab( text ) "{{{
    return XPT#convertSpaceToTab( a:text )
endfunction "}}}



" For internal use only, the caller is reponsible to set settings correctly.
fun! XPreplaceInternal(start, end, replacement, ...) "{{{
    " Cursor stays just after replacement

    let option = { 'doJobs' : 1, 'saveHoriScroll' : 0 }
    if a:0 == 1
        call extend( option, a:1, 'force' )
    endif

    call s:log.Debug( 'XPreplaceInternal parameters:' . string( [ a:start, a:end, a:replacement, option ] ) )

    " if option.saveHoriScroll
    "     " NOTE: long replacement cause screen scroll horizontally if 'nowrap' set
    "     call XPT#saveHoriScroll()
    " endif

    Assert exists( 'b:_xpr_session' )

    " NOTE: bug! if 'virtualedit'=all, and 'selection'=exclusive, visual mode
    " deletion delete only the first space of the last <tab> char
    Assert &l:virtualedit == 'onemore'
    Assert &l:whichwrap == 'b,s,h,l,<,>,~,[,]'
    Assert &l:selection == 'exclusive'
    Assert &l:selectmode == ''

    " Note: In one session, invoking this function multiple times causes the
    " following assertion fail.
    "
    " reserved register 0
    " Assert @" == 'XPreplaceInited'


    let replacement = s:ConvertSpaceToTab( a:replacement )
    " let repLines = XPT#SpaceToTabExceptFirstLine( split( a:replacement, '\n', 1 ) )
    let repLines = XPT#SpaceToTab( split( a:replacement, '\n', 1 ) )



    if option.doJobs
        " TODO not good
        call s:doPreJob(a:start, a:end, replacement)
    endif


    call s:log.Log( 'before replacing, line=' . string( getline( a:start[0] ) ) )

    call s:log.Debug( 'line at start=' . string( getline( a:start[0] ) ) )
    call s:log.Debug( 'line at start + 1=' . string( getline( a:start[0] + 1 ) ) )


    if 0
        let [ curNrLines, finalNrLines ] = [ a:end[ 0 ] - a:start[ 0 ] + 1, len( repLines ) ]

        let [ s, e ] = [ 1, col( [ a:end[ 0 ], '$' ] ) ]

        let repLines[ 0 ] = XPT#TextInLine( a:start[ 0 ], s, a:start[ 1 ] ) . repLines[ 0 ]
        let repLines[ -1 ] .= XPT#TextInLine( a:end[ 0 ], a:end[ 1 ], e )
        call s:log.Debug( 'relLines=' . string( repLines ) )


        let positionAfterReplacement = [ a:end[ 0 ] + ( finalNrLines - curNrLines ), a:end[1] - len(getline(a:end[0])) ]


        if curNrLines > finalNrLines

            call cursor( a:start )
            if curNrLines > finalNrLines + 1
                exe 'silent!' 'normal!' 'zOd' ( finalNrLines - curNrLines - 1 ) 'j'
            else
                silent! normal! zOdd
            endif

        elseif curNrLines < finalNrLines

            call append( a:start[ 0 ], repeat( [ '' ], finalNrLines - curNrLines ) )

        endif


        call setline( a:start[ 0 ], repLines )

        let positionAfterReplacement[1] += len(getline(positionAfterReplacement[0]))
        call cursor( positionAfterReplacement )
        silent! normal! zO

    else

        " remove old
        call cursor( a:start )
        silent! normal! zO
        call cursor( a:start )


        if a:start != a:end

            silent! normal! v
            call cursor( a:end )
            silent! normal! dzO
            " NOTE: in some old version of vim, cursor goes back 1 char after delete. 
            call cursor( a:start )

        endif


        call s:log.Log( 'after deleting content, line=' . string( getline( a:start[0] ) ) )
        call s:log.Debug( "line at start=" . string( getline( a:start[0] ) ) )
        call s:log.Debug( 'line at start + 1=' . string( getline( a:start[0] + 1 ) ) )

        if replacement != ''
            let positionAfterReplacement = s:Replace_standard( a:start, a:end, replacement )
            " let positionAfterReplacement = s:Replace_gp( a:start, a:end, replacement )
        else
            let positionAfterReplacement = [ line("."), col(".") ]
        endif

    endif


    call s:log.Log( 'to do post?=' . option.doJobs )
    if option.doJobs
        call s:doPostJob( a:start, positionAfterReplacement, replacement )
    endif

    return positionAfterReplacement

endfunction "}}}

fun! s:Replace_standard( start, end, replacement ) "{{{

    let replacement = a:replacement


    " add new 
    let bStart = [a:start[0] - line( '$' ), a:start[1] - len(getline(a:start[0]))]


    call cursor( a:start )

    call s:log.Debug( 'current cursor:'.string( [ line( "." ), col( "." ), mode() ] ) . 'expect at:' . string( a:start ) )

    call s:log.Log( 'before append' )

    " TODO use this only when entering insert mode from select mode
    " example snipppet: 
    " `aa^`aa^fff()^
    " fun! s:f.fff()
    "   let v = self.V()
    "   if v == 'aa'
    "     return ''
    "   else
    "     return ', another'
    "   endif
    " endfunction
    let ifPasteAtEnd = ( col( [ a:start[0], '$' ] ) == a:start[1] && a:start[1] > 1 ) 
          " \ && 0



    call s:log.Log( 'ifPasteAtEnd=' . ifPasteAtEnd )
    call s:log.Debug( 'replacement=' . len(replacement) )

    " force non-linewise paste
    let @" = replacement . ';'

    call s:log.Log( 'before append content, line=' . string( getline( a:start[0] ) ) )
    call s:log.Log( 'to append=' . @" )

    call s:log.Debug( "ifPasteAtEnd=" . ifPasteAtEnd )
    call s:log.Debug( string( getline( a:start[0] ) ) )
    call s:log.Debug( col( [ a:start[0], '$' ] ) . " " . a:start[1] )
    call s:log.Debug( string(a:start) )



    " NOTE: When just entering insert mode from select mode, it is impossible to paste at line end.
    " May be bug of vim
    if ifPasteAtEnd
        " " paste before last char 
        " call cursor( a:start[0], a:start[1] - 1 )
        " normal! ""p


        " *) if paste at end of line, paste before last char may not be possible.
        " *) and if previous char is <tab>, pasting after <tab> may break tab
        " to spaces
        call cursor( a:start[0], a:start[1] - 1 )

        " NOTE: unicode char can not be extracted with [ -1:-1 ].
        "       The following statement breaks unicode char:
        "           let char = getline( "." )[ -1:-1 ]
        let char = matchstr( getline( '.' ), '\v.$' )

        call s:log.Debug( 'char=' . string( char ) )


        let @" = char . replacement . ';'
        call s:log.Debug( 'at last , to append=' . @" )
        silent! normal! ""P

    else
        " NOTE: vim70 can not paste from after last char
        if col( "." ) == len( getline( line( "." ) ) ) + 1
            silent! normal! ""p
        else
            silent! normal! ""P
        endif

    endif




    call s:log.Log( 'after append content, line=' . string( getline( a:start[0] ) ) )

    let positionAfterReplacement = [ bStart[0] + line( '$' ), 0 ]
    let positionAfterReplacement[1] = bStart[1] + len(getline(positionAfterReplacement[0]))

    call s:log.Log( 'positionAfterReplacement='.string( positionAfterReplacement ) )

    call cursor( a:start )
    k'

    call cursor(positionAfterReplacement)
    " open fold from mark ' to current line.
    silent! '',.foldopen!

    " remove ';'
    if ifPasteAtEnd
        " last char of line start replacing, and ';'
        call cursor( positionAfterReplacement[0], positionAfterReplacement[1] - 1 - len( char ) )

        " if appending is occur at end of line, delete all following.
        " 'x' command expands tab and delete only 1 char
        silent! normal! DzO

    else
        call cursor( positionAfterReplacement )
        call s:log.Log( 'before remove ";" positionAfterReplacement='.string( positionAfterReplacement ) )

        " NOTE: vim70 can not successfully remove last char from the postion after the last char of line
        if positionAfterReplacement[ 1 ] == len( getline( positionAfterReplacement[ 0 ] ) ) + 1 
              \ && positionAfterReplacement[ 1 ] > 1
            call cursor( positionAfterReplacement[ 0 ], positionAfterReplacement[ 1 ] - 1 )
            silent! normal! xzO
        else
            silent! normal! XzO
        endif
    endif


    let positionAfterReplacement = [ bStart[0] + line( '$' ), 0 ]
    let positionAfterReplacement[1] = bStart[1] + len(getline(positionAfterReplacement[0]))



    return positionAfterReplacement
    
endfunction "}}}

fun! s:Replace_gp( start, end, replacement ) "{{{

    let replacement = a:replacement


    " add new 
    let bStart = [a:start[0] - line( '$' ), a:start[1] - len(getline(a:start[0]))]


    call cursor( a:start )

    call s:log.Debug( 'current cursor:'.string( [ line( "." ), col( "." ), mode() ] ) . 'expect at:' . string( a:start ) )

    call s:log.Log( 'before append' )

    " TODO use this only when entering insert mode from select mode
    " example snipppet: 
    " `aa^`aa^fff()^
    " fun! s:f.fff()
    "   let v = self.V()
    "   if v == 'aa'
    "     return ''
    "   else
    "     return ', another'
    "   endif
    " endfunction
    let ifPasteAtEnd = ( col( [ a:start[0], '$' ] ) == a:start[1] && a:start[1] > 1 ) 

    call s:log.Log( 'ifPasteAtEnd=' . ifPasteAtEnd )
    call s:log.Debug( 'replacement=' . len(replacement) )

    " force non-linewise paste
    let @" = replacement . ';'

    call s:log.Log( 'before append content, line=' . string( getline( a:start[0] ) ) )
    call s:log.Log( 'to append=' . @" )

    call s:log.Debug( "ifPasteAtEnd=" . ifPasteAtEnd )
    call s:log.Debug( string( getline( a:start[0] ) ) )
    call s:log.Debug( col( [ a:start[0], '$' ] ) . " " . a:start[1] )
    call s:log.Debug( string(a:start) )


    " NOTE: command 'gp' leaves cursor after pasted content. but it still has
    " select-mode -> insert-mode problem
    call cursor( a:start )
    silent! normal! ""gPzOXzO


    let positionAfterReplacement = [ line( "." ), col( "." ) ]


    return positionAfterReplacement
    
endfunction "}}}


fun! XPreplace(start, end, replacement, ...) "{{{
    " Cursor stays just after replacement

    let option = { 'doJobs' : 1 }
    if a:0 == 1
        call extend(option, a:1, 'force')
    endif

    call s:log.Debug( 'XPreplace parameters:' . string( [ a:start, a:end, a:replacement ] ) )

    call XPRstartSession()

    let positionAfterReplacement = a:end
    try
        let positionAfterReplacement = XPreplaceInternal( a:start, a:end, a:replacement, option )
    catch /.*/
        call XPT#warn( v:exception )
        call XPT#warn( v:throwpoint )
    finally
        call XPRendSession()
    endtry



    return positionAfterReplacement

endfunction "}}}

let s:_xpreplace = { 'post' : {}, 'pre' : {} }

fun! XPRaddPreJob( functionName ) "{{{
    let s:_xpreplace.pre[ a:functionName ] = function( a:functionName )
endfunction "}}}

fun! XPRaddPostJob( functionName ) "{{{
    let s:_xpreplace.post[ a:functionName ] = function( a:functionName )
endfunction "}}}

fun! XPRremovePreJob( functionName ) "{{{
    let d = s:_xpreplace.pre
    if has_key( d, a:functionName )
        unlet d[ a:functionName ]
    endif
endfunction "}}}

fun! XPRremovePostJob( functionName ) "{{{
    let d = s:_xpreplace.post
    if has_key( d, a:functionName )
        unlet d[ a:functionName ]
    endif
endfunction "}}}

fun! s:doPreJob( start, end, replacement ) "{{{
    let d = { 'f' : '' }
    for d.f in values( s:_xpreplace.pre )
        call s:log.Debug( 'XPreplace pre job:' . string( d.f ) )
        call d.f( a:start, a:end )
    endfor
    
endfunction "}}}

fun! s:doPostJob( start, end, replacement ) "{{{
    let d = { 'f' : '' }
    for d.f in values( s:_xpreplace.post )
        call s:log.Debug( 'XPreplace post job:' . string( d.f ) )
        call d.f( a:start, a:end )
    endfor

    call s:log.Debug( "done post job:" . string( s:_xpreplace.post ) )
    
endfunction "}}}

let &cpo = s:oldcpo

" vim: set sw=4 sts=4 :
