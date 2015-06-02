exec xpt#once#init
let s:oldcpo = &cpo
set cpo-=< cpo+=B
call XPT#default('g:xptemplate_cwd_snippet', 0)
augroup XPT_CWD_SNIPPET
	au!
	if g:xptemplate_cwd_snippet == 1
		au BufEnter * call xpt#cwd#snpt#load()
		au FileType * call xpt#cwd#snpt#reload()
		au BufUnload * call xpt#cwd#snpt#clearFlag()
	endif
augroup END
let &cpo = s:oldcpo
