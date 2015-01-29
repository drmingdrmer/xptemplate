if exists( "g:__AL_XPT_EVALSUPPORT_f67523jhrk" ) && g:__AL_XPT_EVALSUPPORT_f67523jhrk >= 1
    finish
endif
let g:__AL_XPT_EVALSUPPORT_f67523jhrk = 1

let s:oldcpo = &cpo
set cpo-=< cpo+=B

let s:f = xpt#snipfunction#funcs

fun! s:f.GetVar( name )

    if a:name =~# '\V\^$_x'
        let n = a:name[ 1 : ]
        return self.Call( n, [] )
    endif

    let closures = self._ctx.closures
    let i = len(closures)
    while i > 0
        let i = i - 1
        let c = closures[ i ]

        let v = get( c, a:name, 0 )
        if v isnot 0
            return v
        endif
    endwhile

    return ''
endfunction

fun! s:f.Call( name, args )

    let F = get(self, a:name, 0)

    if type(F) == type(function('tr'))
        return call(F, a:args, self)
    else
        return call(function(a:name), a:args)
    endif
endfunction

let &cpo = s:oldcpo
