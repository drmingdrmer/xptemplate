if exists("b:__LEX_XPT_VIM__") 
    finish 
endif
let b:__LEX_XPT_VIM__ = 1 

" inclusion
XPTinclude
    \ _common/common
    \ c/c

XPTemplateDef
XPT lex hint=Basic\ lex\ file
%{
/* includes */
%}
/* options */
%%
/* rules */
%%
/* C code */


XPT ruleList hint=..\ \ {..}\ ...
`reg^           { `return^ }`...^
`reg^           { `return^ }`...^



" ================================= Wrapper ===================================

XPT rule_ hint=SEL\ \ {\ ...\ }
`wrapped^       { `cursor^ }

