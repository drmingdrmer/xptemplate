if exists( "g:__AL_XPT_NG_VIM__" ) && g:__AL_XPT_NG_VIM__ >= XPT#ver
	finish
endif
let g:__AL_XPT_NG_VIM__ = XPT#ver
let s:oldcpo = &cpo
set cpo-=< cpo+=B
let s:priorities = XPT#priorities
fun! xpt#ng#SetFiletypeDetector(funName)
	if !exists("b:xptemplateData")
		call XPTemplateInit()
	endif
	let x = b:xptemplateData
	let prio = get( x.snipFileScope, 'priority', s:priorities.lang )
	if prio <= x.ftdetector.priority
		let x.ftdetector = { 'priority' : prio, 'func':function( a:funName ) }
	endif
endfunction
let &cpo = s:oldcpo
