let g:ftscope = xpt#ftsc#New()


let s:suite = {}


fun! s:suite.GenerateSnip() "{{{
    let snip = s:CreateSnip( '-`l`x`r^=' )

    call xpt#snip#CompileAndParse( snip )

    let phs = snip.parsedSnip

    call XPT#AssertEq( 3, len( phs ), 'nr of phs' )
    call XPT#AssertEq( '-', phs[ 0 ], 'ph 0' )
    call XPT#AssertEq( '=', phs[ -1 ], 'ph -1' )

    call XPT#AssertEq( 'x', phs[ 1 ].name, 'name of ph 1' )
    call XPT#AssertEq( 'x', phs[ 1 ].displayText, 'displayText of ph 1' )
    call XPT#AssertEq( 'l', phs[ 1 ].leftEdge, 'leftEdge of ph ' )
    call XPT#AssertEq( 'r', phs[ 1 ].rightEdge, 'rightEdge of ph ' )

endfunction "}}}

fun! s:suite.BasicReplacePHs() "{{{

    let snip = s:SnipForReplacePHs()

    let phs = xpt#snip#ReplacePH( snip, { 'a' : 'b' } )

    call XPT#AssertEq( len( phs ), 3, '3 phs' )

    call XPT#AssertEq( phs[ 0 ], '-', 'left part is -' )

    call XPT#AssertEq( type( phs[ 1 ] ), type( {} ), '2nd part is ph' )
    call XPT#AssertEq( 'b', phs[ 1 ].name, 'replaced with b' )
    call XPT#AssertEq( 'b', phs[ 1 ].displayText, 'displayText replaced with b' )

    call XPT#AssertEq( phs[ 2 ], '=', 'right part is -' )


endfunction "}}}

fun! s:suite.ReplacePHs_CreateEdge() "{{{

    let snip = s:SnipForReplacePHs()

    let phs = xpt#snip#ReplacePH( snip, { 'a' : 'le`b`re' } )


    call XPT#AssertEq( 'le', phs[ 1 ].leftEdge, 'new Created leftEdge' )
    call XPT#AssertEq( 'b', phs[ 1 ].name, 'new Created name' )
    call XPT#AssertEq( 'b', phs[ 1 ].displayText, 'new Created displayText' )
    call XPT#AssertEq( 're', phs[ 1 ].rightEdge, 'new Created rightEdge' )


    let snip.parsedSnip = phs

    let phs = xpt#phfilter#Filter( snip,
          \ 'xpt#phfilter#ReplacePH',
          \ { 'replParams' : { 'b' : '`LE`B`RE^' } } )

    call XPT#AssertEq( 'LE', phs[ 1 ].leftEdge, 'new Created leftEdge of New Fashion' )
    call XPT#AssertEq( 'B', phs[ 1 ].name, 'new Created name of New Fashion' )
    call XPT#AssertEq( 'B', phs[ 1 ].displayText, 'new Created displayText of New Fashion' )
    call XPT#AssertEq( 'RE', phs[ 1 ].rightEdge, 'new Created rightEdge of New Fashion' )

endfunction "}}}

fun! s:suite.ReplacePHs_MultiPHs() "{{{

    let snip = s:SnipForReplacePHs()

    let phs = xpt#snip#ReplacePH( snip, { 'a' : '`x^`le`y`re^' } )


    call XPT#AssertEq( 4, len( phs ), 'Create another 2 phs' )

    call XPT#AssertEq( type( {} ), type( phs[ 1 ] ), '1st part is ph' )
    call XPT#AssertEq( type( {} ), type( phs[ 2 ] ), '2nd part is ph' )

    call XPT#AssertEq( 'x', phs[ 1 ].name, 'name of first ph' )
    call XPT#AssertEq( 'x', phs[ 1 ].displayText, 'displayText of first ph' )

    call XPT#AssertEq( 1, has_key( phs[ 2 ], 'isKey' ), '2nd ph is key ph' )

    call XPT#AssertEq( 'le', phs[ 2 ].leftEdge, 'left edge of 2nd ph' )
    call XPT#AssertEq( 'y', phs[ 2 ].name, 'name of 2nd ph' )
    call XPT#AssertEq( 'y', phs[ 2 ].displayText, 'displayText of 2nd ph' )
    call XPT#AssertEq( 're', phs[ 2 ].rightEdge, 'right edge of 2nd ph' )

endfunction "}}}

fun! s:suite.EvalInstantValue_Basic() "{{{
    let snip = s:CreateSnip( '-`Pre( Echo("a") )^=' )

    let phs = xpt#phfilter#Filter( snip,
          \ 'xpt#phfilter#EvalInstantFilters',
          \ {} )

    call XPT#AssertEq( '-a=', phs[ 0 ], 'everything evaled' )


    let snip = s:CreateSnip( '-`Echo("a")^=' )

    let phs = xpt#snip#EvalInstantFilters( snip )

    call XPT#AssertEq( 3, len( phs ), 'Echo should not be evaled at pre-eval phase' )
    call XPT#AssertEq( 1, has_key( phs[ 1 ], 'value' ), 'phs[1] is an instant value filter' )
    call XPT#AssertEq( 'Echo("a")', phs[ 1 ].name, 'name would not change during eval' )
    call XPT#AssertEq( type( {} ), type( phs[ 1 ].displayText ), 'Echo keep still a filter' )
    call XPT#AssertEq( 'Echo("a")', phs[ 1 ].displayText.text, 'filter text' )

endfunction "}}}

fun! s:suite.EvalInstantValue_Indent() "{{{

    let text = '    `Pre(Echo("\n="))^'
    let snip = s:CreateSnip( text )


    " Align indent to upper line
    let snip.parsedSnip[ 1 ].displayText.nIndent = 0
    
    let phs = xpt#snip#EvalInstantFilters( snip )

    call XPT#AssertEq( "    \n    =", phs[ 0 ], 'indent should be aligned to upper line' )

endfunction "}}}

fun! s:suite.EvalInstantValue_DynaIndent() "{{{

    let text = ' `Pre(Echo(" "))^`Pre(Echo("\n="))^'
    let snip = s:CreateSnip( text )


    " Align indent to upper line
    let snip.parsedSnip[ 2 ].displayText.nIndent = 0


    let phs = xpt#snip#EvalInstantFilters( snip )

    call XPT#AssertEq( "  \n  =", phs[ 0 ], 'indent should be aligned to upper line, include dynamic indent' )

endfunction "}}}

fun! s:suite.EvalInstantValue_Inc() "{{{

    let text = "\n a"
    let isnip = s:CreateSnip( text, 'inc' )

    let text = ' `Inc("inc",0,{})^'
    let snip = s:CreateSnip( text )


    let phs = xpt#snip#EvalInstantFilters( snip )

    call XPT#AssertEq( 1, len( phs ), 'all ph are combined to 1 string' )
    call XPT#AssertEq( " \n  a", phs[ 0 ], 'included snippet adds relative indent' )

endfunction "}}}

fun! s:suite.EvalInstantValue_Inc_DynIndent() "{{{

    let text = "\n a"
    let isnip = s:CreateSnip( text, 'inc' )

    let text = ' `Pre(Echo(" "))^`Inc("inc",0,{})^'
    let snip = s:CreateSnip( text )


    let phs = xpt#snip#EvalInstantFilters( snip )

    call XPT#AssertEq( 1, len( phs ), 'all ph are combined to 1 string' )
    call XPT#AssertEq( "  \n   a", phs[ 0 ], 'included snippet adds relative dynamic indent' )

endfunction "}}}

fun! s:suite.PostQuote_Basic() "{{{
    let text = ' `a{{^foo`x^`}}^`b^'
    let snip = s:CreateSnip( text )

    let phs = xpt#snip#PostQuote( snip )

    call XPT#AssertEq( 3, len( phs ), 'quoted phs are saved' )
    call XPT#AssertEq( ' ', phs[ 0 ], 'first ph' )
    call XPT#AssertEq( 'a', phs[ 1 ].name, '"{{" of the 2nd ph is stripped' )
    call XPT#AssertEq( -1, snip.setting.postFilters[ 'a' ].nIndent, 'filter indent' )
    call XPT#AssertEq( 'b', phs[ 2 ].name, 'name of 3rd ph' )

    let slaves = xpt#ftsc#GetPHPieces( g:ftscope, -1 )

    call XPT#AssertEq( 2, len( slaves ), 'generated phs' )
    call XPT#AssertEq( 'foo', slaves[ 0 ], '1st string ph' )
    call XPT#AssertEq( type( {} ), type( slaves[ 1 ] ), 'an ph' )
    call XPT#AssertEq( 'x', slaves[ 1 ].name, 'ph name' )
    call XPT#AssertEq( 'x', slaves[ 1 ].displayText, 'ph displayText' )

endfunction "}}}



fun! s:suite.Repetition_Basic() "{{{
    let text = ' `a...^`x^`a...^'
    let snip = s:CreateSnip( text )

    let phs = xpt#snip#Repetition( snip )


    call XPT#AssertEq( 2, len( phs ), 'repetition phs are saved' )
    call XPT#AssertEq( ' ', phs[ 0 ], 'first ph' )
    call XPT#AssertEq( 'a...', phs[ 1 ].name, 'name of 2nd ph' )
    call XPT#AssertEq( 'a...', phs[ 1 ].displayText, 'displayText of 2nd ph' )
    call XPT#AssertEq( -1, snip.setting.postFilters[ 'a...' ].nIndent, 'filter indent' )


    let slaves = xpt#ftsc#GetPHPieces( g:ftscope, -1 )

    call XPT#AssertEq( 2, len( slaves ), 'len of generated phs' )

    call XPT#AssertEq( type( {} ), type( slaves[ 0 ] ), 'type of 1st ph' )
    call XPT#AssertEq( 'x', slaves[ 0 ].name, '1st ph name' )
    call XPT#AssertEq( 'x', slaves[ 0 ].displayText, '1st ph displayText' )

    call XPT#AssertEq( type( {} ), type( slaves[ 1 ] ), 'type of 2nd ph' )
    call XPT#AssertEq( 'a...', slaves[ 1 ].name, '2nd ph name' )
    call XPT#AssertEq( 'a...', slaves[ 1 ].displayText, '2nd ph displayText' )

endfunction "}}}

fun! s:SnipForReplacePHs() "{{{
    return s:CreateSnip( '-`a^=' )
endfunction "}}}

fun! s:CreateSnip( text, ... ) "{{{
    let text = a:text
    let name = a:0 > 0 ? a:1 : 'a'

    let setting = xpt#st#New()
    call xpt#st#Extend( setting )

    let snip = xpt#snip#New( name, g:ftscope, text, 0, setting, xpt#snipf#GenPattern( { 'l' : '`', 'r' : '^' } ) )
    call xpt#snip#Compile( snip )

    let snip.parsedSnip = snip.compiledSnip

    let g:ftscope.allTemplates[ name ] = snip

    return snip

endfunction "}}}

for k in keys( s:suite )
    echom 'Test: ' . k
    call s:suite[ k ]()
endfor
" call s:suite.EvalInstantValue_Basic()

if inputdialog( "quit(y/n)? " ) == 'y'
    qa
endif



