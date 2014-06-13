XPTemplate priority=lang

let s:f = g:XPTfuncs()

XPTinclude
      \ _common/common

" expression is not selectable
XPT build-instant
-`Build("x")^-

" expression is not selectable
XPT build-instant-edge
-`left=`Build("x")`=right^-

" expression is not selectable
XPT build-instant-edge-expr
-`Build("x")`Build("y")`Build("z")^-

" TODO fix this: ph should be converted to place holder
XPT build-ph
-`Build('\`ph\^')^-

" TODO build edge with ph

" post, ontype, edge, etc
