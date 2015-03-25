XPTemplate priority=lang

let s:f = g:XPTfuncs()

XPTinclude
      \ _common/common

XPT basic
XSET x|post=BuildIfNoChange( '`ph-built^' )
-`x^=

XPT with-def
XSET x|def=x2
XSET x|post=BuildIfNoChange( '`ph-built^' )
-`x^=

XPT with-edge
XSET x|def=x2
XSET x|post=BuildIfNoChange( '`ph-built^' )
-`Echo( "left." )`x`Echo( ".right" )^=
