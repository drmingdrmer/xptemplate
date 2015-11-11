let s:oldcpo = &cpo
set cpo-=< cpo+=B
let s:log = xpt#debug#Logger( 'warn' )
exe XPT#importConst
fun! xpt#group#New(name,sessid)
	let g = { 'name'      : a:name, 'fullname':a:name, 'initValue':a:name, 'phase':'created',  'processed':0, 'placeHolders':[], 'keyPH':s:nullDict, 'behavior':{}, 'sessid':a:sessid,  }
	return g
endfunction
fun! xpt#group#InsertPH(g,ph,where)
	if has_key( a:ph, 'isKey' ) && a:g.keyPH != s:nullDict
		unlet a:ph.isKey
	endif
	if has_key( a:ph, 'isKey' )
		let a:g.keyPH = a:ph
		let a:g.fullname = a:ph.fullname
	else
		call insert(a:g.placeHolders,a:ph,a:where)
	endif
endfunction
let &cpo = s:oldcpo
