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


let s:log = xpt#debug#Logger( 'warn' )
" let s:log = xpt#debug#Logger( 'debug' )


fun! xpt#stsw#New()  "{{{
    return {
          \ 'settings' : [],
          \ 'saved'    : [],
          \}
endfunction "}}}

fun! xpt#stsw#Add( inst, key, value )  "{{{
    if a:inst.saved != []
        throw "settings are already saved and can not be added again"
    endif
    let a:inst.settings += [ [ a:key, a:value ] ]
endfunction "}}}

fun! xpt#stsw#AddList( inst, ... )  "{{{
    if a:inst.saved != []
        throw "settings are already saved and can not be added again"
    endif
    " let a:inst.settings += a:000
    for item in a:000
        " call xpt#stsw#Add( a:inst, item[0], item[1] )
        " let a:inst.settings += [ [ item[ 0 ], item[ 1 ] ] ]
        call add( a:inst.settings, [ item[ 0 ], item[ 1 ] ] )
    endfor

endfunction "}}}

fun! xpt#stsw#Switch( inst )  "{{{
    if a:inst.saved != []
        " throw "settings are already saved and can not be save again"
        return
    endif

    call s:log.Debug( 'SettingSwitched' )

    for [ key, value ] in a:inst.settings

        call insert( a:inst.saved, [ key, eval( key ) ] )

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

fun! xpt#stsw#Restore( inst )  "{{{
    if a:inst.saved == []
        return
    endif

    for setting in a:inst.saved
        exe 'let '. setting[0] . '=' . string( setting[1] )
    endfor

    let a:inst.saved = []

endfunction "}}}


let &cpo = s:oldcpo
