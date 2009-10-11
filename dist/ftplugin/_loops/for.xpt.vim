"
" standard for( i = 0; i < 10; ++i ) snippets
"

XPTemplate priority=all-

let s:f = g:XPTfuncs() 
 
XPTvar $NULL            NULL
XPTvar $CURSOR_PH       CURSOR
XPTvar $FOR_BRACKET_STL ' '

XPTvar $VAR_PRE 
XPTvar $FOR_SCOPE 

XPTinclude 
      \ _common/common


" ========================= Function and Variables =============================

" ================================= Snippets ===================================
XPTemplateDef



XPT for hint=for\ (..;..;++)
for ( `$FOR_SCOPE^`$VAR_PRE^`i^ = `0^; `$VAR_PRE^`i^ < `len^; ++`$VAR_PRE^`i^ )`$FOR_BRACKET_STL^{
    `cursor^
}


XPT forr hint=for\ (..;..;--)
for ( `$FOR_SCOPE^`$VAR_PRE^`i^ = `0^; `$VAR_PRE^`i^ >`=^ `end^; --`$VAR_PRE^`i^ )`$FOR_BRACKET_STL^{
    `cursor^
}


XPT fornn hint=for\ \(\ ;\ $NULL\ !=\ var;\ )
XSET ptrOp=R( 'ptr' )
for ( `$FOR_SCOPE^`$VAR_PRE^`ptr^ = `init^; `$NULL^ != `$VAR_PRE^`ptr^; `$VAR_PRE^`ptrOp^ )`$FOR_BRACKET_STL^{
    `cursor^
}


XPT forever hint=for\ (;;)\ ..
XSET body|pre=VoidLine()
for (;;) `body^

" ================================= Wrapper ===================================


