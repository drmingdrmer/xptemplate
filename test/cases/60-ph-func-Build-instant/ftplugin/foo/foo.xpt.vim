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

XPT build-ph
-`Build('\`ph\^')^-

XPT build-ph-group
-`\`ph\^-`Build('\`ph\^-\`ph\^')^-

