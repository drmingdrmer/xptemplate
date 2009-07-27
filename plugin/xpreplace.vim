if exists("g:__XPREPLACE_VIM__")
  " finish
endif
let g:__XPREPLACE_VIM__ = 1


runtime plugin/debug.vim
runtime plugin/mapstack.vim
runtime plugin/xpmark.vim

" test range
    " s
" 000000000000000000000000000000000000000
" 111111111111111111111111111111111111111
" 222222222222222222222222222222222222222
" 333333333333333333333333333333333333333
" 444444444444444444444444444444444444444
" 555555555555555555555555555555555555555
" 
" 

fun! TestXPR()
    call XPMadd( 'a', [ 12, 6 ], 'l' )
    call XPMadd( 'b', [ 12, 6 ], 'r' )

    call XPRstartSession()

    call XPreplaceByMarkInternal( 'a', 'b', ', element..' )

    call XPRendSession()
    call XPMremove( 'a' )
    call XPMremove( 'b' )
endfunction



" let s:log = CreateLogger( 'debug' )
let s:log = CreateLogger( 'warn' )

fun! XPRstartSession() "{{{
    if exists( 'b:_xpr_session' )
        return
    endif

    let b:_xpr_session = {}


    call SettingPush( '&l:ve', 'all' )
    call SettingPush( '&l:ww', 'b,s,h,l,<,>,~,[,]' )
    call SettingPush( '&l:selection', 'exclusive' )
    call SettingPush( '&l:selectmode', '' )

    let b:_xpr_session.savedReg = @"
    let @" = 'XPreplaceInited'



endfunction "}}}

fun! XPRendSession() "{{{
    if !exists( 'b:_xpr_session' )
        throw "no setting pushed"
        return
    endif

    let @" = b:_xpr_session.savedReg

    call SettingPop()
    call SettingPop()
    call SettingPop()
    call SettingPop()

    unlet b:_xpr_session
endfunction "}}}

" no option parameter, marks are always updated
fun! XPreplaceByMarkInternal( startMark, endMark, replacement ) "{{{
    let [ start, end ] = [ XPMpos( a:startMark ), XPMpos( a:endMark ) ]
    if start == [0, 0] || end == [0, 0]
        throw a:startMark . ' or ' . a:endMark . 'is invalid'
    endif

    call s:log.Debug( 'XPreplaceByMarkInternal parameters:' . string( [ a:startMark, a:endMark, a:replacement ] ) )

    call s:log.Debug( 'before replacing', join( getline( 1, '$' ), "\n" ) )
    let pos = XPreplaceInternal( start, end, a:replacement, { 'doJobs' : 0 } )
    call s:log.Debug( 'after replacing', join( getline( 1, '$' ), "\n" ) )

    call XPMupdateWithMarkRangeChanging( a:startMark, a:endMark, start, pos )

    return pos
endfunction "}}}

" let s:ii = 0

" For internal use only, the caller is reponsible to set settings correctly.
fun! XPreplaceInternal(start, end, replacement, option) "{{{
    " Cursor stays just after replacement

    let option = { 'doJobs' : 1 }
    call extend( option, a:option, 'force' )

    call s:log.Debug( 'XPreplaceInternal parameters:' . string( [ a:start, a:end, a:replacement, option ] ) )

    " TODO use assertion to ensure settings

    Assert exists( 'b:_xpr_session' )

    Assert &l:virtualedit == 'all' 
    Assert &l:whichwrap == 'b,s,h,l,<,>,~,[,]' 
    Assert &l:selection == 'exclusive' 
    Assert &l:selectmode == '' 

    " reserved register 0
    Assert @" == 'XPreplaceInited'



    if option.doJobs
        " TODO not good
        call s:doPreJob(a:start, a:end, a:replacement)
    endif


    call s:log.Log( 'before replacing, line=' . string( getline( a:start[0] ) ) )

    " remove old
    call cursor( a:start )


    if a:start != a:end
        normal! v
        call cursor( a:end )
        silent! normal! dzO
    endif

    call s:log.Log( 'after deleting content, line=' . string( getline( a:start[0] ) ) )



    " add new 
    let bStart = [a:start[0] - line( '$' ), a:start[1] - len(getline(a:start[0]))]


    call cursor( a:start )

    call s:log.Debug( 'current cursor:'.string( [ line( "." ), col( "." ), mode() ] ) )

    call s:log.Log( 'before append' )
    " force non-linewise paste
    let @" = a:replacement . ';'

    " TODO use this only when entering insert mode from select mode
    let ifPasteAtEnd = ( col( [ a:start[0], '$' ] ) == a:start[1] && a:start[1] > 1 ) 


    " NOTE: When just entering insert mode from select mode, it is impossible to paste at line end.
    " May be bug of vim
    if ifPasteAtEnd
        " paste before last char 
        call cursor( a:start[0], a:start[1] - 1 )
        normal! ""p
    else
        normal! ""P
    endif



    call s:log.Log( 'after append content, line=' . string( getline( a:start[0] ) ) )

    let positionAfterReplacement = [ bStart[0] + line( '$' ), 0 ]
    let positionAfterReplacement[1] = bStart[1] + len(getline(positionAfterReplacement[0]))

    call cursor( a:start )
    k'

    call cursor(positionAfterReplacement)
    " open fold from mark ' to current line.
    silent! '',.foldopen!

    " remove ';'
    if ifPasteAtEnd
        call cursor( positionAfterReplacement[0], positionAfterReplacement[1] - 1 )
        silent! normal! xzo
    else
        silent! normal! XzO
    endif


    let positionAfterReplacement = [ bStart[0] + line( '$' ), 0 ]
    let positionAfterReplacement[1] = bStart[1] + len(getline(positionAfterReplacement[0]))


    if option.doJobs
        call s:doPostJob( a:start, positionAfterReplacement, a:replacement )
    endif

    return positionAfterReplacement

endfunction "}}}

" fun! XPreplace
fun! XPreplace(start, end, replacement, ...) "{{{
    " Cursor stays just after replacement

    let option = { 'doJobs' : 1 }
    if a:0 == 1
        call extend(option, a:0, 'force')
    endif

    call s:log.Debug( 'XPreplace parameters:' . string( [ a:start, a:end, a:replacement ] ) )

    call XPRstartSession()

    let positionAfterReplacement = XPreplaceInternal( a:start, a:end, a:replacement, option )

    call XPRendSession()


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
    for F in values( s:_xpreplace.pre )
        call s:log.Debug( 'XPreplace pre job:' . string( F ) )
        call F( a:start, a:end )
    endfor
    
endfunction "}}}

fun! s:doPostJob( start, end, replacement ) "{{{
    for F in values( s:_xpreplace.post )
        call s:log.Debug( 'XPreplace post job:' . string( F ) )
        call F( a:start, a:end )
    endfor
    
endfunction "}}}


" vim: set sw=4 sts=4 :
