XPTemplate priority=all


let s:f = g:XPTfuncs()


" which bracket should be completed in block mode. Thus <CR> push right bracket
" down to the third line from the left bracket
XPTvar $XPT_BRACE_BLOCK '[({'

XPTinclude
      \ _common/common


let s:pairs = { 'left' : "'" . '"([{<|*`+ ',
      \         'right': "'" . '")]}>|*`+ ', }

let s:pairMap = {}

fun! s:CreatePairsMap()

    let i = 0
    for c in split( s:pairs.left, '\V\s\{-}' )
        let s:pairMap[ c ] = s:pairs.right[ i ]
        let i += 1
    endfor

    let pkeys = keys( s:pairMap )
    for c in pkeys
        for c2 in pkeys
            let s:pairMap[ c . c2 ] = s:pairMap[ c2 ] . s:pairMap[ c ]
        endfor
    endfor
endfunction
call s:CreatePairsMap()
delfun s:CreatePairsMap


" TODO not perfect: hide right part if found right is already in input area.
"      use searchpair() to improve

let s:crIndent = 0

fun! s:f.BracketRightPart( leftReg )
    let r = self.renderContext

    if has_key( self.renderContext, 'bracketComplete' )
        return ''
    endif

    let v = self.V()
    let rightPart = v

    let rightPart = get( s:pairMap, matchstr( v, a:leftReg ), '' )
    if rightPart == ''
        return ''
    endif


    let blockModeChars = self.GetVar( '$XPT_BRACE_BLOCK' )

    if stridx( blockModeChars, r.char ) >= 0 && v =~ '\V\n\s\*\$'
        let rightPart = matchstr( rightPart, '\V\S\+' )
        return self.ResetIndent( -s:crIndent, "\n" . rightPart )
    else
        return rightPart
    endif
endfunction

fun! s:f.bkt_cmpl()
    if has_key( self.renderContext, 'leftReg' )
        " initialized
        return self.BracketRightPart( self.renderContext.leftReg )
    else
        return ''
    endif
endfunction

fun! s:f.quote_cmpl()
    if has_key( self.renderContext, 'leftReg' )
        let r = self.renderContext
        let v = self.V()
        let v = matchstr( v, r.leftReg )

        if has_key( r, 'bracketComplete' )
            echom "completed"
            return ''
        elseif v == ''
            return ''
        else
            return r.charRight
        endif
    else
        return ''
    endif
endfunction

fun! s:f.quote_ontype()
    let r = self.renderContext

    let v = self.V()

    if v == ''
        return self.Finish()

    elseif v =~ '\V\n'

        return self.FinishOuter( v )

    else
        return v
    endif
    
endfunction

fun! s:f.bkt_ontype()

    let r = self.renderContext
    let blockModeChars = self.GetVar( '$XPT_BRACE_BLOCK' )

    let v = self.V()

    if v == ''
        return self.Finish()

    elseif v =~ '\V\n\s\*\$'

        if &indentexpr != ''
            let indentexpr = substitute( &indentexpr, '\Vv:lnum', 'line(".")', '' )
            try
                let nNewLineIndent = eval( indentexpr )
                let s:crIndent = nNewLineIndent - indent( line( "." ) - 1 )
            catch /.*/
                let s:crIndent = self.NIndent()
            endtry
        else
            let s:crIndent = self.NIndent()
        endif

        let v = substitute( v, '\V\s\*\n\.\*', "\n", 'g' )

        if stridx( blockModeChars, r.char ) >= 0
            return self.FinishOuter( v . repeat( ' ', s:crIndent ) )
        else
            return v
        endif

    else

        let pos = self.ItemPos()[ 0 ]
        return self.ResetIndent( -xpt#util#getIndentNr( pos ), v )

    endif

endfunction

fun! s:f.bkt_init( followingChar )
    let r = self.renderContext

    let r.char = self.GetVar( '$_xSnipName' )
    let r.followingChar = a:followingChar
    let r.leftReg = '\V\^' . r.char . r.followingChar . '\?'


    let i = stridx( s:pairs.left, r.char )

    if i != -1
        let r.charRight = s:pairs.right[ i ]

        call XPTmapKey( r.charRight, 'bkt_finish(' . string( r.charRight ) . ')' )
    else
        let r.charRight = ''
    endif

    return ''
endfunction

fun! s:f.bkt_finish( keyPressed )

    let r = self.renderContext

    if a:keyPressed != r.charRight
        " may be outer snippet key bind
        return a:keyPressed
    endif


    let v = self.V()

    if self.GetVar( '$SParg' ) == ' '

        if v == r.char . r.followingChar
            let outstr = r.char . r.charRight
        else
            let outstr = v . r.charRight
        endif

    else
        let outstr = v . r.charRight
    endif


    let r.bracketComplete = 1

    let [ phStart, phEnd ] = self.ItemPos()

    if [ line( "." ), col( "." ) ] == phEnd

        return self.FinishOuter( outstr )

    else

        echom "out side"

        return self.FinishPH( { 'cursor' : [ 'innerMarks.end' ],
              \                 'postponed' : r.charRight } )

    endif

endfunction




XPT _bracket hidden
XSET s|pre=Echo('')
XSET s|ontype=bkt_ontype()
XSET s=bkt_init(' ')
`$_xSnipName$SParg`s^`s^bkt_cmpl()^

" XPT _bracket hidden
" `$_xSnipName$SParg`s^^`s^bkt_cmpl()^

XPT _quote hidden
XSET s|pre=Echo('')
XSET s|ontype=quote_ontype()
XSET s=bkt_init('')
`$_xSnipName`s^`s^quote_cmpl()^


" XPT ( hidden
" XSET s|pre=Echo('')
" `($SParg`s^`s^SV( '\v\^(\()( ?)(.*)', '\2)', '' )^


XPT ( hidden alias=_bracket
XPT [ hidden alias=_bracket
XPT { hidden alias=_bracket
XPT < hidden alias=_bracket
XPT ' hidden alias=_quote
XPT " hidden alias=_quote
