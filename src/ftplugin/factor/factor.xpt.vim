XPTemplate priority=lang

let s:f = g:XPTfuncs()

XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL

XPTinclude
    \ _common/common


" ========================= Function and Variables =============================

" ================================= Snippets ===================================
XPTemplateDef

XPT alias hint=ALIAS:\ ...\ ...
ALIAS: `newword^ `oldword^

XPT const hint=CONSTANT:\ ...\ ...
CONSTANT: `word^ `constantValue^

XPT word hint=:\ ...\ (\... --\ ...)
: `wordName^ ( `stackBefore^ -- `stackafter^ )
    `cursor^
    ;

XPT if hint=...\ [\ ...\ ]\ \[\ ...\ ]\ if
`cond^ [ `then^ ] [ `else^ ] if

XPT times hint=...\ [\ ...\ ]\ times
`count^ [ `what^ ] times

XPT test hint=[\ ...\ ]\ [\ ...\ ]\ unit-test
[ `ret^ ] [ `test^ ] unit-test

XPT header hint=USING\ ...\ IN\ ...
USING: `imports^ ;
IN: 

" ================================= Wrapper ===================================

