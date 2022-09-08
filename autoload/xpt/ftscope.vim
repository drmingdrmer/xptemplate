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


fun! xpt#ftscope#New() "{{{

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
          \ 'ftkeyword'       : { 'regexp' : '\w', 'list' : [] },
          \ 'funcs'           : { '$CURSOR_PH' : 'CURSOR' },
          \ 'inited'          : 0,
          \ 'varPriority'     : {},
          \ 'loadedSnipFiles' : {},
          \ 'extensionTable'  : {},
          \ 'snipPieces'      : [],
          \ }

    " call xpt#snipfunc#Extend( inst.funcs )

    return inst

endfunction "}}}

fun! xpt#ftscope#Init( ftscope ) "{{{

    if a:ftscope.inited
        return
    endif


    let l = a:ftscope.funcs.GetVar( '$CL' )
    let m = a:ftscope.funcs.GetVar( '$CM' )


    if len( l ) <= len( m )
        let a:ftscope.funcs[ '$CM_OFFSET' ] = ''
        let a:ftscope.funcs[ '$CL_STRIP' ] = l
    else
        let a:ftscope.funcs[ '$CM_OFFSET' ] = repeat( ' ', len( l ) - len( m ) )
        let a:ftscope.funcs[ '$CL_STRIP' ] = l[ : -len( m ) -1 ]
    endif

    let a:ftscope.inited = 1

endfunction "}}}

fun! xpt#ftscope#IsSnippetLoaded( inst, filename ) "{{{

    return has_key( a:inst.loadedSnipFiles, a:filename )

endfunction "}}}

fun! xpt#ftscope#SetSnippetLoaded( inst, filename ) "{{{

    let a:inst.loadedSnipFiles[ a:filename ] = 1

    let fn = substitute(a:filename, '\\', '/', 'g')
    let shortname = matchstr(fn, '\Vftplugin\/\zs\[^/]\+\/\.\*\ze.xpt.vim')

    if shortname != ''
        let a:inst.loadedSnipFiles[shortname] = 1
    endif

endfunction "}}}

fun! xpt#ftscope#CheckAndSetSnippetLoaded( inst, filename ) "{{{

    let loaded = has_key( a:inst.loadedSnipFiles, a:filename )

    call xpt#ftscope#SetSnippetLoaded( a:inst, a:filename )

    return loaded

endfunction "}}}

fun! xpt#ftscope#PushPHPieces( ftscope, phs ) "{{{

    call add( a:ftscope.snipPieces, a:phs )

    return len( a:ftscope.snipPieces ) - 1

endfunction "}}}

fun! xpt#ftscope#GetPHPieces( ftscope, phsID ) "{{{

    return a:ftscope.snipPieces[ a:phsID ]

endfunction "}}}


let &cpo = s:oldcpo
