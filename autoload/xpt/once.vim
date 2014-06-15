let xpt#once#init = 'if xpt#once#SetAndGetLoaded(expand("<sfile>")) | finish | endif'

fun! xpt#once#SetAndGetLoaded( fn ) "{{{

    if ! exists('g:xptemplate_loaded')
        let g:xptemplate_loaded = {}
    endif

    for p in split( &runtimepath, ',' )

        let p = expand( p ) . '/'

        let pref = a:fn[ 0 : len(p) - 1 ]

        if pref == p

            let relpath = a:fn[ len(pref) : ]

            if has_key(g:xptemplate_loaded, relpath)
                return 1
            else
                let g:xptemplate_loaded[relpath] = 1
                return 0
            endif
        endif
    endfor

    echoerr a:fn . ' not found in any one of &runtimepath'
    return 0

endfunction "}}}

exec xpt#once#init
