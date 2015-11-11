if exists( "g:__AL_XPT_RENDER_VIM__" ) && g:__AL_XPT_RENDER_VIM__ >= XPT#ver
	finish
endif
let g:__AL_XPT_RENDER_VIM__ = XPT#ver
let s:oldcpo = &cpo
set cpo-=< cpo+=B
let s:log = xpt#debug#Logger( 'warn' )
let s:log = xpt#debug#Logger( 'debug' )
exe XPT#importConst
fun! xpt#render#New(rctx,posStart,...)
	let p = copy(a:posStart)
	let nSp = a:0 == 0 ? 0 : a:1
	let render = { 'rctx':a:rctx, 'outerIndent':xpt#util#getIndentNr( p ) + nSp, 'relIndent':0, 'nSpaceToAdd':nSp, 'start':copy( p ), 'pos':copy( p ), 'rst':[ '' ], 'marks':[], }
	let p[1] -= 1
	let render.offset = p[1] == 0 ? 0 : virtcol(p) - render.outerIndent
	return render
endfunction
let s:buildingSeqNr = 0
let s:anonymouseIndex = 0
fun! xpt#render#GenScreenData(render)
	let rctx = a:render.rctx
	call add(a:render.marks,[rctx.marks.tmpl.start, copy( a:render.pos ), 'l', '\Ve\$' ] )
	let rctx.groupList = []
	call xpt#render#GenScreenDataOfPHs(a:render,rctx.snipObject.parsedSnip)
	call add(a:render.marks,[rctx.marks.tmpl.end, copy( a:render.pos ), 'r', '\Ve\$' ] )
	return [a:render.rst,a:render.marks]
endfunction
fun! xpt#render#GenScreenDataOfPHs(render,phs)
	let rctx = a:render.rctx
	call xpt#rctx#InitOrderedGroupList(rctx)
	call xpt#render#BuildPHs(a:render,a:phs)
	call filter( rctx.firstList, 'type(v:val) != ' . string( type( '' ) ) )
	call filter( rctx.lastList,  'type(v:val) != ' . string( type( '' ) ) )
	let rctx.groupList = rctx.firstList + rctx.groupList + rctx.lastList
	return [a:render.rst,a:render.marks]
endfunction
let s:buildingSessionID = 0
let s:renderStack = []
fun! xpt#render#BuildPHs(render,phs)
	if empty(s:renderStack)
		let s:buildingSessionID += 1
		let a:render.rctx.itemDict = {}
	endif
	call add(s:renderStack,a:render)
	let a:render.rctx.buildingSessionID = s:buildingSessionID
	if a:render.nSpaceToAdd != 0
		let phs = [ repeat( ' ', a:render.nSpaceToAdd ) ] + a:phs
	else
		let phs = a:phs
	endif
	let phs = xpt#snip#EvalPresetFilters(a:render.rctx,phs,{ 'outerIndent':a:render.outerIndent, 'offset':a:render.offset, 'variables':{ '$_xN_OUTER_INDENT':a:render.outerIndent, '$_xOUTER_INDENT':repeat( ' ', a:render.outerIndent ),  '$_xN_OFFSET':a:render.offset, '$_xOFFSET':repeat( ' ', a:render.offset ), } })
	for ph in phs
		if type(ph) == type({})
			call xpt#rctx#AddDefaultPHFilters(a:render.rctx,ph)
		endif
		unlet ph
	endfor
	let s:buildingSeqNr += 1
	for ph in phs
		if type( ph ) == type( '' )
			call xpt#render#AppendText(a:render,ph)
		else
			call s:BuildPH(a:render,ph)
		endif
		unlet ph
	endfor
	call remove(s:renderStack,-1)
endfunction
fun! xpt#render#AppendFilter(render,flt)
	call xpt#flt#Eval(a:flt,a:render.rctx.ftScope.funcs, { 'nIndAdd' : a:render.relIndent } )
	let text = get( a:flt.rst, 'text', '' )
	call xpt#render#AppendText(a:render,text)
endfunction
fun! xpt#render#AppendText(render,text)
	if a:text =~ '\V\n'
		call xpt#render#AppendMultiLine(a:render,a:text,a:render.outerIndent)
	else
		let a:render.rst[-1] .= a:text
		let a:render.pos[1] += len(a:text)
	endif
endfunction
fun! xpt#render#AppendMultiLine(render,text,nIndent)
	if a:nIndent != 0
		let text = xpt#util#AddIndent(a:text,a:nIndent)
	else
		let text = a:text
	endif
	let textLines = split( text, "\n", 1 )
	let a:render.rst[-1] .= textLines[0]
	call extend(a:render.rst,textLines[1 :])
	call xpt#render#UpdatePosInfo(a:render)
endfunction
fun! xpt#render#UpdatePosInfo(render)
	let a:render.pos = [a:render.start[0] + len(a:render.rst) - 1, len(a:render.rst[-1]) + 1]
	let iNonspace = match( a:render.rst[ -1 ], '\v[^ ]' )
	let a:render.relIndent = iNonspace == -1 ? XPT#Strlen(a:render.rst[-1]) : iNonspace
endfunction
fun! s:BuildPH(render,ph)
	let [rctx,ph] = [a:render.rctx,a:ph]
	let g = xpt#rctx#GetGroup(rctx,ph.name)
	if g.sessid == rctx.buildingSessionID
		call xpt#group#InsertPH(g,a:ph,len(g.placeHolders))
	else
		call xpt#group#InsertPH(g,a:ph,0)
	endif
	call s:CreatePHMarkNames(rctx,g,ph)
	call add(a:render.marks,[ph.mark.start, copy( a:render.pos ), 'l' ] )
	if has_key( ph, 'isKey' )
		call s:Append( a:render, ph, 'leftEdge' )
		call add(a:render.marks,[ph.editMark.start, copy( a:render.pos ), 'l' ] )
		call xpt#render#AppendText( a:render, ph[ 'displayText' ] )
		call add(a:render.marks,[ph.editMark.end, copy( a:render.pos ), 'r' ] )
		call s:Append( a:render, ph, 'rightEdge' )
	else
		call xpt#render#AppendText( a:render, ph[ 'displayText' ] )
	endif
	call add(a:render.marks,[ph.mark.end, copy( a:render.pos ), 'r' ] )
endfunction
fun! s:CreatePHMarkNames(rctx,g,ph)
	if a:ph.name == ''
		let markName =  '``' . s:anonymouseIndex
		let s:anonymouseIndex += 1
	else
		let markName =  a:ph.name . s:buildingSeqNr . '`' . ( has_key( a:ph, 'isKey' ) ? 'k' : ( len( a:g.placeHolders ) - 1 ) )
	endif
	let markPre = a:rctx.markNamePre . markName . '`'
	call extend(a:ph, { 'mark' : { 'start' : markPre . 'os', 'end':markPre . 'oe', }, }, 'force' )
	if has_key( a:ph, 'isKey' )
		call extend(a:ph, { 'editMark' : { 'start' : markPre . 'is', 'end':markPre . 'ie', }, }, 'force' )
		let a:ph.innerMarks = a:ph.editMark
	else
		let a:ph.innerMarks = a:ph.mark
	endif
endfunction
fun! s:Append(render,ph,key)
	if has_key(a:ph,a:key)
			call xpt#render#AppendText(a:render,a:ph[a:key])
	endif
endfunction
let &cpo = s:oldcpo
