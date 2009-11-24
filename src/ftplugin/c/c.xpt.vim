XPTemplate priority=lang indent=auto


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

XPTinclude
      \ _loops/for


" ========================= Function and Variables =============================

let s:f = g:XPTfuncs()

let s:printfElts = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'

"  %[flags][width][.precision][length]specifier
let s:printfItemPattern = '\V\C' . '%' . '\[+\- 0#]\*' . '\%(*\|\d\+\)\?' . '\(.*\|.\d\+\)\?' . '\[hlL]\?' . '\(\[cdieEfgGosuxXpn]\)'

let s:printfSpecifierMap = {
      \'c' : 'char',
      \'d' : 'int',
      \'i' : 'int',
      \'e' : 'scientific',
      \'E' : 'scientific',
      \'f' : 'float',
      \'g' : 'float',
      \'G' : 'float',
      \'o' : 'octal',
      \'s' : 'str',
      \'u' : 'unsigned',
      \'x' : 'decimal',
      \'X' : 'Decimal',
      \'p' : 'pointer',
      \'n' : 'numWritten',
      \}

fun! s:f.c_printfElts( v )
  " remove '%%' representing a single '%'
  let v = substitute( a:v, '\V%%', '', 'g' )


  if v =~ '\V%'

    let start = 0
    let post = ''
    let i = -1
    while 1
      let i += 1

      let start = match( v, s:printfItemPattern, start )
      if start < 0
        break
      endif

      let eltList = matchlist( v, s:printfItemPattern, start )

      if eltList[1] == '.*'
        " need to specifying string length before string pointer
        let post .= ', `' . s:printfElts[ i ] . '_len^'
      endif

      let post .= ', `' . s:printfElts[ i ] . '_' . s:printfSpecifierMap[ eltList[2] ] . '^'

      let start += len( eltList[0] )

    endwhile
    return post

  else
    return self.Next( '' )

  endif
endfunction



" ================================= Snippets ===================================
XPTemplateDef



XPT printf	hint=printf\(...)
XSET elts|pre=Echo('')
XSET elts=c_printfElts( R( 'pattern' ) )
printf( "`pattern^"`elts^ )


XPT sprintf	hint=sprintf\(...)
XSET elts|pre=Echo('')
XSET elts=c_printfElts( R( 'pattern' ) )
sprintf( `str^, "`pattern^"`elts^ )


XPT snprintf	hint=snprintf\(...)
XSET elts|pre=Echo('')
XSET elts=c_printfElts( R( 'pattern' ) )
snprintf( `str^, `size^, "`pattern^"`elts^ )


XPT fprintf	hint=fprintf\(...)
XSET elts|pre=Echo('')
XSET elts=c_printfElts( R( 'pattern' ) )
fprintf( `stream^, "`pattern^"`elts^ )


XPT assert	hint=assert\ (..,\ msg)
assert(`isTrue^, "`text^")


XPT fcomment
/**
 * @author : `$author^ | `$email^
 * @description
 *     `cursor^
 * @return {`int^} `desc^
 */


XPT para syn=comment	hint=comment\ parameter
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



" ================================= Wrapper ===================================


XPT call_ hint=..(\ SEL\ )
XSET p*|post=ExpandIfNotEmpty(', ', 'p*')
`name^(`wrapped^`, `p*^)`cursor^


