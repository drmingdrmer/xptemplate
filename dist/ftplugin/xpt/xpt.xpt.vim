XPTemplate priority=sub indent=auto

let [s:f, s:v] = XPTcontainer() 
 
XPTvar $TRUE          1
XPTvar $FALSE         0

XPTinclude 
      \ _common/common
      \ _common/personal


" ========================= Function and Variables =============================

fun! s:f.hintEscape()
  let v = substitute( self.V(), '(', '\\&', 'g' )
  return escape( v, '\ ' )
endfunction

" ================================= Snippets ===================================
XPTemplateDef 

" TODO detect path to generate popup list 
XPT inc hint=XPTinclude\ ...
XPTinclude 
      \ _common/common
      \ _common/personal`
      `...{{^`
      \ `a^E("%:p:h:t")^/`name^`
      `...^`}}^


XPT container hint=let\ [s:f,\ s:v]\ =...
let [s:f, s:v] = XPTcontainer()


XPT tmpl hint=XPT\ name\ ...
XSET tips|post=hintEscape()
\XPT `name^ hint=`tips^
`cursor^


XPT snip alias=tmpl


XPT var hint=XPTvar\ $***\ ***
XSET name|post=UpperCase(V())
XSET value|post=escape(V(), ' ')
XPTvar $`name^ `value^


XPT fun hint=fun!\ s:f.**
XSET parameters|def=
XSET parameters|post=Echo( V() =~ '^\s*$' ? '' : V() )
fun! s:f.`name^(` `parameters` ^)
  `cursor^
endfunction



XPT xpt hint=start\ template\ to\ write\ template
XPTemplate priority=`prio^` `keyword...^` `mark...^` `indent...^
XSET prio=ChooseStr( 'all', 'spec', 'like', 'lang', 'sub', 'personal' )
XSET keyword...|post= keyword=`char^
XSET mark...|post= mark=`char^
XSET indent...|post= indent=`indentValue^
XSET indentValue=ChooseStr( 'auto', 'keep' )

let [s:f, s:v] = XPTcontainer() 
 
XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL
XPTvar $INDENT_HELPER /* void */;
XPTvar $IF_BRACKET_STL \n

`XPTinclude...^
XSET XPTinclude...|post=`bridge^
XSET bridge=Trigger('inc')


" ========================= Function and Variables =============================


" ================================= Snippets ===================================
XPTemplateDef 

`cursor^
..XPT


