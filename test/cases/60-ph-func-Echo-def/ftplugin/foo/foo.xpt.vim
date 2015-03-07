XPTemplate priority=lang

let s:f = g:XPTfuncs()

XPTvar $FOO foo

XPTinclude
      \ _common/common

" TODO build edge with ph

XPT basic
XSET x=Echo("echo")
-`x^=

XPT func_and_var
XSET x=Echo("$FOO-tr('aaa','a','b')")
-`x^=

XPT escape
XSET x=Echo( "\"\'" . '\"' )
-`x^=

XPT slave
XSET x=Echo("echo")
-`x^=`x^=

XPT ph-not-built
XSET x=Echo( "`ph1^" )
-`x^=

XPT args
XSET x=Echo( $FOO . tr('aaa','a','b') )
-`x^=
