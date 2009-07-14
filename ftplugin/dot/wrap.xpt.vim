if exists("b:__DOT_WRAP_XPT_VIM__") 
    finish 
endif
let b:__DOT_WRAP_XPT_VIM__ = 1 

" containers
let [s:f, s:v] = XPTcontainer() 

" inclusion
XPTinclude
    \ _common/common

" ========================= Function and Variables =============================


" ================================= Snippets ===================================
XPTemplateDef 

XPT subgraph_ hint=subgraph\ ..\ {\ SEL\ }
subgraph `clusterName^
{
    `wrapped^
}
..XPT

