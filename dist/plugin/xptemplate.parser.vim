if exists("g:__XPTEMPLATE_PARSER_VIM__")
  finish
endif
let g:__XPTEMPLATE_PARSER_VIM__ = 1
runtime plugin/debug.vim
runtime plugin/xpclass.vim
runtime plugin/FiletypeScope.class.vim
runtime plugin/xptemplate.util.vim
runtime plugin/xptemplate.vim
let s:log = CreateLogger( 'warn' )
let s:log = CreateLogger( 'debug' )
com! -nargs=* XPTemplate
            \   if XPTsnippetFileInit( expand( "<sfile>" ), <f-args> ) == 'finish'
            \ |     finish
            \ | endif
com!          XPTemplateDef call s:XPTstartSnippetPart(expand("<sfile>")) | finish
com! -nargs=* XPTvar        call XPTsetVar( <q-args> )
com! -nargs=* XPTsnipSet    call XPTsnipSet( <q-args> )
com! -nargs=+ XPTinclude    call XPTinclude(<f-args>)
com! -nargs=+ XPTembed      call XPTembed(<f-args>)
let s:nonEscaped = '\%(' . '\%(\[^\\]\|\^\)' . '\%(\\\\\)\*' . '\)' . '\@<='
fun! s:AssignSnipFT( filename ) 
    let x = g:XPTobject()
    let filename = substitute( a:filename, '\\', '/', 'g' )
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
fun! XPTsnippetFileInit( filename, ... ) 
    let x = XPTbufData()
    let filetypes = x.filetypes
    let snipScope = XPTnewSnipScope(a:filename)
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
        elseif key =~ 'ind\%[ent]'
            call XPTemplateIndent(val)
        elseif key =~ 'key\%[word]'
            call XPTemplateKeyword(val)
        endif
    endfor
    return 'doit'
endfunction 
fun! XPTsnipSet( dictNameValue ) 
    let x = XPTbufData()
    let snipScope = x.snipFileScope
    let [ dict, nameValue ] = split( a:dictNameValue, '\V.', 1 )
    let name = matchstr( nameValue, '^.\{-}\ze=' )
    let value = nameValue[ len( name ) + 1 :  ]
    let snipScope[ dict ][ name ] = value
endfunction 
fun! XPTsetVar( nameSpaceValue ) 
    let x = XPTbufData()
    let ftScope = g:GetSnipFileFtScope()
    let name = matchstr(a:nameSpaceValue, '^\S\+\ze\s')
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
            call XPTsnipScopePush()
            exe 'runtime ftplugin/' . v . '.xpt.vim'
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
            exe 'runtime ftplugin/' . v . '.xpt.vim'
            call XPTsnipScopePop()
        endif
    endfor
endfunction 
fun! s:XPTstartSnippetPart(fn) 
    let lines = readfile(a:fn)
    let i = match( lines, '^XPTemplateDef' )
    let lines = lines[ i : ]
    let [i, len] = [0, len(lines)]
    call s:ConvertIndent( lines )
    let [s, e, blk] = [-1, -1, 10000]
    while i < len-1 | let i += 1
        let v = lines[i]
        if v =~ '^\s*$' || v =~ '^"[^"]*$'
            let blk = min([blk, i - 1])
            continue
        endif
        if v =~# '^\.\.XPT'
            let e = i - 1
            call s:XPTemplateParseSnippet(lines[s : e])
            let [s, e, blk] = [-1, -1, 10000]
        elseif v =~# '^XPT\>'
            if s != -1
                let e = min([i - 1, blk])
                call s:XPTemplateParseSnippet(lines[s : e])
                let [s, e, blk] = [i, -1, 10000]
            else
                let s = i
                let blk = i
            endif
        elseif v =~# '^\\XPT'
            let lines[i] = v[ 1 : ]
        else
            let blk = i
        endif
    endwhile
    if s != -1
        call s:XPTemplateParseSnippet(lines[s : min([blk, i])])
    endif
endfunction 
fun! s:XPTemplateParseSnippet(lines) 
    let lines = a:lines
    let snipScope = XPTsnipScope()
    let snipScope.loadedSnip = get( snipScope, 'loadedSnip', {} )
    let snippetLines = []
    let setting = deepcopy( g:XPTemplateSettingPrototype )
    let [hint, lines[0]] = s:GetSnipCommentHint( lines[0] )
    if hint != ''
        let setting.hint = hint
    endif
    let snippetParameters = split(lines[0], '\V'.s:nonEscaped.'\s\+')
    let snippetName = snippetParameters[1]
    let snippetParameters = snippetParameters[2:]
    for pair in snippetParameters
        let nameAndValue = split(pair, '=', 1)
        if len(nameAndValue) > 1
            let propName = nameAndValue[0]
            let propValue = g:xptutil.UnescapeChar( join( nameAndValue[1:], '=' ), ' ' )
            if propName == ''
                throw 'empty property name at line:' . lines[0]
            elseif !has_key( setting, propName )
                let setting[propName] = propValue
            endif
        endif
    endfor
    let start = 1
    let len = len( lines )
    while start < len
        if lines[start] =~# '^XSET\%[m]\s\+'
            let command = matchstr( lines[ start ], '^XSET\%[m]' )
            let [ key, val, start ] = s:getXSETkeyAndValue( lines, start )
            if key == ''
                let start += 1
                continue
            endif
            let [ keyname, keytype ] = s:GetKeyType( key )
            call s:handleXSETcommand(setting, command, keyname, keytype, val)
        elseif lines[start] =~# '^\\XSET\%[m]' " escaped XSET or XSETm
            let snippetLines += [ lines[ start ][1:] ]
        else
            let snippetLines += [ lines[ start ] ]
        endif
        let start += 1
    endwhile
    if has_key( setting, 'alias' )
        call XPTemplateAlias( snippetName, setting.alias, setting )
    else
        call XPTemplate(snippetName, setting, snippetLines)
    endif
    if has_key( snipScope.loadedSnip, snippetName )
        echom "XPT: warn : duplicate snippet:" . snippetName . ' in file:' . snipScope.filename
    endif
    let snipScope.loadedSnip[ snippetName ] = 1
    if has_key( setting, 'synonym' )
        let synonyms = split( setting.synonym, '|' )
        for synonym in synonyms
            call XPTemplateAlias( synonym, snippetName, {} )
            if has_key( snipScope.loadedSnip, synonym )
                echom "XPT: warn : duplicate snippet:" . synonym . ' in file:' . snipScope.filename
            endif
            let snipScope.loadedSnip[ synonym ] = 1
        endfor
    endif
endfunction 
fun! s:GetSnipCommentHint(str) 
    let pos = match( a:str, '\V\s' . s:nonEscaped . '"' )
    if pos == -1
        return [ '', a:str ]
    else
        return [ matchstr( a:str[ pos + 1 + 1 : ], '\S.*' ), a:str[ : pos ] ]
    endif
endfunction 
fun! s:ConvertIndent( snipLines ) 
    let sts = &l:softtabstop
    let ts  = &l:tabstop
    let usingTab = !&l:expandtab
    if 0 == sts 
        let sts = ts
    endif
    let tabspaces = repeat( ' ', ts )
    let indentRep = repeat( '\1', sts )
    let cmdExpand = 'substitute(v:val, ''^\( *\)\1\1\1'', ''' . indentRep . ''', "g" )'
    call map( a:snipLines, cmdExpand )
    if usingTab 
        let cmdReplaceTab = 'v:val !~ ''^ '' ? v:val : join(split( v:val, ' . string( '^\%(' . tabspaces . '\)' ) . ', 1), ''	'')' 
        call map( a:snipLines, cmdReplaceTab )
    endif
endfunction 
fun! s:getXSETkeyAndValue(lines, start) 
    let start = a:start
    let XSETparam = matchstr(a:lines[start], '^XSET\%[m]\s\+\zs.*')
    let isMultiLine = a:lines[ start ] =~# '^XSETm'
    if isMultiLine
        let key = XSETparam
        let [ start, val ] = s:parseMultiLineValues(a:lines, start)
    else
        let key = matchstr(XSETparam, '[^=]*\ze=')
        if key == ''
            return [ '', '', start + 1 ]
        endif
        let val = matchstr(XSETparam, '=\zs.*')
        let val = substitute(val, '\\n', "\n", 'g')
    endif
    return [ key, val, start ]
endfunction 
fun! s:parseMultiLineValues(lines, start) 
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
    let keyname = keytype == "" ? a:rawKey :  a:rawKey[ : - len(keytype) - 2 ]
    let keyname = substitute(keyname, '\V\\\(\[.|\\]\)', '\1', 'g')
    return [ keyname, keytype ]
endfunction 
fun! s:handleXSETcommand(setting, command, keyname, keytype, value) 
    if a:keyname ==# 'ComeFirst'
        let a:setting.comeFirst = s:splitWith( a:value, ' ' )
    elseif a:keyname ==# 'ComeLast'
        let a:setting.comeLast = s:splitWith( a:value, ' ' )
    elseif a:keyname ==# 'postQuoter'
        let a:setting.postQuoter = a:value
    elseif a:keytype == "" || a:keytype ==# 'def'
        let a:setting.defaultValues[a:keyname] = "\n" . a:value
    elseif a:keytype ==# 'pre'
        let a:setting.preValues[a:keyname] = "\n" . a:value
    elseif a:keytype ==# 'post'
        if a:keyname =~ '\V...'
            let a:setting.postFilters[a:keyname] = "\n" . 'BuildIfNoChange(' . string(a:value) . ')'
        else
            let a:setting.postFilters[a:keyname] = "\n" . a:value
        endif
    else
        throw "unknown key name or type:" . a:keyname . ' ' . a:keytype
    endif
endfunction 
fun! s:splitWith( str, char ) 
  let s = split( a:str, '\V' . s:nonEscaped . a:char, 1 )
  return s
endfunction 
