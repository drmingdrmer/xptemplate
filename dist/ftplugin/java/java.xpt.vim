XPTemplate priority=lang

" containers
let [s:f, s:v] = XPTcontainer()

" constant definition
call extend(s:v, { '$TRUE': 'true'
               \ , '$FALSE' : 'false'
               \ , '$NULL' : 'null'
               \ , '$UNDEFINED' : ''
               \ , '$IF_BRACKET_STL' : ''
               \ , '$INDENT_HELPER' : ';'})

" inclusion
XPTinclude 
      \ _common/common
      \ _comment/c.like
      \ _condition/c.like
      \ _loops/java.for.like
      \ _loops/c.while.like
      \ c/wrap

" ========================= Function and Varaibles =============================

" ================================= Snippets ===================================
XPTemplateDef

XPT foreach hint=for\ \(\ ..\ :\ ..\ \)
for ( `type^ `var^ : `inWhat^ ) {
    `cursor^
}


XPT private hint=private\ ..\ ..
private `type^ `varName^;

XPT public hint=private\ ..\ ..
public `type^ `varName^;

XPT protected hint=private\ ..\ ..
protected `type^ `varName^;

XPT class hint=class\ ..\ ctor
public class `className^ {
    public `className^( `ctorParam^^ ) {
        `cursor^
    }
}


XPT main hint=main\ (\ String\ )
public static void main( String[] args )
{
    `cursor^
}


XPT enum hint=public\ enum\ {\ ..\ }
`access^public^ enum `enumName^
{
    `elem^`...^,
    `subElem^`...^
};
`cursor^

XPT prop hint=var\ getVar\ ()\ setVar\ ()
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


XPT try hint=try\ ..\ catch\ (..)\ ..\ finally
try
{
    `what^
}` `catch...^
XSETm catch...|post

catch (`except^ `e^)
{
    `handler^
}` `catch...^
XSETm END
`finally...{{^finally
{
    `cursor^
}`}}^



