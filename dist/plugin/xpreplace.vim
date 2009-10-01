if exists("g:__XPREPLACE_VIM__")
  finish
endif
let g:__XPREPLACE_VIM__ = 1
runtime plugin/debug.vim
runtime plugin/mapstack.vim
runtime plugin/xpmark.vim
fun! TestXPR()
    call XPMadd( 'a', [ 12, 6 ], 'l' )
    call XPMadd( 'b', [ 12, 6 ], 'r' )
    call XPRstartSession()
    call XPreplaceByMarkInternal( 'a', 'b', ', element..' )
    call XPRendSession()
    call XPMremove( 'a' )
    call XPMremove( 'b' )
endfunction
let s:log = CreateLogger( 'warn' )
let s:log = CreateLogger( 'debug' )
fun! XPRstartSession() 
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
endfunction 
fun! XPRendSession() 
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
endfunction 
fun! XPreplaceByMarkInternal( startMark, endMark, replacement ) 
    let [ start, end ] = [ XPMpos( a:startMark ), XPMpos( a:endMark ) ]
    if start == [0, 0] || end == [0, 0]
        throw 'XPM:' . ' ' . a:startMark . ' or ' . a:endMark . 'is invalid'
    endif
    let pos = XPreplaceInternal( start, end, a:replacement, { 'doJobs' : 0 } )
    call XPMupdateWithMarkRangeChanging( a:startMark, a:endMark, start, pos )
    return pos
endfunction 
fun! XPreplaceInternal(start, end, replacement, option) 
    let option = { 'doJobs' : 1 }
    call extend( option, a:option, 'force' )
    Assert exists( 'b:_xpr_session' )
    Assert &l:virtualedit == 'all' 
    Assert &l:whichwrap == 'b,s,h,l,<,>,~,[,]' 
    Assert &l:selection == 'exclusive' 
    Assert &l:selectmode == '' 
    if option.doJobs
        call s:doPreJob(a:start, a:end, a:replacement)
    endif
    call cursor( a:start )
    if a:start != a:end
        silent! normal! v
        call cursor( a:end )
        silent! normal! dzO
        call cursor( a:start )
    endif
    if a:replacement == ''
        if option.doJobs
            call s:doPostJob( a:start, a:start, a:replacement )
        endif
        return copy( a:start )
    endif
    let bStart = [a:start[0] - line( '$' ), a:start[1] - len(getline(a:start[0]))]
    call cursor( a:start )
    let ifPasteAtEnd = ( col( [ a:start[0], '$' ] ) == a:start[1] && a:start[1] > 1 ) 
    let isAtStart = ( a:start[1] == 1 )
    let @" = a:replacement . ';'
    if ifPasteAtEnd
        call cursor( a:start[0], a:start[1] - 1 )
        let char = getline( "." )[ -1:-1 ]
        let @" = char . a:replacement . ';'
        silent! normal! ""P
    else
        silent! normal! ""P
    endif
    let positionAfterReplacement = [ bStart[0] + line( '$' ), 0 ]
    let positionAfterReplacement[1] = bStart[1] + len(getline(positionAfterReplacement[0]))
    call cursor( a:start )
    k'
    call cursor(positionAfterReplacement)
    silent! '',.foldopen!
    if ifPasteAtEnd
        call cursor( positionAfterReplacement[0], positionAfterReplacement[1] - 1 - 1 )
        silent! normal! DzO
    else
        call cursor( positionAfterReplacement )
        silent! normal! XzO
    endif
    let positionAfterReplacement = [ bStart[0] + line( '$' ), 0 ]
    let positionAfterReplacement[1] = bStart[1] + len(getline(positionAfterReplacement[0]))
    if option.doJobs
        call s:doPostJob( a:start, positionAfterReplacement, a:replacement )
    endif
    return positionAfterReplacement
endfunction 
fun! XPreplace(start, end, replacement, ...) 
    let option = { 'doJobs' : 1 }
    if a:0 == 1
        call extend(option, a:1, 'force')
    endif
    call XPRstartSession()
    try
        let positionAfterReplacement = XPreplaceInternal( a:start, a:end, a:replacement, option )
    catch /.*/
    finally
        call XPRendSession()
    endtry
    return positionAfterReplacement
endfunction 
let s:_xpreplace = { 'post' : {}, 'pre' : {} }
fun! XPRaddPreJob( functionName ) 
    let s:_xpreplace.pre[ a:functionName ] = function( a:functionName )
endfunction 
fun! XPRaddPostJob( functionName ) 
    let s:_xpreplace.post[ a:functionName ] = function( a:functionName )
endfunction 
fun! XPRremovePreJob( functionName ) 
    let d = s:_xpreplace.pre
    if has_key( d, a:functionName )
        unlet d[ a:functionName ]
    endif
endfunction 
fun! XPRremovePostJob( functionName ) 
    let d = s:_xpreplace.post
    if has_key( d, a:functionName )
        unlet d[ a:functionName ]
    endif
endfunction 
fun! s:doPreJob( start, end, replacement ) 
    let d = { 'f' : '' }
    for d.f in values( s:_xpreplace.pre )
        call d.f( a:start, a:end )
    endfor
endfunction 
fun! s:doPostJob( start, end, replacement ) 
    let d = { 'f' : '' }
    for d.f in values( s:_xpreplace.post )
        call d.f( a:start, a:end )
    endfor
endfunction 
