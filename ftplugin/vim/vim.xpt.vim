XPTemplate priority=lang

let s:f = g:XPTfuncs()

XPTvar $TRUE          1
XPTvar $FALSE         0

" int fun ** (
" class name ** (
XPTvar $SPfun      ''

" int fun( ** arg ** )
" if ( ** condition ** )
" for ( ** statement ** )
" [ ** a, b ** ]
" { ** 'k' : 'v' ** }
XPTvar $SParg      ' '

" if ** (
" while ** (
" for ** (
XPTvar $SPcmd      ' '

" a ** = ** a ** + ** 1
" (a, ** b, ** )
XPTvar $SPop       ' '

XPTinclude
      \ _common/common
      \ _printf/c.like

XPTvar $CS    "
XPTinclude
      \ _comment/singleSign

fun! s:f.vim_call()
    " Note: do not use [ * - 2 ] which may be -1
    return getline( '.' )[ : self.ItemPos()[0][1] - 1 ] =~ '\v^\s*\w$' ? 'call ' : ''
endfunction

call XPTdefineSnippet('vimformat', {}, [ '" vim:tw=78:ts=8:sw=4:sts=4:et:norl:fdm=marker:fmr={{{,}}}' ])



XPT lncol " [ line\( "." ), col\( "." ) ]
[ line( '.' ), col( '.' ) ]

XPT printf	" printf\(..)
XSET elts|pre=Echo('')
XSET elts=c_printf_elts( R( 'pattern' ), "," )
printf(`$SParg^"`pattern^"`elts^`$SParg^)

XPT _args hidden " expandable arguments
XSET arg*|post=ExpandInsideEdge( ',$SPop', '' )
`$SParg`arg*`$SParg^

XPT self " self.
self.

XPT once " if exists.. finish
XSET i|pre=headerSymbol()
if exists(`$SParg^"`g^:`i^"`$SParg^)
    finish
endif
let `g^:`i^`$SPop^=`$SPop^1
`cursor^

XPT version " if exists && larger than
XSET i|pre=headerSymbol()
XSET ver=1
if exists(`$SParg^"`g^:`i^"`$SParg^) && `g^:`i^`$SPop^>=`$SPop^`ver^
    finish
endif
let ``g^:``i^`$SPop^=`$SPop^``ver^
`cursor^

XPT varconf " if !exists ".." let .. = .. endif
if !exists(`$SParg^"`g^:`varname^"`$SParg^)
    let `g^:`varname^`$SPop^=`$SPop^`val^
endif

XPT _fun hidden wrap " fun! ..(..) .. endfunction
fun! `name^`$SPfun^(`:_args:^) "{{{
    `cursor^
endfunction "}}}

XPT fun alias=_fun

XPT member wrap " tips
fun! `name^`$SPfun^(`:_args:^) dict "{{{
    `cursor^
endfunction "}}}

XPT while wrap " while .. .. endwhile
while `cond^
    `cursor^
endwhile

XPT while1 alias=while
XSET cond=Embed( $TRUE )

XPT whilei wrap " while i | let i += 1
let [`$SParg^`i^,`$SPop^`len^`$SParg^] = [`$SParg^`0^`$SPop^-`$SPop^1,`$SPop^`len_expr^`$SPop^-`$SPop^1`$SParg^]
while `i^`$SPop^<`$SPop^`len^ | let `i^`$SPop^+=`$SPop^1
    `cursor^
endwhile

XPT forin wrap " for .. in ..
for `value^ in `list^
    `cursor^
endfor

XPT try wrap=job " try .. catch ..
try
    `job^
`:catch:^
endtry

XPT catch " catch / .. /
XSET exception=.*
catch /`exception^/
    `cursor^

XPT finally " finally ..
finally
    `cursor^

XPT if wrap " if .. else ..
if `cond^
    `cursor^
endif

XPT else " else ..
else
    `cursor^

XPT filehead " description of file
" File Description {{{
" =============================================================================
" `cursor^
"                                                  by `$author^
"                                                     `$email^
" Usage :
"
" =============================================================================
" }}}
..XPT

XPT savecpo " save &cpo
let s:oldcpo = &cpo
set cpo-=< cpo+=B
`cursor^
let &cpo = s:oldcpo

" The first placeholder wrapping 'com' keyword that causes ctags halt
XPT sid "  generate s:sid variable
exe 'map <Plug>xsid <SID>|let s:sid=matchstr(maparg("<Plug>xsid"), "\\d\\+_")|unmap <Plug>xsid'

..XPT

XPT bench " while 1000.. doit..
let n = `100000^
let i = 0
let `t^_0 = reltime()

while i < n
    let i += 1
    `cursor^
endwhile

let `t^ = reltime( `t^_0 )
let us = `t^[0] * 1000*1000 + `t^[1]
echo 'spent:' reltimestr( `t^ )
echo 'per-call(us):' us/n

XPT call wraponly=param " ..\( .. )
`vim_call()`name^(`$SParg^`param^`$SParg^)

XPT _call hidden wrap=param? " $_xSnipName( .. )
`$_xSnipName^(`$SParg`param?`$SParg^)

XPT string alias=_call
