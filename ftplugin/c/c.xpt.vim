XPTemplate priority=lang


XPTvar $TRUE           1
XPTvar $FALSE          0
XPTvar $NULL           NULL

XPTvar $BRif           ' '
XPTvar $BRloop         ' '
XPTvar $BRstc          ' '
XPTvar $BRfun          \n

XPTvar $VOID_LINE      /* void */;
XPTvar $CURSOR_PH      /* cursor */

XPTinclude
      \ _common/common

XPTvar $CL  /*
XPTvar $CM   *
XPTvar $CR   */
XPTinclude
      \ _comment/doubleSign

XPTinclude
      \ _condition/c.like
      \ _func/c.like
      \ _loops/c.while.like
      \ _preprocessor/c.like
      \ _structures/c.like
      \ _printf/c.like

XPTinclude
      \ _loops/for


let s:f = g:XPTfuncs()



XPT _printfElts hidden 
XSET elts|pre=Echo('')
XSET elts=c_printf_elts( R( 'pattern' ), ',' )
"`pattern^"`elts^


XPT printf	" printf\(...)
printf(`$SParg^`:_printfElts:^`$SParg^)


XPT sprintf	" sprintf\(...)
sprintf(`$SParg^`str^,`$SPop^`:_printfElts:^`$SParg^)


XPT snprintf	" snprintf\(...)
snprintf(`$SParg^`str^,`$SPop^`size^,`$SPop^`:_printfElts:^`$SParg^)


XPT fprintf	" fprintf\(...)
fprintf(`$SParg^`stream^,`$SPop^`:_printfElts:^`$SParg^)

XPT memcpy " memcpy (..., ..., sizeof (...) ... )
memcpy(`$SParg^`dest^,`$SPop^`source^,`$SPop^sizeof(`type^int^)`$SPop^*`$SPop^`count^`$SParg^)

XPT memset " memset (..., ..., sizeof (...) ... )
memset(`$SParg^`buffer^,`$SPop^`what^0^,`$SPop^sizeof(`$SParg^`type^int^`$SParg^)`$SPop^*`$SPop^`count^`$SParg^)

XPT malloc " malloc ( ... );
(`type^int^*)malloc(`$SParg^sizeof(`$SParg^`type^`$SParg^)`$SPop^*`$SPop^`count^`$SParg^)

XPT assert	" assert (.., msg)
assert(`$SParg^`isTrue^,`$SPop^"`text^"`$SParg^)


XPT fcomment
/**
 * @author : `$author^ | `$email^
 * @description
 *     `cursor^
 * @return {`int^} `desc^
 */


XPT para syn=comment	" comment parameter
@param {`Object^} `name^ `desc^

XPT filehead
XSET cursor|pre=CURSOR
/**-------------------------/// `sum^ \\\---------------------------
 *
 * <b>`function^</b>
 * @version : `1.0^
 * @since : `strftime("%Y %b %d")^
 *
 * @description :
 *     `cursor^
 * @usage :
 *
 * @author : `$author^ | `$email^
 * @copyright `.com.cn^
 * @TODO :
 *
 *--------------------------\\\ `sum^ ///---------------------------*/

..XPT


XPT call wraponly=param " ..( .. )
`name^(`$SParg^`param^`$SParg^)

