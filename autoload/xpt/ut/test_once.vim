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

exec xpt#unittest#run

let &cpo = s:oldcpo
