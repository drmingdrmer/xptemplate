if exists("g:__XPT_VIM__")
	finish
endif
let g:__XPT_VIM__ = 1
let s:oldcpo = &cpo
set cpo-=< cpo+=B
let XPT#ver = 2
let XPT#let_sid = 'map <Plug>xsid <SID>|let s:sid=matchstr(maparg("<Plug>xsid"), "\\d\\+_")|unmap <Plug>xsid'
let XPT#nullDict = {}
let XPT#nullList = []
let XPT#escapeHead   = '\v(\\*)\V'
let XPT#unescapeHead = '\v(\\*)\1\\?\V'
let XPT#nonEscaped = '\%(' .     '\%(\[^\\]\|\^\)' .     '\%(\\\\\)\*' . '\)' . '\@<='
let XPT#regEval     = '\V\w(\|$\w'
let XPT#nonsafe     = '{$( '
let XPT#nonsafeHint = '$('
let XPT#item_var   = '\V' . '$\w\+'
let XPT#item_qvar  = '\V' . '{$\w\+}'
let XPT#item_func  = '\V' . '\w\+(\.\*)'
let XPT#item_qfunc = '\V' . '{\w\+(\.\*)}'
let XPT#ptnIncFull = '\V' . '\^Include:' . '\zs' . '\(\.\{-}\)\$'
let XPT#ptnIncSimp = '\V' . '\^:' . '\zs' . '\(\.\{-}\)' . '\ze' . ':\$'
let XPT#ptnRepetition = '\V'. '\^\w\*...\w\*\$'
let XPT#ptnPreEvalFunc = '\v^%(Inc|Inline|ResetIndent|Pre)\('
let XPT#NONE = 0x000
let XPT#BUILT = 0x001
let XPT#NOTBUILT = 0x002
let XPT#DONE = 0x100
let XPT#UNDONE = 0x200
let XPT#GOON = 0x300
let XPT#AGAIN = 0x400
let XPT#BROKEN = -1
let XPT#importConst = '' . 'let s:escapeHead     = XPT#escapeHead | ' . 'let s:unescapeHead   = XPT#unescapeHead | ' . 'let s:nonEscaped     = XPT#nonEscaped | ' . 'let s:regEval        = XPT#regEval | ' . 'let s:nonsafe        = XPT#nonsafe | ' . 'let s:nonsafeHint    = XPT#nonsafeHint | ' . 'let s:nullDict       = XPT#nullDict | ' . 'let s:nullList       = XPT#nullList | ' . 'let s:item_var       = XPT#item_var   | ' . 'let s:item_qvar      = XPT#item_qvar  | ' . 'let s:item_func      = XPT#item_func  | ' . 'let s:item_qfunc     = XPT#item_qfunc | ' . 'let s:ptnIncFull     = XPT#ptnIncFull | ' . 'let s:ptnIncSimp     = XPT#ptnIncSimp | ' . 'let s:ptnRepetition  = XPT#ptnRepetition | ' . 'let s:ptnPreEvalFunc = XPT#ptnPreEvalFunc | ' . 'let s:NONE           = XPT#NONE | ' . 'let s:DONE           = XPT#DONE | ' . 'let s:UNDONE         = XPT#UNDONE | ' . 'let s:GOON           = XPT#GOON | ' . 'let s:AGAIN          = XPT#AGAIN | ' . 'let s:BROKEN         = XPT#BROKEN | ' . 'let s:BUILT          = XPT#BUILT | ' . 'let s:NOTBUILT       = XPT#NOTBUILT | '  . 'let s:R_NEXT = 0x008 | ' . 'let s:R_OUT  = 0x009 | ' . 'let s:R_     = 0x00A | ' . 'let s:R_FOO  = 0x00B | '  . 'let s:G_CRESTED   = 0x010 | ' . 'let s:G_INITED    = 0x020 | ' . 'let s:G_PROCESSED = 0x030 | ' . 'let s:G_REFOCUSED = 0x040 | '
let XPT#priorities = {'all' : 192, 'spec' : 160, 'like' : 128, 'lang' : 96, 'sub' : 64, 'personal' : 32}
let XPT#skipPattern = 'synIDattr(synID(line("."), col("."), 0), "name") =~? "\\vstring|comment"'
fun! XPT#warn(msg)
	echohl WarningMsg
	echom a:msg
	echohl
endfunction
fun! XPT#info(msg)
	echom a:msg
endfunction
fun! XPT#error(msg)
	echohl ErrorMsg
	echom a:msg
	echohl
endfunction
fun! XPT#fallback(fbs)
	let fbs = a:fbs
	if len(fbs) > 0
		let [key,flag] = fbs[0]
		call remove(fbs,0)
		if flag == 'feed'
			call feedkeys( key, 'mt' )
			return ''
		else
			return key
		endif
	else
		return ''
	endif
endfunction
fun! XPT#softTabStop()
	let ts = &l:tabstop
	return &l:softtabstop == 0 ? ts : &l:softtabstop
endfunction
fun! XPT#getIndentNr(ln,col)
	let line = matchstr( getline(a:ln), '\V\^\s\*' )
	let line = ( a:col == 1 ) ? '' : line[ 0 : a:col - 1 - 1 ]
	let tabspaces = repeat( ' ', &l:tabstop )
	return len( substitute( line, '	', tabspaces, 'g' ) )
endfunction
fun! XPT#getPreferedIndentNr(ln)
	if &indentexpr != ''
		let indentexpr = substitute( &indentexpr, '\Vv:lnum', a:ln, '' )
		try
			return eval(indentexpr)
		catch /.*/
			return -1
		endtry
	elseif &cindent
		return cindent(a:ln)
	else
		return -1
	endif
endfunction
fun! XPT#getCmdOutput(cmd)
	let l:a = ""
	redir => l:a
	exe a:cmd
	redir END
	return l:a
endfunction
fun! XPT#convertSpaceToTab(text)
	if ( "\n" . a:text ) !~ '\V\n ' || &expandtab
		return a:text
	else
		let tabspaces = repeat( ' ',  &tabstop )
		let lines = split( a:text, '\V\n', 1 )
		let newlines = []
		for line in lines
			let newline = join( split( line, '\V\^\%(' . tabspaces . '\)', 1 ), '	' )
			let newlines += [newline]
		endfor
		return join( newlines, "\n" )
	endif
endfunction
fun! XPT#SpaceToTab(lines)
	if ! &expandtab && match( a:lines, '\v^ ' ) > -1
		let cmd = 'join( split( v:val, ''\v^%('' . repeat( '' '',  &tabstop ) . '')'', 1 ), ''	'' )'
		call map(a:lines,cmd)
	endif
	return a:lines
endfunction
fun! XPT#SpaceToTabExceptFirstLine(lines)
	if ! &expandtab && len( a:lines ) > 1 && match( a:lines, '\v^ ', 1 ) > -1
		let line0 = a:lines[0]
		let cmd = 'join( split( v:val, ''\v^%('' . repeat( '' '',  &tabstop ) . '')'', 1 ), ''	'' )'
		call map(a:lines,cmd)
		let a:lines[0] = line0
	endif
	return a:lines
endfunction
fun! XPT#TextBetween(posList)
	return join(XPT#LinesBetween( a:posList ), "\n")
endfunction
fun! XPT#TextInLine(ln,s,e)
	if a:s >= a:e
		return ""
	endif
	return getline(a:ln)[a:s - 1 : a:e - 2]
endfunction
fun! XPT#LinesBetween(posList)
	let [s,e] = a:posList
	if s[0] > e[0]
		return ""
	endif
	if s[0] == e[0]
		if s[1] == e[1]
			return ""
		else
			return getline(s[0])[s[1] - 1 : e[1] - 2]
		endif
	endif
	let r = [getline(s[0])[s[1] - 1:]] + getline(s[0]+1,e[0]-1)
	if e[1] > 1
		let r += [getline(e[0])[:e[1] - 2]]
	else
		let r += ['']
	endif
	return r
endfunction
fun! XPT#default(k,v)
	if !exists(a:k)
		exe "let" a:k "=" string( a:v )
	endif
endfunction
fun! XPT#Strlen(s)
	return strlen(substitute(a:s, ".", "x", "g"))
endfunction
fun! XPT#Assert(toBeTrue,msg)
	if !a:toBeTrue
		call XPT#warn(a:msg)
		if g:xpt_test_on_error == 'stop'
			throw "XPT_TEST: fail: " . a:msg
		endif
	endi
endfunction
fun! XPT#AssertEq(a,b,msg)
	call XPT#Assert( a:a == a:b, 'expect:' . string( a:a ) . ' but:' . string( a:b ) . ' message:' . a:msg )
endfunction
let &cpo = s:oldcpo
