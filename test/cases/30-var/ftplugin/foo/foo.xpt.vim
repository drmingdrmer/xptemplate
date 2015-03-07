XPTemplate priority=lang

let s:f = g:XPTfuncs()

XPTinclude
      \ _common/common

XPTvar $FOO var-foo
XPTvar $BAR_QUOTE 'var-bar'

" variable in simple place holder is evaluated instantly and is converted to
" literal text.
XPT var-x
XSET $x=var-x
-before-`$x^-after-

" var in complete place holder is evaluated but place holder is not removed.
XPT var-x-edge
XSET $x=var-x-edge
-before-`=left=`$x`=right=^-after-

XPT var-x-alias alias=var-x
XSET $x=alias

XPT var-foo
`$FOO^

XPT var-bar-quote
`$BAR_QUOTE^

XPT var-as-linebreak
XSET $lb=\n
line1`$lb^line2

XPT edge-break
XSET $lb=\n
line1`$lb`x^line2
