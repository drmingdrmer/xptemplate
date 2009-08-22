XPTemplate priority=lang

let [s:f, s:v] = XPTcontainer() 
 
XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL
XPTvar $INDENT_HELPER /* void */;
XPTvar $IF_BRACKET_STL \n

XPTinclude 
      \ _common/common


" ========================= Function and Variables =============================


" ================================= Snippets ===================================
XPTemplateDef 


XPT try_ hint=try\ {\ SEL\ }\ catch...
try
{
    `wrapped^
}` `catch...^
XSETm catch...|post

catch (`except^ `e^)
{
    `handler^
}` `catch...^
XSETm END
`finally...{{^finally
{
    `cursor^
}`}}^
