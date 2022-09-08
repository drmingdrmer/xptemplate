XPTemplate priority=lang
let s:f = g:XPTfuncs()
XPTinclude
      \ _common/common

fun! s:f.DotRemove()
    if self.V() =~ '\V.'
        return self.Remove()
    else
        return 0
    endif
endfunction

XPT pre
XSET x|pre=Remove()
(`x^)

XPT def
XSET x=Remove()
(`x^)

XPT post
XSET x|post=Remove()
(`x^)

XPT ontype
XSET x|ontype=DotRemove()
(`x^)
