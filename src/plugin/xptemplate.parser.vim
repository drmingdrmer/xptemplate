if exists( "g:__XPTEMPLATE_PARSER_VIM__" ) && g:__XPTEMPLATE_PARSER_VIM__ >= XPT#ver
    finish
endif
let g:__XPTEMPLATE_PARSER_VIM__ = XPT#ver


"
" Special XSET[m] Keys
"   ComeFirst   : item names which come first before any other
"               // XSET ComeFirst=i,len
"
"   ComeLast    : item names which come last after any other
"               // XSET ComeLast=i,len
"
"   postQuoter  : Quoter to define repetition
"               // XSET postQuoter=<{[,]}>
"               // defulat : {{,}}
"
"
"

let s:oldcpo = &cpo
set cpo-=< cpo+=B


" runtime plugin/classes/FiletypeScope.vim
" runtime plugin/classes/FilterValue.vim
" runtime plugin/xptemplate.util.vim
runtime plugin/xptemplate.vim



let s:log = xpt#debug#Logger( 'warn' )
let s:log = xpt#debug#Logger( 'debug' )


com! -nargs=* XPTemplate
      \   if XPTsnippetFileInit( expand( "<sfile>" ), <f-args> ) == 'finish'
      \ |     finish
      \ | endif

com! -nargs=* XPTemplateDef echom expand("<sfile>") . " XPTemplateDef is NOT needed any more. All right to remove it."
com! -nargs=* XPTvar        call XPTsetVar( <q-args> )
" TODO rename me to XSET
com! -nargs=* XPTsnipSet    call XPTsnipSet( <q-args> )
com! -nargs=+ XPTinclude    call XPTinclude(<f-args>)
com! -nargs=+ XPTembed      call XPTembed(<f-args>)
" com! -nargs=* XSET          call XPTbufferScopeSet( <q-args> )


let s:nonEscaped = '\%(' . '\%(\[^\\]\|\^\)' . '\%(\\\\\)\*' . '\)' . '\@<='

fun! s:AssignSnipFT( filename ) "{{{

    let x = b:xptemplateData

    let filename = substitute( a:filename, '\\', '/', 'g' )

    if filename =~ '\Vunknown.xpt.vimc\?\$'
        return 'unknown'
    endif


    let ftFolder = matchstr( filename, '\V/ftplugin/\zs\[^\\]\+\ze/' )
    if empty( x.snipFileScopeStack )

        " Top Level snippet
        "
        " All cross filetype inclusions must be done with XPTinclude or
        " XPTembed.
        " But 'runtime' command is not allowed for inclusion or embed

        if &filetype =~ '\<' . ftFolder . '\>' " sub type like 'xpt.vim'
            let ft =  &filetype
        else
            let ft = 'NOT_ALLOWED'
        endif

    else

        if x.snipFileScopeStack[ -1 ].inheritFT
                \ || ftFolder =~ '\V\^_'

            " Snippet is loaded with XPTinclude
            " or it is an general snippet like "_common/common.xpt.vim"

            if ! has_key( x.snipFileScopeStack[ -1 ], 'filetype' )

                " no parent snippet file
                " maybe parent snippet file has no XPTemplate command called

                throw 'parent may has no XPTemplate command called :' . a:filename

            endif

            let ft = x.snipFileScopeStack[ -1 ].filetype

        else

            " Snippet is loaded with XPTembed which uses an independent
            " filetype.

            let ft = ftFolder

        endif

    endif

    call s:log.Log( "filename=" . filename . ' filetype=' . &filetype . " ft=" . ft )

    return ft

endfunction "}}}


fun! s:LoadOtherFTPlugins( ft ) "{{{

    " NOTE: XPT depends on some per-language setting such as shiftwidth.
    "       So we need to load other ftplugins first.

    call XPTsnipScopePush()

    for subft in split( a:ft, '\V.' )

        exe 'runtime! ftplugin/' . subft . '.vim'
        exe 'runtime! ftplugin/' . subft . '_*.vim'
        exe 'runtime! ftplugin/' . subft . '/*.vim'

    endfor

    call XPTsnipScopePop()

endfunction "}}}

fun! DoSnippetFileInit( filename, ... ) "{{{

    " This function is called before 'BufEnter' event which
    " initialize XPTemplate

    if !exists("b:xptemplateData")
        call XPTemplateInit()
    endif

    call s:log.Debug( 'DoSnippetFileInit is called' )

    let x = b:xptemplateData
    let filetypes = x.filetypes

    let snipScope = XPTnewSnipScope( a:filename )
    let snipScope.filetype = s:AssignSnipFT( a:filename )


    if snipScope.filetype == 'NOT_ALLOWED'
        call s:log.Info(  "NOT_ALLOWED:" . a:filename )
        return 'finish'
    endif

    if ! has_key( filetypes, snipScope.filetype )
        let filetypes[ snipScope.filetype ] = xpt#ftsc#New()
    endif

    let ftScope = filetypes[ snipScope.filetype ]


    if xpt#ftsc#CheckAndSetSnippetLoaded( ftScope,  a:filename )
        return 'finish'
    endif


    " call s:LoadOtherFTPlugins()
    " let snipScope = x.snipFileScope


    for pair in a:000

        let kv = split( pair, '=', 1 )

        let key = kv[ 0 ]
        let val = join( kv[ 1 : ], '=' )

        call s:log.Log( "init:key=" . key . ' val=' . val )

        if key =~ 'prio\%[rity]'
            call XPTemplatePriority(val)

        elseif key =~ 'mark'
            call XPTemplateMark( val[ 0 : 0 ], val[ 1 : 1 ] )

        " elseif key =~ 'key\%[word]'
        "     call XPTemplateKeyword(val)

        endif

    endfor

    return 'doit'

endfunction "}}}

fun! XPTsnippetFileInit( filename, ... ) "{{{

    call s:log.Debug( 'XPTsnippetFileInit is called. filename=' . string( a:filename ) )

    if a:filename =~ '\V.xpt.vim\$'

        call s:log.Debug( 'original file, to compile it' )

        call xpt#parser#Compile( a:filename )
        exe 'so' a:filename . 'c'

        return 'finish'

    else

        call s:log.Debug( 'Compiled file: ' . string( a:filename ) )

        return call( function( 'DoSnippetFileInit' ), [ a:filename ] + a:000 )

    endif

endfunction "}}}

fun! XPTsnipSet( dictNameValue ) "{{{
    let x = b:xptemplateData
    let snipScope = x.snipFileScope

    let [ dict, nameValue ] = split( a:dictNameValue, '\V.', 1 )
    let name = matchstr( nameValue, '^.\{-}\ze=' )
    let value = nameValue[ len( name ) + 1 :  ]

    call s:log.Log( 'set snipScope:' . string( [ dict, name, value ] ) )
    let snipScope[ dict ][ name ] = value

endfunction "}}}

fun! XPTsetVar( nameSpaceValue ) "{{{

    let x = b:xptemplateData
    let ftScope = g:GetSnipFileFtScope()

    call s:log.Debug( 'xpt var raw data=' . string( a:nameSpaceValue ) )

    let name = matchstr(a:nameSpaceValue, '^\S\+\ze')

    if name == ''
        return
    endif

    " TODO use s:nonEscaped to detect escape
    let val  = matchstr(a:nameSpaceValue, '\s\+\zs.*')
    if val =~ '^''.*''$'
        let val = val[1:-2]
    else
        let val = substitute( val, '\\ ', " ", 'g' )
    endif
    let val = substitute( val, '\\n', "\n", 'g' )


    let priority = x.snipFileScope.priority
    call s:log.Log("name=".name.' value='.val.' priority='.priority)


    if !has_key( ftScope.varPriority, name ) || priority <= ftScope.varPriority[ name ]
        let [ ftScope.funcs[ name ], ftScope.varPriority[ name ] ] = [ val, priority ]
    endif

endfunction "}}}

fun! XPTinclude(...) "{{{

    let scope = b:xptemplateData.snipFileScope

    let scope.inheritFT = 1

    for v in a:000
        if type(v) == type([])

            for s in v
                call XPTinclude(s)
            endfor

        elseif type(v) == type('')

            if xpt#ftsc#IsSnippetLoaded( b:xptemplateData.filetypes[ scope.filetype ], v )
                continue
            endif

            call XPTsnipScopePush()
            exe 'runtime! ftplugin/' . v . '.xpt.vim'
            call XPTsnipScopePop()

        endif
    endfor
endfunction "}}}

fun! XPTembed(...) "{{{

    let scope = b:xptemplateData.snipFileScope

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
endfunction "}}}



fun! DoParseSnippet( p ) "{{{

    call XPTsnipScopePush()

    let x = b:xptemplateData

    let x.snipFileScope = a:p.snipFileScope
    let lines = a:p.lines


    let [i, len] = [0, len(lines)]

    call s:AdjustIndentWidth( lines )

    " parse lines
    " start end and blank start
    let [s, e, blk] = [-1, -1, 100000]
    while i < len-1 | let i += 1

        let v = lines[i]

        " blank line
        if v == '' || v =~ '\v^"[^"]*$'
            let blk = min([blk, i - 1])
            continue
        endif


        if v =~# '\V\^..XPT\>'

            let e = i - 1
            call s:XPTemplateParseSnippet(lines[s : e])
            let [s, e, blk] = [-1, -1, 100000]

        elseif v =~# '\V\^XPT\>'

            if s != -1
                " template with no end
                let e = min([i - 1, blk])
                call s:XPTemplateParseSnippet(lines[s : e])
                let [s, e, blk] = [i, -1, 100000]
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
endfunction "}}}

fun! s:XPTemplateParseSnippet(lines) "{{{

    let lines = a:lines


    let snipFileScope = XPTsnipScope()
    let snipFileScope.loadedSnip = get( snipFileScope, 'loadedSnip', {} )


    let snippetLines = []


    let setting = deepcopy( g:XPTemplateSettingPrototype )


    " " inline-ed
    " let [hint, lines[0]] = s:GetSnipCommentHint( lines[0] )

    let l0 = lines[ 0 ]
    let pos = match( l0, '\VXPT\s\+\S\+\.\{-}\zs\s' . s:nonEscaped . '"' )
    if pos >= 0
        " skip space, '"'
        let [setting.rawHint, lines[0]] = [ matchstr( l0[ pos + 1 + 1 : ], '\v\S.*' ), l0[ : pos ] ]
    endif


    let [ x, snippetName; snippetParameters ] = split(lines[0], '\V'.s:nonEscaped.'\s\+')

    for pair in snippetParameters
        let name = matchstr(pair, '\V\^\[^=]\*')
        let value = pair[ len(name) : ]

        " flag setting need no value present
        let value = value[0:0] == '=' ? xpt#util#UnescapeChar(value[1:], ' ') : 1

        let setting[name] = value
    endfor



    " skip the title line
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


            call s:log.Log("got value, start=".start)


            let [ keyname, keytype ] = s:GetKeyType( key )

            call s:log.Log("parse XSET:" . keyname . "|" . keytype . '=' . val)


            call s:HandleXSETcommand(setting, command, keyname, keytype, val)


            " TODO can not input \XSET
        elseif lines[start] =~# '^\\XSET' " escaped XSET or XSETm
            let snippetLines += [ lines[ start ][1:] ]

        else
            " let snippetLines += [ lines[ start ] ]
            call add( snippetLines, lines[ start ] )

        endif

        let start += 1
    endwhile


    call s:log.Log("start:".start)
    call s:log.Log("to parse tmpl : snippetName=" . snippetName)


    let setting.fromXPT = 1


    call s:log.Log("tmpl setting:".string(setting))
    if has_key( setting, 'alias' )
        call XPTemplateAlias( snippetName, setting.alias, setting )
    else
        call XPTdefineSnippet(snippetName, setting, snippetLines)
    endif


    if has_key( snipFileScope.loadedSnip, snippetName )
        XPT#warn( "XPT: warn : duplicate snippet:" . snippetName . ' in file:' . snipFileScope.filename )
    endif

    let snipFileScope.loadedSnip[ snippetName ] = 1


    if has_key( setting, 'synonym' )
        let synonyms = split( setting.synonym, '|' )
        for synonym in synonyms
            call XPTemplateAlias( synonym, snippetName, {} )

            if has_key( snipFileScope.loadedSnip, synonym )
                call XPT#warn( "XPT: warn : duplicate synonym:" . synonym . ' in file:' . snipFileScope.filename )
            endif

            let snipFileScope.loadedSnip[ synonym ] = 1

        endfor
    endif


endfunction "}}}


" TODO convert indent in runtime
fun! s:AdjustIndentWidth( snipLines ) "{{{

    let tabspaces = repeat( ' ', &tabstop )
    let indentRep = repeat( '\1', &shiftwidth )

    let cmdExpand = 'substitute(v:val, ''^\( *\)\1\1\1'', ''' . indentRep . ''', "g" )'

    call map( a:snipLines, cmdExpand )

endfunction "}}}

fun! s:getXSETkeyAndValue(lines, start) "{{{
    let start = a:start

    let XSETparam = matchstr(a:lines[start], '\V\^XSET\%[m]\s\+\zs\.\*')
    let isMultiLine = a:lines[ start ] =~# '\V\^XSETm'

    if isMultiLine
        let key = XSETparam

        let [ start, val ] = s:ParseMultiLineValues(a:lines, start)
        call s:log.Log( 'multi line XSETm ends at:' . start )


    else
        let key = matchstr(XSETparam, '\V\[^=]\*\ze=')

        if key == ''
            return [ '', '', start + 1 ]
        endif

        let val = matchstr(XSETparam, '\V=\s\*\zs\.\*')

        " TODO can not input '\\n'
        let val = substitute(val, '\\n', "\n", 'g')

    endif

    return [ key, val, start ]

endfunction "}}}

" XXX
" fun! s:XPTbufferScopeSet( str )
    " let [ key, value, start ] = s:getXSETkeyAndValue( [ 'XSET ' . a:str ], 0 )
    " let [ keyname, keytype ] = s:GetKeyType( key )
"
" endfunction

fun! s:ParseMultiLineValues(lines, start) "{{{
    " @return  [ which_line_XSETm_ends, multi_line_text ]


    call s:log.Log("multi line XSET")

    let lines = a:lines
    let start = a:start


    " non-escaped end symbol
    let endPattern = '\V\^XSETm\s\+END\$'



    " really it is a multi line item

    " current line has been fetched already.
    let start += 1

    " get lines upto 'XSETm END'
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

    call s:log.Log("multi line XSET value=".string(multiLineValues))

    let val = join(multiLineValues, "\n")



    return [ start, val ]
endfunction "}}}

fun! s:GetKeyType(rawKey) "{{{

    let keytype = matchstr(a:rawKey, '\V'.s:nonEscaped.'|\zs\.\{-}\$')
    if keytype == ""
        let keytype = matchstr(a:rawKey, '\V'.s:nonEscaped.'.\zs\.\{-}\$')
    endif

    let keyname = keytype == "" ? a:rawKey :  a:rawKey[ 0 : - len(keytype) - 2 ]
    let keyname = substitute(keyname, '\V\\\(\[.|\\]\)', '\1', 'g')

    return [ keyname, keytype ]

endfunction "}}}

fun! s:HandleXSETcommand(setting, command, keyname, keytype, value) "{{{

    if a:keyname ==# 'ComeFirst'
        let a:setting.comeFirst = xpt#util#SplitWith( a:value, ' ' )

    elseif a:keyname ==# 'ComeLast'
        let a:setting.comeLast = xpt#util#SplitWith( a:value, ' ' )

    elseif a:keyname ==# 'postQuoter'
        let a:setting.postQuoter = a:value

    elseif a:keyname =~ '\V\^$'
        let a:setting.variables[ a:keyname ] = a:value


    elseif a:keytype == 'repl'
        let a:setting.replacements[ a:keyname ] = a:value

    elseif a:keytype == "" || a:keytype ==# 'def' || a:keytype ==# 'onfocus'
        " first line is indent : empty indent
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
            " TODO not good, use another keytype to define 'buildIfNoChange' post filter
            "
            " first line is indent : empty indent
            let a:setting.postFilters[a:keyname] =
                  \ g:FilterValue.New( 0, 'BuildIfNoChange(' . string(a:value) . ')' )

        else
            " first line is indent : empty indent
            let a:setting.postFilters[a:keyname] = g:FilterValue.New( 0, a:value )

        endif

    else
        throw "unknown key name or type:" . a:keyname . ' ' . a:keytype

    endif

endfunction "}}}


let &cpo = s:oldcpo


" call StartProf()
