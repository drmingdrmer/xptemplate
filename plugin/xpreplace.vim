if exists("g:__XPREPLACE_VIM__")
  finish
endif
let g:__XPREPLACE_VIM__ = 1


runtime plugin/mapstack.vim

" test range
" 000000000000000000000000000000000000000
" 111111111111111111111111111111111111111
" 222222222222222222222222222222222222222
" 333333333333333333333333333333333333333
" 444444444444444444444444444444444444444
" 555555555555555555555555555555555555555
" 
" 




" let s:log = CreateLogger( 'debug' )
let s:log = CreateLogger( 'warn' )


" For internal use only, the caller is reponsible to set settings correctly.
fun! XPreplaceInternal(start, end, replacement, ...) "{{{
    " Cursor stays just after replacement

    let doJobs = a:0 == 0 || a:1
    call s:log.Debug( 'XPreplaceInternal parameters:' . string( [ a:start, a:end, a:replacement, doJobs ] ) )

    " TODO use assertion to ensure settings

    Assert &l:virtualedit == 'all' 
    Assert &l:whichwrap == 'b,s,h,l,<,>,~,[,]' 
    Assert &l:selection == 'exclusive' 
    Assert &l:selectmode == '' 

    " reserved register 0
    Assert @" == 'XPreplaceInited'



    if doJobs
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

    " force non-linewise paste
    let @" = a:replacement . ';'
    normal! ""P

    call s:log.Log( 'after append content, line=' . string( getline( a:start[0] ) ) )

    let positionAfterReplacement = [ bStart[0] + line( '$' ), 0 ]
    let positionAfterReplacement[1] = bStart[1] + len(getline(positionAfterReplacement[0]))

    call cursor( a:start )
    k'

    call cursor(positionAfterReplacement)
    " open fold from mark ' to current line.
    silent! '',.foldopen!

    " remove ';'
    silent! normal! XzO


    let positionAfterReplacement = [ bStart[0] + line( '$' ), 0 ]
    let positionAfterReplacement[1] = bStart[1] + len(getline(positionAfterReplacement[0]))


    if doJobs
        call s:doPostJob( a:start, positionAfterReplacement, a:replacement )
    endif

    return positionAfterReplacement

endfunction "}}}

fun! XPreplace(start, end, replacement, ...) "{{{
    " Cursor stays just after replacement

    let doJobs = a:0 == 0 || a:1
    call s:log.Debug( 'XPreplace parameters:' . string( [ a:start, a:end, a:replacement ] ) )

    " TODO use assertion to ensure settings

    call SettingPush( '&l:ve', 'all' )
    call SettingPush( '&l:ww', 'b,s,h,l,<,>,~,[,]' )
    call SettingPush( '&l:selection', 'exclusive' )
    call SettingPush( '&l:selectmode', '' )

    let savedReg = @"
    let @" = 'XPreplaceInited'


    let positionAfterReplacement = XPreplaceInternal( a:start, a:end, a:replacement, doJobs )


    let @" = savedReg

    call SettingPop()
    call SettingPop()
    call SettingPop()
    call SettingPop()


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
