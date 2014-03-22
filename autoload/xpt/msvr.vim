" File Description {{{
" =============================================================================
" Map Saver.
" Saving and restoring key mappings.
"                                                  by drdr.xp
"                                                     drdr.xp@gmail.com
" Usage :
"
" =============================================================================
" }}}

if exists( "g:__AL_XPT_MSVR_VIM__" ) && g:__AL_XPT_MSVR_VIM__ >= XPT#ver
    finish
endif
let g:__AL_XPT_MSVR_VIM__ = XPT#ver


let s:oldcpo = &cpo
set cpo-=< cpo+=B



let s:log = xpt#debug#Logger( 'warn' )
" let s:log = xpt#debug#Logger( 'debug' )



snoremap <Plug>selectToInsert d<BS>
let g:globalStack = []


" Critical implementation!!
" Not sure whether it works well on any platform
"
" TODO Maybe using <script> mapping is better
fun! s:_GetAlighWidth() "{{{
    nmap <buffer> 1 2
    let line = xpt#util#getCmdOutput("silent nmap <buffer> 1")
    nunmap <buffer> 1

    let line = split(line, "\n")[0]

    return len(matchstr(line, '^n.*\ze2$'))
endfunction "}}}

let s:alignWidth = s:_GetAlighWidth()

delfunction s:_GetAlighWidth



fun! xpt#msvr#New( isLocal ) "{{{

    " \ 'stackName' : s:GetStack( a:isLocal ),
    return {
          \ 'keys'      : [],
          \ 'saved'     : [],
          \ }

endfunction "}}}

fun! xpt#msvr#Add( inst, mode, key ) "{{{
    if a:inst.saved != []
        throw "keys are already saved and can not be added"
    endif
    let a:inst.keys += [ [ a:mode, a:key ] ]
endfunction "}}}

fun! xpt#msvr#AddList( inst, ... ) "{{{
    if a:0 > 0 && type( a:1 ) == type( [] )
        let list = a:1
    else
        let list = a:000
    endif
    for item in list
        let [ mode, key ] = split( item, '^\w\zs_' )
        call xpt#msvr#Add( a:inst, mode, key )
    endfor

endfunction "}}}

fun! xpt#msvr#UnmapAll( inst ) "{{{
    if a:inst.saved == []
        throw "keys are not saved, can not unmap all"
    endif

    let localStr = '<buffer> '

    for [ mode, key ] in a:inst.keys
        exe 'silent! ' . mode . 'unmap ' . localStr . key
    endfor

endfunction "}}}

fun! xpt#msvr#Save( inst ) "{{{

    if a:inst.saved != []
        " throw "keys are already saved and can not be save again"
        return
    endif


    for [ mode, key ] in a:inst.keys
        call insert( a:inst.saved, xpt#msvr#MapInfo( key, mode ) )
    endfor

    let stack = s:GetStack()
    call add( stack, a:inst )

    call s:log.Debug( "Saved stack:" . s:String( stack ) )

endfunction "}}}

fun! xpt#msvr#Literalize( inst, ... ) "{{{
    if a:inst.saved == []
        throw "keys are not saved yet, can not literalize"
    endif

    let option = a:0 == 1 ? a:1 : {}

    let insertAsSelect = get(option, 'insertAsSelect', 0)

    let localStr = '<buffer> '
    let nowait = v:version >= 704 ? '<nowait>' : ''

    for [ mode, key ] in a:inst.keys
        if mode == 's' && insertAsSelect
            " NOTE: do not use nore-map to enable original insert-mode key mapping
            exe 'silent! ' . mode . 'map ' . nowait . localStr . key . ' <Plug>selectToInsert' . key
        else
            exe 'silent! ' . mode . 'noremap ' . nowait . localStr . key . ' ' . key
        endif
    endfor

endfunction "}}}

fun! xpt#msvr#Restore( inst ) "{{{

    if a:inst.saved == []
        return
    endif


    let stack = s:GetStack()
    if empty( stack ) || stack[ -1 ] != a:inst
        throw "MapSaver: Incorrect Restore of MapSaver:" . s:String( stack )
              \ . ' but ' . string( a:inst.keys )
    endif

    for info in a:inst.saved
        call s:MappingPop( info )
    endfor

    let a:inst.saved = []

    call remove( stack, -1 )

    call s:log.Debug( "Restored stack:" . s:String( stack ) )

endfunction "}}}

fun! s:GetStack() "{{{
    if !exists( 'b:__map_saver_stack__' )
        let b:__map_saver_stack__ = []
    endif
    return b:__map_saver_stack__
endfunction "}}}


if v:version >= 704
" from vim7.4, maparg() returns full inforamtion of mapping. no more trick
" is required.
fun! xpt#msvr#MapInfo( key, mode ) "{{{
    let arg = maparg( a:key, a:mode, 0, 1 )
    if arg == {} || arg.buffer == 0
        return { 'mode'  : a:mode,
              \  'key'   : a:key,
              \  'nore'  : '',
              \  'isexpr': '',
              \  'isbuf' : ' <buffer> ',
              \  'cont'  : ''}
    endif

    " maparg() does not convert sid
    let rhs = substitute( arg.rhs, '\V\C<SID>', '<SNR>' . arg.sid . '_', 'g' )

    return { 'mode'  : a:mode,
          \  'key'   : a:key,
          \  'nore'  : arg.noremap ? 'nore' : '',
          \  'isexpr': arg.expr ? '<expr>' : '',
          \  'isbuf' : arg.buffer ? '<buffer>' : '',
          \  'cont'  : rhs }

endfunction "}}}

else

fun! xpt#msvr#MapInfo( key, mode ) "{{{
    let line = s:GetMappingLine(a:key, a:mode)
    if line == ''
        " unmap info
        return { 'mode'  : a:mode,
              \  'key'   : a:key,
              \  'nore'  : '',
              \  'isexpr': '',
              \  'isbuf' : ' <buffer> ',
              \  'cont'  : ''}
    endif

    let item = line[0:1] " the first 2 characters

    " NOTE: guess it, no way to figure out whether a key is mapped with <expr> or not
    let isexpr = ''
    if a:mode == 'i' && line[2:] =~ '\V\w(\.\*)' && line[2:] !~? '\V<c-r>'
          \ || a:mode != 'i' && line[2:] =~ '\V\w(\.\*)' 
          \ || a:mode == 'i' && line[2:] =~ '\V\.\*?\.\*:\.\*'
        let isexpr = '<expr> '
    endif

    let info =  {'mode' : a:mode,
          \'key'   : a:key,
          \'nore'  : item =~ '*' ? 'nore' : '',
          \'isexpr': isexpr,
          \'isbuf' : ' <buffer> ',
          \'cont'  : line[2:]}

    call s:log.Debug( "map info=" . string( info ) )
    return info

endfunction "}}}

endif

fun! xpt#msvr#MapCommand( info ) "{{{

    let exprMap = a:info.isexpr

    if a:info.cont == ''
        let cmd = "silent! " . a:info.mode . 'unmap <silent> ' . a:info.isbuf . a:info.key
    else
        let cmd = "silent! " . a:info.mode . a:info.nore . 'map <silent> '. exprMap . a:info.isbuf . a:info.key . ' ' . a:info.cont
    endif

    return cmd

endfunction "}}}

fun! s:GetMappingLine(key, mode) "{{{
    let mcmd = "silent ".a:mode."map <buffer> ".a:key

    " get fixed mapping
    let str = xpt#util#getCmdOutput(mcmd)

    let lines = split(str, "\n")


    " Find out the line representing the expect mapping. Because mappings with
    " the same prefix may all returned.
    "
    " *  norepeat
    " &@ script or buffer local
    "
    " The :map command format: if a mapped key length is less than s:alignWidth,
    " the right hand part is aligned. Or 1 space separates the left part and the
    " right part
    let localmark = '@'
    let ptn = '\V\c' . a:mode . '  ' . escape(a:key, '\') . '\s\{-}' . '\zs\[* ]'
          \. localmark . '\%>' . s:alignWidth . 'c\S\.\{-}\$'


    for line in lines
        if line =~? ptn
            return matchstr(line, ptn)
        endif
    endfor

    return ""

endfunction "}}}

fun! s:MappingPop( info ) "{{{

    call s:log.Debug("map a:info:".string(a:info))

    Assert !empty( a:info )

    let cmd = xpt#msvr#MapCommand( a:info )

    try
        exe cmd
    catch /.*/
    endtry

endfunction "}}}

fun! s:String( stack ) "{{{
    let rst = ''
    for ms in a:stack
        let rst .= " **** " . string( ms.keys )
    endfor

    return rst
endfunction "}}}



let &cpo = s:oldcpo
