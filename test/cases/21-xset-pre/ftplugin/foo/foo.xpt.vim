XPTemplate priority=lang
let s:f = g:XPTfuncs()
XPTinclude
      \ _common/common

XPT pre-indent
XSET x|pre=BuildSnippet("sub")
-`what^-`x^=

XPT sub
    l1-1-indent
l2-0-indent
        l3-2-indent(`ph_in_sub_snippet_is_not_built^)
