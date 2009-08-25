XPTemplate priority=spec keyword=<

let [s:f, s:v] = XPTcontainer() 
 
XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL
XPTvar $INDENT_HELPER /* void */;
XPTvar $IF_BRACKET_STL \n
XPTvar $CL <!--
XPTvar $CR -->


XPTinclude 
      \ _comment/pattern


" ========================= Function and Variables =============================


" ================================= Snippets ===================================
XPTemplateDef 
