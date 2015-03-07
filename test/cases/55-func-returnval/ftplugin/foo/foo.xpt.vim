XPTemplate priority=lang
let s:f = g:XPTfuncs()
XPTinclude
      \ _common/common

fun! s:f.Return(arg)
    return a:arg
endfunction


XPT return0
XSET a|pre=Return(0)
XSET b|def=Return(0)
XSET c|post=Return(0)
-`(left)`Return(0)`(right)^
-`(left)`a`(right)^
-`(left)`b`(right)^
-`(left)`c`(right)^
=
