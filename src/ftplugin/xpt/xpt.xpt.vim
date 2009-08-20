if exists("b:__XPT_XPT_XPT_VIM__")
  finish
endif
let b:__XPT_XPT_XPT_VIM__ = 1

" containers
let [s:f, s:v] = XPTcontainer()

XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL
XPTvar $INDENT_HELPER /* void */;


XPTinclude
      \ _common/common
      \ _common/personal

" ========================= Function and Varaibles =============================

fun! s:f.hintEncode( str, ... ) "{{{
    let s = substitute( a:str, '\([^\\]\) ', '\1\\ ', 'ge' )
    return s
endfunction "}}}

" ================================= Snippets ===================================
XPTemplateDef

" repeatable part or defualt value must be escaped
XPT tmpl hint=call\ XPTemplate(\ ...
XSET funName=XPT
XSET tips|post=hintEncode(V())
`funName^ `name^ hint=`tips^
`cursor^


XPT tmpl_ hint=call\ XPTemplate(\ ..,\ SEL\ ...
XSET funName=XPT
XSET tips|post=hintEncode(V())
`funName^ `name^_ hint=`hint^
`wrapped^

XPT inc hint=XPTinclude\ ...
XPTinclude 
      \ `a^-E("%:p:h:t")^/`name^`
      `...{{^`
      \ `a^-E("%:p:h:t")^/`name^`
      `...^`}}^


XPT container hint=let\ [s:f,\ s:v]\ =...
let [s:f, s:v] = XPTcontainer()


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


