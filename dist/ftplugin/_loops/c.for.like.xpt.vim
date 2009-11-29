XPTemplate priority=like

let s:f = g:XPTfuncs()

XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL

XPTvar $VOID_LINE  /* void */;
XPTvar $CURSOR_PH      /* cursor */

XPTvar $BRif          ' '
XPTvar $BRloop        ' '
XPTvar $BRloop        ' '
XPTvar $BRstc         ' '




" ========================= Function and Variables =============================


" ================================= Snippets ===================================
XPTemplateDef


XPT for hint=for\ (..;..;++)
for (`i^ = `0^; `i^ < `len^; ++`i^)`$BRloop^{
    `cursor^
}


XPT forr hint=for\ (..;..;--)
for (`i^ = `n^; `i^ >`=^ `end^; --`i^)`$BRloop^{
    `cursor^
}


XPT forever hint=for\ (;;)\ ..
XSET body=$CL void $CR;
for (;;) `body^


