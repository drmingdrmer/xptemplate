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

let &cpo = s:oldcpo
