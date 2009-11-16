XPTemplate priority=like

XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL


" if () ** {
XPTvar $BRif     ' '

" } ** else {
XPTvar $BRel     \n



" int fun( ** arg ** )
XPTvar $SParg      ' '

" if ** (
XPTvar $SPif       ' '

" if ( ** condition ** )
XPTvar $SPcnd      ' '

" a = a ** + ** 1
XPTvar $SPop       ' '


XPTvar $VOID_LINE      /* void */;
XPTvar $CURSOR_PH      /* cursor */





" ================================= Snippets ===================================
XPTemplateDef

XPT _if hidden=1
if`$SPif^(`$SPcnd^`condition^`$SPcnd^)`$BRif^{
    `job^
}


XPT if hint=if\ (..)\ {..}\ else...
XSET job=$VOID_LINE
`Include:_if^` `else...{{^`$BRel^`Include:else^`}}^


XPT elif hint=else\ if\ \(\ ...\ )\ {\ ...\ }
XSET job=$VOID_LINE
else `Include:_if^


XPT else hint=else\ {\ ...\ }
else`$BRif^{
    `cursor^
}


XPT ifn  alias=if	hint=if\ ($NULL\ ==\ ..)\ {..}\ else...
XSET condition=Embed('`$NULL^`$SPop^==`$SPop^`var^')


XPT ifnn alias=if	hint=if\ ($NULL\ !=\ ..)\ {..}\ else...
XSET condition=Embed('`$NULL^`$SPop^!=`$SPop^`var^')


XPT if0  alias=if	hint=if\ (0\ ==\ ..)\ {..}\ else...
XSET condition=Embed('0`$SPop^==`$SPop^`var^')


XPT ifn0 alias=if	hint=if\ (0\ !=\ ..)\ {..}\ else...
XSET condition=Embed('0`$SPop^!=`$SPop^`var^')


XPT ifee	hint=if\ (..)\ {..}\ else\ if...
XSET job=$VOID_LINE
XSET another_cond=R('condition')
`Include:_if^` `else_if...^
XSETm else_if...|post
`$BRel^else if`$SPif^(`$SPcnd^`another_cond^`$SPcnd^)`$BRif^{
    `job^
}` `else_if...^
XSETm END


XPT switch	hint=switch\ (..)\ {case..}
switch (`$SParg^`var^`$SParg^)`$BRif^{
    `:case:^
`
    `case...`
    {{^
    `:case:^
`
    `case...`
^`}}^`
    `default...`{{^
    `:default:^`}}^
}
..XPT

XPT case " case ..:
XSET job=$VOID_LINE
case `constant^`$SPif^:
    `job^
    break;

XPT default " default ..:
default:
    `cursor^



" ================================= Wrapper ===================================


XPT if_ hint=if\ (..)\ {\ SEL\ }
if`$SPif^(`$SPcnd^`condition^`$SPcnd^)`$BRif^{
    `wrapped^
}


XPT else_ hint=else\ {\ SEL\ }
else`$BRif^{
    `wrapped^
}
