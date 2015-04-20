XPTemplate priority=lang
let s:f = g:XPTfuncs()
XPTinclude
      \ _common/common

XPT origin " hint-origin
origin

XPT alias alias=origin
alias

XPT alias-redefined alias=origin " hint-redefined
alias-redefined

XPT def-var
XSET $a=it-is-a
`$a^
XPT alias-var alias=def-var
`$a^

XPT bar synonym=bar-syn " hint-bar
snippet-bar

XPT xx
xx-in-low
XPT alias-to-prior alias=origin


XPT _alias_low
alias-low
XPT alias-override-by-priority
not-alias-in-low
XPT override-alias-by-priority alias=_alias_low
