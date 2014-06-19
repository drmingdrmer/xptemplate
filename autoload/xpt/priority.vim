if exists( "g:__AL_XPT_PRIORITY_f78d9s873942__" ) && g:__AL_XPT_PRIORITY_f78d9s873942__ >= XPT#ver
	finish
endif
let g:__AL_XPT_PRIORITY_f78d9s873942__ = XPT#ver
let s:oldcpo = &cpo
set cpo-=< cpo+=B
let s:priorities = { 'lowest': 9999999, 'all':64, 'spec' : 48, 'like' : 32, 'lang' : 16, 'sub':8, 'personal' : 0, 'highest':-1, }
let s:priorities.default = s:priorities.lang
fun! xpt#priority#Get(pstr)
	return s:priorities[a:pstr]
endfunction
fun! xpt#priority#Parse(pstr)
	let pstr = a:pstr
	if pstr =~ '\V\[+-]\$'
		let pstr .= '1'
	endif
	let reg = '\V\(\w\+\|\[+-]\)\zs'
	let prioParts = split(pstr,reg)
	let prioParts[0] = get(s:priorities,prioParts[0],prioParts[0] - 0)
	return eval( join( prioParts, '' ) )
endfunction
let &cpo = s:oldcpo
