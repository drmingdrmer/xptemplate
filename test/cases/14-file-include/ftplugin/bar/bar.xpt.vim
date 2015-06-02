XPTemplate priority=lang-
let s:f = g:XPTfuncs()

XPTvar $FooVar FooVar

fun! s:f.FooFunc()
    return 'FooFunc'
endfunction

XPTinclude
      \ _common/common

XPT foo
foo-in-bar
