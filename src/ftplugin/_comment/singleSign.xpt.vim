XPTemplate priority=all-


" snippets for language whose comment sign is only 1 sign, like perl:"#"
"
" assuming only $CM defined
"
" TODO friendly cursor place holder


XPTinclude
      \ _comment/common


" ========================= Function and Variables =============================


" ================================= Snippets ===================================
XPTemplateDef

XPT comment hint=$CS\ ...
`$CS^ `cursor^


XPT commentBlock hint=$CS\ ...
`$CS^ `cursor^
`$CS^


XPT commentDoc hint=$CS\ ...
`$CS^
`$CS^ `cursor^
`$CS^

XPT commentLine hint=$CS\ ...
`$CS^ `cursor^

" ================================= Wrapper ===================================

XPT comment_ hint=$CS\ ...
`$CS^ `wrapped^

XPT commentLine_ hint=$CS\ ...
`$CS^ `wrapped^
