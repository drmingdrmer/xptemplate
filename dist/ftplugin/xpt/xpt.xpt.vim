XPTemplate priority=sub indent=auto

let [s:f, s:v] = XPTcontainer() 
 
XPTvar $TRUE          1
XPTvar $FALSE         0

XPTinclude 
      \ _common/common


" ========================= Function and Variables =============================

fun! s:f.hintEscape()
  let v = substitute( self.V(), '\(\\*\)\([( ]\)', '\1\1\\\2', 'g' )
  return v
endfunction

let s:xpt_snip = split( globpath( &rtp, "**/*.xpt.vim" ), "\n" )
call map( s:xpt_snip, 'substitute(v:val, ''\V\'', ''/'', ''g'')' )
call map( s:xpt_snip, 'matchstr(v:val, ''\Vftplugin/\zs\.\*\ze.xpt.vim'')' )

let s:xpts = {}
for v in s:xpt_snip
  let [ ft, snip ] = split( v, '/' )
  if !has_key( s:xpts, ft )
    let s:xpts[ ft ] = []
  endif

  let s:xpts[ ft ] += [ snip ]
endfor

" echom string( s:xpts )



fun! s:f.xpt_vim_path()
  return keys( s:xpts )
endfunction

fun! s:f.xpt_vim_name(path)
  let path = matchstr( a:path, '\w\+' )
  if has_key( s:xpts, path )
    return s:xpts[ path ]
  else 
    return ''
  endif
endfunction

" ================================= Snippets ===================================
XPTemplateDef

" TODO detect path to generate popup list 
XPT inc hint=XPTinclude\ ...
XSET path=xpt_vim_path()
XSET name=xpt_vim_name( R( 'path' ) )
XPTinclude 
    \ _common/common`
    `...{{^`
    \ `path^/`name^`
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
XPTvar $`name^ `cursor^


XPT varLang hint=variables\ to\ define\ language\ properties
XPTvar $VAR_PRE            


XPT varFormat hint=variables\ to\ define\ format
XPTvar $IF_BRACKET_STL     \ 
XPTvar $ELSE_BRACKET_STL   \n
XPTvar $FOR_BRACKET_STL    \ 
XPTvar $WHILE_BRACKET_STL  \ 
XPTvar $STRUCT_BRACKET_STL \ 
XPTvar $FUNC_BRACKET_STL   \ 

XPT varSpaces hint=variable\ to\ define\ spacing
XPTvar $SP_ARG      
XPTvar $SP_IF       
XPTvar $SP_EQ       \ 
XPTvar $SP_OP       \ 
XPTvar $SP_COMMA    \ 


XPT varConst hint=variables\ to\ define\ constants
XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL


XPT varHelper hint=variables\ to\ define\ helper\ place\ holders
XPTvar $VOID_LINE      
XPTvar $CURSOR_PH      `cursor^


XPT varComment1 hint=variables\ to\ define\ single\ sign\ comments
XPTvar $CS    `cursor^


XPT varComment2 hint=variables\ to\ define\ double\ sign\ comments
XPTvar $CL    `left sign^
XPTvar $CM    `cursor^
XPTvar $CR    `right sign^





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

let s:f = XPTcontainer()[0]

XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL

XPTvar $VOID_LINE  /* void */;
XPTvar $CURSOR_PH      cursor

XPTvar $IF_BRACKET_STL     \ 
XPTvar $ELSE_BRACKET_STL   \n
XPTvar $FOR_BRACKET_STL    \ 
XPTvar $WHILE_BRACKET_STL  \ 
XPTvar $STRUCT_BRACKET_STL \ 
XPTvar $FUNC_BRACKET_STL   \ 

`XPTinclude...^
XSET XPTinclude...|post=`incTrigger^
XSET incTrigger=Trigger('inc')


" ========================= Function and Variables =============================

" ================================= Snippets ===================================
XPTemplateDef


`cursor^

" ================================= Wrapper ===================================

..XPT


