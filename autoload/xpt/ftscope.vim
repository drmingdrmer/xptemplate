" File Description {{{
" =============================================================================
" FileType Scope is an isolated context |Dictionary| which provides snippets
" for a particular filetype.
"
" The filetype it supports could be a sub-filetype like "xpt.vim".
"
" One |buffer| could have several filetype scopes assigning to it.
"
"
" TODO Not implemented: Different buffers should share a certain filetype
" scope instance.
"
"
"
"                                                  by drdr.xp
"                                                     drdr.xp@gmail.com
" Usage :
"
" =============================================================================
" }}}

if exists( "g:__AL_XPT_FTSCP_VIM__" ) && g:__AL_XPT_FTSCP_VIM__ >= XPT#ver
    finish
endif
let g:__AL_XPT_FTSCP_VIM__ = XPT#ver



let s:oldcpo = &cpo
set cpo-=< cpo+=B


fun! xpt#ftsc#New() "{{{

    " inst.extensionTable:
    "   Some snippet has extension pattern which defines what text can be an
    "   extension.
    "
    "   Extensions is a way to implement zencode-like snippet.
    "
    "   But extensions can be very few as there could be relatively very many
    "   snippets which share these few extensions.
    "
    "   Thus this dictionary represents a extension-to-snippet-name mapping.

    let inst = {
          \ 'filetype'        : '',
          \ 'allTemplates'    : {},
          \ 'funcs'           : { '$CURSOR_PH' : 'CURSOR' },
          \ 'inited'          : 0,
          \ 'varPriority'     : {},
          \ 'loadedSnipFiles' : {},
          \ 'extensionTable'  : {},
          \ 'snipPieces'      : [],
          \ }

    call xpt#snipfunc#Extend( inst.funcs )

    return inst

endfunction "}}}

fun! xpt#ftsc#Init( ftsc ) "{{{

    if a:ftsc.inited
        return
    endif


    let l = a:ftsc.funcs.GetVar( '$CL' )
    let m = a:ftsc.funcs.GetVar( '$CM' )


    if len( l ) <= len( m )
        let a:ftsc.funcs[ '$CM_OFFSET' ] = ''
        let a:ftsc.funcs[ '$CL_STRIP' ] = l
    else
        let a:ftsc.funcs[ '$CM_OFFSET' ] = repeat( ' ', len( l ) - len( m ) )
        let a:ftsc.funcs[ '$CL_STRIP' ] = l[ : -len( m ) -1 ]
    endif

    let a:ftsc.inited = 1

endfunction "}}}

fun! xpt#ftsc#IsSnippetLoaded( inst, filename ) "{{{

    return has_key( a:inst.loadedSnipFiles, a:filename )

endfunction "}}}

fun! xpt#ftsc#SetSnippetLoaded( inst, filename ) "{{{

    let a:inst.loadedSnipFiles[ a:filename ] = 1

    let fn = substitute(a:filename, '\\', '/', 'g')
    let shortname = matchstr(fn, '\Vftplugin\/\zs\[^/]\+\/\.\*\ze.xpt.vim')

    if shortname != ''
        let a:inst.loadedSnipFiles[shortname] = 1
    endif

endfunction "}}}

fun! xpt#ftsc#CheckAndSetSnippetLoaded( inst, filename ) "{{{

    let loaded = has_key( a:inst.loadedSnipFiles, a:filename )

    call xpt#ftsc#SetSnippetLoaded( a:inst, a:filename )

    return loaded

endfunction "}}}

fun! xpt#ftsc#PushPHPieces( ftsc, phs ) "{{{

    call add( a:ftsc.snipPieces, a:phs )

    return len( a:ftsc.snipPieces ) - 1

endfunction "}}}

fun! xpt#ftsc#GetPHPieces( ftsc, phsID ) "{{{

    return a:ftsc.snipPieces[ a:phsID ]

endfunction "}}}


let &cpo = s:oldcpo
