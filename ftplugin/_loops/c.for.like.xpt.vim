XPTemplate priority=like


XPTvar $BRloop        ' '

" int fun( ** arg ** )
" if ( ** condition ** )
" for ( ** statement ** )
" [ ** a, b ** ]
" { ** 'k' : 'v' ** }
XPTvar $SParg      ' '

" if ** (
" while ** (
" for ** (
XPTvar $SPcmd      ' '

" a ** = ** a ** + ** 1
" (a, ** b, ** )
XPTvar $SPop       ' '



XPT for wrap " for (..;..;++)
for`$SPcmd^(`$SParg^`i^`$SPop^=`$SPop^`0^; `i^`$SPop^<`$SPop^`len^; `i^++`$SParg^)`$BRloop^{
    `cursor^
}


XPT forr wrap " for (..;..;--)
for`$SPcmd^(`$SParg^`i^`$SPop^=`$SPop^`n^; `i^`$SPop^>`=$SPop`0^; `i^--`$SParg^)`$BRloop^{
    `cursor^
}


XPT forever " for (;;) ..
for`$SPcmd^(;;) `cursor^
