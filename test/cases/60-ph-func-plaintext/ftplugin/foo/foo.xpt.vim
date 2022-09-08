XPTemplate priority=lang
let s:f = g:XPTfuncs()
XPTinclude
      \ _common/common

XPT text
`plaintext^

XPT echo-text-without-mark
`Echo("echoed")^

XPT echo-text-and-Echo
`before{Echo("(echoed)")}after^

XPT build-text-with-mark
XSET a=Build('`ph^-`ph^=')
`a^

XPT build-text-and-Build
XSET a=`ph^={Build('`ph^-`ph^=')}
`a^
