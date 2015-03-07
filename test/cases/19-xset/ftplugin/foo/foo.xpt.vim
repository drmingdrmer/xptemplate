XPTemplate priority=lang

let s:f = g:XPTfuncs()

XPTinclude
      \ _common/common

XPT pre-basic
XSET x|pre=a
XSET y|pre=b
-`x^-`y^=

XPT pre-and-def
XSET x|pre=x-pre
XSET y|pre=y-pre
XSET y=y-def
-`x^-`y^=

XPT def
XSET x=x-def
-`x^=

XPT def-as-pre
XSET x|def=x-def
XSET y|def=y-def
XSET y|pre=y-pre
-`x^-`y^=

XPT pre-use-def
XSET y|def=y-def
-`x^-`y^=

