XPTemplate priority=lang-

let s:f = g:XPTfuncs() 
 
XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL

XPTvar $VOID_LINE      /* void */;
XPTvar $CURSOR_PH      /* cursor */

XPTvar $IF_BRACKET_STL     \ 
XPTvar $ELSE_BRACKET_STL   \n
XPTvar $FOR_BRACKET_STL    \ 
XPTvar $WHILE_BRACKET_STL  \ 
XPTvar $STRUCT_BRACKET_STL \ 
XPTvar $FUNC_BRACKET_STL   \ 


XPTinclude 
    \ _common/common
    \ c/c


" ========================= Function and Variables =============================

" ================================= Snippets ===================================
XPTemplateDef


XPT yacc hint=Basic\ yacc\ file
%{
/* includes */
%}
/* options */
%%
/* grammar rules */
%%
/* C code */

XPT rule hint=..:\ ..\ |\ ..\ |\ ...
`ruleName^: `pattern^   { `action^ }
`        `...`
{{^        | `pattern^   { `action^ }
`        `...`
^`}}^        ;

XPT tok hint=%token\ ...
%token 

XPT prio hint=%left\ ...\ %right\ ...
XSET op*|post=ExpandIfNotEmpty( "' '", 'op*', "" )
%left   '`op*^'` `...^
%left   '`op*^'` `...^


