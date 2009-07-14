if exists("b:__XPT_XPT_XPT_VIM__")
  finish
endif
let b:__XPT_XPT_XPT_VIM__ = 1

" containers
let [s:f, s:v] = XPTcontainer()

" constant definition
call extend(s:v, {'$TRUE': '1', '$FALSE': '0', '$NULL': '', '$UNDEFINED': ''})
" call XPTemplatePriority('sub')

" inclusion

" ========================= Function and Varaibles =============================
fun! s:f.xptHeader() "{{{
  let symbol = expand("%:p")
  "let symbol = matchstr(symbol, '/ftplugin/\zs.*')
  let symbol = matchstr(symbol, '[/\\]ftplugin[/\\]\zs.*')
  let symbol = substitute(symbol, '/', '_', 'g')
  let symbol = substitute(symbol, '\.', '_', 'g')
  let symbol = substitute(symbol, '\\', '_', 'g')
  let symbol = substitute(symbol, '.', '\u&', 'g')
  
  return '__'.symbol.'__'
endfunction "}}}

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
      \ `^E("%:p:h:t")^/`name^`...^
      \ `^E("%:p:h:t")^/`name^`...^


XPT once hint=if\ exists\ finish\ let\ b...
if exists("b:`i^xptHeader()^")
    finish
endif
let b:`i^ = 1


XPT container hint=let\ [s:f,\ s:v]\ =...
let [s:f, s:v] = XPTcontainer()


XPT xpt hint=start\ template\ to\ write\ template
if exists("b:`i^xptHeader()^") 
  finish 
endif
let b:`i^ = 1 
 
" containers
let [s:f, s:v] = XPTcontainer() 
 
" constant definition
XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $INDENT_HELPER /* void */;
XPTVar $UNDEFINED     ''
XPTVar $BRACKETSTYLE  "\n"

" inclusion
XPTinclude

" ========================= Function and Variables =============================

 
" ================================= Snippets ===================================
XPTemplateDef 
`cursor^
