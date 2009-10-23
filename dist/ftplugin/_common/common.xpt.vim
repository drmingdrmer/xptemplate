XPTemplate priority=all

" containers
let s:f = g:XPTfuncs() 

XPTvar $author        $author is not set, you need to set g:xptemplate_vars="$author=your_name"
XPTvar $email         $email is not set, you need to set g:xptemplate_vars="$author=your_email@com"

XPTvar $VOID

XPTvar $IF_BRACKET_STL     ' '
XPTvar $ELSE_BRACKET_STL   \n
XPTvar $FOR_BRACKET_STL    ' '
XPTvar $WHILE_BRACKET_STL  ' '
XPTvar $STRUCT_BRACKET_STL ' '
XPTvar $FUNC_BRACKET_STL   ' '

XPTvar $SP_ARG      ' '
XPTvar $SP_IF       ' '
XPTvar $SP_EQ       ' '
XPTvar $SP_OP       ' '
XPTvar $SP_COMMA    ' '

XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          0
XPTvar $UNDEFINED     0

XPTvar $VOID_LINE  
XPTvar $CURSOR_PH      CURSOR


XPTinclude
      \ _common/personal
      \ _common/cmn.counter

" ========================= Function and Varaibles =============================




" current name
fun! s:f.N() "{{{
  if has_key(self._ctx, 'name')
    return self._ctx.name
  else
    return ""
  endif
endfunction "}}}

" name with edge
fun! s:f.NN() "{{{
  if has_key(self._ctx, 'fullname')
    return self._ctx.fullname
  else
    return ""
  endif
endfunction "}}}

" TODO left edge, right edge 
fun! s:f.Edges()
  return [ '', '' ]
endfunction

" current value
fun! s:f.V() dict "{{{
  if has_key(self._ctx, 'value')
    return self._ctx.value
  else
    return ""
  endif
endfunction "}}}

" edge stripped value
fun! s:f.V0() dict
  let v = self.V()

  let [edgeLeft, edgeRight] = self.ItemEdges()

  let v = substitute( v, '\V\^' . edgeLeft,       '', '' )
  let v = substitute( v, '\V' . edgeRight . '\$', '', '' )

  return v
endfunction

" TODO this is not needed at all except as a shortcut.
" equals to expand()
fun! s:f.E(s) "{{{
  return expand(a:s)
endfunction "}}}

" return the context
fun! s:f.C() "{{{
  return self._ctx
endfunction "}}}

" TODO this is not needed at all except as a shortcut.
" post filter	substitute
fun! s:f.S(str, ptn, rep, ...) "{{{
  let flg = a:0 >= 1 ? a:1 : 'g'
  return substitute(a:str, a:ptn, a:rep, flg)
endfunction "}}}

" equals to S(C().value, ...)
fun! s:f.SV(ptn, rep, ...) "{{{
  let flg = a:0 >= 1 ? a:1 : 'g'
  return substitute(self.V(), a:ptn, a:rep, flg)
endfunction "}}}

" reference to another finished item value
fun! s:f.R(name) "{{{
  let ctx = self._ctx
  if has_key(ctx.namedStep, a:name)
    return ctx.namedStep[a:name]
  endif

  return ""
endfunction "}}}

" black hole
fun! s:f.VOID(...) "{{{
  return ""
endfunction "}}}

" Echo several expression and concat them.
" That's the way to use normal vim script expression instead of mixed string
fun! s:f.Echo(...)
  return join( a:000, '' )
endfunction

fun! s:f.EchoIf( isTrue, ... )
  if a:isTrue
    return join( a:000, '' )
  else
    return self.V()
  endif
endfunction

fun! s:f.EchoIfEq( expected, ... )
  if self.V() ==# a:expected
    return join( a:000, '' )
  else
    return self.V()
  endif
endfunction

fun! s:f.EchoIfNoChange( ... )
  if self.V() ==# self.ItemFullname()
    return join( a:000, '' )
  else
    return self.V()
  endif
endfunction

fun! s:f.Commentize( text )
  if has_key( self, '$CL' )
    return self[ '$CL' ] . ' ' . a:text . ' ' . self[ '$CR' ]

  elseif has_key( self, '$CS' )
    return self[ '$CS' ] . ' ' . a:text

  endif

  return a:text
endfunction

fun! s:f.VoidLine()
  return self.Commentize( 'void' )
endfunction

" Same with Echo* except echoed text is to be build to generate dynamic place
" holders
fun! s:f.Build( ... )
  return { 'action' : 'build', 'text' : join( a:000, '' ) }
endfunction

fun! s:f.BuildIfChanged( ... )
  let v = substitute( self.V(), "\\V\n\\|\\s", '', 'g')
  let fn = substitute( self.ItemFullname(), "\\V\n\\|\\s", '', 'g')

  if v ==# fn || v == ''
      " return { 'action' : 'keepIndent', 'text' : self.V() }
      return ''
  else
      return { 'action' : 'build', 'text' : join( a:000, '' ) }
  endif
endfunction

fun! s:f.BuildIfNoChange( ... )
  let v = substitute( self.V(), "\\V\n\\|\\s", '', 'g')
  let fn = substitute( self.ItemFullname(), "\\V\n\\|\\s", '', 'g')

  if v ==# fn
      return { 'action' : 'build', 'text' : join( a:000, '' ) }
  else
      return { 'action' : 'keepIndent', 'text' : self.V() }
  endif
endfunction

" trigger nested template
fun! s:f.Trigger(name) "{{{
  return {'action' : 'expandTmpl', 'tmplName' : a:name}
endfunction "}}}


fun! s:f.Finish(...)
    return { 'action' : 'finishTemplate', 'postTyping' : join( a:000 ) }
endfunction

fun! s:f.Embed( snippet )
  return { 'action' : 'embed', 'snippet' : a:snippet }
endfunction

fun! s:f.Next( ... )
  if a:0 == 0
    return { 'action' : 'next' }
  else
    return { 'action' : 'next', 'text' : join( a:000, '' ) }
  endif
endfunction

" This function is intented to be used for popup selection :
" XSET bidule=Choose([' ','dabadi','dabada'])
fun! s:f.Choose( lst ) "{{{
    return a:lst
endfunction "}}}

fun! s:f.ChooseStr(...) "{{{
  return copy( a:000 )
endfunction "}}}

" XXX
" Fill in postType, and finish template rendering at once. 
" This make nested template rendering go back to upper level, top-level
" template rendering quit.
fun! s:f.xptFinishTemplateWith(postType) dict
endfunction

" XXX  
" Fill in postType, jump to next item. For creating item being able to be
" automatically filled in
fun! s:f.xptFinishItemWith(postType) dict
endfunction

" TODO test me
" unescape marks
fun! s:f.UE(string) dict
  let patterns = self.C().tmpl.ptn
  let charToEscape = '\(\[' . patterns.l . patterns.r . ']\)'

  let r = substitute( a:string,  '\v(\\*)\1\\?\V' . charToEscape, '\1\2', 'g')

  return r

endfunction





fun! s:f.headerSymbol(...) "{{{
  let h = expand('%:t')
  let h = substitute(h, '\.', '_', 'g') " replace . with _
  let h = substitute(h, '.', '\U\0', 'g') " make all characters upper case

  return '__'.h.'__'
endfunction
 "}}}
 "
fun! s:f.date(...) "{{{
  return strftime("%Y %b %d")
endfunction "}}}
fun! s:f.datetime(...) "{{{
  return strftime("%c")
endfunction "}}}
fun! s:f.time(...) "{{{
  return strftime("%H:%M:%S")
endfunction "}}}
fun! s:f.file(...) "{{{
  return expand("%:t")
endfunction "}}}
fun! s:f.fileRoot(...) "{{{
  return expand("%:t:r")
endfunction "}}}
fun! s:f.fileExt(...) "{{{
  return expand("%:t:e")
endfunction "}}}
fun! s:f.path(...) "{{{
  return expand("%:p")
endfunction "}}}


fun! s:f.UpperCase( v )
  return substitute(a:v, '.', '\u&', 'g')
endfunction

fun! s:f.LowerCase( v )
  return substitute(a:v, '.', '\l&', 'g')
endfunction



" Return Item Edges
fun! s:f.ItemEdges() "{{{
  let leader =  get( self._ctx, 'leadingPlaceHolder', {} )
  if has_key( leader, 'leftEdge' )
      return [ leader.leftEdge, leader.rightEdge ]
  else
      return [ '', '' ]
  endif
endfunction "}}}


fun! s:f.ItemCreate( name, edges, filters )
  let [ ml, mr ] = XPTmark()


  let item = ml . a:name
  
  if has_key( a:edges, 'left' )
    let item = ml . a:edges.left . item 
  endif

  if has_key( a:edges, 'right' )
    let item .= ml . a:edges.right
  endif

  let item .= mr

  if has_key( a:filters, 'post' )
    let item .= a:filters.post . mr . mr
  endif

  return item

endfunction

" {{{ Quick Repetition
" If something typed, <tab>ing to next generate another item other than the
" typed.
"
" If nothing typed but only <tab> to next, clear it.
"
" Normal clear typed, also clear it
" TODO escape mark character in a:sep or a:item
" }}}
fun! s:f.ExpandIfNotEmpty( sep, item, ... ) "{{{
  let v = self.V()

  let marks = XPTmark()

  if a:0 != 0
    let r = a:1
  else
    let r = ''
  endif
  
  let t = ( v == '' || v == a:item || v == ( a:sep . a:item ) )
        \ ? ''
        \ : ( v . marks[0] . a:sep . marks[0] . a:item . marks[0] . r . marks[1] . 'ExpandIfNotEmpty("' . a:sep . '", "' . a:item  . '")' . marks[1] . marks[1] )

  return t
endfunction "}}}

let s:xptCompleteMap = [ 
            \"''",
            \'""',
            \'()',
            \'[]',
            \'{}',
            \'<>',
            \'||',
            \'**',
            \'``', 
            \]
let s:xptCompleteLeft = join( map( deepcopy( s:xptCompleteMap ), 'v:val[0:0]' ), '' )
let s:xptCompleteRight = join( map( deepcopy( s:xptCompleteMap ), 'v:val[1:1]' ), '' )

fun! s:f.CompleteRightPart( left ) dict
    let v = self.V()
    " let left = substitute( a:left, '[', '[[]', 'g' )
    let left = escape( a:left, '[\' )
    let v = matchstr( v, '^\V\[' . left . ']\+' )
    if v == '' 
        return ''
    endif

    let v = join( reverse( split( v, '\s*' ) ), '')
    let v = tr( v, s:xptCompleteLeft, s:xptCompleteRight )
    return v

endfunction

fun! s:f.CmplQuoter_pre() dict
    let v = substitute( self.ItemStrippedValue(), '\V\^\s\*', '', '' )

    let first = matchstr( v, '\V\^\[''"]' )
    if first == ''
        return ''
    endif

    let v = substitute( v, '\V\[^' . first . ']', '', 'g' )
    if v == first
        " only 1 quoter
        return first
    else
        return ''
    endif
endfunction




" Short name is not good. Some alias to those short name functions are
" made, with a meaningful names.
" 
" They all start with prefix 'xpt'
"

let s:f.Edges = s:f.ItemEdges

let s:f.ItemName = s:f.N
let s:f.ItemFullname = s:f.NN
let s:f.ItemValue = s:f.V
let s:f.ItemStrippedValue = s:f.V0
" s:f.E
let s:f.Context = s:f.C
" s:f.S 
let s:f.SubstituteWithValue = s:f.SV
let s:f.Reference = s:f.R
let s:f.Void = s:f.VOID
let s:f.UnescapeMarks = s:f.UE

" ================================= Snippets ===================================
call XPTemplateMark('`', '^')

" Shortcuts
call XPTemplate('Author', '`$author^')
call XPTemplate('Email', '`$email^')
call XPTemplate("Date", "`date()^")
call XPTemplate("File", "`file()^")
call XPTemplate("Path", "`path()^")

" wrapping snippets do not need using \w as name
call XPTemplate('"_', {'hint' : '" ... "'}, '"`wrapped^"')
call XPTemplate("'_", {'hint' : "' ... '"}, "'`wrapped^'")
call XPTemplate("<_", {'hint' : '< ... >'}, '<`wrapped^>')
call XPTemplate("(_", {'hint' : '( ... )'}, '(`wrapped^)')
call XPTemplate("[_", {'hint' : '[ ... ]'}, '[`wrapped^]')
call XPTemplate("{_", {'hint' : '{ ... }'}, '{`wrapped^}')
call XPTemplate("`_", {'hint' : '` ... `'}, '\``wrapped^\`')
