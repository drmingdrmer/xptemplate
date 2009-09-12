XPTemplate priority=lang

let [s:f, s:v] = XPTcontainer() 
 
XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL
XPTvar $VOID_LINE /* void */;
XPTvar $IF_BRACKET_STL \n

XPTinclude 
      \ _common/common
      \ _common/personal


" ========================= Function and Variables =============================


" ================================= Snippets ===================================
XPTemplateDef


XPT try_ hint=try:\ SEL\ except...
try:
    `wrapped^
except `except^:
    `handler^`...^
except `exc^:
    `handle^`...^
`else...^else:
    \`\^^^
`finally...^finally:
   \`\^^^

