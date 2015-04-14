XPTemplate priority=lang
let s:f = g:XPTfuncs()
XPTinclude
      \ _common/common

XPT f " hint-f
f-snip

XPT foo " hint-foo
`ph1^-`ph2^=

XPT foobar " hint-foobar
foobar
