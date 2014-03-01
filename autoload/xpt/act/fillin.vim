" File Description {{{
" =============================================================================
" Action Handlers in fill-in phase
"                                                  by drdr.xp
"                                                     drdr.xp@gmail.com
" Usage :
"
" =============================================================================
" }}}

if exists( "g:__AL_XPT_ACT__FILLIN_VIM__" ) && g:__AL_XPT_ACT__FILLIN_VIM__ >= XPT#ver
    finish
endif
let g:__AL_XPT_ACT__FILLIN_VIM__ = XPT#ver



let s:oldcpo = &cpo
set cpo-=< cpo+=B


let s:log = xpt#debug#Logger( 'warn' )
let s:log = xpt#debug#Logger( 'debug' )

exe XPT#importConst

fun! xpt#act#fillin#resetIndent( rctx, flt ) "{{{
    let a:rctx[ -1 ] .= a:flt.text
endfunction "}}}


fun! xpt#act#fillin#embed( rctx, flt ) "{{{

    let marksToUse = get( a:flt.rst, 'marks', a:rctx.activeLeaderMarks )

    let activeMarks = a:rctx.leadingPlaceHolder[ marksToUse ]
    let [ start, end ] = XPMposStartEnd( activeMarks )


    let phs = xpt#act#cmn#PHsToEmbed( a:rctx.snipObject, a:flt )


    let render = xpt#render#New( a:rctx, start )
    let [ lines, markArgs ] = xpt#render#GenScreenDataOfPHs( render, phs )


    call XPMsetLikelyBetween( activeMarks.start, activeMarks.end )
    call XPreplace( start, end, join( lines, "\n" ) )
    call XPMaddSeq( markArgs )

    call XPMupdateStat()

    let rg = XPMposStartEnd( activeMarks )
    exe 'silent! ' . rg[0][0] . ',' . rg[1][0] . 'foldopen!'

    return len( markArgs ) > 0 ? s:BUILT : s:NOTBUILT

endfunction "}}}

let &cpo = s:oldcpo
