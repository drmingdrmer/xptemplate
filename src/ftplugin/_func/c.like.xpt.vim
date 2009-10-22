XPTemplate priority=like

let s:f = g:XPTfuncs() 
 
XPTvar $TRUE           1
XPTvar $FALSE          0
XPTvar $NULL           NULL

XPTvar $IF_BRACKET_STL     \ 
XPTvar $FOR_BRACKET_STL    \ 
XPTvar $WHILE_BRACKET_STL  \ 
XPTvar $STRUCT_BRACKET_STL \ 
XPTvar $FUNC_BRACKET_STL   \n

XPTvar $VOID_LINE      /* void */;
XPTvar $CURSOR_PH      /* cursor */

XPTvar $CL  /*
XPTvar $CM   *
XPTvar $CR   */
XPTinclude 
      \ _common/common


" ========================= Function and Variables =============================

fun! s:f.c_fun_type_indent()
  if self[ '$FUNC_BRACKET_STL' ] == "\n"
    return repeat( ' ', &softtabstop == 0 ? &tabstop : &softtabstop )
  else
    return ""
  endif
endfunction

fun! s:f.c_fun_body_indent()
  if self[ '$FUNC_BRACKET_STL' ] == "\n"
    return repeat( ' ', &softtabstop == 0 ? &tabstop : &softtabstop ). "\n\n"
    " return "    \n\n"
  else
    return " "
  endif
endfunction

" ================================= Snippets ===================================
XPTemplateDef



XPT main hint=main\ (argc,\ argv)
`c_fun_type_indent()^int`c_fun_body_indent()^main(int argc, char **argv)`$FUNC_BRACKET_STL^{
    `cursor^
    return 0;
}
..XPT

XPT fun 	hint=func..\ (\ ..\ )\ {...
XSET param|def=$CL no parameters $CR
XSET param|post=Echo( V() == $CL . " no parameters " . $CR ? '' : V() )
`c_fun_type_indent()^`int^`c_fun_body_indent()^`name^(`param^)`$FUNC_BRACKET_STL^{
    `cursor^
}



" ================================= Wrapper ===================================

XPT fun_ 	hint=func..\ (\ SEL\ )\ {...
XSET param|def=$CL no parameters $CR
XSET param|post=Echo( V() == $CL . " no parameters " . $CR ? '' : V() )
`c_fun_type_indent()^`int^`c_fun_body_indent()^`name^(`param^)`$FUNC_BRACKET_STL^{
    `wrapped^
    `cursor^
}
