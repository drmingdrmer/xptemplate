XPTemplate priority=lang

let s:f = g:XPTfuncs()


XPTinclude
      \ _common/common


fun! s:f.fff()
  let v = self.V()
  if v == 'aa'
    return ''
  else
    return ', another'
  endif
endfunction



XPT _params
`in^` `var^` `dt^
XPT _params_2
`, `in^` `var^` `dt^

XPT foo
XSET in|def=Choose( [ "IN", "OUT", "INOUT" ], 'acceptEmpty' )
XSET in|post=Echo( V() !~ '\vIN|OUT|INNOUT' ? '' : V() )
XSET var|def=Echo( R( 'in' ) !~ '\vIN|OUT|INNOUT' ? Remove() : '-fill-' )
XSET dt|def=Echo( R( 'in' ) !~ '\vIN|OUT|INNOUT' ? Remove() : Choose( [ "whatever", "foo" ], 'acceptEmpty' ) )
XSET dt|post=Echo( V() =~ '\v^\s*$' ? V() : Build( V() . '`:_params_2:^' ) )
doit:`:_params:^ foo


XPT aa syn=43w
fjdkls
\XPT
fdskl
..XPT

XPT table alias=_tag
XPT tr    alias=_tag

XPT e " tips
#{ `^ }

XPT bb " tips
XSET cursor=123
what `a^ `cursor^
\XPT
..XPT

" XPT jkldsjfksl

XPT q " tips
XSET $a=3
`p`{$a}`p^-`p^

XPT x " tips
XSET $a=3
`p`p`p^-`$a^

XPT t " tips
`:x:^fjkdls
fjksl


fd
..XPT
" XPT aa " paste at end test
" `f^`aa...{{^pp`}}^`l^Echo( Context().history[-1].item.name )^

XPT pp " tips
`...^
- Let's repeat `this^
`...^
