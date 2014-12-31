let s:oldcpo = &cpo
set cpo-=< cpo+=B

fun! s:TestSetLoaded( t ) "{{{

    let k = 'autoload/xpt/ut/helper/loadonce.vim'

    exec 'runtime' k
    call a:t.Eq( 1, g:xptemplate_loaded[k], "should have been loaded: " . k )
    call a:t.Eq( 1, g:xptemplate_unittest_once_value, 'autoload value init' )

    let g:xptemplate_unittest_once_value = 0

    exec 'runtime' k
    call a:t.Eq( 0, g:xptemplate_unittest_once_value, 'autoload value should not initiated again' )

    call remove(g:xptemplate_loaded, k)
    unlet g:xptemplate_unittest_once_value

endfunction "}}}

fun! s:TestRelativePath( t ) "{{{

    let old = &runtimepath

    let fn = fnamemodify( ".", ":p" ) . 'a'
    let &runtimepath .= ",."

    call xpt#once#SetAndGetLoaded( fn )
    call a:t.Eq( 1, g:xptemplate_loaded[ 'a' ], 'a is loaded' )

    let &runtimepath = old

endfunction "}}}

fun! s:TestUnnormalized( t ) "{{{

    let old = &runtimepath

    let fn = '/x//b/aa/bb/../y.z'
    let &runtimepath .= ",/x//b/c/d/../..///"

    call xpt#once#SetAndGetLoaded( fn )
    call a:t.Eq( 1, g:xptemplate_loaded[ 'aa/y.z' ], 'aa/y.z is loaded' )

    let &runtimepath = old

endfunction "}}}

exec xpt#unittest#run

let &cpo = s:oldcpo
