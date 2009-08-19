XPTemplate priority=like


XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $IF_BRACKET_STL  \ 
XPTvar $INDENT_HELPER /* void */;


XPTinclude
      \ _loops/c.for.like



" ================================= Snippets ===================================
XPTemplateDef

XPT while0 hint=do\ {\ ..\ }\ while\ ($FALSE)
do`$IF_BRACKET_STL^{
  `cursor^
}`$IF_BRACKET_STL^while (`$FALSE^)


XPT do hint=do\ {\ ..\ }\ while\ (..)
do`$IF_BRACKET_STL^{
  `cursor^
}`$IF_BRACKET_STL^while (`condition^)


XPT while1 hint=while\ ($TRUE)\ {\ ..\ }
while (`$TRUE^)`$IF_BRACKET_STL^{
  `cursor^
}


