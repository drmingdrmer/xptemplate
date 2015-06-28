exec xpt#once#init
let s:oldcpo = &cpo
set cpo-=< cpo+=B
let s:log = xpt#debug#Logger( 'warn' )
let s:log = xpt#debug#Logger( 'debug' )
let g:EmptyFilter = {}
let s:proto = { 'force':0, }
fun! xpt#flt#New(nIndent,text,...)
	let flt = deepcopy(s:proto)
	call extend(flt,{ 'nIndent':a:nIndent, 'text':a:text, 'force':a:0 == 1 && a:1, }, 'force' )
	return flt
endfunction
fun! xpt#flt#NewSimple(nIndent,text,...)
	let flt = { 'nIndent' : a:nIndent, 'text' : a:text, }
	if a:0 == 1 && a:1
		let flt.force = 1
	endif
	return flt
endfunction
fun! xpt#flt#Extend(flt)
	call extend( a:flt, s:proto, 'keep' )
endfunction
fun! xpt#flt#Simplify(flt)
	call filter( a:flt, 'v:val!=get(s:proto,v:key,-987654)' )
endfunction
fun! xpt#flt#Eval(snip,flt,closures)
	let snipptn = a:snip.ptn
	let r = { 'rc' : 1, 'parseIndent' : 1, 'nav' : 'stay' }
	let rst = xpt#eval#Eval(a:flt.text,a:closures)
	if type(rst) == type(0)
		let r.rc = 0
		return r
	endif
	if type( rst ) == type( '' )
		if rst =~ snipptn.lft
			let r.action = 'build'
		else
			let r.action = 'text'
		endif
		let r.text = rst
		return r
	endif
	if type(rst) == type([])
		let r.action = 'pum'
		let r.pum = rst
		return r
	endif
	call extend( r, rst, 'force' )
	if ! has_key( r, 'action' ) && has_key( r, 'text' )
		if r.text =~ snipptn.lft
			let r.action = 'build'
		else
			let r.action = 'text'
		endif
	endif
	let r.action = get( r, 'action', '' )
	if r.action ==# 'embed'
		let r.action = 'build'
	endif
	if has_key( r, 'cursor' )
		call xpt#flt#ParseCursorSpec(r)
	endif
	return r
endfunction
fun! xpt#flt#ParseCursorSpec(flt_rst)
	let rst = a:flt_rst
	if type(rst.cursor) == type([]) && type( rst.cursor[ 0 ] ) == type( '' )
		let rst.cursor = { 'rel' : 1, 'where':rst.cursor[ 0 ], 'offset':get( rst.cursor, 1, [ 0, 0 ] ) }
	endif
	let rst.isCursorRel = type(rst.cursor) == type({})
endfunction
fun! s:AddIndentToPHs(flt)
	if a:flt.rst.nIndent == 0
		return
	endif
	let nIndent = a:flt.rst.nIndent
	let rst = []
	for ph in a:flt.rst.phs
		if type( ph ) == type( '' )
			call add(rst,xpt#util#AddIndent(ph,nIndent))
		else
			call add(rst,ph)
		endif
		unlet ph
	endfor
	let a:flt.rst.phs = rst
endfunction
let &cpo = s:oldcpo
