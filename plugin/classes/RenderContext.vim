if exists( "g:__RENDERCONTEXT_VIM__" ) && g:__RENDERCONTEXT_VIM__ >= XPT#ver
	finish
endif
let g:__RENDERCONTEXT_VIM__ = XPT#ver
let s:oldcpo = &cpo
set cpo-=< cpo+=B
let s:proto = {}
let g:xptRenderPhase = { 'uninit':'uninit'   , 'popup':'popup'    , 'inited':'inited'   , 'rendering':'rendering', 'rendered':'rendered' , 'iteminit':'iteminit' , 'fillin':'fillin'   , 'post':'post'     , 'finished':'finished' , }
let p = g:xptRenderPhase
let s:phaseGraph = { p.uninit : [p.popup,p.inited], p.popup : [p.inited], p.inited : [p.rendering], p.rendering : [p.rendered], p.rendered : [p.iteminit], p.iteminit : [p.iteminit,p.fillin,p.post], p.fillin : [p.post,p.finished], p.post : [p.finished,p.iteminit], p.finished : [p.uninit], }
unlet p
fun! s:New(x) dict
	let pre = "X" . len( a:x.stack ) . '_'
	call extend(self,{ 'ftScope':{}, 'level':len( a:x.stack ), 'snipObject':{}, 'evalContext':{}, 'phase':g:xptRenderPhase.uninit, 'action':'', 'wrap':{}, 'markNamePre':pre, 'item':{}, 'leadingPlaceHolder':{}, 'activeLeaderMarks':'innerMarks', 'history':[], 'namedStep':{}, 'processing':0, 'marks':{ 'tmpl':{ 'start':pre . '`tmpl`s', 'end':pre . '`tmpl`e' } }, 'itemDict':{}, 'itemList':[], 'lastContent':'', 'snipSetting':{}, 'tmpmappings':{}, 'oriIndentkeys':{}, 'leadingCharToReindent':{}, }, 'force' )
	let lst = split( &indentkeys, ',' )
	let indentkeysList = []
	for k in lst
		if k == ""
			let indentkeysList[ -1 ] .= ','
		else
			if k[ 0 ] == '0'
				call add(indentkeysList,k)
			endif
		endif
	endfor
	for k in indentkeysList
		if k[ 1 ] == '=' && len( k ) > 2
			let self.oriIndentkeys[k[2:]] = 1
		else
			let self.leadingCharToReindent[k[1:]] = 1
		endif
	endfor
endfunction
fun! s:SwitchPhase(nextPhase) dict
	if -1 == match( s:phaseGraph[ self.phase ], '\V\<' . a:nextPhase . '\>' )
		throw 'XPT:RenderContext:switching from [' . self.phase . '] to [' . a:nextPhase . '] is not allowed'
	endif
	let self.phase = a:nextPhase
endfunction
exe XPT#let_sid
let g:RenderContext = XPT#class(s:sid,s:proto)
let &cpo = s:oldcpo
