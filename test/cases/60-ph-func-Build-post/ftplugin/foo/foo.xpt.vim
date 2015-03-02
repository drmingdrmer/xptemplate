XPTemplate priority=lang

let s:f = g:XPTfuncs()

XPTinclude
      \ _common/common

" TODO build edge with ph

XPT build-post
XSET x|post=Build("text_built")
-`x^=

XPT build-post-ph
XSET x|post=Build("-`ph_built^-")
-`x^=

XPT build-post-2ph
XSET x|post=Build("-`ph1^-`ph2^-")
-`x^=

XPT build-post-phgroup
XSET x|post=Build("-`ph1^-`ph1^-")
-`x^=

XPT build-post-ph-no-mixin
XSET x|post=Build("-`ph1^-`ph1^-")
-`x^-`ph1^-`ph1^=

XPT plain-text-with-ph
XSET x|post=-`ph1^-
-`x^=
