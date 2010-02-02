XPTemplate priority=lang

let s:f = g:XPTfuncs()

XPTvar $TRUE          true
XPTvar $FALSE         false
XPTvar $NULL          null
XPTvar $UNDEFINED     null

XPTvar $VOID_LINE  /* void */;
XPTvar $CURSOR_PH      /* cursor */

XPTvar $BRif          ' '
XPTvar $BRloop        ' '
XPTvar $BRstc         ' '
XPTvar $BRfun         ' '

XPTinclude
      \ _common/common

XPTvar $CL    /*
XPTvar $CM    *
XPTvar $CR    */
XPTinclude
      \ _comment/doubleSign

XPTinclude
      \ _condition/c.like
      \ _loops/java.for.like
      \ _loops/c.while.like


" ========================= Function and Variables =============================

" ================================= Snippets ===================================
XPTemplateDef




XPT foreach " for ( .. : .. )
for ( `type^ `var^ : `inWhat^ )`$BRloop^{
    `cursor^
}


XPT private " private .. ..
private `type^ `varName^;

XPT public " private .. ..
public `type^ `varName^;

XPT protected " private .. ..
protected `type^ `varName^;

XPT class " class .. ctor
public class `className^ {
    public `className^(` `ctorParam` ^)`$BRfun^{
        `cursor^
    }
}


XPT main " main ( String )
public static void main( String[] args )`$BRfun^{
    `cursor^
}


XPT enum " public enum { .. }
`public^ enum `enumName^
{
    `elem^` `...^,
    `subElem^` `...^
};
`cursor^

XPT prop " var getVar () setVar ()
`type^ `varName^;

`get...^
XSETm get...|post
public `R("type")^ get`S(R("varName"),'.','\u&',"")^()
    { return `R("varName")^; }

XSETm END
`set...^
XSETm set...|post
public `R("type")^ set`S(R("varName"),'.','\u&',"")^( `R('type')^ val )
    { `R("varName")^ = val; return `R( 'varName' )^; }

XSETm END


XPT try " try .. catch (..) .. finally
XSET handler=$CL handling $CR
try
{
    `what^
}` `catch...^
XSETm catch...|post

catch (`Exception^ `e^)
{
    `handler^
}` `catch...^
XSETm END
`finally...{{^finally
{
    `cursor^
}`}}^



" ================================= Wrapper ===================================


XPT try_ " try { SEL } catch...
XSET handler=$CL handling $CR
try
{
    `wrapped^
}` `catch...^
XSETm catch...|post

catch (`Exception^ `e^)
{
    `handler^
}` `catch...^
XSETm END
`finally...{{^finally
{
    `cursor^
}`}}^
