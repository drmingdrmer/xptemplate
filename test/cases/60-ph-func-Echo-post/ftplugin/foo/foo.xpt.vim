XPTemplate priority=lang

let s:f = g:XPTfuncs()

XPTvar $FOO foo

XPTinclude
      \ _common/common

" TODO build edge with ph

XPT basic
XSET x|post=Echo("echo")
-`x^=

XPT func_and_var
XSET x|post=Echo("$FOO-tr('aaa','a','b')")
-`x^=

XPT escape
XSET x|post=Echo( "\"\'" . '\"' )
-`x^=

XPT slave
XSET x|post=Echo("echo")
-`x^=`x^=

XPT ph-not-built
XSET x|post=Echo( "`ph1^" )
-`x^=

XPT args
XSET x|post=Echo( $FOO . tr('aaa','a','b') )
-`x^=
