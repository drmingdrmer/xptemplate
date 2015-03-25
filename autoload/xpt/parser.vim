exec xpt#once#init

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


let s:oldcpo = &cpo
set cpo-=< cpo+=B

let s:log = xpt#debug#Logger( 'warn' )
" let s:log = xpt#debug#Logger( 'debug' )


exe XPT#importConst


" TODO warning of deprecated keys.

" Add each key a dot to avoid empty string as dictionary key.
let s:KEYTYPE_MAP = {
      \ '.'         : 'onfocus',
      \ '.def'      : 'onfocus',
      \ '.ontype'   : 'live',
      \ '.onchange' : 'live',
      \ }

let s:KEYTYPE_TO_DICT = {
      \ 'pre'     : 'preValues',
      \ 'live'    : 'liveFilters',
      \ 'onfocus' : 'onfocusFilters',
      \}


fun s:CompileSnippetFile( fn ) "{{{
    if a:fn =~ '\V.xpt.vimc\$' || !filereadable( a:fn )
        return
    endif

    let lines = readfile( a:fn )
    let lines = xpt#parser#Compact( lines )
    let lines = xpt#parser#CompileCompacted( lines )

    call writefile( lines, a:fn . 'c' )

endfunction "}}}

fun! xpt#parser#Compile( fn ) "{{{

    let compiledFn = a:fn . 'c'
    let ctime = getftime( a:fn )

    if !filereadable( compiledFn ) || getftime( compiledFn ) < ctime
          \ || g:xptemplate_always_compile

        call s:CompileSnippetFile( a:fn )

        call s:log.Debug( 'Compiled file has written to: ' . string( compiledFn ) )
    else
        call s:log.Debug( 'No need to Compile: ' . string( compiledFn ) )

    endif

endfunction "}}}

fun! xpt#parser#Compact( lines ) "{{{

    let compacted = []

    let iSnipPart = match( a:lines, '\V\^XPT\s' )
    if iSnipPart < 0
        let iSnipPart = len( a:lines )
    endif


    let [ i, len ] = [ 0 - 1, iSnipPart - 1 ]
    while i < len | let i += 1
        let l = a:lines[ i ]
        if l != '' && l !~ '\v^"[^"]*$'
            call add( compacted, l )
        endif
    endwhile


    let [s, e, lastNonblank] = [-1, -1, 100000]

    let [ i, len ] = [ iSnipPart - 1, len( a:lines ) - 1 ]
    while i < len | let i += 1
        let l = a:lines[ i ]

        if l == '' || l =~ '\v^"[^"]*$'
            let lastNonblank = min([lastNonblank, i - 1])
            continue
        endif


        if l =~# '\V\^..XPT\>'

            if s == -1
                let [s, e, lastNonblank] = [-1, -1, 100000]
                continue

            else

                let compacted += a:lines[ s : i - 1 ]
                let [s, e, lastNonblank] = [-1, -1, 100000]

            endif

        elseif l =~# '\V\^XPT\>'

            if s == -1
                let [ s, lastNonblank ] = [ i, i ]
            else
                " template with no end
                let e = min([i - 1, lastNonblank])
                let compacted += a:lines[ s : e ]
                let [s, e, lastNonblank] = [i, -1, 100000]
            endif

        else
            let lastNonblank = i
        endif

    endwhile

    if s != -1
        let compacted += a:lines[ s : min([lastNonblank, i]) ]
    endif

    return compacted
endfunction "}}}

fun! xpt#parser#CompileCompacted( lines ) "{{{

    let rst = []
    let lines = a:lines

    let iSnipPart = match( lines, '\V\^XPT\s' )

    if iSnipPart < 0
        return lines
    endif

    if iSnipPart > 0
        let rst += lines[ : iSnipPart - 1 ]
        let lines = lines[ iSnipPart : ]
    endif


    let [i, len] = [0, len(lines)]

    call xpt#indent#IndentToTab( lines )

    " parse lines
    " start end and blank start
    let s = i
    while i < len-1 | let i += 1

        let v = lines[i]

        if v =~# '\V\^XPT\>'

            " template with no end

            let ll = xpt#parser#CompileSnippet( lines[ s : i - 1 ] )
            let rst += [ ll ]

            let s = i

        elseif v =~# '\V\^\\XPT'
            let lines[i] = v[ 1 : ]
        endif

    endwhile

    if i >= s
        let ll = xpt#parser#CompileSnippet( lines[ s : i ] )
        let rst += [ ll ]
    endif

    return rst

endfunction "}}}

fun! xpt#parser#CompileSnippet( lines ) "{{{

    let lines = a:lines

    let snippetLines = []


    let setting = xpt#st#New()


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

            let [ key, val, start ] = s:GetXSETkeyAndValue( lines, start )
            if key == ''
                let start += 1
                continue
            endif
            call s:log.Log("got value, start=".start)

            let [ keyname, keytype ] = xpt#parser#GetKeyType( key )
            call s:log.Log("parse XSET:" . keyname . "|" . keytype . '=' . val)

            call s:HandleXSETcommand( setting, command, [ keyname, keytype, val ] )

            " TODO can not input \XSET
        elseif lines[start] =~# '^\\XSET' " escaped XSET or XSETm
            let snippetLines += [ lines[ start ][1:] ]

        else
            call add( snippetLines, lines[ start ] )

        endif

        let start += 1
    endwhile


    call s:log.Log("start:".start)
    call s:log.Log("to parse tmpl : snippetName=" . snippetName)

    call xpt#st#Simplify( setting )

    call s:log.Log("tmpl setting:".string(setting))

    if has_key( setting, 'alias' )
        " call XPTemplateAlias( snippetName, setting.alias, setting )
        return printf( 'call XPTemplateAlias(%s,%s,%s)',
              \ string( snippetName ), string( setting.alias ), string( setting ) )
    else
        " call XPTdefineSnippet(snippetName, setting, snippetLines)
        " return printf( 'call xpt#snip#DefExt(%s,%s,%s)',
        "       \ string( snippetName ), string( setting ), string( snippetLines ) )
        return printf( 'call XPTdefineSnippet(%s,%s,%s)',
              \ string( snippetName ), string( setting ), string( snippetLines ) )
    endif

endfunction "}}}


fun! xpt#parser#Include(...) "{{{

    let scope = b:xptemplateData.snipFileScope

    let scope.inheritFT = 1

    for v in a:000
        if type(v) == type([])

            for s in v
                call xpt#parser#Include(s)
            endfor

        elseif type(v) == type('')

            if xpt#ftsc#IsSnippetLoaded( b:xptemplateData.filetypes[ scope.filetype ], v )
                continue
            endif

            call xpt#snipf#Push()
            exe 'runtime! ftplugin/' . v . '.xpt.vim'
            call xpt#parser#LoadFTSnippets(v)
            call xpt#snipf#Pop()

        endif
    endfor
endfunction "}}}

fun! xpt#parser#Embed(...) "{{{

    let scope = b:xptemplateData.snipFileScope

    let scope.inheritFT = 0

    for v in a:000
        if type(v) == type([])

            for s in v
                call xpt#parser#Embed(s)
            endfor

        elseif type(v) == type('')

            call xpt#snipf#Push()
            exe 'runtime! ftplugin/' . v . '.xpt.vim'
            call xpt#parser#LoadFTSnippets(v)
            call xpt#snipf#Pop()

        endif
    endfor
endfunction "}}}

fun! xpt#parser#SetVar( nameSpaceValue ) "{{{
    

    let x = b:xptemplateData
    let ftScope = x.filetypes[ x.snipFileScope.filetype ]

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

fun! xpt#parser#SnipSet( dictNameValue ) "{{{
    let x = b:xptemplateData
    let snipScope = x.snipFileScope

    let [ dict, nameValue ] = split( a:dictNameValue, '\V.', 1 )
    let name = matchstr( nameValue, '^.\{-}\ze=' )
    let value = nameValue[ len( name ) + 1 :  ]

    call s:log.Log( 'set snipScope:' . string( [ dict, name, value ] ) )
    let snipScope[ dict ][ name ] = value

endfunction "}}}



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
        "
        " Unless it is a pseudo filename, which is for loading "_common"(or
        " anything independent ) snippet into unsupported filetype.


        if filename =~ '\V\<pseudo\>/'
            return ftFolder
        endif


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

fun! XPTDoSnippetFileInit( filename, ... ) "{{{

    " This function is called before 'BufEnter' event which
    " initialize XPTemplate

    if !exists("b:xptemplateData")
        call XPTemplateInit()
    endif

    call s:log.Debug( 'XPTDoSnippetFileInit is called' )

    let x = b:xptemplateData
    let filetypes = x.filetypes

    let snipScope = xpt#snipf#New( a:filename )
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


    for pair in a:000

        let kv = split( pair, '=', 1 )

        let key = kv[ 0 ]
        let val = join( kv[ 1 : ], '=' )

        call s:log.Log( "init:key=" . key . ' val=' . val )

        if key =~ 'prio\%[rity]'
            call XPTemplatePriority(val)

        elseif key =~ 'mark'
            call XPTemplateMark( val[ 0 : 0 ], val[ 1 : 1 ] )

        endif

    endfor

    return 'doit'

endfunction "}}}

fun! xpt#parser#SnippetFileInit( filename, ... ) "{{{

    call s:log.Debug( 'xpt#parser#SnippetFileInit is called. filename=' . string( a:filename ) )

    if !filereadable( a:filename )
        " Just init the pseudo snippet file.
        " In most of these cases, a pseudo snippet file is used to initialize
        " a context for inclusion, etc.
        return call( function( 'XPTDoSnippetFileInit' ), [ a:filename ] + a:000 )
    endif

    if a:filename =~ '\V.xpt.vim\$'

        call s:log.Debug( 'original file, to compile it' )

        call xpt#parser#Compile( a:filename )
        exe 'so' a:filename . 'c'

        return 'finish'

    else

        call s:log.Debug( 'Compiled file: ' . string( a:filename ) )

        return call( function( 'XPTDoSnippetFileInit' ), [ a:filename ] + a:000 )

    endif

endfunction "}}}



fun! xpt#parser#LoadSnippets() "{{{
    let fts = split( &filetype, '\V.', 1 )
    call filter( fts, 'v:val!=""' )

    for ft in fts
        " call xpt#parser#LoadFtDetectors( ft )
        call xpt#parser#LoadFTSnippets( ft )
    endfor

endfunction "}}}

fun! s:RTP() "{{{
    let rtps = split( &runtimepath, ',' )
    call filter( rtps, 'v:val!=""' )

    let rtps += [ g:XPT_PATH . '/xptsnippets',
          \       g:XPT_PATH . '/personal' ]

    let rtpath = join( rtps, ',' )
    return rtpath
endfunction "}}}

fun! xpt#parser#LoadFtDetectors( ft ) "{{{
    let namePattern = a:ft =~ '/' ? a:ft : a:ft . '/*'
    let rtpath = s:RTP()

    let ftdetectfiles = split( globpath( rtpath, 'ftplugin/' . namePattern . '.ftdetect.vim' ), "\n" )
    for fn in ftdetectfiles
        exe 'so' fn
    endfor

endfunction "}}}

fun! xpt#parser#LoadFTSnippets( ft ) "{{{

    let namePattern = a:ft =~ '/' ? a:ft : a:ft . '/*'
    let rtpath = s:RTP()


    let ftdetectfiles = split( globpath( rtpath, 'ftplugin/' . namePattern . '.ftdetect.vim' ), "\n" )
    for fn in ftdetectfiles
        exe 'so' fn
    endfor


    let snipfiles = split( globpath( rtpath, 'ftplugin/' . namePattern . '.xpt.vim' ), "\n" )
    for fn in snipfiles

        let compiled = fn . 'c'

        if !filereadable( compiled ) || getftime( compiled ) < getftime( fn )
              \ || g:xptemplate_always_compile

            call xpt#parser#Compile( fn )
            exe 'so' compiled

        endif

    endfor
endfunction "}}}

fun! xpt#parser#GetKeyType( rawKey ) "{{{

    let keytype = matchstr(a:rawKey, '\V'.s:nonEscaped.'|\zs\.\{-}\$')
    if keytype == ""
        let keytype = matchstr(a:rawKey, '\V'.s:nonEscaped.'.\zs\.\{-}\$')
    endif

    let keyname = keytype == "" ? a:rawKey :  a:rawKey[ 0 : - len(keytype) - 2 ]
    let keyname = substitute(keyname, '\V\\\(\[.|\\]\)', '\1', 'g')

    return [ keyname, keytype ]

endfunction "}}}




let s:KEY_NAME = 0
let s:KEY_TYPE = 1
let s:VALUE    = 2

let s:stHandler = {}

fun! s:stHandler.ComeFirst( setting, cmdArgs ) "{{{
    let a:setting.comeFirst = xpt#util#SplitWith( a:cmdArgs[ s:VALUE ], ' ' )
endfunction "}}}

fun! s:stHandler.ComeLast( setting, cmdArgs ) "{{{
    let a:setting.comeLast = xpt#util#SplitWith( a:cmdArgs[ s:VALUE ], ' ' )
endfunction "}}}

fun! s:stHandler.postQuoter( setting, cmdArgs ) "{{{
    let pq = split( a:cmdArgs[ s:VALUE ], ',' )
    let a:setting.postQuoter = { 'start' : pq[0], 'end' : pq[1] }
endfunction "}}}

let s:stHandler.PostQuoter = s:stHandler.postQuoter



let s:keytypeHandler = {}

fun! s:keytypeHandler.repl( setting, cmdArgs ) "{{{
    let a:setting.replacements[ a:cmdArgs[ s:KEY_NAME ] ] = a:cmdArgs[ s:VALUE ]
endfunction "}}}

fun! s:keytypeHandler.map( setting, cmdArgs ) "{{{

    let [ kn, kt, val ] = a:cmdArgs
    let mp = a:setting.mappings


    if !has_key( mp, kn )
        let mp[ kn ] = { 'saver' : xpt#msvr#New( 1 ), 'keys' : {} }
    endif


    let key = matchstr( val, '\V\^\S\+\ze\s' )
    let mapping = matchstr( val, '\V\s\+\zs\.\*' )


    call xpt#msvr#Add( mp[ kn ].saver, 'i', key )

    let mp[ kn ].keys[ key ] = xpt#flt#NewSimple( 0, mapping )

endfunction "}}}

fun! s:keytypeHandler.post( setting, cmdArgs ) "{{{

    let [ kn, kt, val ] = a:cmdArgs

    " TODO not good, use another keytype to define 'buildIfNoChange' post filter
    let val = xpt#ph#AlterFilterByPHName( kn, val )

    let a:setting.postFilters[ kn ] = xpt#flt#NewSimple( 0, val )

endfunction "}}}


fun! s:HandleXSETcommand( setting, command, cmdArgs ) "{{{
    " In the statement as below:
    "    XSET phName|post=UpperCase( V() )
    "
    " 'XSET' is command
    " 'phName' is keyname
    " 'post' is kt
    " 'UpperCase( V() )' is value

    let [ kn, kt, val ] = a:cmdArgs

    let kt = get( s:KEYTYPE_MAP, '.' . kt, kt )


    let fcon = {}
    if has_key( s:stHandler, kn )
        let fcon.f = s:stHandler[ kn ]
        call fcon.f( a:setting, [ kn, kt, val ] )

    elseif has_key( s:KEYTYPE_TO_DICT, kt )
        let dicName = s:KEYTYPE_TO_DICT[ kt ]
        let a:setting[ dicName ][ kn ] = xpt#flt#NewSimple( 0, val )

    elseif kn =~ '\V\^$'
        let a:setting.variables[ kn ] = val

    elseif has_key( s:keytypeHandler, kt )
        let fcon.f = s:keytypeHandler[ kt ]
        call fcon.f( a:setting, [ kn, kt, val ] )

    else
        throw "unknown key name or type:" . kn . ' ' . kt

    endif

endfunction "}}}

fun! s:GetXSETkeyAndValue(lines, start) "{{{
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

let &cpo = s:oldcpo
