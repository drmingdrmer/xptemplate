if exists( "g:__AL_XPT_EVALSUPPORT_f67523jhrk" ) && g:__AL_XPT_EVALSUPPORT_f67523jhrk >= 1
	finish
endif
let g:__AL_XPT_EVALSUPPORT_f67523jhrk = 1
let s:oldcpo = &cpo
set cpo-=< cpo+=B
let s:f = xpt#snipfunction#funcs
fun! s:f.GetVar(name)
	if a:name =~# '\V\^$_x'
		try
			let n = a:name[1 :]
			return self[n]()
		catch /.*/
			return a:name
		endtry
	endif
	let r = self.renderContext
	let ev = get( self.evalContext, 'variables', {} )
	let rv = get( r.snipSetting, 'variables', {} )
	return get(ev,a:name, get(rv,a:name, get(self,a:name,a:name)))
endfunction
fun! s:f.Call(name,args)
	let F = get(self,a:name,0)
	if type(F) == type(function('tr'))
		return call(F,a:args,self)
	else
		return call(function(a:name),a:args)
	endif
endfunction
let &cpo = s:oldcpo
