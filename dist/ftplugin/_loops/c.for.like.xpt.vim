XPTemplate priority=like

let s:f = g:XPTfuncs() 
 
XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL

XPTvar $VOID_LINE  /* void */;
XPTvar $CURSOR_PH      /* cursor */

XPTvar $IF_BRACKET_STL     \ 
XPTvar $FOR_BRACKET_STL    \ 
XPTvar $WHILE_BRACKET_STL  \ 
XPTvar $STRUCT_BRACKET_STL \ 




" ========================= Function and Variables =============================


" ================================= Snippets ===================================
XPTemplateDef


XPT for hint=for\ (..;..;++)
for (`i^ = `0^; `i^ < `len^; ++`i^)`$FOR_BRACKET_STL^{
    `cursor^
}


XPT forr hint=for\ (..;..;--)
for (`i^ = `n^; `i^ >`=^ `end^; --`i^)`$FOR_BRACKET_STL^{
    `cursor^
}


XPT forever hint=for\ (;;)\ ..
XSET body=$CL void $CR;
for (;;) `body^


