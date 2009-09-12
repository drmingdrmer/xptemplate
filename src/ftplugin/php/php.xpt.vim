XPTemplate priority=lang-

let s:f = XPTcontainer()[0]
 
XPTvar $TRUE          true
XPTvar $FALSE         false
XPTvar $NULL          null
XPTvar $UNDEFINED     null

XPTvar $VOID_LINE  /* void */
XPTvar $CURSOR_PH      /* cursor */

XPTvar $IF_BRACKET_STL     \ 
XPTvar $ELSE_BRACKET_STL   \n
XPTvar $FOR_BRACKET_STL    \ 
XPTvar $WHILE_BRACKET_STL  \ 
XPTvar $STRUCT_BRACKET_STL \ 
XPTvar $FUNC_BRACKET_STL   \ 

XPTvar $CL    /*
XPTvar $CM    *
XPTvar $CR    */

XPTinclude 
      \ _common/common
      \ _comment/doubleSign
      \ _condition/c.like
      \ _loops/c.while.like


" ========================= Function and Variables =============================

" ================================= Snippets ===================================
XPTemplateDef



XPT for hint=for\ (..;..;++)
for ($`i^ = `init^; $`i^ < `val^; $`i^++)`$FOR_BRACKET_STL^{
    `cursor^
}


XPT forr hint=for\ (..;..;--)
for ($`i^ = `init^; $`i^ >= `0^; $`i^--)`$FOR_BRACKET_STL^{
    `cursor^
}


XPT foreach hint=foreach\ (..\ as\ ..)\ {..}
foreach ($`var^ as `container^)`$FOR_BRACKET_STL^{
    `cursor^
}


XPT fun hint=function\ ..(\ ..\ )\ {..}
function `funName^( `params^ )`$FUNC_BRACKET_STL^{
    `cursor^
}


XPT class hint=class\ ..\ {\ ..\ }
class `className^`$FUNC_BRACKET_STL^{
    function __construct( `args^ )`$FUNC_BRACKET_STL^{
        `cursor^
    }
}


XPT interface hint=interface\ ..\ {\ ..\ }
interface `interfaceName^`$FUNC_BRACKET_STL^{
    `cursor^
}


" ================================= Wrapper ===================================
