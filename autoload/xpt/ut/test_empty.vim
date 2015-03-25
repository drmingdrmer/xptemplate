let s:oldcpo = &cpo
set cpo-=< cpo+=B

fun! s:TestNothing( t ) "{{{
    call a:t.Eq( 'yes', 'yes', 'yes is yes' )
endfunction "}}}

exec xpt#unittest#run

let &cpo = s:oldcpo
