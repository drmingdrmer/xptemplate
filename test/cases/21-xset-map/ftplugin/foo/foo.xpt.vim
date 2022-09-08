XPTemplate priority=lang

let s:f = g:XPTfuncs()

XPTinclude
      \ _common/common

XPT maps
XSET x|map=[ .br.
XSET y|map=( Echo('y_build')
XSET z|map=- Next()
-`x^-`y^-`z^-`w^=

XPT foo
-`x^=
