if exists( "g:__AL_XPT_SNIP_VIM__" ) && g:__AL_XPT_SNIP_VIM__ >= XPT#ver
    finish
endif
let g:__AL_XPT_SNIP_VIM__ = XPT#ver




let s:oldcpo = &cpo
set cpo-=< cpo+=B

let s:log = xpt#debug#Logger( 'warn' )
let s:log = xpt#debug#Logger( 'debug' )


fun! xpt#snip#DefExt( name, setting, lines ) "{{{

    call xpt#st#Extend( a:setting )

    call XPTdefineSnippet( a:name, a:setting, a:lines )

endfunction "}}}

fun! xpt#snip#New( name, ftScope, snipText, prio, setting, patterns ) "{{{
    return {
          \ 'name'        : a:name,
          \ 'parsed'      : 0,
          \ 'ftScope'     : a:ftScope,
          \ 'rawSnipText' : a:snipText,
          \ 'snipText'    : a:snipText,
          \ 'priority'    : a:prio,
          \ 'setting'     : a:setting,
          \ 'ptn'         : a:patterns,
          \ }

endfunction "}}}



fun! xpt#snip#ReplacePH( snipObject, params ) "{{{

    if params == {} | return | endif

    let xp = a:snipObject.ptn
    let incSnip = a:snipObject.snipText

    let incSnipPieces = split( incSnip, '\V' . xp.rt, 1 )

    " NOTE: not very strict matching
    for [ k, v ] in items( a:params )

        let [ i, len ] = [ 0 - 1, len( incSnipPieces ) - 1 ]
        while i < len | let i += 1
            let piece = incSnipPieces[ i ]


            if piece =~# '\V' . k
                let parts = split( piece, '\V' . xp.lft, 1 )

                " len of parts : 2 3 4
                " index of name: 1 2 2

                let iName = len( parts ) == 4 ? 2 : len( parts ) - 1


                if parts[ iName ] ==# k
                    let parts[ iName ] = v
                endif

                let incSnipPieces[ i ] = join( parts, xp.l )
            endif

        endwhile

    endfor

    let incSnip = join( incSnipPieces, xp.r )

    return incSnip
endfunction "}}}

fun! xpt#snip#ParseInclusionStatement( snipObject, statement ) "{{{

    let xp = a:snipObject.ptn


    let ptn = '\V\^\[^(]\{-}('
    let statement = a:statement

    if statement =~ ptn && statement[ -1 : -1 ] == ')'

        let name = matchstr( statement, ptn )[ : -2 ]
        let paramStr = statement[ len( name ) + 1 : -2 ]

        call s:log.Debug( 'name=' . string( name ) )
        call s:log.Debug( 'paramStr' . string( paramStr ) )

        let paramStr = xpt#util#UnescapeChar( paramStr, xp.l . xp.r )
        let params = {}
        try
            let params = eval( paramStr )
        catch /.*/
            XPT#warn( 'XPT: Invalid parameter: ' . string( paramStr ) . ' Error=' . v:exception )
        endtry

        call s:log.Debug( 'params=' . string( params ) )

        return [ name, params ]

    else
        return [ statement, {} ]
    endif

endfunction "}}}







let &cpo = s:oldcpo
