exec xpt#once#init
let s:oldcpo = &cpo
set cpo-=< cpo+=B
let s:log = xpt#debug#Logger( 'warn' )
exe XPT#importConst
fun! xpt#ph#CreateFromScreen(snipObject,nameInfo,valueInfo)
	let xp = a:snipObject.ptn
	let toescape = xp.l . xp.r
	let leftEdge = xpt#util#TextBetween(a:nameInfo[0 : 1])
	let name = xpt#util#TextBetween(a:nameInfo[1 : 2])
	let rightEdge = xpt#util#TextBetween(a:nameInfo[2 : 3])
	let [leftEdge,name,rightEdge] = [leftEdge[1 :],name[1 :],rightEdge[1 :]]
	let leftEdge = xpt#util#UnescapeChar(leftEdge,toescape)
	let name = xpt#util#UnescapeChar(name,toescape)
	let rightEdge = xpt#util#UnescapeChar(rightEdge,toescape)
	if a:valueInfo[1] != a:valueInfo[0]
		let posList = [a:valueInfo[0],a:valueInfo[2]]
		let val = xpt#util#TextBetween(posList)
		let val = val[1:]
		let nIndent = indent(a:valueInfo[0][0])
		let phFilter =  { 'text' : val, 'indent' : nIndent, }
	else
		let phFilter = 0
	endif
	return xpt#ph#New(a:snipObject, { 'leftEdge'  : leftEdge, 'name':name, 'rightEdge':rightEdge, 'isKey':a:nameInfo[0] != a:nameInfo[1], }, phFilter )
endfunction
fun! xpt#ph#New(snipObject,pieces)
	let phptns = a:snipObject.ptn
	let textPieces = deepcopy(a:pieces)
	call map( textPieces, 'v:val.text' )
	let iFilter = match( textPieces, '\V\^' . a:snipObject.ptn.r )
	if iFilter > 1
		let ph ={ 'leftEdge':a:pieces[ 0 ], 'name':a:pieces[ 1 ].text, 'displayText':a:pieces[ 1 ], 'rightEdge':iFilter > 2 ? a:pieces[2] : { 'nIndent' : a:pieces[ 1 ].nIndent, 'text' : '' }, 'isKey':1 }
		let ph.fullname = ph.leftEdge.text . ph.name . ph.rightEdge.text
		for key in [ 'leftEdge', 'displayText', 'rightEdge' ]
			call xpt#ph#CreateEvaluatablePHElt(a:snipObject,ph,key)
		endfor
	else
		let ph ={ 'name':a:pieces[ 0 ].text, 'displayText':a:pieces[ 0 ], 'fullname':a:pieces[ 0 ].text }
		call xpt#ph#CreateEvaluatablePHElt( a:snipObject, ph, 'displayText' )
	endif
	let spec = xpt#ph#CreateSpecial(a:snipObject,ph)
	if spec isnot 0
		return spec
	endif
	if len(a:pieces) - iFilter == 1
		return ph
	endif
	let ftype = len( a:pieces ) - iFilter > 2 ? 'postFilter' : 'liveFilter'
	let fltPart = copy(a:pieces[iFilter])
	let fltPart.text = fltPart.text[1:]
	let fltPart.text = xpt#ph#AlterFilterByPHName(ph.name,fltPart.text)
	let flt = xpt#ph#CreatePHEltFilter(a:snipObject,fltPart)
	if has_key( ph, 'isKey' ) && ph.name != ''
		let a:snipObject.setting[ ftype . 's' ][ ph.name ] = flt
	else
		let ph[ftype] = flt
	endif
	return ph
endfunction
fun! xpt#ph#CreateEvaluatablePHElt(snipObject,ph,key)
	let phptns = a:snipObject.ptn
	if a:ph[ a:key ].text =~ '\V' . phptns.item_var . '\|' . phptns.item_func . '\|\n'
		let a:ph[a:key] = xpt#ph#CreatePHEltFilter(a:snipObject,a:ph[a:key])
	elseif a:ph[ a:key ].text =~ '\V' . s:ptnIncFull . '\|' . s:ptnIncSimp
		let a:ph[a:key] = xpt#ph#CreatePHEltFilter(a:snipObject,a:ph[a:key])
	else
		let a:ph[a:key] = xpt#util#UnescapeChar(a:ph[a:key].text,a:snipObject.ptn.lr)
	endif
endfunction
fun! xpt#ph#CreateSpecial(snipObject,ph)
	let phptns = a:snipObject.ptn
	if type(a:ph.displayText) == type({})
		if a:ph.displayText[ 'text' ] =~ s:ptnIncFull
			let params = matchstr( a:ph.displayText[ 'text' ], s:ptnIncFull )
			let [name,args] = xpt#snip#ParseInclusionStatement(a:snipObject,params)
			let a:ph.displayText[ 'text' ] = 'Inc(' . string( name ) . ', 1,  ' . string( args ) .')'
			return a:ph
		elseif a:ph.displayText[ 'text' ] =~ s:ptnIncSimp
			let params = matchstr( a:ph.displayText[ 'text' ], s:ptnIncSimp )
			let [name,args] = xpt#snip#ParseInclusionStatement(a:snipObject,params)
			let a:ph.displayText[ 'text' ] = 'Inc(' . string( name ) . ', 0,  ' . string( args ) .')'
			return a:ph
		endif
		let a:ph.value = 1
		return a:ph
	endif
	return 0
endfunction
fun! xpt#ph#FilterEltKeys(ph)
	let phKeys = [ 'leftEdge', 'displayText', 'rightEdge' ]
	call filter( phKeys, 'type( get( a:ph, v:val, 0 ) ) is ' . string( type( {} ) ) )
	return phKeys
endfunction
fun! xpt#ph#GetPresetFilter(ph,setting)
	let phLive = get( a:ph, 'liveFilter', g:EmptyFilter )
	if a:ph.name != ''
		let pre = get(a:setting.preValues,a:ph.name,g:EmptyFilter)
		if get( pre, 'force' )
			return pre
		endif
		let live = get(a:setting.liveFilters,a:ph.name,g:EmptyFilter)
		if get( live, 'force' )
			return live
		endif
		let phLive = phLive is g:EmptyFilter || get( pre, 'force' ) ? pre : phLive
		let phLive = phLive is g:EmptyFilter || get( live, 'force' ) ? live : phLive
	endif
	return phLive
endfunction
fun! xpt#ph#CreatePHEltFilter(snipObject,elt)
	let val = xpt#util#UnescapeChar(a:elt.text,a:snipObject.ptn.lr)
	return xpt#flt#New(-a:elt.nIndent,val)
endfunction
fun! xpt#ph#AlterFilterByPHName(phname,fltText)
	if a:phname =~ '\V...\$'
		let a:fltText = xpt#util#UnescapeChar( a:fltText, '$({' )
		return 'BuildIfNoChange(' . string( a:fltText ) . ')'
	endif
	return a:fltText
endfunction
let &cpo = s:oldcpo
