if exists( "g:__XPREPLACE_VIM__" ) && g:__XPREPLACE_VIM__ >= XPT#ver
    finish
endif
let g:__XPREPLACE_VIM__ = XPT#ver
let s:oldcpo = &cpo
set cpo-=< cpo+=B
runtime plugin/debug.vim
runtime plugin/xpmark.vim
runtime plugin/classes/SettingSwitch.vim
let s:log = CreateLogger( 'warn' )
let s:log = CreateLogger( 'debug' )
fun! s:InitBuffer() 
    if exists( 'b:__xpr_init' )
        return
    endif
    let b:__xpr_init = { 'settingSwitch' : g:SettingSwitch.New() }
    call b:__xpr_init.settingSwitch.AddList( 
          \ [ '&l:virtualedit', 'onemore' ],
          \ [ '&l:whichwrap'  , 'b,s,h,l,<,>,~,[,]' ],
          \ [ '&l:selection'  , 'exclusive' ],
          \ [ '&l:selectmode' , '' ],
          \)
endfunction 
fun! XPRstartSession() 
    call s:InitBuffer()
    if exists( 'b:_xpr_session' )
        throw "xpreplace session already pushed"
        return
    endif
    let b:_xpr_session = {}
    call b:__xpr_init.settingSwitch.Switch()
    let b:_xpr_session.savedReg = @"
    let @" = 'XPreplaceInited'
endfunction 
fun! XPRendSession() 
    if !exists( 'b:_xpr_session' )
        throw "no setting pushed"
        return
    endif
    let @" = b:_xpr_session.savedReg
    call b:__xpr_init.settingSwitch.Restore()
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
fun! s:ConvertSpaceToTab( text ) 
    return XPT#convertSpaceToTab( a:text )
endfunction 
fun! XPreplaceInternal(start, end, replacement, ...) 
    let option = { 'doJobs' : 1, 'saveHoriScroll' : 0 }
    if a:0 == 1
        call extend( option, a:1, 'force' )
    endif
    let replacement = s:ConvertSpaceToTab( a:replacement )
    if option.doJobs
        call s:doPreJob(a:start, a:end, replacement)
    endif
    call cursor( a:start )
    if a:start != a:end
        silent! normal! v
        call cursor( a:end )
        silent! normal! dzO
        call cursor( a:start )
    endif
    if replacement != ''
        let positionAfterReplacement = s:Replace_standard( a:start, a:end, replacement )
    else
        let positionAfterReplacement = [ line("."), col(".") ]
    endif
    if option.doJobs
        call s:doPostJob( a:start, positionAfterReplacement, replacement )
    endif
    return positionAfterReplacement
endfunction 
fun! s:Replace_standard( start, end, replacement ) 
    let replacement = a:replacement
    let bStart = [a:start[0] - line( '$' ), a:start[1] - len(getline(a:start[0]))]
    call cursor( a:start )
    let ifPasteAtEnd = ( col( [ a:start[0], '$' ] ) == a:start[1] && a:start[1] > 1 ) 
    let @" = replacement . ';'
    if ifPasteAtEnd
        call cursor( a:start[0], a:start[1] - 1 )
        let char = getline( "." )[ -1:-1 ]
        let @" = char . replacement . ';'
        silent! normal! ""P
    else
        if col( "." ) == len( getline( line( "." ) ) ) + 1
            silent! normal! ""p
        else
            silent! normal! ""P
        endif
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
endfunction 
fun! s:Replace_gp( start, end, replacement ) 
    let replacement = a:replacement
    let bStart = [a:start[0] - line( '$' ), a:start[1] - len(getline(a:start[0]))]
    call cursor( a:start )
    let ifPasteAtEnd = ( col( [ a:start[0], '$' ] ) == a:start[1] && a:start[1] > 1 ) 
    let @" = replacement . ';'
    call cursor( a:start )
    silent! normal! ""gPzOXzO
    let positionAfterReplacement = [ line( "." ), col( "." ) ]
    return positionAfterReplacement
endfunction 
fun! XPreplace(start, end, replacement, ...) 
    let option = { 'doJobs' : 1 }
    if a:0 == 1
        call extend(option, a:1, 'force')
    endif
    call XPRstartSession()
    let positionAfterReplacement = a:end
    try
        let positionAfterReplacement = XPreplaceInternal( a:start, a:end, a:replacement, option )
    catch /.*/
        call XPT#war( v:exception )
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
let &cpo = s:oldcpo
