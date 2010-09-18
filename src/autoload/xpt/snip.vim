if exists( "g:__AL_XPT_SNIP_VIM__" ) && g:__AL_XPT_SNIP_VIM__ >= XPT#ver
    finish
endif
let g:__AL_XPT_SNIP_VIM__ = XPT#ver




let s:oldcpo = &cpo
set cpo-=< cpo+=B

let s:log = xpt#debug#Logger( 'warn' )
let s:log = xpt#debug#Logger( 'debug' )

exe XPT#importConst


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


fun! xpt#snip#Compile( snipObject ) "{{{

    let snipPattern = a:snipObject.ptn
    let [ lptn, rptn ] = [ '\V\^' . snipPattern.lft, '\V\^' . snipPattern.rt ]
    let [ l, r ] = [ snipPattern.l, snipPattern.r ]

    let delimiter = '\V\ze' . snipPattern.lft . '\|\ze' . snipPattern.rt


    let lines0 = split( a:snipObject.snipText, "\n" )
    let lines = []

    for line in lines0
        call add( lines, split( line, delimiter ) )
        " echom string( lines[ -1 ] )
    endfor

    " TODO empty check

    " TODO create indents

    let lines[ -1 ] += [ l ]
    let [ i, j, nlines, nitems ] = [ 0, 0, len( lines ), len( lines[ 0 ] ) ]

    let [ st ] = [ 'LeftEdge' ]

    let nIndent = 0
    let pieces  = ['']
    let rst     = []

    while 1

        let elt = lines[ i ][ j ]
        let e = matchstr( elt, '\v.' )

        if e != l && e != r
            let pieces[ -1 ] .= lines[ i ][ j ]
        endif

        if st == 'LeftEdge'

            if e == l
                let [ st ] = [ 'Name' ]
                let rst += pieces
                let pieces = [ nIndent, elt[ 1 : ] ]
            endif

        elseif st == 'Name'

            if e == l
                call add( pieces, elt[ 1 : ] )
            elseif e == r
                let [ st ] = [ 'Filter' ]
                continue
            endif

        elseif st == 'Filter'

            if e == l
            elseif e == r
                let [ st ] = [ 'FilterEnd' ]
                call add( pieces, elt )
            endif

        elseif st == 'FilterEnd'

            if e == l
                let [ st ] = [ 'LeftEdge' ]

                " TODO do add PH
                let followingText = pieces[ -1 ][ 1 : ]
                let pieces[ -1 ] = pieces[ -1 ][ 0 : 0 ]
                let rst += [ s:CreatePH( a:snipObject, pieces ) ]
                let pieces = [ followingText ]

                continue

            elseif e == r
                call add( pieces, elt )
                let [ st ] = [ 'FilterEnd2' ]
            endif

        elseif st == 'FilterEnd2'

            if e == l
                let [ st ] = [ 'LeftEdge' ]

                " TODO do add PH
                let followingText = pieces[ -1 ][ 1 : ]
                let pieces[ -1 ] = pieces[ -1 ][ 0 : 0 ]
                let rst += [ s:CreatePH( a:snipObject, pieces ) ]
                let pieces = [ followingText ]

                continue
            elseif e == r
                call add( pieces, elt )
                let [ st ] = [ 'FilterEnd2' ]
            endif

        endif


        let j += 1

        if j >= nitems
            let [ i, j ] = [ i + 1, 0 ]
            if i >= nlines
                break
            endif
            let pieces[ -1 ] .= "\n"
            let nIndent = len( matchstr( lines[ i ][ 0 ], '\V\^\s\*' ) )
            let nitems = len( lines[ i ] )
        endif

    endwhile

    " echom string( rst )
endfunction "}}}

fun! s:CreatePH( snipObject, pieces ) "{{{
    let indent = remove( a:pieces, 0 )
    let iFilter = match( a:pieces, '\V\^' . a:snipObject.ptn.r )
    let filterParts = a:pieces[ iFilter ][ 1: ]

    let isKey = iFilter > 1
    if isKey
        let ph ={ 'leftEdge' : a:pieces[ 0 ], 'name' : a:pieces[ 1 ], 'rightEdge' :iFilter > 2 ? a:pieces[ 2 ] : '', 'isKey' : isKey } 
    else
        let ph ={ 'leftEdge' : '', 'name' : a:pieces[ 0 ], 'rightEdge' :'', 'isKey' : isKey } 
    endif

    if len( a:pieces ) - iFilter > 1
        let filterParts .= a:snipObject.ptn.r
    endif

    return xpt#ph#New( a:snipObject, ph, { 'text' : filterParts, 'indent' : indent } )

endfunction "}}}

fun! xpt#snip#ReplacePH( snipObject, params ) "{{{

    if a:params == {} | return a:snipObject.snipText | endif

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
