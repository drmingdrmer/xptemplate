XPTemplate priority=lang

let s:f = g:XPTfuncs()

XPTinclude
      \ _common/common

XPT come
XSET ComeFirst=y x
XSET ComeLast=v u
-`x^-`y^-`u^-`v^=

XPT container
XSET ComeFirst=y x
XSET ComeLast=v u
XSET inc|post=BuildSnippet("sub")
-`x^-`inc^-`y^-`u^-`v^=

XPT def-container
XSET ComeFirst=y x
XSET ComeLast=v u
XSET inc=BuildSnippet("sub")
-`x^-`inc^-`y^-`u^-`v^=

XPT sub
XSET ComeFirst=b a
(-`a^-`b^=)
