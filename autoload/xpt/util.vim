exe xpt#once#init
let s:oldcpo = &cpo
set cpo-=< cpo+=B
let s:log = xpt#debug#Logger( 'warn' )
exe XPT#importConst
let s:charsPatternTable = {}
fun! xpt#util#Flatten(arr)
	let r = []
	for e in a:arr
		if type(e) == 3
			call extend(r,xpt#util#Flatten(e))
		else
			let r += [e]
		endif
		unlet e
	endfor
	return r
endfunction
fun! xpt#util#SplitWith(str,char)
	let s = split( a:str, '\V' . s:nonEscaped . a:char, 1 )
	return s
endfunction
fun! xpt#util#UnescapeChar(str,chars)
	if a:chars == ""
		return a:str
	endif
	if has_key(s:charsPatternTable,a:chars)
		return substitute( a:str, s:charsPatternTable[ a:chars ], '\1', 'g' )
	else
		return substitute( a:str, s:GetUnescapeCharPattern( a:chars ), '\1', 'g' )
	endif
endfunction
fun! xpt#util#DeepExtend(to,from)
	for key in keys(a:from)
		if type(a:from[key]) == 4
			if has_key(a:to,key)
				call xpt#util#DeepExtend(a:to[key],a:from[key])
			else
				let a:to[key] = a:from[key]
			endif
		elseif type(a:from[key]) == 3
			if has_key(a:to,key)
				call extend(a:to[key],a:from[key])
			else
				let a:to[key] = a:from[key]
			endif
		else
			let a:to[key] = a:from[key]
		endif
	endfor
endfunction
fun! xpt#util#RemoveDuplicate(list)
	let dict = {}
	let newList = []
	for e in a:list
		if !has_key(dict,e)
			call add(newList,e)
		endif
		let dict[e] = 1
	endfor
	return newList
endfunction
fun! xpt#util#ExpandTab(text,n)
	if stridx( a:text, "	" ) < 0
		return a:text
	endif
	let str = "\n" . a:text
	let tabspaces = repeat( ' ', a:n )
	let last = ''
	while str != last
		let last = str
		let str = substitute( str, '\n	*\zs	', tabspaces, 'g' )
	endwhile
	return str[1 :]
endfunction
fun! xpt#util#convertSpaceToTab(text)
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
fun! xpt#util#SpaceToTab(lines)
	if ! &expandtab && match( a:lines, '\v^ ' ) > -1
		let cmd = 'join( split( v:val, ''\v^%('' . repeat( '' '',  &tabstop ) . '')'', 1 ), ''	'' )'
		call map(a:lines,cmd)
	endif
	return a:lines
endfunction
fun! xpt#util#SpaceToTabExceptFirstLine(lines)
	if ! &expandtab && len( a:lines ) > 1 && match( a:lines, '\v^ ', 1 ) > -1
		let line0 = a:lines[0]
		let cmd = 'join( split( v:val, ''\v^%('' . repeat( '' '',  &tabstop ) . '')'', 1 ), ''	'' )'
		call map(a:lines,cmd)
		let a:lines[0] = line0
	endif
	return a:lines
endfunction
fun! xpt#util#AddIndent(text,nIndent)
	let baseIndent = repeat( " ", a:nIndent )
	return substitute(a:text, '\n', '&' . baseIndent, 'g')
endfunction
fun! xpt#util#AddIndent2(text,nIndent)
	let baseIndent = repeat( " ", a:nIndent )
	if type( a:text ) == type( '' )
		return substitute(a:text, '\n', '&' . baseIndent, 'g')
	else
		call map( a:text, string( baseIndent ) . '.v:val' )
		let a:text[0] = a:text[0][a:nIndent :]
		return a:text
	endif
endfunction
fun! xpt#util#getIndentNr(pos)
	let [ln,col] = a:pos
	let line = matchstr( getline( ln ), '\V\^\s\*' )
	if 1
		if col == 1
			return 0
		else
			let line = line[0 : col - 1 - 1]
			return virtcol([ln,len(line)])
		endif
	else
		let line = ( col == 1 ) ? '' : line[ 0 : col - 1 - 1 ]
		let tabspaces = repeat( ' ', &tabstop )
		return len( substitute( line, '	', tabspaces, 'g' ) )
	endif
endfunction
fun! xpt#util#LastIndent(text)
	if a:text is ''
		return 0
	endif
	let text = split( a:text, '\V\n', 1 )[ -1 ]
	return len( matchstr( text, '\V\^\s\+' ) )
endfunction
fun! xpt#util#GetPreferedIndentNr(ln)
	if &indentexpr == ''
		return -1
	else
		let indentexpr = substitute( &indentexpr, '\Vv:lnum', a:ln, '' )
		try
			return eval(indentexpr)
		catch /.*/
			return -1
		endtry
	endif
endfunction
fun! xpt#util#TextBetween(posList)
	return join(xpt#util#LinesBetween( a:posList ), "\n")
endfunction
fun! xpt#util#TextInLine(ln,s,e)
	if a:s >= a:e
		return ""
	endif
	return getline(a:ln)[a:s - 1 : a:e - 2]
endfunction
fun! xpt#util#LinesBetween(posList)
	let [s,e] = a:posList
	if s[0] > e[0] || e[0] == 0
		return [""]
	endif
	let r = getline(s[0],e[0])
	let r[-1] = strpart(r[-1],0,e[1] - 1)
	let r[0] = strpart(r[0],s[1] - 1)
	return r
endfunction
fun! xpt#util#SynNameStack(l,c)
	if exists( '*synstack' )
		let ids = synstack(a:l,a:c)
		if empty(ids)
			return []
		endif
		let names = []
		for id in ids
			let names = names + [synIDattr(id, "name")]
		endfor
		return names
	else
		return [synIDattr( synID( a:l, a:c, 0 ), "name" )]
	endif
endfunction
fun! xpt#util#NearestSynName()
	let pos = [ line( "." ), col( "." ) ]
	let synName = synIDattr(synID(pos[0], pos[1], 1), "name")
	if synName == ''
		let prevPos = searchpos( '\S', 'bWn' )
		if prevPos == [0,0]
			return synName
		endif
		let synName = synIDattr(synID(prevPos[0], prevPos[1], 1), "name")
		if synName == ''
			return &filetype
		endif
	endif
	return synName
endfunction
fun! xpt#util#CharsPattern(chars,...)
	let is_magic = 0
	if a:0 > 0 && a:1 is 1
		let is_magic = 1
	endif
	let esc = '\['
	if is_magic
		let esc = '['
	endif
	let pattern = esc . escape( a:chars, '\]-^' ) . ']'
	return pattern
endfunction
fun! s:GetUnescapeCharPattern(chars)
	let chars = substitute( a:chars, '\\', '', 'g' )
	let pattern = s:unescapeHead . '\ze\[' . escape( chars, '\]-^' ) . ']'
	let s:charsPatternTable[a:chars] = pattern
	return pattern
endfunction
fun! xpt#util#getCmdOutput(cmd)
	let l:a = ""
	redir => l:a
	exe a:cmd
	redir END
	return l:a
endfunction
fun! xpt#util#Fallback(fbs)
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
let &cpo = s:oldcpo
