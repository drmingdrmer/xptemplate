XPTemplate priority=lang
let s:f = g:XPTfuncs()
XPTinclude
      \ _common/common

XPT wrapper wrap
left-`cursor^=right

XPT indent-wrapper wrap
left-
    `cursor^=right
