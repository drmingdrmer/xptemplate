exec xpt#once#init

let s:oldcpo = &cpo
set cpo-=< cpo+=B

let s:log = xpt#debug#Logger( 'warn' )
" let s:log = xpt#debug#Logger( 'debug' )

let s:phase = {
      \ 'uninit'    : 'uninit'   ,
      \ 'popup'     : 'popup'    ,
      \ 'inited'    : 'inited'   ,
      \ 'rendering' : 'rendering',
      \ 'rendered'  : 'rendered' ,
      \ 'iteminit'  : 'iteminit' ,
      \ 'fillin'    : 'fillin'   ,
      \ 'post'      : 'post'     ,
      \ 'finished'  : 'finished' ,
      \ }

let xpt#rctx#phase = s:phase
let p = s:phase
let s:phaseGraph = {
      \ p.uninit    : [ p.popup, p.inited ],
      \ p.popup     : [ p.inited ],
      \ p.inited    : [ p.rendering ],
      \ p.rendering : [ p.rendered ],
      \ p.rendered  : [ p.iteminit ],
      \ p.iteminit  : [ p.iteminit, p.fillin, p.post ],
      \ p.fillin    : [ p.post, p.finished ],
      \ p.post      : [ p.finished, p.iteminit ],
      \ p.finished  : [ p.uninit ],
      \ }
unlet p


fun! xpt#rctx#New( x ) "{{{

    let pre = "X" . len( a:x.stack ) . '_'

    let inst = {
          \   'ftScope'            : {},
          \   'level'              : len( a:x.stack ),
          \   'snipObject'         : {},
          \   'snipSetting'        : {},
          \   'phase'              : s:phase.uninit,
          \   'nextStep'           : -1,
          \   'action'             : '',
          \   'userPostAction'     : '',
          \   'wrap'               : {},
          \   'userWrapped'        : {},
          \   'markNamePre'        : pre,
          \   'item'               : {},
          \   'leadingPlaceHolder' : {},
          \   'activeLeaderMarks'  : 'innerMarks',
          \   'history'            : [],
          \   'namedStep'          : {},
          \   'processing'         : 0,
          \   'marks'              : {
          \      'tmpl'            : {
          \         'start' : pre . '`tmpl`s',
          \         'end'   : pre . '`tmpl`e' } },
          \   'itemDict'           : {},
          \   'itemList'           : [],
          \   'groupList'          : [],
          \   'lastContent'        : '',
          \   'tmpmappings'        : {},
          \   'oriIndentkeys'      : {},
          \   'leadingCharToReindent' : {},
          \ }

    " for emulation of 'indentkeys'
    "
    " vim issue:
    "   :set indentkeys=0\,,0}
    "   :echo &indentkeys
    "
    " results in:
    "   "0,,0}"
    "
    " The backslash escaped chars can not be read correctly.

    let lst = split( &indentkeys, ',' )
    let indentkeysList = []
    for k in lst

        " TRICK: Treat first of two continous comma as escaped.
        if k == ""
            let indentkeysList[ -1 ] .= ','
        else
            if k[ 0 ] == '0'
                call add( indentkeysList, k )
            endif
        endif
    endfor

    for k in indentkeysList
        " "0=" is not included
        if k[ 1 ] == '=' && len( k ) > 2
            let inst.oriIndentkeys[ k[ 2: ] ] = 1
        else
            let inst.leadingCharToReindent[ k[ 1: ] ] = 1
        endif
    endfor

    return inst

endfunction "}}}

fun! xpt#rctx#SwitchPhase( inst, nextPhase ) "{{{
    if -1 == match( s:phaseGraph[ a:inst.phase ], '\V\<' . a:nextPhase . '\>' )
        throw 'XPT:RenderContext:switching from [' . a:inst.phase . '] to [' . a:nextPhase . '] is not allowed'
    endif

    let a:inst.phase = a:nextPhase

endfunction "}}}

" fun! xpt#rctx#InitGroupList( rctx ) "{{{
"     let a:rctx.groupList = []

"     call xpt#rctx#InitOrderedGroupList( a:rctx )
" endfunction "}}}

fun! xpt#rctx#InitOrderedGroupList( rctx ) "{{{
    let a:rctx.firstList = copy( a:rctx.snipSetting.comeFirst )
    let a:rctx.lastList = copy( a:rctx.snipSetting.comeLast )
endfunction "}}}

fun! xpt#rctx#AddDefaultPHFilters( rctx, ph ) "{{{

    if a:ph.name == ''
        return
    endif

    let pfs = a:rctx.snipSetting.postFilters
    if !has_key( pfs, a:ph.name )

        if a:ph.name =~ '\V\w\+?\$'
            let pfs[ a:ph.name ] = xpt#flt#New( 0, "EchoIfNoChange('')" )
        endif

    endif

endfunction "}}}

fun! xpt#rctx#DefaultMarks(rctx) "{{{
    if a:rctx.phase == s:phase.post
        return 'mark'
    else
        return 'innerMarks'
    endif
endfunction "}}}

fun! xpt#rctx#UserOut( rctx, text ) "{{{
    let a:rctx.nextStep = s:R_NEXT
    let a:rctx.userPostAction = a:text
endfunction "}}}

fun! xpt#rctx#UserOutAppend( rctx, text ) "{{{
    call xpt#rctx#UserOut( a:rctx, a:rctx.userPostAction . a:text )
endfunction "}}}

" TODO remove me: unclear statement
fun! xpt#rctx#AddPHToGroup( rctx, ph ) "{{{
    throw "do not use me any more"
    " anonymous g with empty name '' will never been added to a:rctx.itemDict

    let g = xpt#rctx#GetGroup( a:rctx, a:ph.name )

    call xpt#group#InsertPH( g, a:ph, len( g.placeHolders ) )

    return g

endfunction "}}}

fun! xpt#rctx#GetGroup( rctx, name ) "{{{

    " TODO rename it
    if has_key(a:rctx.itemDict, a:name)

        let g = a:rctx.itemDict[ a:name ]

    else

        let g = xpt#group#New( a:name, a:rctx.buildingSessionID )

    endif

    " NOTE: No matter new or old, always try to add. during render-time,
    " dynamically generated PH need to be resorted
    call xpt#rctx#AddGroup( a:rctx, g )

    return g

endfunction "}}}

fun! xpt#rctx#AddGroup( rctx, g ) "{{{

    let [rctx, g] = [ a:rctx, a:g ]

    let exist = has_key( rctx.itemDict, g.name )

    if g.name != ''
        let rctx.itemDict[ g.name ] = g
    endif

    if rctx.phase != s:phase.rendering
        call add( rctx.firstList, g )
        call filter( ctx.groupList, 'v:val isnot g' )

        call s:log.Log( 'group insert to the head of groupList:' . string( g ) )
        return

    endif

    " rendering phase
    if exist
        return
    endif

    if g.name == ''

        call add( rctx.groupList, g )

    elseif s:AddToOrderList( rctx.firstList, g )
          \ || s:AddToOrderList( rctx.lastList, g )

        return

    else

        call add( rctx.groupList, g )
        call s:log.Log( g.name . ' added to groupList' )

    endif

endfunction "}}}

fun! s:AddToOrderList( list, g ) "{{{
    let i = index( a:list, a:g.name )

    if i != -1
        let a:list[ i ] = a:g
        call s:log.Log( a:g.name . ' added to ' . string( a:list ) )
        call s:log.Debug( 'index:' . i )

        return 1
    else
        return 0
    endif

endfunction "}}}

let &cpo = s:oldcpo
