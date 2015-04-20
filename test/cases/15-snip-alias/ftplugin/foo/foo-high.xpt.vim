XPTemplate priority=sub
let s:f = g:XPTfuncs()
XPTinclude
      \ _common/common

XPT xx
xx-in-high
XPT alias-to-prior alias=xx


XPT _alias_high
alias-high
XPT alias-override-by-priority alias=_alias_high
XPT override-alias-by-priority
normal-in-high
