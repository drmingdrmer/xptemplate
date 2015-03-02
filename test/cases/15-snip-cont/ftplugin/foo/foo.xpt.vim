XPTemplate priority=lang

let s:f = g:XPTfuncs()

XPTinclude
      \ _common/common


XPT basic
basic
" comment

" comment
XPT in-mid-of-comment
in-mid-of-comment
" comment

XPT comment-in-body
" comment
 " comment
 " comment "
comment-in-body
" comment

XPT comment-only
" comment

XPT comment-at-last
" comment
..XPT

XPT xpt-tail
\..XPT

XPT xset-in-mid
XSET x=x-def
-`x^=

XPT xset-at-end
-`x^=
XSET x=x-def

XPT xset-2
XSET y=y-def
-`x^-`y^=
XSET x=x-def

XPT empty
XPT empty2
