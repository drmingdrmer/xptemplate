" File Description {{{
" =============================================================================
" Setting Switcher
"                                                  by drdr.xp
"                                                     drdr.xp@gmail.com
" Usage :
"
" =============================================================================
" }}}
if exists( "g:__AL_XPT_STSW_VIM__" ) && g:__AL_XPT_STSW_VIM__ >= XPT#ver
    finish
endif
let g:__AL_XPT_STSW_VIM__ = XPT#ver


let s:oldcpo = &cpo
set cpo-=< cpo+=B

runtime plugin/debug.vim

let s:log = xpt#debug#Logger( 'warn' )
let s:log = xpt#debug#Logger( 'debug' )

fun! xpt#stsw#New()  "{{{
    let self.settings = []
    let self.saved = []
endfunction "}}}

fun! xpt#stsw#Add( key, value )  "{{{
    if self.saved != []
        throw "settings are already saved and can not be added"
    endif
    let self.settings += [ [ a:key, a:value ] ]
endfunction "}}}

fun! xpt#stsw#AddList( ... )  "{{{
    for item in a:000
        call self.Add( item[0], item[1] )
    endfor

endfunction "}}}

fun! xpt#stsw#Switch()  "{{{
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




fun! xpt#stsw#Restore()  "{{{
    if self.saved == []
        return
    endif

    for setting in self.saved
        exe 'let '. setting[0] . '=' . string( setting[1] )
    endfor

    let self.saved = []

endfunction "}}}

let g:SettingSwitch = xpt#util#class( s:sid, {} )

let &cpo = s:oldcpo
