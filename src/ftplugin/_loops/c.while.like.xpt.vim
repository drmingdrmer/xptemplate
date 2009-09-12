XPTemplate priority=like



XPTvar $TRUE           1
XPTvar $FALSE          0
XPTvar $NULL           NULL

XPTvar $WHILE_BRACKET_STL  \ 


" ================================= Snippets ===================================
XPTemplateDef


XPT while hint=while\ \(\ ...\ )
while (`condition^)`$WHILE_BRACKET_STL^{
    `cursor^
}

XPT do hint=do\ {\ ..\ }\ while\ (..)
do`$WHILE_BRACKET_STL^{
    `cursor^
}`$WHILE_BRACKET_STL^while (`condition^);


XPT while0 alias=do hint=do\ {\ ..\ }\ while\ ($FALSE)
XSET condition|def=Embed( $FALSE )


XPT while1 alias=while hint=while\ ($TRUE)\ {\ ..\ }
XSET condition|def=Embed( $TRUE )


XPT whilenn alias=while hint=while\ \(\ $NULL\ !=\ var\ )\ {\ ..\ }
XSET condition|def=Embed( $NULL . ' != `var^' )



