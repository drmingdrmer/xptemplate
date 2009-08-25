XPTemplate priority=lang keyword=#

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


XPT #if_ hint=#if\ ..\ SEL\ #endif
#if `cond^0^
`wrapped^`
`else...{{^#else
`cursor^`}}^
#endif

XPT if_ hint=if\ (..)\ {\ SEL\ }
if (`condition^) {
  `wrapped^
}

XPT invoke_ hint=..(\ SEL\ )
`name^(`wrapped^)

