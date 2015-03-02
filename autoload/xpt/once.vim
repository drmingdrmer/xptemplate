let xpt#once#init = 'if xpt#once#SetAndGetLoaded(expand("<sfile>")) | finish | endif'

fun! xpt#once#SetAndGetLoaded( fn ) "{{{

    if ! exists('g:xptemplate_loaded')
        let g:xptemplate_loaded = {}
    endif

    let fn = fnamemodify( a:fn, ':p' )
    let fn = s:Norm(fn)

    for p in split( &runtimepath, ',' )

        let p = fnamemodify( p, ':p' )
        let p = s:Norm(p) . '/'

        let pref = fn[ 0 : len(p) - 1 ]

        if pref == p

            let relpath = fn[ len(pref) : ]

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

fun! s:Norm(path) "{{{
    " trailing slash
    let path = substitute( a:path, '\V/\*\$', '', 'g' )

    " multi slash
    let path = substitute( path, '\V//\*', '/', 'g' )

    while 1
        " remove ref to parent
        let p0 = path
        let path = substitute( path, '\V/\[^/]\+/..', '', 'g' )
        if p0 == path
            break
        endif
    endwhile

    return path
endfunction "}}}

exec xpt#once#init
