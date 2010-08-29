if exists( "g:__AL_XPT_FLT_VIM__" ) && g:__AL_XPT_FLT_VIM__ >= XPT#ver
    finish
endif
let g:__AL_XPT_FLT_VIM__ = XPT#ver




let s:oldcpo = &cpo
set cpo-=< cpo+=B




let g:EmptyFilter = {}

" rc:       1: right status. 0 means nothing should be updated.
let s:proto = {
      \ 'marks'   : 'innerMarks',
      \ 'hasCursor' : 0,
      \ 'rc'      : 1,
      \ 'toBuild' : 0,
      \ 'force'   : 0,
      \ }

fun! xpt#flt#New( nIndent, text, ... ) "{{{
    let inst = deepcopy( s:proto )

    " force:    force using this.
    call extend( inst, {
          \ 'nIndent' : a:nIndent,
          \ 'text'    : a:text,
          \ 'force'   : a:0 == 1 && a:1,
          \ }, 'force' )

    return inst

endfunction "}}}

fun! xpt#flt#NewSimple( nIndent, text, ... ) "{{{

    let inst = { 'nIndent' : a:nIndent, 'text' : a:text, }

    if a:0 == 1 && a:1 | let inst.force = 1 | endif

    return inst

endfunction "}}}

fun! xpt#flt#Extend( inst ) "{{{
    " no reference existed in s:proto, no need to deepcopy it
    call extend( a:inst, s:proto, 'keep' )
endfunction "}}}

fun! xpt#flt#Simplify( inst ) "{{{
    " -987654 is assumed to be an pseudo NONE value
    call filter( a:inst, 'v:val!=get(s:proto,v:key,-987654)' )
endfunction "}}}


fun! xpt#flt#AdjustIndent( inst, startPos ) "{{{

    if a:inst.text !~ '\n'
        let a:inst.nIndent = 0
        return
    endif


    let nIndent = xpt#util#getIndentNr( a:startPos[0], a:startPos[1] )
    let [ nIndent, a:inst.nIndent ] = [ max( [ 0, nIndent + a:inst.nIndent ] ), 0 ]

    if nIndent == 0
        return
    endif


    let indentSpaces = repeat( ' ', nIndent )

    let a:inst.text = substitute( a:inst.text, '\n', "\n" . indentSpaces, 'g' )

endfunction "}}}


fun! xpt#flt#AdjustTextAction( inst, context ) "{{{

    if !has_key( a:inst.action, 'text' )
        return
    endif


    let a:inst.text = a:inst.action.text
    unlet a:inst.action.text

    if has_key( a:inst.action, 'resetIndent' )

        let a:inst.nIndent = a:inst.action.nIndent

        unlet a:inst.action.nIndent
        unlet a:inst.action.resetIndent

    endif

    call xpt#flt#AdjustIndent( a:inst, a:context.startPos )

endfunction "}}}


let &cpo = s:oldcpo
