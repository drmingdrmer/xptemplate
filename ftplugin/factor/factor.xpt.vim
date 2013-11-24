XPTemplate priority=lang

let s:f = g:XPTfuncs()

XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL

XPTinclude
    \ _common/common


" ========================= Function and Variables =============================
fun! s:f.ModuleName()
    let rootfolder = substitute(getcwd(), '^.*[\\/]\([^\\/]\+\)$', '\1', '')
    let filename = rootfolder . '/' . expand('%:h:h') . '/' . expand('%:t:r')
    let stripped = substitute( filename, '[\\/]', '.', 'g' )

    return substitute( stripped, "-tests$", ".tests", '' )
endfunction
" ================================= Snippets ===================================

XPT alias "ALIAS: ... ...
ALIAS: `newword^ `oldword^

XPT const "CONSTANT: ... ...
CONSTANT: `word^ `constantValue^

XPT if "... [ ... ] [ ... ] if
`cond^ [ `then^ ] [ `else^ ] if

XPT times "... [ ... ] times
`count^ [ `what^ ] times

XPT mod " USING: ... IN: ...
XSET moduleName=ModuleName()
USING: kernel sequences accessors ;
IN: `moduleName^

XPT quote " [ ... ]
[ `cursor^ ]

XPT arr " { ... }
{ `cursor^ }

XPT vec " V{ ... }
V{ `cursor^ }

XPT bi " [ ... ] [ ... ] bi
[ `first^ ] [ `cursor^ ] bi

XPT tri " [ ... ] [ ... ] [ ... ] tri
[ `first^ ] [ `second^ ] [ `cursor^ ] tri

XPT map " [ ... ] map
[ `cursor^ ] map

XPT filter " [ ... ] filter
[ `cursor^ ] filter

XPT dip " [ ... ] dip
[ `cursor^ ] dip

XPT cleave " { [ ... ] ... } cleave
{ [ `code^ ]`...^
  [ `code^ ]`...^
} cleave

XPT when " [ ... ] when
[ `cursor^ ] when

XPT unless " [ ... ] unless
[ `cursor^ ] unless

XPT keep " [ ... ] keep
[ `cursor^ ] keep

XPT cond " { { [ ... ] [ ... ] } } cond
{ { [ `cond^ ] [ `code^ ] }`...^
  { [ `cond^ ] [ `code^ ] }`...^`default...{{^
  [ `cursor^ ]`}}^
} cond

XPT case " { { ... [ ... ] } } case
{ { `case^ [ `code^ ] }`...^
  { `case^ [ `code^ ] }`...^`default...{{^
  [ `cursor^ ]`}}^
} case

XPT test "[ ... ] [ ... ] unit-test
{ `ret^ } [ `test^ ] unit-test

