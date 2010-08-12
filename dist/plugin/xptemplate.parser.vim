if exists( "g:__XPTEMPLATE_PARSER_VIM__" ) && g:__XPTEMPLATE_PARSER_VIM__ >= XPT#ver
    finish
endif
let g:__XPTEMPLATE_PARSER_VIM__ = XPT#ver
let s:oldcpo = &cpo
set cpo-=< cpo+=B
runtime plugin/classes/FiletypeScope.vim
runtime plugin/classes/FilterValue.vim
runtime plugin/xptemplate.util.vim
runtime plugin/xptemplate.vim
let s:log = xpt#debug#Logger( 'warn' )
com! -nargs=* XPTemplate
      \   if XPTsnippetFileInit( expand( "<sfile>" ), <f-args> ) == 'finish'
      \ |     finish
      \ | endif
com! -nargs=* XPTemplateDef call s:XPTstartSnippetPart(expand("<sfile>")) | finish
com! -nargs=* XPT           call s:XPTstartSnippetPart(expand("<sfile>")) | finish
com! -nargs=* XPTvar        call XPTsetVar( <q-args> )
com! -nargs=* XPTsnipSet    call XPTsnipSet( <q-args> )
com! -nargs=+ XPTinclude    call XPTinclude(<f-args>)
com! -nargs=+ XPTembed      call XPTembed(<f-args>)
let s:nonEscaped = '\%(' . '\%(\[^\\]\|\^\)' . '\%(\\\\\)\*' . '\)' . '\@<='
fun! s:AssignSnipFT( filename ) 
    let x = b:xptemplateData
    let filename = substitute( a:filename, '\\', '/', 'g' )
    if filename =~ 'unknown.xpt.vim$'
        return 'unknown'
    endif
    let ftFolder = matchstr( filename, '\V/ftplugin/\zs\[^\\]\+\ze/' )
    if empty( x.snipFileScopeStack ) 
        if &filetype !~ '\<' . ftFolder . '\>' " sub type like 'xpt.vim' 
            return 'not allowed'
        else
            let ft =  &filetype
        endif
    else
        if x.snipFileScopeStack[ -1 ].inheritFT
                \ || ftFolder =~ '^_'
            if !has_key( x.snipFileScopeStack[ -1 ], 'filetype' )
                throw 'parent may has no XPTemplate command called :' . a:filename
            endif
            let ft = x.snipFileScopeStack[ -1 ].filetype
        else
            let ft = ftFolder
        endif
    endif
    return ft
endfunction 
fun! s:LoadOtherFTPlugins( ft ) 
    call XPTsnipScopePush()
    for subft in split( a:ft, '\V.' )
        exe 'runtime! ftplugin/' . subft . '.vim'
        exe 'runtime! ftplugin/' . subft . '_*.vim'
        exe 'runtime! ftplugin/' . subft . '/*.vim'
    endfor
    call XPTsnipScopePop()
endfunction 
fun! XPTsnippetFileInit( filename, ... ) 
    if !exists("b:xptemplateData")
        call XPTemplateInit()
    endif
    let x = b:xptemplateData
    let filetypes = x.filetypes
    let snipScope = XPTnewSnipScope( a:filename )
    let snipScope.filetype = s:AssignSnipFT( a:filename )
    if snipScope.filetype == 'not allowed'
        call s:log.Info(  "not allowed:" . a:filename )
        return 'finish'
    endif 
    let filetypes[ snipScope.filetype ] = get( filetypes, snipScope.filetype, g:FiletypeScope.New() )
    let ftScope = filetypes[ snipScope.filetype ]
    if ftScope.CheckAndSetSnippetLoaded( a:filename )
        return 'finish'
    endif
    for pair in a:000
        let kv = split( pair . ';', '=' )
        if len( kv ) == 1
            let kv += [ '' ]
        endif
        let key = kv[ 0 ]
        let val = join( kv[ 1 : ], '=' )[ : -2 ]
        if key =~ 'prio\%[rity]'
            call XPTemplatePriority(val)
        elseif key =~ 'mark'
            call XPTemplateMark( val[ 0 : 0 ], val[ 1 : 1 ] )
        elseif key =~ 'key\%[word]'
            call XPTemplateKeyword(val)
        endif
    endfor
    return 'doit'
endfunction 
fun! XPTsnipSet( dictNameValue ) 
    let x = b:xptemplateData
    let snipScope = x.snipFileScope
    let [ dict, nameValue ] = split( a:dictNameValue, '\V.', 1 )
    let name = matchstr( nameValue, '^.\{-}\ze=' )
    let value = nameValue[ len( name ) + 1 :  ]
    let snipScope[ dict ][ name ] = value
endfunction 
fun! XPTsetVar( nameSpaceValue ) 
    let x = b:xptemplateData
    let ftScope = g:GetSnipFileFtScope()
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
    if !has_key( ftScope.varPriority, name ) || priority < ftScope.varPriority[ name ]
        let [ ftScope.funcs[ name ], ftScope.varPriority[ name ] ] = [ val, priority ]
    endif
endfunction 
fun! XPTinclude(...) 
    let scope = XPTsnipScope()
    let scope.inheritFT = 1
    for v in a:000
        if type(v) == type([])
            for s in v
                call XPTinclude(s)
            endfor
        elseif type(v) == type('') 
            if b:xptemplateData.filetypes[ scope.filetype ].IsSnippetLoaded( v )
                continue
            endif
            call XPTsnipScopePush()
            exe 'runtime! ftplugin/' . v . '.xpt.vim'
            call XPTsnipScopePop()
        endif
    endfor
endfunction 
fun! XPTembed(...) 
    let scope = XPTsnipScope()
    let scope.inheritFT = 0
    for v in a:000
        if type(v) == type([])
            for s in v
                call XPTinclude(s)
            endfor
        elseif type(v) == type('')
            call XPTsnipScopePush()
            exe 'runtime! ftplugin/' . v . '.xpt.vim'
            call XPTsnipScopePop()
        endif
    endfor
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
    let lines = lines[ i : ]
    let x = b:xptemplateData
    let x.snippetToParse += [ { 'snipFileScope' : x.snipFileScope, 'lines' : lines } ]
    call XPTparseSnippets()
    return
endfunction 
fun! XPTparseSnippets() 
    let x = b:xptemplateData
    for p in x.snippetToParse
        call DoParseSnippet(p)
    endfor
    let x.snippetToParse = []
endfunction 
fun! DoParseSnippet( p ) 
    call XPTsnipScopePush()
    let x = b:xptemplateData
    let x.snipFileScope = a:p.snipFileScope
    let lines = a:p.lines
    let [i, len] = [0, len(lines)]
    call s:ConvertIndent( lines )
    let [s, e, blk] = [-1, -1, 10000]
    while i < len-1 | let i += 1
        let v = lines[i]
        if v == '' || v =~ '\v^"[^"]*$'
            let blk = min([blk, i - 1])
            continue
        endif
        if v =~# '\V\^..XPT\>'
            let e = i - 1
            call s:XPTemplateParseSnippet(lines[s : e])
            let [s, e, blk] = [-1, -1, 10000]
        elseif v =~# '\V\^XPT\>'
            if s != -1
                let e = min([i - 1, blk])
                call s:XPTemplateParseSnippet(lines[s : e])
                let [s, e, blk] = [i, -1, 10000]
            else
                let s = i
                let blk = i
            endif
        elseif v =~# '\V\^\\XPT'
            let lines[i] = v[ 1 : ]
        else
            let blk = i
        endif
    endwhile
    if s != -1
        call s:XPTemplateParseSnippet(lines[s : min([blk, i])])
    endif
    call XPTsnipScopePop()
endfunction 
fun! s:XPTemplateParseSnippet(lines) 
    let lines = a:lines
    let snipScope = XPTsnipScope()
    let snipScope.loadedSnip = get( snipScope, 'loadedSnip', {} )
    let snippetLines = []
    let setting = deepcopy( g:XPTemplateSettingPrototype )
    let l0 = line[ 0 ]
    let pos = match( l0, '\VXPT\s\+\S\+\.\{-}\zs\s' . s:nonEscaped . '"' )
    if pos >= 0
        let [setting.rawHint, lines[0]] = [ matchstr( l0[ pos + 1 + 1 : ], '\v\S.*' ), l0[ : pos ] ]
    endif
    let [ x, snippetName; snippetParameters ] = split(lines[0], '\V'.s:nonEscaped.'\s\+')
    for pair in snippetParameters
        let name = matchstr(pair, '\V\^\[^=]\*')
        let value = pair[ len(name) : ]
        let value = value[0:0] == '=' ? xpt#util#UnescapeChar(value[1:], ' ') : 1
        let setting[name] = value
    endfor
    let start = 1
    let len = len( lines )
    while start < len
        let command = matchstr( lines[ start ], '\V\^XSETm\?\ze\s' )
        if command != ''
            let [ key, val, start ] = s:getXSETkeyAndValue( lines, start )
            if key == ''
                let start += 1
                continue
            endif
            let [ keyname, keytype ] = s:GetKeyType( key )
            call s:HandleXSETcommand(setting, command, keyname, keytype, val)
        elseif lines[start] =~# '^\\XSET' " escaped XSET or XSETm
            let snippetLines += [ lines[ start ][1:] ]
        else
            let snippetLines += [ lines[ start ] ]
        endif
        let start += 1
    endwhile
    let setting.fromXPT = 1
    if has_key( setting, 'alias' )
        call XPTemplateAlias( snippetName, setting.alias, setting )
    else
        call XPTdefineSnippet(snippetName, setting, snippetLines)
    endif
    if has_key( snipScope.loadedSnip, snippetName )
        XPT#warn( "XPT: warn : duplicate snippet:" . snippetName . ' in file:' . snipScope.filename )
    endif
    let snipScope.loadedSnip[ snippetName ] = 1
    if has_key( setting, 'synonym' )
        let synonyms = split( setting.synonym, '|' )
        for synonym in synonyms
            call XPTemplateAlias( synonym, snippetName, {} )
            if has_key( snipScope.loadedSnip, synonym )
                call XPT#warn( "XPT: warn : duplicate synonym:" . synonym . ' in file:' . snipScope.filename )
            endif
            let snipScope.loadedSnip[ synonym ] = 1
        endfor
    endif
endfunction 
fun! s:ConvertIndent( snipLines ) 
    let tabspaces = repeat( ' ', &tabstop )
    let indentRep = repeat( '\1', &shiftwidth )
    let cmdExpand = 'substitute(v:val, ''^\( *\)\1\1\1'', ''' . indentRep . ''', "g" )'
    call map( a:snipLines, cmdExpand )
endfunction 
fun! s:getXSETkeyAndValue(lines, start) 
    let start = a:start
    let XSETparam = matchstr(a:lines[start], '\V\^XSET\%[m]\s\+\zs\.\*')
    let isMultiLine = a:lines[ start ] =~# '\V\^XSETm'
    if isMultiLine
        let key = XSETparam
        let [ start, val ] = s:ParseMultiLineValues(a:lines, start)
    else
        let key = matchstr(XSETparam, '\V\[^=]\*\ze=')
        if key == ''
            return [ '', '', start + 1 ]
        endif
        let val = matchstr(XSETparam, '\V=\s\*\zs\.\*')
        let val = substitute(val, '\\n', "\n", 'g')
    endif
    return [ key, val, start ]
endfunction 
fun! s:ParseMultiLineValues(lines, start) 
    let lines = a:lines
    let start = a:start
    let endPattern = '\V\^XSETm\s\+END\$'
    let start += 1
    let multiLineValues = []
    while start < len( lines )
        let line = lines[start]
        if line =~# endPattern
            break
        endif
        if line =~# '^\V\\\+XSET\%[m]'
            let slashes = matchstr( line, '^\\\+' )
            let nrSlashes = len( slashes + 1 ) / 2
            let line = line[ nrSlashes : ]
        endif
        let multiLineValues += [ line ]
        let start += 1
    endwhile
    let val = join(multiLineValues, "\n")
    return [ start, val ]
endfunction 
fun! s:GetKeyType(rawKey) 
    let keytype = matchstr(a:rawKey, '\V'.s:nonEscaped.'|\zs\.\{-}\$')
    if keytype == ""
        let keytype = matchstr(a:rawKey, '\V'.s:nonEscaped.'.\zs\.\{-}\$')
    endif
    let keyname = keytype == "" ? a:rawKey :  a:rawKey[ 0 : - len(keytype) - 2 ]
    let keyname = substitute(keyname, '\V\\\(\[.|\\]\)', '\1', 'g')
    return [ keyname, keytype ]
endfunction 
fun! s:HandleXSETcommand(setting, command, keyname, keytype, value) 
    if a:keyname ==# 'ComeFirst'
        let a:setting.comeFirst = s:SplitWith( a:value, ' ' )
    elseif a:keyname ==# 'ComeLast'
        let a:setting.comeLast = s:SplitWith( a:value, ' ' )
    elseif a:keyname ==# 'postQuoter'
        let a:setting.postQuoter = a:value
    elseif a:keyname =~ '\V\^$'
        let a:setting.variables[ a:keyname ] = a:value
    elseif a:keytype == 'repl'
        let a:setting.replacements[ a:keyname ] = a:value
    elseif a:keytype == "" || a:keytype ==# 'def' || a:keytype ==# 'onfocus'
        let a:setting.defaultValues[a:keyname] = g:FilterValue.New( 0, a:value )
    elseif a:keytype ==# 'map'
        let a:setting.mappings[ a:keyname ] = get(
              \ a:setting.mappings,
              \ a:keyname,
              \ { 'saver' : g:MapSaver.New( 1 ), 'keys' : {} } )
        let key = matchstr( a:value, '\V\^\S\+\ze\s' )
        let mapping = matchstr( a:value, '\V\s\+\zs\.\*' )
        call a:setting.mappings[ a:keyname ].saver.Add( 'i', key )
        let a:setting.mappings[ a:keyname ].keys[ key ] = g:FilterValue.New( 0, mapping )
    elseif a:keytype ==# 'pre'
        let a:setting.preValues[a:keyname] = g:FilterValue.New( 0, a:value )
    elseif a:keytype ==# 'ontype'
        let a:setting.ontypeFilters[a:keyname] = g:FilterValue.New( 0, a:value )
    elseif a:keytype ==# 'post'
        if a:keyname =~ '\V...'
            let a:setting.postFilters[a:keyname] = 
                  \ g:FilterValue.New( 0, 'BuildIfNoChange(' . string(a:value) . ')' )
        else
            let a:setting.postFilters[a:keyname] = g:FilterValue.New( 0, a:value )
        endif
    else
        throw "unknown key name or type:" . a:keyname . ' ' . a:keytype
    endif
endfunction 
fun! s:SplitWith( str, char ) 
  let s = split( a:str, '\V' . s:nonEscaped . a:char, 1 )
  return s
endfunction 
let &cpo = s:oldcpo
call StartProf()
