exec xpt#once#init
let s:oldcpo = &cpo
set cpo-=< cpo+=B
let s:log = xpt#debug#Logger( 'warn' )
exe XPT#importConst
let s:indent_convert_cmd = 'substitute(v:val, ''\v(^\s*)@<=    '', ''	'', "g" )'
fun! xpt#indent#ParseStr(text,first_line_shift)
	let text = xpt#indent#IndentToTabStr(a:text)
	return xpt#indent#ToActualIndentStr(text,a:first_line_shift)
endfunction
fun! xpt#indent#IndentToTabStr(text)
	let lines = split( a:text, '\n', 1 )
	call xpt#indent#IndentToTab(lines)
	return join(lines, "\n")
endfunction
fun! xpt#indent#ToActualIndentStr(text,first_line_shift)
	let lines = split( a:text, '\n', 1 )
	call xpt#indent#ToActualIndent(lines,a:first_line_shift)
	return join(lines, "\n")
endfunction
fun! xpt#indent#IndentToTab(lines)
	call map(a:lines,s:indent_convert_cmd)
endfunction
fun! xpt#indent#ToActualIndent(lines,first_line_shift)
	let indent_spaces = repeat(' ', &shiftwidth)
	let cmd = 'substitute(v:val, ''\v(^	*)@<=	'', ''' . indent_spaces . ''', "g" )'
	call map(a:lines,cmd)
	if a:first_line_shift != 0
		let shift_spaces = repeat(' ', a:first_line_shift)
		let i = 1
		while i < len(a:lines)
			if a:lines[i] != '' || i == len(a:lines)-1
				let a:lines[i] = shift_spaces . a:lines[i]
			endif
			let i += 1
		endwhile
	endif
	if &expandtab
		return
	endif
	let tabspaces = repeat( ' ',  &tabstop )
	let cmd = 'substitute(v:val, ''\v(^\s*)@<=' . tabspaces . ''', ''	'', "g" )'
	call map(a:lines,cmd)
endfunction
fun! xpt#indent#IndentBefore(pos)
	let [ln,col] = a:pos
	let line = matchstr( getline(ln), '\V\^\s\*' )
	let line = ( col == 1 ) ? '' : line[ 0 : col - 1 - 1 ]
	let tabspaces = repeat( ' ', &tabstop )
	return len( substitute( line, '	', tabspaces, 'g' ) )
endfunction
fun! xpt#indent#RemoveIndentStr(text,nIndent)
	let reg = '\V\n \{,' . a:nIndent . '\}'
	let text = substitute(a:text, reg, '\n', 'g')
	return text
endfunction
fun! xpt#indent#ToSpace(text)
	if stridx( a:text, "	" ) < 0
		return a:text
	endif
	let tabspaces = repeat( ' ', &tabstop )
	let reg = '\v' . tabspaces . '| {0,' . (&tabstop-1) . '}	'
	let rst = []
	let lines = split( a:text, '\n', 1 )
	for line in lines
		let leading_space = matchstr( line, '\v\s*' )
		let left = line[len(leading_space) :]
		let l = substitute( leading_space, reg, tabspaces, 'g' )
		call add(rst,l . left)
	endfor
	return join(rst, "\n")
endfunction
fun! xpt#indent#SpaceToTab(text)
	let indent_spaces = repeat(' ', &shiftwidth)
	let reg = 'substitute(v:val, ''\v(^\s*)@<='.indent_spaces.''', "	", "g" )'
	let lines = split( a:text, '\n', 1 )
	call map(lines,reg)
	return join(lines, "\n")
endfunction
fun! xpt#indent#ActualToSnippetNr(n)
	let n_one_indent = &shiftwidth
	let n_indent = a:n / n_one_indent
	return n_indent * 4 + a:n % n_one_indent
endfunction
let &cpo = s:oldcpo
