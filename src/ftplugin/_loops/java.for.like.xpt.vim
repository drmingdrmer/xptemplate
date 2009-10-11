XPTemplate priority=like-

" containers
let s:f = g:XPTfuncs() 

XPTvar $TRUE          true
XPTvar $FALSE         false
XPTvar $NULL          null
XPTvar $IF_BRACKET_STL  
XPTvar $VOID_LINE /* void */;

" ================================= Snippets ===================================
XPTemplateDef

XPT for hint=for\ i++
for (`int^ `i^ = `0^; `i^ < `len^; ++`i^) `$IF_BRACKET_STL^{
    `cursor^
}

XPT forr hint=for\ i--
for (`int^ `i^ = `n^; `i^ >`=^ `end^; --`i^) `$IF_BRACKET_STL^{
    `cursor^
}

