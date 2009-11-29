XPTemplate priority=like

let s:f = g:XPTfuncs()

XPTvar $TRUE           1
XPTvar $FALSE          0
XPTvar $NULL           NULL

XPTvar $BRif           ' '
XPTvar $BRloop         ' '
XPTvar $BRstc          ' '
XPTvar $BRfun          \n

XPTvar $VOID_LINE      /* void */;
XPTvar $CURSOR_PH      /* cursor */

XPTvar $CL  /*
XPTvar $CM   *
XPTvar $CR   */
XPTinclude
      \ _common/common


" ========================= Function and Variables =============================

fun! s:f.c_fun_type_indent()
    if self[ '$BRfun' ] == "\n"
        return repeat( ' ', &softtabstop == 0 ? &tabstop : &softtabstop )
    else
        return ""
    endif
endfunction

fun! s:f.c_fun_body_indent()
    if self[ '$BRfun' ] == "\n"
        return repeat( ' ', &softtabstop == 0 ? &tabstop : &softtabstop ). "\n\n"
        return "\n"
    else
        return " "
    endif
endfunction

" ================================= Snippets ===================================
XPTemplateDef



XPT main hint=main\ (argc,\ argv)
`c_fun_type_indent()^int`c_fun_body_indent()^main(int argc, char **argv)`$BRfun^{
    `cursor^
    return 0;
}
..XPT

XPT fun 	hint=func..\ (\ ..\ )\ {...
XSET param|def=$CL no parameters $CR
XSET param|post=Echo( V() == $CL . " no parameters " . $CR ? '' : V() )
`c_fun_type_indent()^`int^`c_fun_body_indent()^`name^(`param^)`$BRfun^{
    `cursor^
}



" ================================= Wrapper ===================================

XPT fun_ 	hint=func..\ (\ SEL\ )\ {...
XSET param|def=$CL no parameters $CR
XSET param|post=Echo( V() == $CL . " no parameters " . $CR ? '' : V() )
`c_fun_type_indent()^`int^`c_fun_body_indent()^`name^(`param^)`$BRfun^{
    `wrapped^
    `cursor^
}
