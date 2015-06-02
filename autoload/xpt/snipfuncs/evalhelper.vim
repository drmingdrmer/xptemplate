if exists( "g:__AL_XPT_EVALSUPPORT_f67523jhrk" ) && g:__AL_XPT_EVALSUPPORT_f67523jhrk >= 1
	finish
endif
let g:__AL_XPT_EVALSUPPORT_f67523jhrk = 1
let s:oldcpo = &cpo
set cpo-=< cpo+=B
let s:f = xpt#snipfunction#funcs
fun! s:f.GetVar(name)
	if a:name =~# '\V\^$_x'
		let n = a:name[1 :]
		return self.Call(n,[])
	endif
	let closures = self._ctx.closures
	let i = len(closures)
	while i > 0
		let i = i - 1
		let c = closures[i]
		let v = get(c,a:name,0)
		if v isnot 0
			return v
		endif
	endwhile
	return ''
endfunction
fun! s:f.Call(name,args)
	let F = get(self,a:name,0)
	if type(F) == type(function('tr'))
		return call(F,a:args,self)
	else
		return call(function(a:name),a:args)
	endif
endfunction
fun! s:f.Concat(...)
	let lst = a:000
	if len(lst) == 0
		return ''
	endif
	let rst = {}
	for e in lst
		if type(e) == type(0)
			if e == 0
				return 0
			else
				let elt = string(e)
			endif
		else
			let elt = e
		endif
		if type(elt) == type('')
			let rst.text = get(rst, 'text', '') . elt
		elseif type(elt) == type([])
			let rst.action = get(rst, 'action', 'pum')
			let rst.pum = get(rst, 'pum', elt)
		else
			if has_key(rst, 'text') && has_key(elt, 'text')
				let rst.text .= elt.text
			endif
			call extend(rst, elt, 'keep')
		endif
		unlet e
		unlet elt
	endfor
	let ks = keys(rst)
	if len(ks) == 1 && ks[0] == 'text'
		return rst.text
	end
	return rst
endfunction
let &cpo = s:oldcpo
