XPTemplate priority=like

XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL


" if () ** {
XPTvar $BRif     ' '

" } ** else {
XPTvar $BRel     \n



" int fun( ** arg ** )
" if ( ** condition ** )
XPTvar $SParg      ' '

" if ** (
XPTvar $SPcmd       ' '

" a = a ** + ** 1
XPTvar $SPop       ' '


XPTvar $VOID_LINE      /* void */;
XPTvar $CURSOR_PH      /* cursor */





" ================================= Snippets ===================================
XPTemplateDef

XPT _if hidden=1
XSET job=$VOID_LINE
if`$SPcmd^(`$SParg^`condition^`$SParg^)`$BRif^{
    `job^
}


XPT if hint=if\ (..)\ {..}\ else...
`Include:_if^` `else...{{^`$BRel^`Include:else^`}}^


XPT elif hint=else\ if\ \(\ ...\ )\ {\ ...\ }
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
`Include:_if^` `else_if...{{^`$BRel^`Include:elif^` `else_if...^`}}^


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
case `constant^`$SPcmd^:
    `job^
    break;

XPT default " default ..:
default:
    `cursor^



" ================================= Wrapper ===================================


XPT if_ hint=if\ (..)\ {\ SEL\ }
if`$SPcmd^(`$SParg^`condition^`$SParg^)`$BRif^{
    `wrapped^
}


XPT else_ hint=else\ {\ SEL\ }
else`$BRif^{
    `wrapped^
}
