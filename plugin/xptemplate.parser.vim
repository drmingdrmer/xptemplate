if exists( "g:__XPTEMPLATE_PARSER_VIM__" ) && g:__XPTEMPLATE_PARSER_VIM__ >= XPT#ver
	finish
endif
let g:__XPTEMPLATE_PARSER_VIM__ = XPT#ver
let s:oldcpo = &cpo
set cpo-=< cpo+=B
runtime plugin/xptemplate.vim
exec XPT#importConst
let s:log = xpt#debug#Logger( 'warn' )
com! -nargs=* XPTemplate if xpt#parser#InitSnippetFile( expand( "<sfile>" ), <f-args> ) == 'finish' | finish | endif
com! -nargs=* XPTemplateDef call s:XPTstartSnippetPart(expand("<sfile>")) | finish
com! -nargs=* XPT           call s:XPTstartSnippetPart(expand("<sfile>")) | finish
com! -nargs=* XPTvar call xpt#parser#SetVar(<q-args>)
com! -nargs=* XPTsnipSet call xpt#parser#SnipSet(<q-args>)
com! -nargs=+ XPTinclude call xpt#parser#Include(<f-args>)
com! -nargs=+ XPTembed call xpt#parser#Embed(<f-args>)
fun! XPTinclude(...)
	call xpt#parser#Load(a:000,1)
endfunction
fun! XPTembed(...)
	call xpt#parser#Load(a:000,0)
endfunction
fun! s:XPTstartSnippetPart(fn)
	let lines = readfile(a:fn)
	let i = match( lines, '\V\^XPTemplateDef' )
	if i == -1
		let i = match( lines, '\V\^XPT\s' ) - 1
	endif
	if i < 0
		return
	endif
	let lines = lines[i :]
	let x = b:xptemplateData
	let x.snippetToParse += [ { 'snipFileScope' : x.snipFileScope, 'lines' : lines } ]
	return
endfunction
fun! DoParseSnippet(p)
	call xpt#snipfile#Push()
	let x = b:xptemplateData
	let x.snipFileScope = a:p.snipFileScope
	let lines = a:p.lines
	let [i,len] = [0,len(lines)]
	let [s,e,blk] = [-1,-1,10000]
	while i < len-1 | let i += 1
		let v = lines[i]
		if v =~ '^\s*$' || v =~ '^"[^"]*$'
			let blk = min([blk,i - 1])
			continue
		endif
		if v =~# '^\.\.XPT'
			let e = i - 1
			call s:XPTemplateParseSnippet(lines[s : e])
			let [s,e,blk] = [-1,-1,10000]
		elseif v =~# '^XPT\>'
			if s != -1
				let e = min([i - 1,blk])
				call s:XPTemplateParseSnippet(lines[s : e])
				let [s,e,blk] = [i,-1,10000]
			else
				let s = i
				let blk = i
			endif
		elseif v =~# '^\\XPT'
			let lines[i] = v[1 :]
		else
			let blk = i
		endif
	endwhile
	if s != -1
		call s:XPTemplateParseSnippet(lines[s : min([blk,i])])
	endif
	call xpt#snipfile#Pop()
endfunction
fun! s:XPTemplateParseSnippet(lines)
	let lines = a:lines
	let snipScope = XPTsnipScope()
	let snipScope.loadedSnip = get( snipScope, 'loadedSnip', {} )
	let snippetLines = []
	let setting = deepcopy(g:XPTemplateSettingPrototype)
	let [hint,lines[0]] = s:GetSnipCommentHint(lines[0])
	if hint != ''
		let setting.rawHint = hint
	endif
	let snippetParameters = split(lines[0], '\V'.s:nonEscaped.'\s\+')
	let snippetName = snippetParameters[1]
	let snippetParameters = snippetParameters[2:]
	for pair in snippetParameters
		let name = matchstr(pair, '\V\^\[^=]\*')
		let value = pair[len(name) :]
		let value = value[0:0] == '=' ? xpt#util#UnescapeChar(value[1:], ' ') : 1
		let setting[name] = value
	endfor
	let start = 1
	let len = len(lines)
	while start < len
		let command = matchstr( lines[ start ], '\V\^XSETm\?\ze\s' )
		if command != ''
			let [key,val,start] = s:getXSETkeyAndValue(lines,start)
			if key == ''
				let start += 1
				continue
			endif
			let [keyname,keytype] = xpt#parser#GetKeyType(key)
			call s:HandleXSETcommand(setting,command,keyname,keytype,val)
		elseif lines[start] =~# '^\\XSET' " escaped XSET or XSETm
			let snippetLines += [lines[start][1:]]
		else
			let snippetLines += [lines[start]]
		endif
		let start += 1
	endwhile
	let setting.fromXPT = 1
	if has_key( setting, 'alias' )
		call XPTemplateAlias(snippetName,setting.alias,setting)
	else
		call XPTdefineSnippet(snippetName,setting,snippetLines)
	endif
	if has_key(snipScope.loadedSnip,snippetName)
		call XPT#info( "XPT: warn : duplicate snippet:" . snippetName . ' in file:' . snipScope.filename )
	endif
	let snipScope.loadedSnip[snippetName] = 1
	if has_key( setting, 'synonym' )
		let synonyms = split( setting.synonym, '|' )
		for synonym in synonyms
			call XPTemplateAlias(synonym,snippetName,{})
			if has_key(snipScope.loadedSnip,synonym)
				call XPT#warn( "XPT: warn : duplicate synonym:" . synonym . ' in file:' . snipScope.filename )
			endif
			let snipScope.loadedSnip[synonym] = 1
		endfor
	endif
endfunction
fun! s:GetSnipCommentHint(str)
	let pos = match(a:str, '\V' . s:nonEscaped . '\shint=')
	if pos != -1
		return [a:str[pos + 6 :],a:str[: pos - 1]]
	endif
	let pos = match( a:str, '\VXPT\s\+\S\+\.\{-}\zs\s' . s:nonEscaped . '"' )
	if pos == -1
		return [ '', a:str ]
	else
		return [ matchstr( a:str[ pos + 1 + 1 : ], '\S.*' ), a:str[ : pos ] ]
	endif
endfunction
fun! s:getXSETkeyAndValue(lines,start)
	let start = a:start
	let XSETparam = matchstr(a:lines[start], '\V\^XSET\%[m]\s\+\zs\.\*')
	let isMultiLine = a:lines[ start ] =~# '\V\^XSETm'
	if isMultiLine
		let key = XSETparam
		let [start,val] = s:ParseMultiLineValues(a:lines,start)
	else
		let key = matchstr(XSETparam, '\V\[^=]\*\ze=')
		if key == ''
			return [ '', '', start + 1 ]
		endif
		let val = matchstr(XSETparam, '\V=\s\*\zs\.\*')
		let val = substitute(val, '\\n', "\n", 'g')
	endif
	return [key,val,start]
endfunction
fun! s:ParseMultiLineValues(lines,start)
	let lines = a:lines
	let start = a:start
	let endPattern = '\V\^XSETm\s\+END\$'
	let start += 1
	let multiLineValues = []
	while start < len(lines)
		let line = lines[start]
		if line =~# endPattern
			break
		endif
		if line =~# '^\V\\\+XSET\%[m]'
			let slashes = matchstr( line, '^\\\+' )
			let nrSlashes = len(slashes + 1) / 2
			let line = line[nrSlashes :]
		endif
		let multiLineValues += [line]
		let start += 1
	endwhile
	let val = join(multiLineValues, "\n")
	return [start,val]
endfunction
fun! s:HandleXSETcommand(setting,command,keyname,keytype,value)
	if a:keyname ==# 'ComeFirst'
		let a:setting.comeFirst = xpt#util#SplitWith( a:value, ' ' )
	elseif a:keyname ==# 'ComeLast'
		let a:setting.comeLast = xpt#util#SplitWith( a:value, ' ' )
	elseif a:keyname ==# 'postQuoter'
		let a:setting.postQuoter = a:value
	elseif a:keyname =~ '\V\^$'
		let a:setting.variables[a:keyname] = a:value
	elseif a:keytype == "" || a:keytype ==# 'def'
		let a:setting.defaultValues[a:keyname] = xpt#flt#New(0,a:value)
	elseif a:keytype ==# 'map'
		let a:setting.mappings[a:keyname] = get( a:setting.mappings, a:keyname, { 'saver' : xpt#msvr#New(1), 'keys' : {} } )
		let key = matchstr( a:value, '\V\^\S\+\ze\s' )
		let mapping = matchstr( a:value, '\V\s\+\zs\.\*' )
		call xpt#msvr#Add( a:setting.mappings[ a:keyname ].saver, 'i', key )
		let a:setting.mappings[a:keyname].keys[key] = xpt#flt#New(0,mapping)
	elseif a:keytype ==# 'pre'
		let a:setting.preValues[a:keyname] = xpt#flt#New(0,a:value)
	elseif a:keytype ==# 'ontype'
		let a:setting.ontypeFilters[a:keyname] = xpt#flt#New(0,a:value)
	elseif a:keytype ==# 'post'
		if a:keyname =~ '\V...'
			let a:setting.postFilters[a:keyname] = xpt#flt#New( 0, 'BuildIfNoChange(' . string(a:value) . ')' )
		else
			let a:setting.postFilters[a:keyname] = xpt#flt#New(0,a:value)
		endif
	else
		throw "unknown key name or type:" . a:keyname . ' ' . a:keytype
	endif
endfunction
let &cpo = s:oldcpo
