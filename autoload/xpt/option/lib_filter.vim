exec xpt#once#init
let s:oldcpo = &cpo
set cpo-=< cpo+=B
call XPT#default('g:xptemplate_lib_filter', '\v.')
fun! xpt#option#lib_filter#Match(fn)
	if a:fn =~ '\V\<_\w\+\[/\\]\[^/\\]\+' || a:fn =~ '\V~~/xpt/pseudo/ftplugin/'
		return 1
	end
	let regs = []
	if type(g:xptemplate_lib_filter) == type('')
		let regs = [g:xptemplate_lib_filter]
	else
		let regs = g:xptemplate_lib_filter
	endif
	for r in regs
		if a:fn =~# r
			return 1
		endif
	endfor
	return 0
endfunction
let &cpo = s:oldcpo
