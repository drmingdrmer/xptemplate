XPTemplate priority=lang-

let s:f = g:XPTfuncs()

XPTvar $TRUE          true
XPTvar $FALSE         false
XPTvar $NULL          null

XPTvar $BRif     \n
XPTvar $BRloop    \n
XPTvar $BRloop  \n
XPTvar $BRstc \n
XPTvar $BRfun   \n

XPTvar $VOID_LINE  /* void */;
XPTvar $CURSOR_PH      /* cursor */

XPTvar $CL  /*
XPTvar $CM   *
XPTvar $CR   */

XPTinclude
      \ _common/common
      \ _comment/doubleSign
      \ _condition/c.like
      \ _loops/c.while.like
      \ _loops/java.for.like
      \ _structures/c.like

XPTinclude
            \ c/c

" ========================= Function and Variables =============================


" ================================= Snippets ===================================
XPTemplateDef


XPT foreach " foreach (.. in ..) {..}
foreach ( `var^ `e^ in `what^ )`$BRloop^{
    `cursor^
}
..XPT


XPT struct " struct { .. }
`public^ struct `structName^
{
    `fieldAccess^public^ `type^ `name^;`...^
    `fieldAccess^public^ `type^ `name^;`...^
}
..XPT


XPT class " class +ctor
class `className^
{
    public `className^(` `ctorParam` ^)
    {
        `cursor^
    }
}
..XPT


XPT main " static main string[]
public static void Main( string[] args )
{
    `cursor^
}
..XPT


XPT prop " .. .. {get set}
public `type^ `Name^
{`
    `get...{{^
    get { return `what^; }`}}^`
    `set...{{^
    set { `what^ = `value^; }`}}^
}
..XPT


XPT namespace " namespace {}
namespace `name^
{
    `cursor^
}
..XPT

XPT try " try .. catch .. finally
XSET handler=$CL handler $CR
try
{
    `what^
}`
`...^
catch (`except^ e)
{
    `handler^
}`
`...^`
`finally...{{^
finally
{
    `cursor^
}`}}^
..XPT



" ================================= Wrapper ===================================
XPT region_ " #region #endregion
#region `regionText^
`wrapped^
`cursor^
#endregion /* `regionText^ */

XPT try_ " try .. catch .. finally
XSET handler=$CL handler $CR
try
{
    `wrapped^
}`
`...^
catch (`except^ e)
{
    `handler^
}`
`...^`
`finally...{{^
finally
{
    `cursor^
}`}}^
..XPT

