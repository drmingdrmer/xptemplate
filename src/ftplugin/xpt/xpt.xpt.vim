XPTemplate priority=sub

let s:f = g:XPTfuncs()

XPTinclude
      \ _common/common
      \ vim/vim


" ========================= Function and Variables =============================

fun! s:f.xpt_vim_hint_escape()
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


XPT container " let s:f = ..
let s:f = g:XPTfuncs()


XPT tmpl hint=XPT\ name\ ...
XSET tips|post=xpt_vim_hint_escape()
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
" else ** {
XPTvar $BRif     ' '

" } ** else {
XPTvar $BRel     \n

" for () ** {
" while () ** {
" do ** {
XPTvar $BRloop   ' '

" struct name ** {
XPTvar $BRstc    ' '

" int fun() ** {
" class name ** {
XPTvar $BRfun    ' '


XPT varSpaces hint=variable\ to\ define\ spacing
" int fun ** (
" class name ** (
XPTvar $SPfun      ''

" int fun( ** arg ** )
" if ( ** condition ** )
" for ( ** statement ** )
" [ ** a, b ** ]
" { ** 'k' : 'v' ** }
XPTvar $SParg      ' '

" if ** (
" while ** (
" for ** (
XPTvar $SPcmd      ' '

" a ** = ** a ** + ** 1
" (a, ** b, ** )
XPTvar $SPop       ' '


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

XPT spfun " `\$SPfun^
\`$SPfun\^

XPT sparg " `\$SParg^
\`$SParg\^

XPT spcmd " `\$SPcmd^
\`$SPcmd\^

XPT spop hint=`\$SPop^
\`$SPop\^


XPT buildifeq hint={{}}
\``name^{{\^`cursor^\`}}\^

XPT inc hint=`::^
\`:`name^:\^


XPT fun hint=fun!\ s:f.**
XSET parameters|def=
XSET parameters|post=Echo( V() =~ '^\s*$' ? '' : V() )
fun! s:f.`name^(`$SParg`parameters`$SParg^)
    `cursor^
endfunction


XPT skeleton " very simple snippet file skeleton
" Save this file as ~/.vim/ftplugin/c/hello.xpt.vim(or
" ~/vimfiles/ftplugin/c/hello.xpt.vim). 
" Then you can use it in C language file:
"     vim xpt.c
" And type:
"     helloxpt<C-\>
"
XPTemplate priority=personal+
XPTemplateDef



\XPT helloxpt " tips about what this snippet do
Say hello to \`xpt^.
\`xpt^ says hello.





XPT xpt hint=start\ template\ to\ write\ template
XPTemplate priority=`prio^` `mark...^
XSET prio=ChooseStr( 'all', 'spec', 'like', 'lang', 'sub', 'personal' )
XSET mark...|post= mark=`char^

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


