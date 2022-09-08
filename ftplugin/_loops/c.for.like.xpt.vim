XPTemplate priority=like

XPTvar $BRloop        ' '

" int fun( ** arg ** )
" if ( ** condition ** )
" for ( ** statement ** )
" [ ** a, b ** ]
" { ** 'k' : 'v' ** }
XPTvar $SParg      ''

" if ** (
" while ** (
" for ** (
XPTvar $SPcmd      ' '

" a ** = ** a ** + ** 1
" (a, ** b, ** )
XPTvar $SPop       ' '

fun! s:f.c_strip_type()
    let v = self.ItemValue()
    echom v
    echom substitute(v, '\V\^\_.*\s', 'g')
    return substitute(v, '\V\^\_.*\s', 'g')
endfunction

XPT for wrap " for (..;..;++)
for`$SPcmd^(`$SParg^`i^`$SPop^=`$SPop^`0^; `i^c_strip_type()^`$SPop^<`$SPop^`len^; `i^c_strip_type()^++`$SParg^)`$BRloop^{
    `cursor^
}

XPT forr wrap " for (..;..;--)
for`$SPcmd^(`$SParg^`i^`$SPop^=`$SPop^`n^; `i^`$SPop^>`=$SPop`0^; `i^--`$SParg^)`$BRloop^{
    `cursor^
}

XPT forever " for (;;) ..
for`$SPcmd^(;;) `cursor^
