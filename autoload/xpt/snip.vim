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

    " compiledSnip      List of a mixture of plain text and PH
    " parsedSnip        List with inclusion, repetition compiled
    " lines             List of PH whose value are evaluated.
    return {
          \ 'name'        : a:name,
          \ 'compiled'    : 0,
          \ 'parsed'      : 0,
          \ 'ftScope'     : a:ftScope,
          \ 'rawSnipText' : a:snipText,
          \ 'snipText'    : a:snipText,
          \ 'priority'    : a:prio,
          \ 'setting'     : a:setting,
          \ 'ptn'         : a:patterns,
          \ }


endfunction "}}}

fun! xpt#snip#NewSlave( master, snipText ) "{{{
    return xpt#snip#New( '', a:master.ftScope, a:snipText, 0,
          \ a:master.setting, a:master.ptn )
endfunction "}}}

fun! xpt#snip#CompileAndParse( so ) "{{{

    if !a:so.parsed

        if !a:so.compiled
            call xpt#snip#Compile( a:so )
        endif

        call xpt#snip#Parse( a:so )

    endif

endfunction "}}}

fun! xpt#snip#Compile( so ) "{{{

    call xpt#ftsc#Init( a:so.ftScope )

    if a:so.snipText == ''
        let a:so.compiledSnip = [ '' ]
        return
    endif


    let rawLines = s:SplitLines( a:so )

    let nIndent = len( matchstr( rawLines[0][0], '\V\^\s\*' ) )


    let [ l, r ] = [ a:so.ptn.l, a:so.ptn.r ]

    let [ i, j, nlines, nitems ] = [ 0, 0, len( rawLines ), len( rawLines[ 0 ] ) ]

    let [ st, linesCompiled ] = [ 'LeftEdge', [] ]
    let buf = [ { 'nIndent' : 0, 'text' : '' } ]


    while 1

        let elt = rawLines[ i ][ j ]
        let firstChar = matchstr( elt, '\v.' )

        if firstChar == l
            if st == 'LeftEdge'

                let st = 'Name'
                let texts = deepcopy( buf )
                call map( texts, 'v:val.text' )

                call extend( linesCompiled, texts )

                let buf = [ { 'nIndent' : nIndent, 'text' : elt[ 1 : ] } ]

            elseif st == 'Name'

                call add( buf, { 'nIndent' : nIndent, 'text' : elt[ 1 : ] } )

            elseif st == 'Filter'

                let st = 'LeftEdge'

                let followingText = buf[ -1 ].text[ 1 : ]
                let buf[ -1 ].text = buf[ -1 ].text[ 0 : 0 ]

                call add( linesCompiled, xpt#ph#New( a:so, buf ) )

                let buf = [ { 'nIndent' : nIndent, 'text' : followingText } ]

                continue

            endif

        elseif firstChar == r

            " if st == 'LeftEdge'
            "     " nothing to do

            if st == 'Name'

                let st = 'Filter'
                continue

            elseif st == 'Filter'

                call add( buf, { 'nIndent' : nIndent, 'text' : elt } )

            endif
        else
            let buf[ -1 ].text .= rawLines[ i ][ j ]
        endif


        let j += 1

        if j >= nitems

            let [ i, j ] = [ i + 1, 0 ]
            if i >= nlines
                break
            endif
            let buf[ -1 ].text .= "\n"

            let [ nIndent, nitems ] = [
                  \ len( matchstr( rawLines[ i ][ 0 ], '\V\^\s\*' ) ), len( rawLines[ i ] ) ]

        endif

    endwhile

    " remove empty string, list and dictionary
    call filter( linesCompiled, 'len(v:val) > 0' )


    let rst = []
    for e in linesCompiled
        call add( rst,
              \ type( e ) == type( {} )
              \ ? e : xpt#util#UnescapeChar( e, a:so.ptn.lr ) )
        unlet e
    endfor

    let a:so.compiledSnip = rst
    let a:so.compiled = 1

endfunction "}}}

fun! xpt#snip#TextToPlaceholders(text, ptn) "{{{

    let [ l, r ] = [ a:ptn.l, a:ptn.r ]
    let lr = l . r

    let toks = xpt#snip#Tokenize(a:text, a:ptn) + ["", "", ""]
    let elts = []
    let buf = []

    let i = -1
    while i < len(toks) - 1
        let i += 1
        let tok = toks[i]

        " let a = '' a[0] is legal
        let chr = tok[0]
        if chr != l && chr != r
            if tok != ""
                call add(elts, {'text': xpt#util#UnescapeChar(tok, lr)})
            endif
            continue
        endif

        if chr == l
            call add(buf, {'text': xpt#util#UnescapeChar(tok[1:], lr)})
            continue
        endif

        " chr == r
        let ph = s:EltsToPh(buf)
        call add(elts, ph)
        let buf = []

        if toks[i+1][0] == l
            continue
        endif


        if toks[i + 1] == r
            let [flt, iFilterEnd] = [{'text': ''}, i + 1]
        else
            " toks[i+1] is text
            if toks[i + 2] == r
                let [flt, iFilterEnd] = [{'text': xpt#util#UnescapeChar(toks[i + 1], lr)}, i + 2]
            else
                continue
            endif
        end

        if toks[iFilterEnd + 1] == r
            let ph.postFilter = flt
            let i = iFilterEnd + 1
        else
            let ph.liveFilter = flt
            let i = iFilterEnd
        endif

    endwhile

    return elts
endfunction "}}}

fun! s:EltsToPh(buf) "{{{
    let buf = a:buf

    if len(buf) == 0
         throw 'xpt#snip#Unexpected: ' . r
     elseif len(buf) == 1
         let ph = { 'name': buf[0] }
     elseif len(buf) == 2
         let ph = { 'leftEdge': buf[0], 'name': buf[1] }
     elseif len(buf) == 3
         let ph = { 'leftEdge': buf[0], 'name': buf[1], 'rightEdge': buf[2] }
     else
         throw 'xpt#snip#TooMany: ' . string(buf)
    endif
    return ph
endfunction "}}}

fun! xpt#snip#Parse( so ) "{{{

    " deepcopy is make by following parsers
    let a:so.parsedSnip = a:so.compiledSnip

    call s:log.Debug( 'before parse phs=' . xpt#debug#List( a:so.parsedSnip ) )


    let a:so.parsedSnip = xpt#snip#ReplacePH( a:so, a:so.setting.replacements )
    let a:so.parsedSnip = xpt#snip#EvalInstantFilters( a:so )
    let a:so.parsedSnip = xpt#snip#PostQuote( a:so )
    let a:so.parsedSnip = xpt#snip#Repetition( a:so )


    let a:so.parsed = 1


endfunction "}}}

fun! xpt#snip#ReplacePH( so, repls ) "{{{

    let phs = xpt#phfilter#Filter( a:so,
          \ 'xpt#phfilter#ReplacePH',
          \ { 'replParams' : a:repls } )


    call s:log.Debug( 'after RelacePH phs=' . xpt#debug#List( phs ) )

    return phs

endfunction "}}}

fun! xpt#snip#EvalInstantFilters( so ) "{{{

    let phs = xpt#phfilter#Filter( a:so,
          \ 'xpt#phfilter#EvalInstantFilters',
          \ {'skip' : a:so.ptn.item_func . '\|$_x\w', 'forceNotSkip' : s:ptnPreEvalFunc } )

    call s:log.Debug( 'after EvalInstantFilters phs=' . xpt#debug#List( phs ) )

    return phs

endfunction "}}}

fun! xpt#snip#PostQuote( so ) "{{{

    let pqContext = { 'pqStack' : [ [] ] }
    let pqContext.rstPHs = pqContext.pqStack[ 0 ]

    let phs = xpt#phfilter#Filter( a:so,
          \  'xpt#phfilter#PostQuote', pqContext )

    call s:log.Debug( 'after PostQuote phs=' . xpt#debug#List( phs ) )

    return phs

endfunction "}}}

fun! xpt#snip#Repetition( so ) "{{{

    let repContext = { 'repStack' : [ [] ], 'repHeads' : {} }
    let repContext.rstPHs = repContext.repStack[ 0 ]

    let phs = xpt#phfilter#Filter( a:so,
          \  'xpt#phfilter#Repetition', repContext )

    call s:log.Debug( 'after PostQuote phs=' . xpt#debug#List( phs ) )

    return phs

endfunction "}}}

fun! xpt#snip#EvalPresetFilters( rctx, phs, ctx ) "{{{

    let ctx = {
          \ 'rctx' : a:rctx,
          \   'srcPHs' : a:phs,
          \   'snipSetting' : a:rctx.snipSetting,
          \   'phEvalContext' : a:ctx, 
          \ }

    let phs = xpt#phfilter#Filter( a:rctx.snipObject,
          \ 'xpt#phfilter#EvalPresetFilters', ctx )

    call s:log.Debug( 'after PostQuote phs=' . xpt#debug#List( phs ) )

    return phs

endfunction "}}}

fun! xpt#snip#DumbCursorInPlace( so, phs ) "{{{

    for ph in a:phs

        if type( ph ) == type( {} )
              \ && ph.name is 'cursor'

            let ph.name = ''
            " TODO reseting displayText may be override pre-evaled value
            let ph.displayText = ph.name

        endif

        unlet ph

    endfor

endfunction "}}}

fun! xpt#snip#ParseInclusionStatement( so, statement ) "{{{

    let phptns = a:so.ptn


    let ptn = '\V\^\[^(]\{-}('
    let statement = a:statement

    if statement =~ ptn && statement[ -1 : -1 ] == ')'

        let name = matchstr( statement, ptn )[ : -2 ]

        let paramStr = statement[ len( name ) + 1 : -2 ]
        let paramStr = xpt#util#UnescapeChar( paramStr, phptns.lr )

        call s:log.Debug( 'name=' . string( name ) )
        call s:log.Debug( 'paramStr' . string( paramStr ) )


        let params = {}

        try
            let params = eval( paramStr )
        catch /.*/
            XPT#info( 'XPT: Invalid parameter: ' . string( paramStr ) . ' Error=' . v:exception )
        endtry


        call s:log.Debug( 'params=' . string( params ) )

        return [ name, params ]

    else
        return [ statement, {} ]
    endif

endfunction "}}}

fun! s:SplitLines( so ) "{{{

    let delimiter = '\V\ze' . a:so.ptn.lft . '\|\ze' . a:so.ptn.rt

    let lines = split( a:so.snipText, "\n", 1 )
    call map( lines, 'split(v:val, delimiter, 1)' )


    " add an additional left mark to finish the search
    let lines[ -1 ] += [ a:so.ptn.l ]

    return lines
endfunction "}}}

fun! xpt#snip#Tokenize(text, ptn) "{{{
    let delimiter = '\V\ze' . a:ptn.lft . '\|\ze' . a:ptn.rt
    let toks = split(a:text, delimiter, 0)
    " NOTE: vim bug: 'a`' -> [ 'a', '', '`' ]
    if len(toks) == 0
        return ['']
    end

    let rst = []
    for tok in toks
        if tok == a:ptn.r
            call add(rst, tok)
        elseif tok[0] == a:ptn.r
            call extend(rst, [a:ptn.r, tok[1:]])
        else
            call add(rst, tok)
        end
    endfor
    return rst
endfunction "}}}

let &cpo = s:oldcpo
