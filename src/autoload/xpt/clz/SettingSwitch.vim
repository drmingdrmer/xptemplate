finish
if exists( "g:__SETTINGSWITCH_VIM__" ) && g:__SETTINGSWITCH_VIM__ >= XPT#ver
    finish
endif
let g:__SETTINGSWITCH_VIM__ = XPT#ver


let s:oldcpo = &cpo
set cpo-=< cpo+=B

runtime plugin/debug.vim

let s:log = xpt#debug#Logger( 'warn' )
let s:log = xpt#debug#Logger( 'debug' )

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
        return
    endif

    call s:log.Debug( 'SettingSwitched' )

    for [ key, value ] in self.settings

        call insert( self.saved, [ key, eval( key ) ] )

        if type( value ) == type( '' )
            exe 'let ' key '=' string( value )
        elseif type( value ) == type( {} )
            if has_key( value, 'exe' )
                exe value.exe
            endif
        endif

        " Annoying bug variable can not be assigned with different type
        unlet value

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

" fun! s:GetStack() dict "{{{
"     if self.isLocal
"         if !exists( 'b:__map_saver_stack__' )
"             let b:__map_saver_stack__ = []
"         endif
"         return b:__map_saver_stack__
"     else
"         return s:stack
"     endif
" endfunction "}}}

exe XPT#let_sid
let g:SettingSwitch = xpt#util#class( s:sid, {} )

let &cpo = s:oldcpo
