" XPTemplate priority=lang keyword=# mark=12 indent=auto
XPTemplate priority=lang indent=auto


XPTvar $TRUE           1
XPTvar $FALSE          0
XPTvar $NULL           NULL
XPTvar $IF_BRACKET_STL \ 
XPTvar $INDENT_HELPER  /* void */;


XPTinclude
      \ _common/common 
      \ _comment/c.like 
      \ _condition/c.like
      \ _loops/c.like
      \ _structures/c.like
      \ _preprocessor/c.like


" ========================= Function and Varaibles =============================

let s:f = XPTcontainer()[ 0 ]

let s:printfElts = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'

fun! s:f.c_printfItem( v )
  let v = a:v
  if v =~ '\V%'
    let len = len( substitute( v, '\V\[^%]', '', 'g' ) )

    let re = s:printfElts[ : len - 1 ]
    let re = substitute( re, '.', ', `&^', 'g' )

    return re
  else 
    return self.Next( '' )
  endif
endfunction

" ================================= Snippets ===================================
XPTemplateDef

XPT printf	hint=printf\\(...)
XSET printf=Next('printf')
XSET elts=c_printfItem( R( 'pattern' ) )
`printf^(` "`pattern^"`elts^ );
..XPT


XPT sprintf alias=printf
XSET printf=Next( 'sprintf' )


XPT fprintf alias=printf
XSET printf=Next( 'fprintf' )


XPT assert	hint=assert\ (..,\ msg)
assert(`isTrue^, "`text^");

XPT main hint=main\ (argc,\ argv)
  int
main(int argc, char **argv)
{
  `cursor^
  return 0;
}

" Quick-Repetition parameters list
XPT fun		hint=func..\ (\ ..\ )\ {...
XSET p..|post=ExpandIfNotEmpty(', ', 'p..')
  `int^
`name^(`p..^)
{
  `cursor^
}

XPT cmt
/**
 * @author : `$author^ | `$email^
 * @description
 *     `cursor^
 * @return {`int^} `desc^
 */


XPT para syn=comment	hint=comment\ parameter
@param {`Object^} `name^ `desc^


XPT filehead
/**-------------------------/// `sum^ \\\---------------------------
 *
 * <b>`function^</b>
 * @version : `1.0^
 * @since : `strftime("%Y %b %d")^
 * 
 * @description :
 *   `cursor^
 * @usage : 
 * 
 * @author : `$author^ | `$email^
 * @copyright `.com.cn^ 
 * @TODO : 
 * 
 *--------------------------\\\ `sum^ ///---------------------------*/

