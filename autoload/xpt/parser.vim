exec xpt#once#init
let s:oldcpo = &cpo
set cpo-=< cpo+=B
let s:log = xpt#debug#Logger( 'debug' )
exe XPT#importConst
let s:KEYTYPE_MAP = { '.':'onfocus', '.def':'onfocus', '.ontype':'live', '.onchange':'live', }
let s:KEYTYPE_TO_DICT = { 'pre':'preValues', 'live':'liveFilters', 'onfocus':'onfocusFilters', }
runtime plugin/xptemplate.vim
fun s:CompileSnippetFile(fn)
	if a:fn =~ '\V.xpt.vimc\$' || !filereadable( a:fn )
		return
	endif
	let lines = readfile(a:fn)
	let lines = xpt#parser#Compact(lines)
	let lines = xpt#parser#CompileCompacted(lines)
	call writefile( lines, a:fn . 'c' )
endfunction
fun! xpt#parser#Compile(fn)
	let compiledFn = a:fn . 'c'
	let ctime = getftime(a:fn)
	if !filereadable(compiledFn) || getftime(compiledFn) < ctime || g:xptemplate_always_compile
		call s:CompileSnippetFile(a:fn)
	else
	endif
endfunction
fun! xpt#parser#Compact(lines)
	let compacted = []
	let iSnipPart = match( a:lines, '\V\^XPT\s' )
	if iSnipPart < 0
		let iSnipPart = len(a:lines)
	endif
	let [i,len] = [0 - 1,iSnipPart - 1]
	while i < len | let i += 1
		let l = a:lines[i]
		if l != '' && l !~ '\v^"[^"]*$'
			call add(compacted,l)
		endif
	endwhile
	let [s,e,lastNonblank] = [-1,-1,100000]
	let [i,len] = [iSnipPart - 1,len(a:lines) - 1]
	while i < len | let i += 1
		let l = a:lines[i]
		if l == '' || l =~ '\v^"[^"]*$'
			let lastNonblank = min([lastNonblank,i - 1])
			continue
		endif
		if l =~# '\V\^..XPT\>'
			if s == -1
				let [s,e,lastNonblank] = [-1,-1,100000]
				continue
			else
				let compacted += a:lines[s : i - 1]
				let [s,e,lastNonblank] = [-1,-1,100000]
			endif
		elseif l =~# '\V\^XPT\>'
			if s == -1
				let [s,lastNonblank] = [i,i]
			else
				let e = min([i - 1,lastNonblank])
				let compacted += a:lines[s : e]
				let [s,e,lastNonblank] = [i,-1,100000]
			endif
		else
			let lastNonblank = i
		endif
	endwhile
	if s != -1
		let compacted += a:lines[s : min([lastNonblank,i])]
	endif
	return compacted
endfunction
fun! xpt#parser#CompileCompacted(lines)
	let rst = []
	let lines = a:lines
	let iSnipPart = match( lines, '\V\^XPT\s' )
	if iSnipPart < 0
		return lines
	endif
	if iSnipPart > 0
		let rst += lines[: iSnipPart - 1]
		let lines = lines[iSnipPart :]
	endif
	let [i,len] = [0,len(lines)]
	call xpt#indent#IndentToTab(lines)
	let s = i
	while i < len-1 | let i += 1
		let v = lines[i]
		if v =~# '\V\^XPT\>'
			let ll = xpt#parser#CompileSnippet(lines[s : i - 1])
			let rst += [ll]
			let s = i
		elseif v =~# '\V\^\\XPT'
			let lines[i] = v[1 :]
		endif
	endwhile
	if i >= s
		let ll = xpt#parser#CompileSnippet(lines[s : i])
		let rst += [ll]
	endif
	return rst
endfunction
fun! xpt#parser#CompileSnippet(lines)
	let lines = a:lines
	let snippetLines = []
	let setting = xpt#st#New()
	let l0 = lines[0]
	let pos = match( l0, '\VXPT\s\+\S\+\.\{-}\zs\s' . s:nonEscaped . '"' )
	if pos >= 0
		let [setting.rawHint, lines[0]] = [ matchstr( l0[ pos + 1 + 1 : ], '\v\S.*' ), l0[ : pos ] ]
	endif
	let [ x, snippetName; snippetParameters ] = split(lines[0], '\V'.s:nonEscaped.'\s\+')
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
			let [key,val,start] = s:GetXSETkeyAndValue(lines,start)
			if key == ''
				let start += 1
				continue
			endif
			let [keyname,keytype] = xpt#parser#GetKeyType(key)
			call s:HandleXSETcommand(setting,command,[keyname,keytype,val])
		elseif lines[start] =~# '^\\XSET' " escaped XSET or XSETm
			let snippetLines += [lines[start][1:]]
		else
			call add(snippetLines,lines[start])
		endif
		let start += 1
	endwhile
	call xpt#st#Simplify(setting)
	if has_key( setting, 'alias' )
		return printf( 'call XPTemplateAlias(%s,%s,%s)', string(snippetName),string(setting.alias),string(setting))
	else
		return printf( 'call XPTdefineSnippet(%s,%s,%s)', string(snippetName),string(setting),string(snippetLines))
	endif
endfunction
fun! xpt#parser#Include(...)
	call xpt#parser#Load(a:000,1)
endfunction
fun! xpt#parser#Embed(...)
	call xpt#parser#Load(a:000,0)
endfunction
fun! xpt#parser#Load(fns,inherit)
	let scope = b:xptemplateData.snipFileScope
	let ftscope = b:xptemplateData.filetypes[scope.filetype]
	let saved_inherit = scope.inheritFT
	let scope.inheritFT = a:inherit
	let fns = xpt#util#Flatten(a:fns)
	for f in fns
		if a:inherit && xpt#ftscope#IsSnippetLoaded(ftscope,f)
			continue
		endif
		call xpt#snipfile#Push()
		exe 'runtime! ftplugin/' . f . '.xpt.vim'
		call xpt#snipfile#Pop()
	endfor
	let scope.inheritFT = saved_inherit
endfunction
fun! xpt#parser#SetVar(nameSpaceValue)
	let x = b:xptemplateData
	let ftScope = x.filetypes[x.snipFileScope.filetype]
	let name = matchstr(a:nameSpaceValue, '^\S\+\ze')
	if name == ''
		return
	endif
	let val  = matchstr(a:nameSpaceValue, '\s\+\zs.*')
	if val =~ '^''.*''$'
		let val = val[1:-2]
	else
		let val = substitute( val, '\\ ', " ", 'g' )
	endif
	let val = substitute( val, '\\n', "\n", 'g' )
	let priority = x.snipFileScope.priority
	if !has_key(ftScope.varPriority,name) || priority <= ftScope.varPriority[name]
		let [ftScope.funcs[name],ftScope.varPriority[name]] = [val,priority]
	endif
endfunction
fun! xpt#parser#SnipSet(dictNameValue)
	let x = b:xptemplateData
	let snipScope = x.snipFileScope
	let [ dict, nameValue ] = split( a:dictNameValue, '\V.', 1 )
	let name = matchstr( nameValue, '^.\{-}\ze=' )
	let value = nameValue[len(name) + 1 :]
	let snipScope[dict][name] = value
endfunction
fun! xpt#parser#loadSpecialFiletype(ft)
	let x = b:xptemplateData
	let ft = a:ft
	if has_key(x.filetypes,ft)
		return
	endif
	if ft == 'unknown'
		call xpt#parser#loadSnippetFile( 'unknown/unknown' )
	else
		call xpt#parser#InitSnippetFile( '~~/xpt/pseudo/ftplugin/' . ft . '/' . ft . '.xpt.vim' )
		call XPTinclude( '_common/common' )
		call XPTfiletypeInit()
	endif
	call XPTparseSnippets()
endfunction
fun! xpt#parser#loadSnippetFile(rel_snip)
	exe 'runtime! ftplugin/' . a:rel_snip . '.xpt.vim'
	call XPTfiletypeInit()
endfunction
fun! s:AssignSnipFT(filename)
	let x = b:xptemplateData
	let filename = substitute( a:filename, '\\', '/', 'g' )
	if filename =~ 'unknown.xpt.vim$'
		return 'unknown'
	endif
	let ftFolder = matchstr( filename, '\V/ftplugin/\zs\[^\\]\+\ze/' )
	if empty(x.snipFileScopeStack)
		if filename =~ '\V\<pseudo\>/'
			return ftFolder
		endif
		if &filetype =~ '\<' . ftFolder . '\>' " sub type like 'xpt.vim'
			let ft = &filetype
		else
			let ft = 'not allowed'
		endif
	else
		if x.snipFileScopeStack[-1].inheritFT || ftFolder =~ '\V\^_'
			if !has_key( x.snipFileScopeStack[ -1 ], 'filetype' )
				throw 'parent may has no XPTemplate command called :' . a:filename
			endif
			let ft = x.snipFileScopeStack[-1].filetype
		else
			let ft = ftFolder
		endif
	endif
	return ft
endfunction
fun! xpt#parser#InitSnippetFile(filename,...)
	if ! xpt#option#lib_filter#Match(a:filename)
		return 'finish'
	endif
	if !exists("b:xptemplateData")
		call XPTemplateInit()
	endif
	let x = b:xptemplateData
	let filetypes = x.filetypes
	let snipScope = xpt#snipfile#New(a:filename)
	let snipScope.filetype = s:AssignSnipFT(a:filename)
	let x.snipFileScope = snipScope
	let ft = snipScope.filetype
	if ft == 'not allowed'
		call s:log.Info( "not allowed:" . a:filename )
		return 'finish'
	endif
	if ! has_key(filetypes,ft)
		let filetypes[ft] = xpt#ftscope#New()
	endif
	let ftScope = filetypes[ft]
	if xpt#ftscope#CheckAndSetSnippetLoaded(ftScope,a:filename)
		return 'finish'
	endif
	for pair in a:000
		let kv = split( pair, '=', 1 )
		let key = kv[0]
		let val = join( kv[ 1 : ], '=' )
		if key =~ 'prio\%[rity]'
			call XPTemplatePriority(val)
		elseif key =~ 'mark'
			call XPTemplateMark(val[0 : 0],val[1 : 1])
		elseif key =~ 'key\%[word]'
			call XPTemplateKeyword(val)
		endif
	endfor
	return 'doit'
endfunction
fun! xpt#parser#SnippetFileInit_for_compiled(filename,...)
	if !filereadable(a:filename)
		return call( function( 'xpt#parser#InitSnippetFile' ), [ a:filename ] + a:000 )
	endif
	if a:filename =~ '\V.xpt.vim\$'
		call xpt#parser#Compile(a:filename)
		exe 'so' a:filename . 'c'
		return 'finish'
	else
		return call( function( 'xpt#parser#InitSnippetFile' ), [ a:filename ] + a:000 )
	endif
endfunction
fun! xpt#parser#LoadSnippets()
	let fts = split( &filetype, '\V.', 1 )
	call filter( fts, 'v:val!=""' )
	for ft in fts
		call xpt#parser#LoadFTSnippets(ft)
	endfor
endfunction
fun! s:RTP()
	let rtps = split( &runtimepath, ',' )
	call filter( rtps, 'v:val!=""' )
	let rtps += [ g:XPT_PATH . '/xptsnippets', g:XPT_PATH . '/personal' ]
	let rtpath = join( rtps, ',' )
	return rtpath
endfunction
fun! xpt#parser#LoadFtDetectors(ft)
	let namePattern = a:ft =~ '/' ? a:ft : a:ft . '/*'
	let rtpath = s:RTP()
	let ftdetectfiles = split( globpath( rtpath, 'ftplugin/' . namePattern . '.ftdetect.vim' ), "\n" )
	for fn in ftdetectfiles
		exe 'so' fn
	endfor
endfunction
fun! xpt#parser#LoadFTSnippets(ft)
	let namePattern = a:ft =~ '/' ? a:ft : a:ft . '/*'
	let rtpath = s:RTP()
	let ftdetectfiles = split( globpath( rtpath, 'ftplugin/' . namePattern . '.ftdetect.vim' ), "\n" )
	for fn in ftdetectfiles
		exe 'so' fn
	endfor
	let snipfiles = split( globpath( rtpath, 'ftplugin/' . namePattern . '.xpt.vim' ), "\n" )
	for fn in snipfiles
		let compiled = fn . 'c'
		if !filereadable(compiled) || getftime(compiled) < getftime(fn) || g:xptemplate_always_compile
			call xpt#parser#Compile(fn)
			exe 'so' compiled
		endif
	endfor
endfunction
fun! xpt#parser#GetKeyType(rawKey)
	let keytype = matchstr(a:rawKey, '\V'.s:nonEscaped.'|\zs\.\{-}\$')
	if keytype == ""
		let keytype = matchstr(a:rawKey, '\V'.s:nonEscaped.'.\zs\.\{-}\$')
	endif
	let keyname = keytype == "" ? a:rawKey :  a:rawKey[ 0 : - len(keytype) - 2 ]
	let keyname = substitute(keyname, '\V\\\(\[.|\\]\)', '\1', 'g')
	return [keyname,keytype]
endfunction
let s:KEY_NAME = 0
let s:KEY_TYPE = 1
let s:VALUE = 2
let s:stHandler = {}
fun! s:stHandler.ComeFirst(setting,cmdArgs)
	let a:setting.comeFirst = xpt#util#SplitWith( a:cmdArgs[ s:VALUE ], ' ' )
endfunction
fun! s:stHandler.ComeLast(setting,cmdArgs)
	let a:setting.comeLast = xpt#util#SplitWith( a:cmdArgs[ s:VALUE ], ' ' )
endfunction
fun! s:stHandler.postQuoter(setting,cmdArgs)
	let pq = split( a:cmdArgs[ s:VALUE ], ',' )
	let a:setting.postQuoter = { 'start' : pq[0], 'end' : pq[1] }
endfunction
let s:stHandler.PostQuoter = s:stHandler.postQuoter
let s:keytypeHandler = {}
fun! s:keytypeHandler.repl(setting,cmdArgs)
	let a:setting.replacements[a:cmdArgs[s:KEY_NAME]] = a:cmdArgs[s:VALUE]
endfunction
fun! s:keytypeHandler.map(setting,cmdArgs)
	let [kn,kt,val] = a:cmdArgs
	let mp = a:setting.mappings
	if !has_key(mp,kn)
		let mp[ kn ] = { 'saver' : xpt#msvr#New( 1 ), 'keys' : {} }
	endif
	let key = matchstr( val, '\V\^\S\+\ze\s' )
	let mapping = matchstr( val, '\V\s\+\zs\.\*' )
	call xpt#msvr#Add( mp[ kn ].saver, 'i', key )
	let mp[kn].keys[key] = xpt#flt#NewSimple(0,mapping)
endfunction
fun! s:keytypeHandler.post(setting,cmdArgs)
	let [kn,kt,val] = a:cmdArgs
	let val = xpt#ph#AlterFilterByPHName(kn,val)
	let a:setting.postFilters[kn] = xpt#flt#NewSimple(0,val)
endfunction
fun! s:HandleXSETcommand(setting,command,cmdArgs)
	let [kn,kt,val] = a:cmdArgs
	let kt = get( s:KEYTYPE_MAP, '.' . kt, kt )
	let fcon = {}
	if has_key(s:stHandler,kn)
		let fcon.f = s:stHandler[kn]
		call fcon.f(a:setting,[kn,kt,val])
	elseif has_key(s:KEYTYPE_TO_DICT,kt)
		let dicName = s:KEYTYPE_TO_DICT[kt]
		let a:setting[dicName][kn] = xpt#flt#NewSimple(0,val)
	elseif kn =~ '\V\^$'
		let a:setting.variables[kn] = val
	elseif has_key(s:keytypeHandler,kt)
		let fcon.f = s:keytypeHandler[kt]
		call fcon.f(a:setting,[kn,kt,val])
	else
		throw "unknown key name or type:" . kn . ' ' . kt
	endif
endfunction
fun! xpt#parser#LoadSnippetToParseList(fn)
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
endfunction
fun! xpt#parser#ParseSnippet(p)
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
			let [key,val,start] = s:GetXSETkeyAndValue(lines,start)
			if key == ''
				let start += 1
				continue
			endif
			let [keyname,keytype] = xpt#parser#GetKeyType(key)
			call s:HandleXSETcommandOld(setting,command,keyname,keytype,val)
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
fun! s:GetXSETkeyAndValue(lines,start)
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
fun! s:HandleXSETcommandOld(setting,command,keyname,keytype,value)
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
