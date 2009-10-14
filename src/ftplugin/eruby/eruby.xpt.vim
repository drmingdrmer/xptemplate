XPTemplate priority=lang

let s:f = g:XPTfuncs() 

XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL

XPTvar $IF_BRACKET_STL     ' '
XPTvar $ELSE_BRACKET_STL   \n
XPTvar $FOR_BRACKET_STL    ' '
XPTvar $WHILE_BRACKET_STL  ' '
XPTvar $STRUCT_BRACKET_STL ' '
XPTvar $FUNC_BRACKET_STL   ' '

XPTinclude 
    \ _common/common
    \ html/html
    \ html/eruby

XPTembed
    \ ruby/ruby
    \ javascript/javascript
    \ css/css

" ========================= Function and Variables =============================

" ================================= Snippets ===================================
XPTemplateDef




" ================================= Wrapper ===================================

