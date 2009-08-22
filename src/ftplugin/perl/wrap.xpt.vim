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


XPT if_ hint=if\ (..)\ {\ SEL\ }\ ...
if ( `cond^ )
{
    `wrapped^
}`
`elif...{{^
elif ( `cond2^ )
{
    `body^
}`}}^`
`else...^
else
{
    \`body\^
}^^


