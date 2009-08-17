XPTemplate priority=all

" containers
let [s:f, s:v] = XPTcontainer()

XPTvar $author        $author is not set, you need to set g:xptemplate_vars="$author=your_name"
XPTvar $email         $email is not set, you need to set g:xptemplate_vars="$author=your_email@com"
XPTvar $BRACKETSTYLE  


XPTinclude
      \ _common/personal

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
fun! s:f.V() "{{{
  if has_key(self._ctx, 'value')
    return self._ctx.value
  else
    return ""
  endif
endfunction "}}}

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
  if self.V() ==# expected
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


" Same with Echo* except echoed text is to be build to generate dynamic place
" holders
fun! s:f.Build( ... )
  return { 'action' : 'build', 'text' : join( a:000, '' ) }
endfunction

fun! s:f.BuildIfNoChange( ... )
  let v = self.V()
  if v ==# self.ItemFullname()
    return { 'action' : 'build', 'text' : join( a:000, '' ) }
  else
    return v
  endif
endfunction





" trigger nested template
fun! s:f.Trigger(name) "{{{
  return {'action' : 'expandTmpl', 'tmplName' : a:name}
endfunction "}}}

" This function is intented to be used for popup selection :
" XSET bidule=Choose([' ','dabadi','dabada'])
fun! s:f.Choose( lst ) "{{{
    return a:lst
endfunction "}}}

fun! s:f.ChooseStr(...) "{{{
  return a:000
endfunction "}}}

fun! s:f.Finish()
    return { 'action' : 'finishTemplate', 'postTyping' : '' }
endfunction

fun! s:f.Embed( snippet )
  return { 'action' : 'embed', 'snippet' : a:snippet }
endfunction

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


" Short name is not good. Some alias to those short name functions are
" made, with a meaningful names.
" 
" They all start with prefix 'xpt'
"

let s:f.ItemName = s:f.N
let s:f.ItemFullname = s:f.NN
let s:f.ItemEdges = s:f.Edges
let s:f.ItemValue = s:f.V
" s:f.E
let s:f.Context = s:f.C
" s:f.S 
let s:f.SubstituteWithValue = s:f.SV
let s:f.Reference = s:f.R
let s:f.Void = s:f.VOID
let s:f.UnescapeMarks = s:f.UE



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


" draft increment implementation
fun! s:f.CntD() "{{{
  let ctx = self._ctx
  if !has_key(ctx, '__counter')
    let ctx.__counter = {}
  endif
  return ctx.__counter
endfunction "}}}
fun! s:f.CntStart(name, ...) "{{{
  let d = self.CntD()
  let i = a:0 >= 1 ? 0 + a:1 : 0
  let d[a:name] = 0 + i
  return ""
endfunction "}}}
fun! s:f.Cnt(name) "{{{
  let d = self.CntD()
  return d[a:name]
endfunction "}}}
fun! s:f.CntIncr(name, ...)"{{{
  let i = a:0 >= 1 ? 0 + a:1 : 1
  let d = self.CntD()

  let d[a:name] += i
  return d[a:name]
endfunction"}}}

" Return Item Edges
fun! s:f.ItemEdges() "{{{
  let lft_m = XPTmark()[0]
  let r = split(self.NN(), lft_m, 1)
  if len(r) == 1
    return ['','']
  elseif len(r) == 2
    return [r[0],'']
  else
    return [r[0],r[-1]]
  endif
endfunction "}}}

" {{{ Quick Repetition
" If something typed, <tab>ing to next generate another item other than the
" typed.
"
" If nothing typed but only <tab> to next, clear it.
"
" Normal clear typed, also clear it
" }}}
fun! s:f.ExpandIfNotEmpty(sep, item) "{{{
  let v = self.V()

  let marks = XPTmark()
  
  let t = ( v == '' || v == a:item || v == ( a:sep . a:item ) )
        \ ? ''
        \ : ( v . marks[0] . a:sep . marks[0] . a:item . marks[1] )

  return t
endfunction "}}}

" ================================= Snippets ===================================
call XPTemplateMark('`', '^')

" Shortcuts
call XPTemplate('Author', '`$author^')
call XPTemplate('Email', '`$email^')
call XPTemplate("Date", "`date()^")
call XPTemplate("File", "`file()^")
call XPTemplate("Path", "`path()^")

" wrapping snippets do not need using \w as name
call XPTemplate('"', {'hint' : '" ... "'}, '"`wrapped^"')
call XPTemplate("'", {'hint' : "' ... '"}, "'`wrapped^'")
call XPTemplate("<", {'hint' : '< ... >'}, '<`wrapped^>')
call XPTemplate("(", {'hint' : '( ... )'}, '(`wrapped^)')
call XPTemplate("[", {'hint' : '[ ... ]'}, '[`wrapped^]')
call XPTemplate("{", {'hint' : '{ ... }'}, '{`wrapped^}')
call XPTemplate("`", {'hint' : '\` ... \`'}, '\``wrapped^\`')
