XPTemplate priority=lang
let s:f = g:XPTfuncs()

XPTinclude
      \ _common/common
      \ bar/bar
      \ bar/differentmark

XPTvar $FooVar should-be-overrided

XPT foo
foo-in-foo

XPT bar " tips
bar-in-foo

XPT alias-foo alias=foo " tips

XPT call-func-in-bar " tips
`FooFunc()^

XPT call-var-in-bar " tips
`$FooVar^
