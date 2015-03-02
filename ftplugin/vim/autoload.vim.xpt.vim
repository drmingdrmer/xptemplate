if expand( "%:p:h" ) . '/' !~# '\V\[\\/]autoload\[\\/]'
    finish
endif

XPTemplate priority=lang-

let s:f = g:XPTfuncs()

fun! s:f.vim_autoload_pre()
    let path = expand( "%:p" )
    let path = substitute( path, '\V\\', '/', 'g' )
    let path = matchstr( path, '\V/autoload/\zs\.\+\ze.vim\$' )
    let path = substitute( path, '\V/', '#', 'g' )
    return path
endfunction



XPTinclude
      \ _common/common
      \ vim/vim

" TODO fix it
" XSET name|repl=vim_autoload_pre()#`name
XPT fun alias=_fun " fun! vim_autoload_pre()#**
XSET name=Build( '`' . vim_autoload_pre() . '#`n^' )


XPT ## " vim_autoload_pre\()#
`vim_autoload_pre()^#
