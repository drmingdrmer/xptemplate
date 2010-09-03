" File Description {{{
" =============================================================================
" RenderContext
"                                                  by drdr.xp
"                                                     drdr.xp@gmail.com
" Usage :
"
" =============================================================================
" }}}
if exists( "g:__AL_XPT_RCTX_VIM__" ) && g:__AL_XPT_RCTX_VIM__ >= XPT#ver
    finish
endif
let g:__AL_XPT_RCTX_VIM__ = XPT#ver


let s:oldcpo = &cpo
set cpo-=< cpo+=B

" let s:log = xpt#debug#Logger( 'warn' )
" let s:log = xpt#debug#Logger( 'debug' )


let g:xptRenderPhase = {
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

let p = g:xptRenderPhase
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
          \   'evalCtx'            : {},
          \   'phase'              : g:xptRenderPhase.uninit,
          \   'action'             : '',
          \   'wrap'               : {},
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
          \   'lastContent'        : '',
          \   'snipSetting'        : {},
          \   'tmpmappings'        : {},
          \   'oriIndentkeys'      : {},
          \ }

    " for emulation of 'indentkeys'
    let indentkeysList = split( &indentkeys, ',' )
    call filter( indentkeysList, 'v:val=~''\V\^0=''' )
    for k in indentkeysList

        " "0=" is not included
        let inst.oriIndentkeys[ k[ 2: ] ] = 1
    endfor

    return inst

endfunction "}}}

fun! xpt#rctx#SwitchPhase( inst, nextPhase ) "{{{
    if -1 == match( s:phaseGraph[ a:inst.phase ], '\V\<' . a:nextPhase . '\>' )
        throw 'XPT:RenderContext:switching from [' . a:inst.phase . '] to [' . a:nextPhase . '] is not allowed'
    endif

    let a:inst.phase = a:nextPhase

endfunction "}}}

let &cpo = s:oldcpo
