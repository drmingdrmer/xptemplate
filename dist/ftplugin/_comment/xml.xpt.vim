XPTemplate priority=spec keyword=<

let s:f = g:XPTfuncs() 
 
XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL
XPTvar $VOID_LINE /* void */;
XPTvar $IF_BRACKET_STL \n
XPTvar $CL <!--
XPTvar $CR -->


XPTinclude 
      \ _comment/pattern


" ========================= Function and Variables =============================


" ================================= Snippets ===================================
XPTemplateDef
