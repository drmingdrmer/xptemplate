XPTemplate priority=spec

let [s:f, s:v] = XPTcontainer() 
 
XPTvar $TRUE          true
XPTvar $FALSE         false
XPTvar $NULL          null
XPTvar $UNDEFINED     undefined
XPTvar $VOID_LINE /* void */;
XPTvar $IF_BRACKET_STL \n

XPTinclude 
      \ _common/common
      \ _condition/c.like


" ========================= Function and Variables =============================


" ================================= Snippets ===================================
XPTemplateDef


XPT ifu		hint=if\ (undefined\ ===\ ..)\ {..} ..
XSET job=$VOID_LINE
if (`$UNDEFINED^ === `var^) {
  `job^
}`
`else...{{^
else {
  `cursor^
}`}}^


XPT ifnu 	hint=if\ (undefined\ !==\ ..)\ {..} ..
XSET job=$VOID_LINE
if (`$UNDEFINED^ !== `var^) {
  `job^
}`
`else...{{^
else {
  `cursor^
}`}}^

