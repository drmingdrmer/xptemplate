XPTemplate priority=like-

" containers
let [s:f, s:v] = XPTcontainer()

XPTvar $TRUE          true
XPTvar $FALSE         false
XPTvar $NULL          null
XPTvar $BRACKETSTYLE  
XPTvar $INDENT_HELPER /* void */;

" ================================= Snippets ===================================
XPTemplateDef

XPT for hint=for\ i++
for (`int^ `i^ = `0^; `i^ < `len^; ++`i^) `$BRACKETSTYLE^{
    `cursor^
}

XPT forr hint=for\ i--
for (`int^ `i^ = `n^; `i^ >`=^ `end^; --`i^) `$BRACKETSTYLE^{
    `cursor^
}

