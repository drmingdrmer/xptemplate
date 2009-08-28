XPTemplate priority=like



XPTvar $TRUE           1
XPTvar $FALSE          0
XPTvar $NULL           NULL

XPTvar $IF_BRACKET_STL     \ 
XPTvar $FOR_BRACKET_STL    \ 
XPTvar $WHILE_BRACKET_STL  \ 
XPTvar $STRUCT_BRACKET_STL \ 


XPTinclude
      \ _loops/c.for.like



" ================================= Snippets ===================================
XPTemplateDef


XPT while hint=while\ \\(\ ...\ )
while (`cond^)`$WHILE_BRACKET_STL^{
    `cursor^
}


XPT while0 hint=do\ {\ ..\ }\ while\ ($FALSE)
do`$WHILE_BRACKET_STL^{
    `cursor^
}`$WHILE_BRACKET_STL^while (`$FALSE^)


XPT do hint=do\ {\ ..\ }\ while\ (..)
do`$WHILE_BRACKET_STL^{
    `cursor^
}`$WHILE_BRACKET_STL^while (`condition^)


XPT while1 hint=while\ ($TRUE)\ {\ ..\ }
while (`$TRUE^)`$WHILE_BRACKET_STL^{
    `cursor^
}


