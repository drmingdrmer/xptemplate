" File Description {{{
" =============================================================================
" Action Handlers functions
"                                                  by drdr.xp
"                                                     drdr.xp@gmail.com
" Usage :
"
" =============================================================================
" }}}

if exists( "g:__AL_XPT_ACT__CMN_VIM__" ) && g:__AL_XPT_ACT__CMN_VIM__ >= XPT#ver
    finish
endif
let g:__AL_XPT_ACT__CMN_VIM__ = XPT#ver



let s:oldcpo = &cpo
set cpo-=< cpo+=B


let s:log = xpt#debug#Logger( 'warn' )
let s:log = xpt#debug#Logger( 'debug' )


fun! xpt#act#cmn#PHsToEmbed( so, flt ) "{{{

    let phs = []

    if has_key( a:flt.rst, 'snipObject' )

        let phs = deepcopy( a:flt.rst.snipObject.parsedSnip )

    elseif has_key( a:flt.rst, 'phs' )

        let phs = a:flt.rst.phs

    elseif has_key( a:flt.rst, 'text' )

        let slave = xpt#snip#NewSlave( a:so, a:flt.rst.text )
        call xpt#snip#CompileAndParse( slave )

        let phs = slave.parsedSnip

    else
        " TODO other type of embeding

    endif

    return phs


endfunction "}}}

let &cpo = s:oldcpo
