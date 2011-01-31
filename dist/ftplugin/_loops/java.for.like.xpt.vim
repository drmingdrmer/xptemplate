XPTemplate priority=like-

" containers
let s:f = g:XPTfuncs()

XPTvar $TRUE          true
XPTvar $FALSE         false
XPTvar $NULL          null
XPTvar $BRif
XPTvar $VOID_LINE /* void */;

" ================================= Snippets ===================================

XPT for " for i++
for`$SPcmd^(`$SParg^`int^ `i^`$SPop^=`$SPop^`0^; `i^`$SPop^<`$SPop^`len^; ++`i^`$SParg^)`$BRloop^{
    `cursor^
}

XPT forr "for i--
for`$SPcmd^(`$SParg^`int^ `i^`$SPop^=`$SPop^`n^; `i^`$SPop^>`=^`$SPop^`end^; --`i^`$SParg^)`$BRloop^{
    `cursor^
}

