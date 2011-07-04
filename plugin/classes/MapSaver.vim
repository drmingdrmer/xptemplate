if exists( "g:__MAPSAVER_VIM__" ) && g:__MAPSAVER_VIM__ >= XPT#ver
    finish
endif
let g:__MAPSAVER_VIM__ = XPT#ver


let s:oldcpo = &cpo
set cpo-=< cpo+=B



runtime plugin/debug.vim


let s:log = CreateLogger( 'warn' )
let s:log = CreateLogger( 'debug' )



snoremap <Plug>selectToInsert d<BS>

" Critical implementation!!
" Not sure whether it works well on any platform
"
" TODO Maybe use <script> mapping is better
fun! s:_GetAlighWidth() "{{{
    nmap <buffer> 1 2
    let line = XPT#getCmdOutput("silent nmap <buffer> 1")
    nunmap <buffer> 1

    let line = split(line, "\n")[0]

    return len(matchstr(line, '^n.*\ze2$'))
endfunction "}}}

let s:alignWidth = s:_GetAlighWidth()

delfunction s:_GetAlighWidth


let s:stack = []



fun! s:_GetMapLine(key, mode, isbuffer) "{{{
    let mcmd = "silent ".a:mode."map ".(a:isbuffer ? "<buffer> " : "").a:key

    " get fixed mapping
    let str = XPT#getCmdOutput(mcmd)

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
    let localmark = a:isbuffer ? '@' : ' '
    let ptn = '\V\c' . a:mode . '  ' . escape(a:key, '\') . '\s\{-}' . '\zs\[* ]' 
          \. localmark . '\%>' . s:alignWidth . 'c\S\.\{-}\$'


    for line in lines
        if line =~? ptn
            return matchstr(line, ptn)
        endif
    endfor

    return ""

endfunction "}}}

fun! MapSaver_GetMapInfo( key, mode, isbuffer ) "{{{
    let line = s:_GetMapLine(a:key, a:mode, a:isbuffer)
    if line == ''
        " unmap info
        return { 'mode'  : a:mode,
              \  'key'   : a:key,
              \  'nore'  : '',
              \  'isbuf' : a:isbuffer ? ' <buffer> ' : ' ',
              \  'cont'  : ''}
    endif

    let item = line[0:1] " the first 2 characters

    let info =  {'mode' : a:mode,
          \'key'   : a:key,
          \'nore'  : item =~ '*' ? 'nore' : '',
          \'isbuf' : a:isbuffer ? ' <buffer> ' : ' ',
          \'cont'  : line[2:]}

    call s:log.Debug( "map info=" . string( info ) )
    return info

endfunction "}}}

fun! s:_MapPop( info ) "{{{

    call s:log.Debug("map a:info:".string(a:info))

    Assert !empty( a:info )

    let cmd = MapSaverGetMapCommand( a:info )

    try
        exe cmd
    catch /.*/
    endtry
endfunction "}}}

" fun! s:EscapeMap( s ) "{{{
    " return substitute( a:s, '\V<', '\<lt>', 'g' )
" endfunction "}}}

fun! MapSaverGetMapCommand( info ) "{{{
    " NOTE: guess it, no way to figure out whether a key is mapped with <expr> or not
    let exprMap = ''
    if a:info.mode == 'i' && a:info.cont =~ '\V\w(\.\*)' && a:info.cont !~? '\V<c-r>'
          \ || a:info.mode != 'i' && a:info.cont =~ '\V\w(\.\*)' 
          \ || a:info.mode == 'i' && a:info.cont =~ '\V\.\*?\.\*:\.\*'
        let exprMap = '<expr> '
    endif


    if a:info.cont == ''
        let cmd = "silent! " . a:info.mode . 'unmap <silent> ' . a:info.isbuf . a:info.key 
    else
        let cmd = "silent! " . a:info.mode . a:info.nore . 'map <silent> '. exprMap . a:info.isbuf . a:info.key . ' ' . a:info.cont
    endif

    return cmd
    
endfunction "}}}



fun! s:String( stack ) "{{{
    let rst = ''    
    for ms in a:stack
        let rst .= " **** " . string( ms.keys )
    endfor

    return rst
endfunction "}}}


fun! s:New( isLocal ) dict "{{{
    let self.isLocal = !!a:isLocal
    let self.keys = []
    let self.saved = []
endfunction "}}}

fun! s:Add( mode, key ) dict "{{{
    if self.saved != []
        throw "keys are already saved and can not be added"
    endif
    let self.keys += [ [ a:mode, a:key ] ]
endfunction "}}}

fun! s:AddList( ... ) dict "{{{
    if a:0 > 0 && type( a:1 ) == type( [] )
        let list = a:1
    else
        let list = a:000
    endif
    for item in list
        let [ mode, key ] = split( item, '^\w\zs_' )
        call self.Add( mode, key )
    endfor

endfunction "}}}

fun! s:UnmapAll() dict "{{{
    if self.saved == []
        throw "keys are not saved, can not unmap all"
    endif

    let localStr = self.isLocal ? '<buffer> ' : ''

    for [ mode, key ] in self.keys
        exe 'silent! ' . mode . 'unmap ' . localStr . key
    endfor

endfunction "}}}

fun! s:Save() dict "{{{

    if self.saved != []
        " throw "keys are already saved and can not be save again"
        return
    endif


    for [ mode, key ] in self.keys
        call insert( self.saved, MapSaver_GetMapInfo( key, mode, self.isLocal ) )
    endfor

    let stack = self.GetStack()
    call add( stack, self )

    call s:log.Debug( "Saved stack:" . s:String( stack ) )

endfunction "}}}

fun! s:Literalize( ... ) dict "{{{
    if self.saved == []
        throw "keys are not saved yet, can not literalize"
    endif

    let option = a:0 == 1 ? a:1 : {}

    let insertAsSelect = get(option, 'insertAsSelect', 0)

    let localStr = self.isLocal ? '<buffer> ' : ''
    for [ mode, key ] in self.keys
        if mode == 's' && insertAsSelect
            " exe 'silent! ' . mode . 'noremap ' . localStr . key . ' d<BS><C-o>:call feedkeys(' . string(key) . ', "mt")<CR>'

            " NOTE: do not use nore-map to enable original insert-mode key mapping
            exe 'silent! ' . mode . 'map ' . localStr . key . ' <Plug>selectToInsert' . key
        else
            exe 'silent! ' . mode . 'noremap ' . localStr . key . ' ' . key
        endif
    endfor

endfunction "}}}

fun! s:Restore() dict "{{{
    if self.saved == []
        return
    endif


    let stack = self.GetStack()
    if empty( stack ) || stack[ -1 ] != self
        throw "MapSaver: Incorrect Restore of MapSaver:" . s:String( stack )
              \ . ' but ' . string( self.keys )
    endif

    for info in self.saved
        call s:_MapPop( info )
    endfor

    let self.saved = []

    call remove( stack, -1 )

    call s:log.Debug( "Restored stack:" . s:String( stack ) )

endfunction "}}}

fun! s:GetStack() dict "{{{
    if self.isLocal
        if !exists( 'b:__map_saver_stack__' )
            let b:__map_saver_stack__ = []
        endif
        return b:__map_saver_stack__
    else
        return s:stack
    endif
endfunction "}}}

exe XPT#let_sid
let g:MapSaver = XPT#class( s:sid, {} )

let &cpo = s:oldcpo
