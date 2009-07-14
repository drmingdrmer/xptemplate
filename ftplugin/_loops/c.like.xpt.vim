XPTemplate priority=like


XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $BRACKETSTYLE  
XPTvar $INDENT_HELPER /* void */;


XPTinclude
      \ _loops/c.for.like



" ================================= Snippets ===================================
XPTemplateDef

XPT while0 hint=do\ {\ ..\ }\ while\ ($FALSE)
do `$BRACKETSTYLE^{
  `cursor^
} `$BRACKETSTYLE^while (`$FALSE^)


XPT do hint=do\ {\ ..\ }\ while\ (..)
do `$BRACKETSTYLE^{
  `cursor^
} `$BRACKETSTYLE^while (`condition^)


XPT while1 hint=while\ ($TRUE)\ {\ ..\ }
while (`$TRUE^) `$BRACKETSTYLE^{
  `cursor^
}


