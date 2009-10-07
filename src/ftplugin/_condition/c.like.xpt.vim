XPTemplate priority=like

XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL

XPTvar $IF_BRACKET_STL  \ 
XPTvar $ELSE_BRACKET_STL   \n

XPTvar $VOID_LINE  /* void */;
XPTvar $CURSOR_PH      /* cursor */





" ================================= Snippets ===================================
XPTemplateDef

XPT if		hint=if\ (..)\ {..}\ else...
XSET job=$VOID_LINE
if (`condition^)`$IF_BRACKET_STL^{ 
    `job^
}` `else...{{^`$ELSE_BRACKET_STL^`Include:else^`}}^


XPT elif hint=else\ if\ \(\ ...\ )\ {\ ...\ }
XSET job=$VOID_LINE
else if (`condition^)`$IF_BRACKET_STL^{
    `job^
}


XPT else hint=else\ {\ ...\ }
else`$IF_BRACKET_STL^{
    `cursor^
}


XPT ifn  alias=if	hint=if\ ($NULL\ ==\ ..)\ {..}\ else...
XSET condition=Embed('`$NULL^ == `var^')


XPT ifnn alias=if	hint=if\ ($NULL\ !=\ ..)\ {..}\ else...
XSET condition=Embed('`$NULL^ != `var^')


XPT if0  alias=if	hint=if\ (0\ ==\ ..)\ {..}\ else...
XSET condition=Embed('0 == `var^')


XPT ifn0 alias=if	hint=if\ (0\ !=\ ..)\ {..}\ else...
XSET condition=Embed('0 != `var^')


XPT ifee	hint=if\ (..)\ {..}\ elseif...
XSET job=$VOID_LINE
XSET another_cond=R('condition')
if (`condition^)`$IF_BRACKET_STL^{
    `job^
}` `else_if...^
XSETm else_if...|post
`$IF_BRACKET_STL^else if (`another_cond^)`$IF_BRACKET_STL^{
    `job^
}` `else_if...^
XSETm END


XPT switch	hint=switch\ (..)\ {case..}
XSET job=$VOID_LINE
switch (`var^)`$IF_BRACKET_STL^{
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
^
XSETm END
XSETm default...|post

    default:
        `cursor^
XSETm END
..XPT




" ================================= Wrapper ===================================


XPT if_ hint=if\ (..)\ {\ SEL\ }
if (`condition^)`$IF_BRACKET_STL^{
    `wrapped^
}


XPT else_ hint=else\ {\ SEL\ }
else`$IF_BRACKET_STL^{
    `wrapped^
}
