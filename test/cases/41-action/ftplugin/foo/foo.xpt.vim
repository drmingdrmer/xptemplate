XPTemplate priority=lang

let s:f = g:XPTfuncs()

XPTinclude
      \ _common/common

fun! s:f.no_text()
    return { 'action': 'text' }
endfunction

fun! s:f.set_text(text)
    return { 'action': 'text', 'text':a:text }
endfunction

XPT def
XSET x|def=no_text()
XSET y|def=no_text()
-`x^-`y^=

XPT def-set
XSET x|def=set_text('x2')
XSET y|def=set_text('y2')
-`x^-`y^=

XPT post
XSET x|post=no_text()
XSET y|post=no_text()
-`x^-`y^=
