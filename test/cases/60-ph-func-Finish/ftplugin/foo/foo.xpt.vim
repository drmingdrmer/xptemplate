XPTemplate priority=lang
let s:f = g:XPTfuncs()
XPTinclude
      \ _common/common

fun! s:f.FininshWhen(str)
    if self.ItemValue() =~ a:str
        return self.Finish()
    end
    return 0
endfunction

XPT finish-def
XSET a=Finish()
`a^=

XPT finish-def-text
XSET a=Finish('foo')
`a^=

XPT finish-def-indent
XSET a=Finish('line-1\n    line-2')
    `a^=

XPT finish-def-tab-indent
XSET a=Finish('line-1\n	line-2')
    `a^=

XPT finish-def-indent-3sp
XSET a=Finish('line-1\n   line-2')
    `a^=

XPT finish-def-indent-after-3sp
XSET a=Finish('line-1\n    line-2')
   `a^=


" edge
XPT finish-edge-def " by default innerMarks
XSET a=Finish('line-1\n    line-2')
    `x`a`x^=

XPT finish-edge-inner-def
XSET a=FinishInner('line-1\n    line-2')
    `x`a`x^=

XPT finish-edge-outer-def
XSET a=FinishOuter('line-1\n    line-2')
    `x`a`x^=


" post filter
XPT finish-post-no-arg
XSET a|post=Finish()
    `[`a`]^=

XPT finish-post-string " post filter use marks by default
XSET a|post=Finish('line-1\n    line-2')
    `[`a`]^=

XPT finish-post-string-inner
XSET a|post=FinishInner('line-1\n    line-2')
    `[`a`]^=

XPT finish-post-string-outer " post filter use marks
XSET a|post=FinishOuter('line-1\n    line-2')
    `[`a`]^=

" ontype
XPT finish-ontype
XSET a|ontype=FininshWhen('c')
`[`a`]^=
