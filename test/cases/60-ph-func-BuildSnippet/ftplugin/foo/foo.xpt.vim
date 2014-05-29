XPTemplate priority=lang

let s:f = g:XPTfuncs()

XPTinclude
      \ _common/common

XPT snip_a
this-is-a:`a^

XPT snip_b hidden
this-is-b:`b^

XPT snip_pum hidden
XSET pum=Choose(["foo", "for"])
this-is-pum:`pum^

XPT test_post
XSET x|post=BuildSnippet( V() )
-`x^=

XPT test_initval
XSET x=BuildSnippet( 'snip_a' )
-`x^=

XPT test_post_with_setting
XSET x|post=BuildSnippet( "snip_pum" )
-`x^=
