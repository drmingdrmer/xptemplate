" File Description {{{
" =============================================================================
" PlaceHolder
" 1) Place holder with edge is the editable place holder. Or the key place holder
"
" 2) If none of place holders of one item has edge. The first place
" holder is the key place holder.
"
" 3) if more than one place holders set with edge, the first
" one is the key place holder.
"
"                                                  by drdr.xp
"                                                     drdr.xp@gmail.com
" Usage :
"
" =============================================================================
" }}}
if exists( "g:__AL_XPT_PH_VIM__" ) && g:__AL_XPT_PH_VIM__ >= XPT#ver
    finish
endif
let g:__AL_XPT_PH_VIM__ = XPT#ver




let s:oldcpo = &cpo
set cpo-=< cpo+=B


let s:log = xpt#debug#Logger( 'warn' )
let s:log = xpt#debug#Logger( 'debug' )

exe XPT#importConst

let s:incPattern = '\V\^:\zs\.\*\ze:\$\|\^Include:\zs\.\*\$'


fun! xpt#ph#CreateFromScreen( snipObject, nameInfo, valueInfo ) "{{{

    " 1 is length of left mark
    let leftEdge  = xpt#util#TextBetween( a:nameInfo[ 0 : 1 ] )
    let name      = xpt#util#TextBetween( a:nameInfo[ 1 : 2 ] )
    let rightEdge = xpt#util#TextBetween( a:nameInfo[ 2 : 3 ] )

    let [ leftEdge, name, rightEdge ] = [ leftEdge[1 : ], name[1 : ], rightEdge[1 : ] ]

    if a:valueInfo[1] != a:valueInfo[0]

        let posList = [ a:valueInfo[ 0 ], a:valueInfo[ 2 ] ]
        let val = xpt#util#TextBetween( posList )
        let val = val[1:]


        " TODO problem: indent() returns indent without mark consideration
        let nIndent = indent( a:valueInfo[0][0] )


        call s:log.Debug("placeHolder post filter:key=val : " . name . "=" . val)

        let phFilter =  { 'text' : val, 'indent' : nIndent, }
    else
        let phFilter = 0
    endif


    return s:CreatePH( a:snipObject, 
          \ { 'leftEdge' : leftEdge,
          \   'name' : name,
          \   'rightEdge' : rightEdge,
          \   'isKey' : ( a:nameInfo[0] != a:nameInfo[1] ), }, phFilter )

endfunction "}}}

fun! s:CreatePH( snipObject, ph, phFilter ) "{{{

    let snipPattern = a:snipObject.ptn

    call s:log.Log( "item is :" . string( a:ph ) )


    " NOTE: inclusion comes first

    if a:ph.name =~ s:incPattern
        " build-time inclusion for XSET

        return { 'include' : matchstr( a:ph.name, s:incPattern ) }

    endif


    if a:ph.name =~ '\V' . snipPattern.item_var . '\|' . snipPattern.item_func
        " This is only a instant place holder
        " TODO quoted pattern
        " if a place holder need to be evalueated, the evaluate part must be all
        " in name but not edge.

        return { 'value'     : a:ph.leftEdge . a:ph.name . a:ph.rightEdge,
              \  'leftEdge'  : a:ph.leftEdge,
              \  'name'      : a:ph.name,
              \  'rightEdge' : a:ph.rightEdge,
              \ }

    endif


    " PlaceHolder.item is set by caller.
    " After this step, to which item this placeHolder belongs has not been set.
    let placeHolder = { 'name'  : a:ph.name, 'isKey' : a:ph.isKey, }

    if placeHolder.isKey
        call extend( placeHolder, {
              \     'leftEdge'  : a:ph.leftEdge,
              \     'rightEdge' : a:ph.rightEdge,
              \     'fullname'  : a:ph.leftEdge . a:ph.name . a:ph.rightEdge,
              \ }, 'force' )
    endif

    if a:phFilter isnot 0

        if a:phFilter.text =~ snipPattern.rt . '\$'
            let [ val, ftype ] = [ a:phFilter.text[ 0 : -2 ], 'postFilter' ]
        else
            let [ val, ftype ] = [ a:phFilter.text, 'ontimeFilter' ]
        endif

        let val = xpt#util#UnescapeChar( val, snipPattern.l . snipPattern.r )

        let placeHolder[ ftype ] = xpt#flt#New( -a:phFilter.indent, val )

    endif

    return placeHolder


endfunction "}}}


let &cpo = s:oldcpo
