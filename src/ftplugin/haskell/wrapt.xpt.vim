XPTemplate priority=lang mark=`~

let s:f = g:XPTfuncs()

XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL
XPTvar $VOID_LINE /* void */;
XPTvar $BRif \n

XPTinclude
      \ _common/common


" ========================= Function and Variables =============================


" ================================= Snippets ===================================
XPTemplateDef


XPT str_ hint="SEL"
"`wrapped~"

XPT cmt_ hint={-\ SEL\ -}
{-
`wrapped~
-}

XPT p_ hint=(\ SEL\ )
(`wrapped~)

