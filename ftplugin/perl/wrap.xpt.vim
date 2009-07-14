if exists("b:__PERL_WRAP_XPT_VIM__") 
    finish 
endif
let b:__PERL_WRAP_XPT_VIM__ = 1 

" containers
let [s:f, s:v] = XPTcontainer() 

" inclusion
XPTinclude
    \ _common/common

" ========================= Function and Variables =============================


" ================================= Snippets ===================================
XPTemplateDef 
XPT if_ hint=if\ (..)\ {\ SEL\ }\ ...
if ( `cond^ )
{
    `wrapped^
}`...^
elif ( `cond2^ )
{
    `body^
}`...^`else...^
else
{
    \`body\^
}^^


