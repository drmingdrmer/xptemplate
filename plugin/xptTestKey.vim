if exists( "g:__XPTTESTKEY_VIM__" ) && g:__XPTTESTKEY_VIM__ >= 2
    finish
endif
let g:__XPTTESTKEY_VIM__ = 2



let s:actions = []

let s:conf =      g:xptemplate_key
      \ . ':' . g:xptemplate_key_force_pum
      \ . ':' . g:xptemplate_minimal_prefix
      \ . ':' . g:xptemplate_pum_tab_nav
      \ . ':' . g:xptemplate_fallback
      \ . ':' . g:xptemplate_key_pum_only
      \ . ':' . exists( 'g:SuperTabMappingForward' )

" remove two single quotes
let s:conf = tolower( s:conf )


let s:go = "\<C-r>=XPTtestKeyGo()\<cr>"

let s:suiteSet = {
      \  '<c-\>:<tab>:1:1:<tab>:<c-r><tab>:0' : [
      \      [ [ "\<Tab>" ], '\V\^\s\+\$', 0 ], 
      \      [ [ "p\<Tab>" ], '\Vp\$', 1 ], 
      \      [ [ "p\<Tab>", "\<CR>" ], '\Vpass\$', 0 ], 
      \      [ [ "p\<Tab>", "\<C-n>\<CR>" ], '\Vpass\$', 0 ], 
      \      [ [ "p\<Tab>", "\<C-n>\<C-n>" . s:go ], '\Vpython\$', 1 ], 
      \      [ [ "P\<Tab>", "\<C-n>\<CR>" ], '\V\w\+\$', 0 ], 
      \      [ [ "foo\<Tab>" ], '\Vfoo\s\+\$', 0 ], 
      \      [ [ "\<C-r>\<Tab>" ], '\V\^\$', 1 ], 
      \      [ [ "is if i\<Tab>" ], '\Vi\$', 1 ], 
      \      [ [ "is if i\<Tab>", "\<C-c>a\<C-n>" . s:go ], '\Vi\$', 1 ], 
      \      [ [ "is if i\<Tab>", "\<C-c>a\<C-n>\<Tab>" ], '\Vi\s\+\$', 0, 'reenter insert mode, <C-n> pum ' ], 
      \  ],
      \  '<c-\>:<tab>:1:1:<tab>:<c-r><tab>:1' : [
      \      [ [ "\<Tab>" ], '\V\^\s\+\$', 0 ], 
      \      [ [ "p\<Tab>" ], '\Vp\$', 1 ], 
      \      [ [ "p\<Tab>", "\<CR>" ], '\Vpass\$', 0 ], 
      \      [ [ "p\<Tab>", "\<C-n>\<CR>" ], '\Vpass\$', 0 ], 
      \      [ [ "p\<Tab>", "\<C-n>\<C-n>" . s:go ], '\Vpython\$', 1 ], 
      \      [ [ "P\<Tab>", "\<C-n>\<CR>" ], '\V\w\+\$', 0 ], 
      \      [ [ "foo\<Tab>" ], '\Vfoo\s\+\$', 0 ], 
      \      [ [ "\<C-r>\<Tab>" ], '\V\^\$', 1 ], 
      \      [ [ "is if i\<Tab>" ], '\Vi\$', 1 ], 
      \      [ [ "is if i\<Tab>", "\<C-c>a\<C-n>" . s:go ], '\Vi\$', 1 ], 
      \      [ [ "is if i\<Tab>", "\<C-c>a\<C-n>\<Tab>" ], '\Vi\$', 1, 'reenter insert mode, <C-n> pum ' ], 
      \      [ [ "is if i\<Tab>", "\<C-c>a\<C-n>\<Tab>\<Tab>" ], '\Vif\$', 1 ], 
      \  ],
      \  '<c-\>:<tab>:1:1:<plug>supertabkey:<c-r><tab>:1' : [
      \      [ [ "\<Tab>" ], '\V\^\s\+\$', 0 ], 
      \      [ [ "p\<Tab>" ], '\Vp\$', 1 ], 
      \      [ [ "p\<Tab>", "\<CR>" ], '\Vpass\$', 0 ], 
      \      [ [ "p\<Tab>", "\<C-n>\<CR>" ], '\Vpass\$', 0 ], 
      \      [ [ "p\<Tab>", "\<C-n>\<C-n>" . s:go ], '\Vpython\$', 1 ], 
      \      [ [ "P\<Tab>", "\<C-n>\<CR>" ], '\V\w\+\$', 0 ], 
      \      [ [ "foo\<Tab>" ], '\Vfoo\$', 0 ], 
      \      [ [ "foofoo foobar foo\<Tab>" . s:go ], '\Vfoo\$', 1 ], 
      \      [ [ "foofoo foobar foo\<Tab>" . s:go, "\<C-n>\<C-n>" .s:go ], '\Vfoofoo\$', 1 ], 
      \      [ [ "foofoo foobar foo\<Tab>" . s:go, "\<Tab>\<Tab>" .s:go ], '\Vfoofoo\$', 1 ], 
      \      [ [ "\<C-r>\<Tab>" ], '\V\^\$', 1 ], 
      \      [ [ "is if i\<Tab>" ], '\Vi\$', 1 ], 
      \      [ [ "is if i\<Tab>", "\<C-c>a\<C-n>" . s:go ], '\Vi\$', 1 ], 
      \      [ [ "is if i\<Tab>", "\<C-c>a\<C-n>\<Tab>" . s:go ], '\Vi\.\?\$', 1 ], 
      \      [ [ "is if i\<Tab>", "\<C-c>a\<C-n>\<Tab>\<Tab>" . s:go ], '\Vif\$', 1 ], 
      \  ],
      \  '<tab>:<c-r><tab>:1:1:<plug>supertabkey:<c-r><c-r><tab>:1' : [
      \      [ [ "\<Tab>" ], '\V\^\s\+\$', 0 ], 
      \      [ [ "p\<Tab>" ], '\Vpass\$', 0 ], 
      \      [ [ "p\<C-r>\<Tab>", "\<C-n>\<CR>" ], '\Vpass\$', 0 ], 
      \      [ [ "p\<C-r>\<Tab>", "\<C-n>\<C-n>" . s:go ], '\Vpython\$', 1 ], 
      \      [ [ "P\<Tab>" ], '\V\w\+\$', 0 ], 
      \      [ [ "foo\<Tab>" ], '\Vfoo\$', 0 ], 
      \      [ [ "foofoo foobar foo\<Tab>" . s:go ], '\Vfoo\$', 1 ], 
      \      [ [ "foofoo foobar foo\<Tab>" . s:go, "\<C-n>\<C-n>" .s:go ], '\Vfoofoo\$', 1 ], 
      \      [ [ "foofoo foobar foo\<Tab>" . s:go, "\<Tab>\<Tab>" .s:go ], '\Vfoofoo\$', 1 ], 
      \      [ [ "\<C-r>\<Tab>" ], '\V\^\s\+\$', 0 ], 
      \      [ [ "\<C-r>\<C-r>\<Tab>" ], '\V\^\$', 1 ], 
      \      [ [ "is if i\<Tab>" ], '\Vi\$', 1 ], 
      \      [ [ "is if i\<Tab>", "\<C-c>a\<C-n>" . s:go ], '\Vi\$', 1 ], 
      \      [ [ "is if i\<Tab>", "\<C-c>a\<C-n>\<Tab>" . s:go ], '\Vi\.\?\$', 1 ], 
      \      [ [ "is if i\<Tab>", "\<C-c>a\<C-n>\<Tab>\<Tab>" . s:go ], '\Vif\$', 1 ], 
      \  ],
      \ }

let s:suites = []


fun! XPTassertLine( l, msg ) "{{{
    call Assert( getline( line( "." ) ) =~ a:l,
          \ 'line should be :' . a:l . ' but:' . string( getline( line( "." ) ) )
          \ . a:msg )
    return ''
endfunction "}}}

fun! XPTassertPum( hasPum, msg ) "{{{
    call Assert( pumvisible() == a:hasPum, 'should has pum:' . string( a:hasPum )
          \ . a:msg )
    return ''
endfunction "}}}


fun! s:Test( inputs, expect, hasPum, msg ) "{{{


    for inp in a:inputs 
        let s:actions += [ inp ]
    endfor
    
    " another <C-e> to clear pum
    let s:actions += [ "\<C-r>=XPTassertLine(" . string( a:expect ) . ', ' . string( a:msg ) . ")\<CR>"
          \ . "\<C-r>=XPTassertPum(" .  string( a:hasPum ) . ', ' . string( a:msg ) . ")\<CR>" . "\<C-e>" ]
    let s:actions += [ "\<CR>" ]
    let s:actions += [ "\<CR>\<C-c>S\<C-c>i" ]

endfunction "}}}





fun! XPTtestKeyGo() "{{{
    if len( s:actions ) > 0
        let action = s:actions[ 0 ]
        let s:actions = s:actions[ 1: ]

         call XPT#info( "to input:" . string( action ) )
        call feedkeys( action, 'mt' )
    else
        call s:XPTtestKeyEnd()
        call feedkeys( "\<ESC>:message\<CR>", 'nt' )
    endif

    return ''
endfunction "}}}


fun! s:XPTtestKeyEnd() "{{{
    let g:xpt_post_action = ""
    augroup XPTtestKey
        au!
    augroup END
endfunction "}}}

fun! XPTtestKey() "{{{

    call XPT#info( "keyTest conf=" . string( s:conf ) )

    let s:suites = s:suiteSet[ s:conf ]
    let g:xpt_post_action = "\<C-r>=XPTtestKeyGo()\<cr>"

    if exists( ':AcpLock' )
        AcpLock
    endif

    call feedkeys( 'i', 'nt' )

    augroup XPTtestKey
        au!
        au CursorMovedI,CursorHoldI * call XPTtestKeyGo()
    augroup END


    for t in s:suites
        call s:Test( t[ 0 ], t[ 1 ], t[ 2 ], get( t, 3, '' ) )
    endfor

    call XPTtestKeyGo()

endfunction "}}}
