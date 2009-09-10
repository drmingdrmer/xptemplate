XPTemplate priority=all-

let s:f = XPTcontainer()[0]
 
XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL

XPTvar $INDENT_HELPER  /* void */;
XPTvar $CURSOR_PH      cursor

XPTvar $IF_BRACKET_STL     \ 
XPTvar $ELSE_BRACKET_STL   \n
XPTvar $FOR_BRACKET_STL    \ 
XPTvar $WHILE_BRACKET_STL  \ 
XPTvar $STRUCT_BRACKET_STL \ 
XPTvar $FUNC_BRACKET_STL   \ 

XPTinclude 
      \ _common/common


" ========================= Function and Variables =============================

" ================================= Snippets ===================================
XPTemplateDef



XPT for hint=for\ (..;..;++)
for (`$VAR_PRE^`i^ = `0^; `$VAR_PRE^`i^ < `len^; ++`$VAR_PRE^`i^)`$FOR_BRACKET_STL^{
    `cursor^
}


XPT forr hint=for\ (..;..;--)
for (`$VAR_PRE^`i^ = `n^; `$VAR_PRE^`i^ >`=^ `end^; --`$VAR_PRE^`i^)`$FOR_BRACKET_STL^{
    `cursor^
}


XPT forever hint=for\ (;;)\ ..
XSET body=$CL void $CR;
for (;;) `body^

" ================================= Wrapper ===================================

