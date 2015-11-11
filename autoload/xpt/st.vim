if exists( "g:__AL_XPT_ST_VIM__" ) && g:__AL_XPT_ST_VIM__ >= XPT#ver
	finish
endif
let g:__AL_XPT_ST_VIM__ = XPT#ver
let s:oldcpo = &cpo
set cpo-=< cpo+=B
let s:log = xpt#debug#Logger( 'warn' )
exe XPT#importConst
let s:proto = { 'hidden':0, 'variables':{}, 'preValues':{}, 'onfocusFilters':{}, 'mappings':{}, 'liveFilters':{}, 'postFilters':{}, 'replacements':{}, 'postQuoter':{}, 'comeFirst':[], 'comeLast':[], }
let s:protoDefault = { 'preValues':{ 'cursor' : xpt#flt#New( 0, '$CURSOR_PH' ) }, 'onfocusFilters':{ 'cursor' : xpt#flt#New( 0, 'FinishPH({"text":""})' ) }, 'postQuoter':{ 'start' : '{{', 'end' : '}}' }, }
fun! xpt#st#New()
	return deepcopy(s:proto)
endfunction
fun! xpt#st#Extend(setting)
	for k in [ 'preValues', 'onfocusFilters', 'liveFilters', 'postFilters' ]
		if has_key(a:setting,k)
			for val in values(a:setting[k])
				call xpt#flt#Extend(val)
			endfor
		endif
	endfor
	if has_key( a:setting, 'mappings' )
		for phMapping in values(a:setting.mappings)
			for mapFilter in values(phMapping.keys)
				call xpt#flt#Extend(mapFilter)
			endfor
		endfor
	endif
	call extend( a:setting, deepcopy( s:proto ), 'keep' )
	for [k,v] in items(s:protoDefault)
		call extend( a:setting[ k ], deepcopy( v ), 'keep' )
	endfor
endfunction
fun! xpt#st#RenderPhaseCopy(setting)
	let setting = copy(a:setting)
	for k in [ 'variables', 'preValues', 'onfocusFilters' , 'liveFilters', 'postFilters', 'comeFirst', 'comeLast' ]
		let setting[k] = copy(setting[k])
	endfor
	let x = b:xptemplateData
	if x.currentExt != {}
		let setting.variables[ '$EXT' ] = x.currentExt.ext
		let x.currentExt = {}
	endif
	return setting
endfunction
fun! xpt#st#What()
endfunction
fun! xpt#st#Simplify(setting)
	call filter( a:setting, '!has_key(s:proto,v:key) || v:val!=s:proto[v:key]' )
endfunction
fun! xpt#st#Merge(setting,fromSettings)
	let a:setting.comeFirst += a:fromSettings.comeFirst
	let a:setting.comeLast = a:fromSettings.comeLast + a:setting.comeLast
	call xpt#st#InitItemOrderList(a:setting)
	call extend( a:setting.preValues, a:fromSettings.preValues, 'keep' )
	call extend( a:setting.onfocusFilters, a:fromSettings.onfocusFilters, 'keep' )
	call extend( a:setting.postFilters, a:fromSettings.postFilters, 'keep' )
	call extend( a:setting.variables, a:fromSettings.variables, 'keep' )
	for key in keys(a:fromSettings.mappings)
		if !has_key(a:setting.mappings,key)
			let a:setting.mappings[key] = { 'saver' : xpt#msvr#New( 1 ), 'keys' : {} }
		endif
		for keystroke in keys(a:fromSettings.mappings[key].keys)
			let a:setting.mappings[key].keys[keystroke] = a:fromSettings.mappings[key].keys[keystroke]
			call xpt#msvr#Add( a:setting.mappings[ key ].saver, 'i', keystroke )
		endfor
	endfor
endfunction
fun! xpt#st#Parse(setting,snipObject)
	let st = a:setting
	if get( st, 'wraponly' ) isnot 0
		call extend( st, { 'iswrap' : 1, 'iswraponly' : 1, 'wrapPH' : st.wraponly }, 'force' )
	elseif get( st, 'wrap' ) isnot 0
		call extend( st, { 'iswrap' : 1, 'iswraponly' : 0, 'wrapPH' : st.wrap }, 'force' )
	else
		call extend( st, { 'iswrap' : 0, 'iswraponly' : 0 }, 'force' )
	endif
	if st.iswrap && st.wrapPH is 1
		let st.wrapPH = 'cursor'
	endif
	if has_key(st, 'rawHint')
		if st.rawHint =~ s:regEval
			let x = b:xptemplateData
			let x.renderContext.snipObject = a:snipObject
			let st.hint = xpt#eval#Eval(st.rawHint, x.filetypes[x.snipFileScope.filetype].funcs, { 'variables' : st.variables } )
		else
			let st.hint = xpt#util#UnescapeChar(st.rawHint,s:nonsafe)
		endif
	endif
	call xpt#st#ParsePostQuoter(st)
	if has_key( st, 'extension' )
		let ext = st.extension
		let a:snipObject.ftScope.extensionTable[ext] = get(a:snipObject.ftScope.extensionTable,ext,[])
		let a:snipObject.ftScope.extensionTable[ext] += [a:snipObject.name]
	endif
endfunction
fun! xpt#st#ParsePostQuoter(setting)
	if !has_key( a:setting, 'postQuoter' ) || type(a:setting.postQuoter) == type({})
		return
	endif
	let quoters = split( a:setting.postQuoter, ',' )
	if len(quoters) < 2
		throw 'postQuoter must be separated with ","! :' . a:setting.postQuoter
	endif
	let a:setting.postQuoter = { 'start' : quoters[0], 'end' : quoters[1] }
endfunction
fun! xpt#st#InitItemOrderList(setting)
	call filter( a:setting.comeLast, 'v:val!="cursor"' )
	call add( a:setting.comeLast, 'cursor' )
	let a:setting.comeFirst = xpt#util#RemoveDuplicate(a:setting.comeFirst)
	let a:setting.comeLast = xpt#util#RemoveDuplicate(a:setting.comeLast)
endfunction
let &cpo = s:oldcpo
