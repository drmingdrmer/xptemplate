XPTemplate priority=like

let s:f = g:XPTfuncs()

XPTvar $TRUE           1
XPTvar $FALSE          0
XPTvar $NULL           NULL

XPTvar $BRif           ' '
XPTvar $BRloop         ' '
XPTvar $BRstc          ' '
XPTvar $BRfun          \n

" Preference variable to get return type above
" declaration, mainly for convenience with C++
XPTvar $TypeAbove      1

XPTvar $VOID_LINE      /* void */;
XPTvar $CURSOR_PH      /* cursor */

XPTvar $CL  /*
XPTvar $CM   *
XPTvar $CR   */
XPTinclude
      \ _common/common


" ========================= Function and Variables =============================

fun! s:f.c_fun_type_indent()
    if self[ '$TypeAbove' ]
        return repeat( ' ', &softtabstop == 0 ? &tabstop : &softtabstop )
    else
        return ""
    endif
endfunction

fun! s:f.c_fun_body_indent()
    if self[ '$TypeAbove' ]
        return repeat( ' ', &softtabstop == 0 ? &tabstop : &softtabstop ). "\n\n"
        return "\n"
    else
        return " "
    endif
endfunction

fun! s:GetImplementationFile() "{{{
    let name = expand('%:p')
    
    if name =~ '\.h$'
        let name = substitute( name, 'h$', '[cC]*', '' )
    elseif name =~ '\.hpp$'
        let name = substitute( name, 'hpp$', '[cC]*', '' )
    endif

    return glob( name )
endfunction "}}}

fun! s:f.c_fun_implem()
    let imple = s:GetImplementationFile()
    if imple == ''
        return
    endif

    let type = self.R( 'type' )
    let funcName = self.R( 'funcName' )

    let cr = self.R( '$CR' )
    let cl = self.R( '$CL' )
    let brfun = self.R('$BRfun')

    let params = self.R( 'param' )
    let params = ( params == (cl . " no parameters " . cr) ? '' : params )   

    let methodBody = [ self.c_fun_type_indent() . type . self.c_fun_body_indent() . funcName 
                   \ . '(' . params . ')' . brfun . '{'
                   \ , '}'
                   \ , '' ]

    let txt = extend( readfile( imple ), methodBody )
    call writefile( txt, imple )

    return params
endfunction

" ================================= Snippets ===================================
XPTemplateDef



XPT main " main (int argc, char argv)
`c_fun_type_indent()^int`c_fun_body_indent()^main(int argc, char *argv[])`$BRfun^{
    `cursor^
    return 0;
}
..XPT

XPT fun " func ...( ...) {...
XSET param|def=$CL no parameters $CR
XSET param|post=Echo( V() == $CL . " no parameters " . $CR ? '' : V() )
`c_fun_type_indent()^`int^`c_fun_body_indent()^`name^(`param^)`$BRfun^{
    `cursor^
}
..XPT

XPT hfun " function + implementation skeleton
XSET param|def=$CL no parameters $CR
XSET param|post=c_fun_implem()
`c_fun_type_indent()^`type^`c_fun_body_indent()^`funcName^(`param^);
..XPT


" ================================= Wrapper ===================================

XPT fun_ 	hint=func..\ (\ SEL\ )\ {...
XSET param|def=$CL no parameters $CR
XSET param|post=Echo( V() == $CL . " no parameters " . $CR ? '' : V() )
`c_fun_type_indent()^`int^`c_fun_body_indent()^`name^(`param^)`$BRfun^{
    `wrapped^
    `cursor^
}
