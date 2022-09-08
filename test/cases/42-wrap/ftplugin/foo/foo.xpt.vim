XPTemplate priority=lang
let s:f = g:XPTfuncs()
XPTinclude
      \ _common/common

let s:i = 0
fun! s:f.GetIndex()
    let s:i = s:i + 1
    return s:i
endfunction

XPT wrapper wrap
left-`cursor^=right

XPT indent-wrapper wrap
left-
    `cursor^=right

XPT linenumber-wrapper wrap
`GetIndex() - `cursor` *^
