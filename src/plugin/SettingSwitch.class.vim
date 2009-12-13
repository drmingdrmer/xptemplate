if exists("g:__SETTINGSAVER_CLASS_VIM__")
    finish
endif
let g:__SETTINGSAVER_CLASS_VIM__ = 1

let s:oldcpo = &cpo
set cpo-=< cpo+=B

runtime plugin/debug.vim

let s:log = CreateLogger( 'warn' )
let s:log = CreateLogger( 'debug' )

fun! s:New() dict "{{{
    let self.settings = []
    let self.saved = []
endfunction "}}}

fun! s:Add( key, value ) dict "{{{
    if self.saved != []
        throw "settings are already saved and can not be added"
    endif
    let self.settings += [ [ a:key, a:value ] ]
endfunction "}}}

fun! s:AddList( ... ) dict "{{{
    for item in a:000
        call self.Add( item[0], item[1] )
    endfor

endfunction "}}}

fun! s:Switch() dict "{{{
    if self.saved != []
        " throw "settings are already saved and can not be save again"
    endif
    call s:log.Debug( 'SettingSwitched' )
    for [ key, value ] in self.settings
        call insert( self.saved, [ key, eval( key ) ] )
        exe 'let ' . key . '=' . string( value )
    endfor
endfunction "}}}

fun! s:Restore() dict "{{{
    if self.saved == []
        return
    endif

    for setting in self.saved
        exe 'let '. setting[0] . '=' . string( setting[1] )
    endfor

    let self.saved = []

endfunction "}}}


exe XPT#let_sid
let g:SettingSwitch = XPT#class( s:sid, {} )

let &cpo = s:oldcpo
