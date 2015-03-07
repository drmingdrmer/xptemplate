XPTemplate priority=lang

let s:f = g:XPTfuncs()

XPTvar $FOO foo

XPTinclude
      \ _common/common

" TODO build edge with ph

XPT basic
-`Echo( "echo" . $FOO )^=

XPT edge
-`Echo( "left" )`Echo( "x" )`Echo( "right" )^=

XPT escape
-`Echo( "\"\'" . '\"' )^=

XPT ph-not-built
-`Echo( "\`ph1\^" )^=
