XPTemplate priority=lang

let s:f = g:XPTfuncs()

XPTinclude
      \ _common/common

XPT build
XSET x=Build("text_built")
-`x^=

XPT build-ph
XSET x=Build("-`ph_built^-")
-`x^=

XPT build-2ph
XSET x=Build("-`ph1^-`ph2^-")
-`x^=

XPT build-phgroup
XSET x=Build("-`ph1^-`ph1^-")
-`x^=

XPT build-ph-no-mixin
XSET x=Build("-`ph1^-`ph1^-")
-`x^-`ph1^-`ph1^=

XPT embed
XSET x=Embed("text_embed")
-`x^=

XPT embed-ph-no-mixin
XSET x=Embed("-`ph1^-`ph1^-")
-`x^-`ph1^-`ph1^=

