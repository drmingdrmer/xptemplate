if exists( "g:__AL_XPT_SNIPFUNC_VIM__" ) && g:__AL_XPT_SNIPFUNC_VIM__ >= XPT#ver
	finish
endif
let g:__AL_XPT_SNIPFUNC_VIM__ = XPT#ver
let s:oldcpo = &cpo
set cpo-=< cpo+=B
let s:log = xpt#debug#Logger( 'warn' )
let s:log = xpt#debug#Logger( 'debug' )
fun! xpt#snipfunc#Extend(container)
	call extend( a:container, s:f, 'keep' )
endfunction
let s:f = {}
fun! s:f.Pre(a)
	return a:a
endfunction
fun! s:f.SnipObject()
	return self.phFilterContext isnot 0 ? self.phFilterContext.snipObject : self.renderContext.snipObject
endfunction
fun! s:f.PHs(snipText)
	let so = self.SnipObject()
	let slave = xpt#snip#NewSlave(so,a:snipText)
	call xpt#snip#CompileAndParse(slave)
	return slave.parsedSnip
endfunction
fun! s:f.Inline(snipText)
	return { 'action' : 'embed', 'phs' : self.PHs( a:snipText ) }
endfunction
fun! s:f.Inc(targetName,keepCursor,params)
	let so = self.SnipObject()
	let snipDict = so.ftScope.allTemplates
	if has_key(snipDict,a:targetName)
		let tsnip = snipDict[a:targetName]
		call xpt#snip#CompileAndParse(tsnip)
		let phs = xpt#phfilter#Filter( tsnip, 'xpt#phfilter#ReplacePH', { 'replParams' : a:params } )
		if !a:keepCursor
			call xpt#snip#DumbCursorInPlace(tsnip,phs)
		endif
		call xpt#st#Merge(so.setting,tsnip.setting)
		return { 'action' : 'embed', 'nIndent' : 0,  'phs' : phs }
	else
		return 0
	endif
endfunction
fun! s:f.GetDict(...)
	return
endfunction
fun! s:f.GetVar(name)
	if a:name =~# '\V\^$_x'
		let n = a:name[1 :]
		if has_key(self,n)
			return self[n]()
		endif
	endif
	let varScopes = []
	if has_key( self, 'evalContext' )
		call add(varScopes,self.evalContext.variables)
	endif
	if has_key( self, 'renderContext' )
		call add( varScopes, get( self.renderContext.snipSetting, 'variables', {} ) )
	endif
	call add(varScopes,self)
	for sc in varScopes
		let val = get(sc,a:name)
		if val isnot 0
			return val
		endif
	endfor
	return a:name
endfunction
fun! s:f._xSnipName()
	return self.renderContext.snipObject.name
endfunction
fun! s:f.EmbedWrappedText()
	let wrapData = self.renderContext.userWrapped
	if !has_key( wrapData, 'text' )
		return 0
	endif
	let ph = self.phFilterContext.ph
	if has_key( ph, 'isKey' )
		let n = len(wrapData.lines)
		let nIndent = self.phFilterContext.phEvalContext.pos[1] - self.phFilterContext.phEvalContext.nIndAdd
		if self.phFilterContext.phEvalContext.pos[0] == 0
			let nIndent += self.phFilterContext.phEvalContext.offset
		endif
		let sep = "\n"
		let ph = extend(deepcopy(ph),{ 'name':'',  'value':1, }, 'force' )
		unlet ph.isKey
		let newPHs = []
		let i = 0
		while i < n
			let newph = extend(deepcopy(ph),{ 'displayText':wrapData.lines[ i ], }, 'force' )
			call extend(newPHs,[newph,sep])
			let i += 1
		endwhile
		call remove(newPHs,-1)
		return { 'action' : 'embed', 'nIndent' : nIndent, 'phs' : newPHs }
	else
		return { 'nIndent'  : wrapData.indent, 'text':wrapData.text }
	endif
endfunction
fun! s:f.WrapAlignAfter(min)
	let userWrapped = self.renderContext.userWrapped
	let n = max([a:min,userWrapped.max]) - len(userWrapped.curline)
	return repeat( ' ', n )
endfunction
fun! s:f.WrapAlignBefore(min)
	let userWrapped = self.renderContext.userWrapped
	let n = max([a:min,userWrapped.max]) - len(userWrapped.lines[0])
	return repeat( ' ', n )
endfunction
fun! s:f.Item()
	return get( self.renderContext, 'item', {} )
endfunction
fun! s:f.ItemName()
	return get( self.Item(), 'name', '' )
endfunction
fun! s:f.ItemFullname()
	return get( self.Item(), 'fullname', '')
endfunction
fun! s:f.ItemValue() dict
	return get( self.evalContext, 'userInput', '' )
endfunction
fun! s:f.PrevItem(n)
	let hist = get( self.renderContext, 'history', [] )
	return get(hist,a:n,{})
endfunction
fun! s:f.ItemInitValue()
	return get( self.Item(), 'initValue', '' )
endfunction
fun! s:f.ItemInitValueWithEdge()
	let [l,r] = self.ItemEdges()
	return l . self.ItemInitValue() . r
endfunction
fun! s:f.ItemValueStripped(...)
	let ptn = a:0 == 0 || a:1 =~ 'lr' ? '\V\^\s\*\|\s\*\$' : ( a:1 == 'l' ? '\V\^\s\*' : '\V\s\*\$' )
	return substitute( self.ItemValue(), ptn, '', 'g' )
endfunction
fun! s:f.ItemPos()
	return XPMposStartEnd(self.renderContext.leadingPlaceHolder.mark)
endfunction
fun! s:f.Vmatch(...)
	let v = self.V()
	for reg in a:000
		if match(v,reg) != -1
			return 1
		endif
	endfor
	return 0
endfunction
fun! s:f.VMS(reg)
	return matchstr(self.V(),a:reg)
endfunction
fun! s:f.ItemStrippedValue()
	let v = self.V()
	let [edgeLeft,edgeRight] = self.ItemEdges()
	let v = substitute( v, '\V\^' . edgeLeft,       '', '' )
	let v = substitute( v, '\V' . edgeRight . '\$', '', '' )
	return v
endfunction
fun! s:f.Phase() dict
	return get( self.renderContext, 'phase', '' )
endfunction
fun! s:f.E(s)
	return expand(a:s)
endfunction
fun! s:f.Context()
	return self.renderContext
endfunction
fun! s:f.S(str,ptn,rep,...)
	let flg = a:0 >= 1 ? a:1 : 'g'
	return substitute(a:str,a:ptn,a:rep,flg)
endfunction
fun! s:f.SubstituteWithValue(ptn,rep,...)
	let flg = a:0 >= 1 ? a:1 : 'g'
	return substitute(self.V(),a:ptn,a:rep,flg)
endfunction
fun! s:f.HasStep(name)
	let namedStep = get( self.renderContext, 'namedStep', {} )
	return has_key(namedStep,a:name)
endfunction
fun! s:f.Reference(name)
	let namedStep = get( self.renderContext, 'namedStep', {} )
	return get( namedStep, a:name, '' )
endfunction
fun! s:f.Snippet(name)
	return get( self.renderContext.ftScope.allTemplates, a:name, { 'tmpl' : '' } )[ 'tmpl' ]
endfunction
fun! s:f.Void(...)
	return ""
endfunction
fun! s:f.Echo(...)
	if a:0 > 0
		return a:1
	else
		return ''
	endif
endfunction
fun! s:f.EchoIf(isTrue,...)
	if a:isTrue
		return join( a:000, '' )
	else
		return self.V()
	endif
endfunction
fun! s:f.EchoIfEq(expected,...)
	if self.V() ==# a:expected
		return join( a:000, '' )
	else
		return self.V()
	endif
endfunction
fun! s:f.EchoIfNoChange(...)
	if self.V0() ==# self.ItemName()
		return join( a:000, '' )
	else
		return self.V()
	endif
endfunction
fun! s:f.Commentize(text)
	if has_key( self, '$CL' )
		return self[ '$CL' ] . ' ' . a:text . ' ' . self[ '$CR' ]
	elseif has_key( self, '$CS' )
		return self[ '$CS' ] . ' ' . a:text
	endif
	return a:text
endfunction
fun! s:f.VoidLine()
	return self.Commentize( 'void' )
endfunction
fun! s:f.Empty()
	return self.ItemValue() == ''
endfunction
fun! s:f.IsChanged()
	let initFull = self.ItemInitValueWithEdge()
	let v = self.ItemValue()
	return initFull !=# v
endfunction
fun! s:f.EmbedPHs(phsID)
	let snipObject = self.renderContext.snipObject
	return { 'action' : 'embed', 'phs':xpt#ftsc#GetPHPieces( snipObject.ftScope, a:phsID ) }
endfunction
fun! s:f.Build(...)
	return { 'action' : 'build', 'text' : join( a:000, '' ) }
endfunction
fun! s:f.BuildIfChanged(...)
	let v = substitute( self.V(), "\\V\n\\|\\s", '', 'g')
	let fn = substitute( self.ItemInitValueWithEdge(), "\\V\n\\|\\s", '', 'g')
	if v ==# fn || v == ''
		return ''
	else
		return { 'action' : 'build', 'text' : join( a:000, '' ) }
	endif
endfunction
fun! s:f.BuildIfNoChange(...)
	let v = substitute( self.V(), "\\V\n\\|\\s", '', 'g')
	let fn = substitute( self.ItemInitValueWithEdge(), "\\V\n\\|\\s", '', 'g')
	if v ==# fn
		return { 'action' : 'build', 'text' : join( a:000, '' ) }
	else
		return 0
	endif
endfunction
fun! s:f.Trigger(name)
	return {'action' : 'expandTmpl', 'tmplName' : a:name}
endfunction
fun! s:f.Finish(...)
	return self.FinishPH( a:0 > 0 ? { 'text' : a:1 } : {} )
endfunction
fun! s:f.FinishOuter(...)
	return self.FinishPH(a:0 > 0 ? { 'text' : a:1, 'marks' : 'mark' } : { 'marks' : 'mark' } )
endfunction
fun! s:f.FinishPH(opt)
	let opt = a:opt
	if empty(self.renderContext.groupList)
		let o = { 'action' : g:XPTact.finishPH }
		call extend( o, opt, 'keep' )
		return o
	else
		return get( opt, 'text', 0 )
	endif
endfunction
fun! s:f.Embed(snippetText)
	return { 'action' : g:XPTact.embed, 'text' : a:snippetText }
endfunction
fun! s:f.Next(...)
	let rst = { 'action' : 'next' }
	if a:0 > 0
		let phs = deepcopy(a:000)
		call filter( phs, 'type(v:val)==' . type( '' ) )
		if len(phs) < len(a:000)
			let rst.phs = a:000
		else
			let text = join( a:000, '' )
			let so = self.SnipObject()
			if match(text,so.ptn.lft) >= 0
				let rst.phs = self.PHs(text)
			else
				let rst.text = text
			endif
		endif
	endif
	return rst
endfunction
fun! s:f.Remove()
	return { 'action' : 'remove' }
endfunction
fun! s:f.Choose(lst,...)
	let val = { 'action' : 'pum', 'pum' : a:lst }
	if a:0 == 1
		let val.acceptEmpty = a:1 != 0
	endif
	return val
endfunction
fun! s:f.ChooseStr(...)
	return copy(a:000)
endfunction
fun! s:f.Complete(key,...)
	let val = { 'action' : 'complete', 'pum' : a:key }
	if a:0 == 1
		let val.acceptEmpty = a:1 != 0
	endif
	return val
endfunction
fun! s:f.xptFinishTemplateWith(postType) dict
endfunction
fun! s:f.xptFinishItemWith(postType) dict
endfunction
fun! s:f.UnescapeMarks(string) dict
	let patterns = self.renderContext.snipObject.ptn
	let charToEscape = '\(\[' . patterns.l . patterns.r . ']\)'
	let r = substitute( a:string,  '\v(\\*)\1\\?\V' . charToEscape, '\1\2', 'g')
	return r
endfunction
fun! s:f.headerSymbol(...)
	let h = expand('%:t')
	let h = substitute(h, '\.', '_', 'g') " replace . with _
	let h = substitute(h, '.', '\U\0', 'g') " make all characters upper case
	return '__'.h.'__'
endfunction
fun! s:f.date(...)
	return strftime( self.GetVar( '$DATE_FMT' ) )
endfunction
fun! s:f.datetime(...)
	return strftime( self.GetVar( '$DATETIME_FMT' ) )
endfunction
fun! s:f.time(...)
	return strftime( self.GetVar( '$TIME_FMT' ) )
endfunction
fun! s:f.file(...)
	return expand("%:t")
endfunction
fun! s:f.fileRoot(...)
	return expand("%:t:r")
endfunction
fun! s:f.fileExt(...)
	return expand("%:t:e")
endfunction
fun! s:f.path(...)
	return expand("%:p")
endfunction
fun! s:f.UpperCase(v)
	return substitute(a:v, '.', '\u&', 'g')
endfunction
fun! s:f.LowerCase(v)
	return substitute(a:v, '.', '\l&', 'g')
endfunction
fun! s:f.ItemEdges()
	let leader =  get( self.renderContext, 'leadingPlaceHolder', {} )
	if has_key( leader, 'leftEdge' )
		return [leader.leftEdge,leader.rightEdge]
	else
		return [ '', '' ]
	endif
endfunction
fun! s:f.ItemCreate(name,edges,filters)
	let [ml,mr] = XPTmark()
	let item = ml . a:name
	if has_key( a:edges, 'left' )
		let item = ml . a:edges.left . item
	endif
	if has_key( a:edges, 'right' )
		let item .= ml . a:edges.right
	endif
	let item .= mr
	if has_key( a:filters, 'post' )
		let item .= a:filters.post . mr . mr
	endif
	return item
endfunction
fun! s:f.ExpandIfNotEmpty(sep,item,...)
	let v = self.V()
	let [ml,mr] = XPTmark()
	if a:0 != 0
		let r = a:1
	else
		let r = ''
	endif
	let t = ( v == '' || v =~ '\V' . a:item ) ? '' : self.Build(v . ml . a:sep . ml . a:item . ml . r . mr . 'ExpandIfNotEmpty(' . string( a:sep ) . ', ' . string( a:item )  . ')' . mr . mr )
	return t
endfunction
fun! s:f.ExpandInsideEdge(newLeftEdge,newRightEdge)
	let v = self.V()
	let fullname = self.ItemFullname()
	let [el,er] = self.ItemEdges()
	if v ==# fullname || v == ''
		return ''
	endif
	return substitute( v, '\V' . er . '\$' , '' , '' ) . self.ItemCreate( self.ItemName(), { 'left' : a:newLeftEdge, 'right' : a:newRightEdge }, {} ) . er
endfunction
fun! s:f.NIndent()
	return &shiftwidth
endfunction
fun! s:f.ResetIndent(nIndent,text)
	return { 'action' : 'resetIndent', 'resetIndent':1, 'nIndent' : a:nIndent, 'text' : a:text }
endfunction
fun! s:f.CmplQuoter_pre() dict
	if !g:xptemplate_brace_complete
		return ''
	endif
	let v = substitute( self.ItemStrippedValue(), '\V\^\s\*', '', '' )
	let first = matchstr( v, '\V\^\[''"]' )
	if first == ''
		return ''
	endif
	let v = substitute( v, '\V\[^' . first . ']', '', 'g' )
	if v == first
		return first
	else
		return ''
	endif
endfunction
fun! s:f.AutoCmpl(keepInPost,list,...)
	if !a:keepInPost && self.Phase() == 'post'
		return ''
	endif
	if type(a:list) == type([])
		let list = a:list
	else
		let list = [a:list] + a:000
	endif
	let v = self.V0()
	if v == ''
		return ''
	endif
	for word in list
		if word =~ '\V\^' . v
			return word[len(v) :]
		endif
	endfor
	return ''
endfunction
let s:f.Edges = s:f.ItemEdges
let s:f.UE = s:f.UnescapeMarks
let s:f.VOID = s:f.Void
let s:f.R = s:f.Reference
let s:f.SV = s:f.SubstituteWithValue
let s:f.C = s:f.Context
let s:f.V0 = s:f.ItemStrippedValue
let s:f.IVE = s:f.ItemInitValueWithEdge
let s:f.VS = s:f.ItemValueStripped
let s:f.IV = s:f.ItemInitValue
let s:f.V = s:f.ItemValue
let s:f.NN = s:f.ItemFullname
let s:f.N = s:f.ItemName
let &cpo = s:oldcpo
