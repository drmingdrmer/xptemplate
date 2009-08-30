XPTemplate priority=lang-

let [s:f, s:v] = XPTcontainer() 
 
XPTvar $TRUE          true
XPTvar $FALSE         false
XPTvar $NULL          null
XPTvar $UNDEFINED     null
XPTvar $INDENT_HELPER /* void */;
XPTvar $IF_BRACKET_STL \n

XPTinclude 
      \ _common/common
      \ _comment/c.like
      \ _condition/c.like
      \ _loops/c.while.like
      \ _loops/java.for.like
      \ c/wrap


" ========================= Function and Variables =============================


" ================================= Snippets ===================================
XPTemplateDef 


XPT foreach hint=foreach\ (..\ in\ ..)\ {..}
foreach ( `var^ `e^ in `what^ )
{
    `cursor^
}


XPT enum hint=enum\ {\ ..\ }
enum `enumName^
{
    `elem^`...^,
    `subElem^`...^
};
`cursor^


XPT struct hint=struct\ {\ ..\ }
`access^public^ struct `structName^
{
    `fieldAccess^public^ `type^ `name^;`...^
    `fieldAccess^public^ `type^ `name^;`...^
}


XPT class hint=class\ +ctor
class `className^
{
    public `className^( `ctorParam^^ )
    {
        `cursor^
    }
}


XPT main hint=static\ main\ string[]
public static void Main( string[] args )
{
    `cursor^
}


XPT prop hint=..\ ..\ {get\ set}
public `type^ `Name^
{`
    `get...{{^
    get { return `what^; }`}}^`
    `set...{{^
    set { `what^ = `value^; }`}}^
}


XPT namespace hint=namespace\ {}
namespace `name^
{
    `cursor^
}


XPT try hint=try\ ..\ catch\ ..\ finally
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
`catch...{{^
catch
{
    `_^^
}`}}^`
`finally...{{^
finally
{
    `cursor^
}`}}^



