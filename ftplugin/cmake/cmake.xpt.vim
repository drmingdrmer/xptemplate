XPTemplate priority=lang

XPTinclude
    \ _common/common

" ================================= Snippets
XPTemplateDef
XPT if " if ( cond )...
if ( `cond^ )
    `cursor^
`else...{{^else( `cond^ )
`}}^endif( `cond^ )
..XPT

XPT foreach " foreach\(...) ... endofreach\( ... )
foreach (`varname^ `collection^)
    `cursor^
endforeach(`varname^)

XPT set " set\(... ...)
set(`varname^ `cursor^)

XPT msg " message\("...")
message("`cursor^")

XPT function " function\(...) ... endfunction\(...)
function(`funcName^ `params^)
    `cursor^
endfunction(`funcName^)

XPT macro " macro\(...) ... endmacro\(...)
macro( `macroName^ `params^ )
    `cursor^
endmacro( `macroName^ )

XPT while " while\(...) ... endwhile\(...)
while( `condition^ )
    `cursor^
enwhile( `condition^ )

