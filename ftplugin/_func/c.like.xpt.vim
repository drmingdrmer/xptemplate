XPTemplate priority=like

let s:f = g:XPTfuncs()

XPTvar $TRUE           1
XPTvar $FALSE          0
XPTvar $NULL           NULL

XPTvar $BRif           ' '
XPTvar $BRloop         ' '
XPTvar $BRstc          ' '
XPTvar $BRfun          ' '

XPTvar $VOID_LINE      /* void */;
XPTvar $CURSOR_PH      /* cursor */

XPTvar $CL  /*
XPTvar $CM   *
XPTvar $CR   */
XPTinclude
      \ _common/common

fun! s:f.c_fun_type_indent()
    if self[ '$BRfun' ] == "\n"
        " let sts = &softtabstop == 0 ? &tabstop : &softtabstop
        return '    '
    else
        return ""
    endif
endfunction

fun! s:f.c_fun_body_indent()
    if self[ '$BRfun' ] == "\n"
        " let sts = &softtabstop == 0 ? &tabstop : &softtabstop
        return self.ResetIndent( -&shiftwidth, "\n" )
    else
        return " "
    endif
endfunction

XPT main hint=main\ (argc,\ argv)
`c_fun_type_indent()^int`c_fun_body_indent()^main(`$SParg^int argc,`$SPop^char **argv`$SParg^)`$BRfun^{
    `cursor^
    return 0;
}

XPT fun wrap=curosr	hint=func..\ (\ ..\ )\ {...
`c_fun_type_indent()^`int^`c_fun_body_indent()^`name^(`$SParg`param?`$SParg^)`$BRfun^{
    `cursor^
}

