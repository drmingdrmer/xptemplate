if exists( "g:__AUTOLOAD__XPT__CWC__SNPT_VIM__" )
	finish
endif
let g:__AUTOLOAD__XPT__CWC__SNPT_VIM__ = 1
let s:oldcpo = &cpo
set cpo-=< cpo+=B
fun! xpt#cwd#snpt#load()
	if exists( 'b:xptemplate_cwd_snpt_loaded' )
		return
	endif
	call XPTemplateInit()
	for fn in split(globpath('.', '.xpt.vim'), '\n')
		exec 'so ' fn
	endfor
	for fn in split(globpath('.', '.' . &filetype . '.xpt.vim'), '\n')
		exec 'so ' fn
	endfor
	let b:xptemplate_cwd_snpt_loaded = 1
endfunction
fun! xpt#cwd#snpt#reload()
	if exists( 'b:xptemplate_cwd_snpt_loaded' )
		unlet b:xptemplate_cwd_snpt_loaded
	endif
	return xpt#cwd#snpt#load()
endfunction
fun! xpt#cwd#snpt#clearFlag()
	if exists( 'b:xptemplate_cwd_snpt_loaded' )
		unlet b:xptemplate_cwd_snpt_loaded
	endif
endfunction
let &cpo = s:oldcpo
