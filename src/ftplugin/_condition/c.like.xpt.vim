XPTemplate priority=like

XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $BRACKETSTYLE  \ 
XPTvar $INDENT_HELPER /* void */;


" ================================= Snippets ===================================
XPTemplateDef

XPT if		hint=if\ (..)\ {..}\ else...
XSET job=$INDENT_HELPER
if (`condition^)`$BRACKETSTYLE^{ 
  `job^
}` `else...^
XSETm else...|post
`$BRACKETSTYLE^else`$BRACKETSTYLE^{ 
  `cursor^
}
XSETm END

XPT ifn  alias=if	hint=if\ ($NULL\ ==\ ..)\ {..}\ else...
XSET condition=Embed('`$NULL^ == `var^')

XPT ifnn alias=if	hint=if\ ($NULL\ !=\ ..)\ {..}\ else...
XSET condition=Embed('`$NULL^ != `var^')

XPT if0  alias=if	hint=if\ (0\ ==\ ..)\ {..}\ else...
XSET condition=Embed('0 == `var^')

XPT ifn0 alias=if	hint=if\ (0\ !=\ ..)\ {..}\ else...
XSET condition=Embed('0 != `var^')

XPT ifee	hint=if\ (..)\ {..}\ elseif...
XSET job=$INDENT_HELPER
XSET another_cond=R('condition')
if (`condition^)`$BRACKETSTYLE^{
  `job^
}` `else_if...^
XSETm else_if...|post
`$BRACKETSTYLE^else if (`another_cond^)`$BRACKETSTYLE^{ 
  `job^
}` `else_if...^XSETm END


XPT switch	hint=switch\ (..)\ {case..}
XSET job=$INDENT_HELPER
switch (`var^)`$BRACKETSTYLE^{
  case `constant^ :
    `job^
    break;
`
  `case...`
^`
  `default...^
}
XSETm case...|post

  case `constant^ :
    `job^
    break;
`
  `case...`
^XSETm END
XSETm default...|post

  default:
    `cursor^XSETm END

