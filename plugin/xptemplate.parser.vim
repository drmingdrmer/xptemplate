if exists("g:__XPTEMPLATE_PARSER_VIM__")
  finish
endif
let g:__XPTEMPLATE_PARSER_VIM__ = 1

" 
" Special XSET[m] Keys
"   ComeFirst   : item names which come first before any other  
"               // XSET ComeFirst=i,len
"
"   ComeLast    : item names which come last after any other 
"               // XSET ComeLast=i,len
"
"   PostQuoter  : Quoter to define repetition
"               // XSET PostQuoter=<{[,]}>
"               // defulat : <{[,]}>
" 
"
"
"
"
"
"
"
"
"
"

runtime plugin/debug.vim
runtime plugin/xptemplate.vim

let s:log = CreateLogger( 'debug' )


com! -nargs=* XPTemplate
            \   if XPTemplateFileDefinition( expand( "<sfile>" ), <f-args> ) == 'finish'
            \ |     finish
            \ | endif

com!          XPTemplateDef call s:XPTemplateDefineSnippet(expand("<sfile>")) | finish
com! -nargs=* XPTvar        call XPTsetVar( <q-args> )
com! -nargs=+ XPTinclude    call XPTinclude(<f-args>)
com! -nargs=* XSET          call XPTbufferScopeSet( <q-args> )


let s:nonEscaped = '\%(' . '\%(\[^\\]\|\^\)' . '\%(\\\\\)\*' . '\)' . '\@<='

fun! XPTemplateFileDefinition( filename, ... ) "{{{
    if !exists( 'b:__xpt_loaded' )
        let b:__xpt_loaded = {}
    endif

    if has_key( b:__xpt_loaded, a:filename )
        return 'finish'
    endif

    let b:__xpt_loaded[a:filename] = 1


    for pair in a:000

        " protect last '='
        let kv = split( pair . ';', '=' )
        if len( kv ) == 1
            let kv += [ '' ]
        endif

        let key = kv[ 0 ]
        " remove last ';'
        let val = join( kv[ 1 : ], '=' )[ : -2 ]

        call s:log.Log( "init:key=" . key . ' val=' . val )

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
endfunction "}}}

fun! XPTsetVar( nameSpaceValue ) "{{{
    let x = XPTbufData()

    call s:log.Debug( 'xpt var raw data=' . string( a:nameSpaceValue ) )
    let name = matchstr(a:nameSpaceValue, '^\S\+\ze\s')
    if name == ''
        return
    endif

    " TODO use s:nonEscaped to detect escape
    let val  = matchstr(a:nameSpaceValue, '\s\+\zs.*')
    let val = substitute( val, '\\n', "\n", 'g' )
    let val = substitute( val, '\\ ', " ", 'g' )


    let priority = x.bufsetting.priority
    call s:log.Log("name=".name.' value='.val.' priority='.priority)


    if !has_key( x.varPriority, name ) || priority < x.varPriority[ name ]
        let [ x.vars[ name ], x.varPriority[ name ] ] = [ val, priority ]
    endif

endfunction "}}}

fun! XPTinclude(...) "{{{
    if a:0 < 1
        return
    endif

    let x = XPTbufData()
    let prio = x.bufsetting.priority


    let list = a:000

    for v in list
        if type(v) == type([])
            for s in v
                call XPTinclude(s)
            endfor
        elseif type(v) == type('')
            let cmd =  'runtime ftplugin/'.v.'.xpt.vim'
            exe cmd
        endif
    endfor

    let x.bufsetting.priority = prio

endfunction "}}}

" TODO refine me
fun! s:XPTemplateDefineSnippet(fn) "{{{
    call s:log.Log("parse file :".a:fn)
    let lines = readfile(a:fn)


    " find the line where XPTemplateDef called
    let [i, len] = [0, len(lines)]
    while i < len
        if lines[i] =~# '^XPTemplateDef'
            break
        endif

        let i += 1
    endwhile


    " parse lines
    " start end and blank start
    let [s, e, blk] = [-1, -1, 10000]
    while i < len-1 | let i += 1

        let v = lines[i]

        " blank line
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
                " template with no end
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

endfunction "}}}

let s:settingPrototype = {
            \    'defaultValues' : {},
            \    'postFilters' : {},
            \    'comeFirst' : [],
            \    'comeLast' : [],
            \}

fun! s:XPTemplateParseSnippet(lines) "{{{
    " TODO arbitrary position of XSET
    let lines = a:lines

    let snippetLines = []

    let snippetParameters = split(lines[0], '\V'.s:nonEscaped.'\s\+')
    let snippetName = snippetParameters[1]

    call s:log.Log("parse lines:".string(lines))
    call s:log.Log("snippetParameters=".string(snippetParameters))
    call s:log.Log("line0=".lines[0])
    call s:log.Log('snippetName='.snippetName)

    let snippetParameters = snippetParameters[2:]

    let setting = {}
    " let setting.postQuoter = '<{[,]}>'
    let setting.postQuoter = '{{,}}'

    for pair in snippetParameters
        let nameAndValue = split(pair, '=', 1)

        if len(nameAndValue) > 1
            let propName = nameAndValue[0]
            let propValue = substitute( join( nameAndValue[1:], '=' ), '\\\(.\)', '\1', 'g' )
            let setting[propName] = propValue
        endif
    endfor

    call extend( setting, deepcopy( s:settingPrototype ), 'force' )

    let start = 1
    let len = len( lines )
    while start < len
        if lines[start] =~# '^XSET\%[m]\s\+'

            let [ key, val, start ] = s:getXSETkeyAndValue( lines, start )
            if key == ''
                continue
            endif


            call s:log.Log("got value, start=".start)


            let [ keyname, keytype ] = s:getKeyType( key )

            call s:log.Log("parse XSET:" . keyname . "|" . keytype . '=' . val)


            call s:handleXSETcommand(setting, keyname, keytype, val)


            " TODO can not input \XSET
        elseif lines[start] =~# '^\\XSET\%[m]' " escaped XSET or XSETm
            let snippetLines += [ lines[ start ][1:] ]
            " break
        else
            let snippetLines += [ lines[ start ] ]
            " break
        endif

        let start += 1
    endwhile


    call s:parseSetting(setting)


    call s:log.Log("start:".start)
    call s:log.Log("to parse tmpl : snippetName=" . snippetName)

    call s:addCursorToComeLast(setting)


    call s:log.Log("tmpl setting:".string(setting))
    if has_key( setting, 'alias' )
        call XPTemplateAlias( snippetName, setting.alias, setting )

    else
        call XPTemplate(snippetName, setting, snippetLines)

    endif


endfunction "}}}

fun! s:parseSetting( setting ) "{{{
    
    let quoters = split( a:setting.postQuoter, ',' )
    if len( quoters ) < 2
        throw 'postQuoter must be separated with ','! :' . a:setting.postQuoter
    endif

    let a:setting.postQuoter = { 'start' : quoters[0], 'end' : quoters[1] }


endfunction "}}}

fun! s:getXSETkeyAndValue(lines, start) "{{{
    let start = a:start

    let XSETparam = matchstr(a:lines[start], '^XSET\%[m]\s\+\zs.*')
    let isMultiLine = a:lines[ start ] =~# '^XSETm'

    if isMultiLine
        let key = XSETparam

        let [ start, val ] = s:parseMultiLineValues(a:lines, start)
        call s:log.Log( 'multi line XSETm ends at:' . start )


    else
        let key = matchstr(XSETparam, '[^=]*\ze=')

        if key == ''
            return [ '', '', start + 1 ]
        endif

        let val = matchstr(XSETparam, '=\zs.*')

        " TODO can not input '\\n'
        let val = substitute(val, '\\n', "\n", 'g')

    endif

    return [ key, val, start ]

endfunction "}}}

" XXX
fun! s:XPTbufferScopeSet( str )
    let [ key, value, start ] = s:getXSETkeyAndValue( [ 'XSET ' . a:str ], 0 )
    let [ keyname, keytype ] = s:getKeyType( key )

endfunction

fun! s:parseMultiLineValues(lines, start) "{{{
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

fun! s:getKeyType(rawKey) "{{{

    let keytype = matchstr(a:rawKey, '\V'.s:nonEscaped.'|\zs\.\{-}\$')
    if keytype == ""
        let keytype = matchstr(a:rawKey, '\V'.s:nonEscaped.'.\zs\.\{-}\$')
    endif

    let keyname = keytype == "" ? a:rawKey :  a:rawKey[ : - len(keytype) - 2 ]
    let keyname = substitute(keyname, '\V\\\(\[.|\\]\)', '\1', 'g')

    return [ keyname, keytype ]

endfunction "}}}

fun! s:handleXSETcommand(setting, keyname, keytype, value) "{{{

    if a:keyname ==# 'ComeFirst'
        let a:setting.comeFirst = s:splitWith( a:value, ' ' )

    elseif a:keyname ==# 'ComeLast'
        let a:setting.comeLast = s:splitWith( a:value, ' ' )

    elseif a:keyname ==# 'PostQuoter'
        let a:setting.postQuoter = a:value

    elseif a:keytype == "" || a:keytype ==# 'def'
        let a:setting.defaultValues[a:keyname] = a:value

    elseif a:keytype ==# 'post'
        let a:setting.postFilters[a:keyname] = a:value

    else
        throw "unknown key name or type:" . a:keyname . ' ' . a:keytype

    endif

endfunction "}}}

fun! s:addCursorToComeLast(setting) "{{{
  let comeLast = copy( a:setting.comeLast )

  let cursorItem = filter( comeLast, 'v:val == "cursor"' )
  call s:log.Debug( 'has cursor item?:' . string( cursorItem ) )

  if cursorItem == []
    call add( a:setting.comeLast, 'cursor' )
  endif

  call s:log.Debug( 'has cursor item?:' . string( a:setting.comeLast ) )

endfunction "}}}

fun! s:splitWith( str, char ) "{{{
  let s = split( a:str, '\V' . s:nonEscaped . a:char, 1 )
  return s
endfunction "}}}





" vim: set sw=4 sts=4 :
