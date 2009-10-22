XPTemplate priority=sub

let s:f = g:XPTfuncs() 
 
XPTinclude 
      \ _common/common
      \ vim/vim


" ========================= Function and Variables =============================

fun! s:f.hintEscape()
  " let v = substitute( self.V(), '\(\\*\)\([( ]\)', '\1\1\\\2', 'g' )
  let v = substitute( self.V(), '\(\\*\)\([(]\)', '\1\1\\\2', 'g' )
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
XPT incf hint=XPTinclude\ ...
XSET path=xpt_vim_path()
XSET name=xpt_vim_name( R( 'path' ) )
XPTinclude 
    \ _common/common`
    `...{{^`
    \ `path^/`name^`
    `...^`}}^


XPT container hint=let\ [s:f,\ s:v]\ =...
let s:f = g:XPTfuncs() 


XPT tmpl hint=XPT\ name\ ...
XSET tips|post=hintEscape()
\XPT `name^ " `tips^
`cursor^


XPT snip alias=tmpl


XPT var hint=XPTvar\ $***\ ***
XSET name|post=UpperCase(V())
XSET value|post=escape(V(), ' ')
XPTvar $`name^ `cursor^


XPT varLang hint=variables\ to\ define\ language\ properties
" variable prefix
XPTvar $VAR_PRE            


XPT varFormat hint=variables\ to\ define\ format
" if () ** {
XPTvar $IF_BRACKET_STL     ' '
" } ** else {
XPTvar $ELSE_BRACKET_STL   \n
" for () ** {
XPTvar $FOR_BRACKET_STL    ' '
" while () ** {
XPTvar $WHILE_BRACKET_STL  ' '
" struct name ** {
XPTvar $STRUCT_BRACKET_STL ' '
" int fun() ** {
XPTvar $FUNC_BRACKET_STL   ' '


XPT varSpaces hint=variable\ to\ define\ spacing
" int fun( ** arg ** )
XPTvar $SP_ARG      ' '
" if ( ** condition ** )
XPTvar $SP_IF       ' '
" a ** = ** b
XPTvar $SP_EQ       ' '
" a = a ** + ** 1
XPTvar $SP_OP       ' '
" (a, ** b, ** )
XPTvar $SP_COMMA    ' '


XPT varConst hint=variables\ to\ define\ constants
XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL


XPT varHelper hint=variables\ to\ define\ helper\ place\ holders
XPTvar $VOID_LINE      
XPTvar $CURSOR_PH      


XPT varComment1 hint=variables\ to\ define\ single\ sign\ comments
XPTvar $CS    `cursor^


XPT varComment2 hint=variables\ to\ define\ double\ sign\ comments
XPTvar $CL    `left sign^
XPTvar $CM    `cursor^
XPTvar $CR    `right sign^

XPT sparg " `\$SP_ARG^
\`$SP_ARG\^

XPT spif hint=`\$SP_ARG^
\`$SP_IF\^

XPT speq hint=`\$SP_EQ^
\`$SP_EQ\^

XPT spop hint=`\$SP_OP^
\`$SP_OP\^

XPT spcomma hint=`\$SP_COMMA^
\`$SP_COMMA\^

XPT buildifeq hint={{}}
\``name^{{\^`cursor^\`}}\^

XPT inc hint=`::^
\`:`name^:\^


XPT fun hint=fun!\ s:f.**
XSET parameters|def=
XSET parameters|post=Echo( V() =~ '^\s*$' ? '' : V() )
fun! s:f.`name^(` `parameters` ^)
    `cursor^
endfunction



XPT xpt hint=start\ template\ to\ write\ template
XPTemplate priority=`prio^` `mark...^
XSET prio=ChooseStr( 'all', 'spec', 'like', 'lang', 'sub', 'personal' )
XSET keyword_disable...|post= keyword=`char^
XSET mark...|post= mark=`char^
XSET indent_disable...|post= indent=`indentValue^
XSET indentValue=ChooseStr( 'auto', 'keep' )

let s:f = g:XPTfuncs() 

`Include:varConst^

`Include:varFormat^

`XPTinclude...{{^`Include:incf^`}}^


" ========================= Function and Variables =============================

" ================================= Snippets ===================================
XPTemplateDef


`cursor^

" ================================= Wrapper ===================================

..XPT


