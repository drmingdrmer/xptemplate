XPTemplate priority=lang
let s:f = g:XPTfuncs()
XPTinclude
      \ _common/common

fun! s:f.l()
    return '(left)'
endfunction

fun! s:f.r()
    return '(right)'
endfunction

fun! s:f.t()
    return 'T'
endfunction


XPT one-ph
-`t()^=

XPT edge-only-is-not-instant
-`l()`x`r()^=

XPT with-edge-3func
-`l()`t()`r()^=

XPT not-confused
-`x`t()x`r()^=

XPT action
-`(text)`Echo("ok")^=
