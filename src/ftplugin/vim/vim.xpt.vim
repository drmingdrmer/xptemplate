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

XPTvar $CS    "
XPTinclude
      \ _comment/singleSign

" ========================= Function and Variables =============================


" ================================= Snippets ===================================
call XPTdefineSnippet('vimformat', {}, [ '" vim:tw=78:ts=8:sw=4:sts=4:et:norl:fdm=marker:fmr={{{,}}}' ])

XPTemplateDef

XPT _args hidden " expandable arguments
XSET arg*|post=ExpandInsideEdge( ',$SPop', '' )
`$SParg`arg*`$SParg^



XPT let " let var = **
let `^`$SPop^=`$SPop^`cursor^


XPT self " self.
self.


XPT once " if exists.. finish .. let
XSET i|pre=headerSymbol()
if exists(`$SParg^"`g^:`i^"`$SParg^)
    finish
endif
let `g^:`i^`$SPop^=`$SPop^1
`cursor^


XPT varconf " if !exists ".." let .. = .. endif
if !exists(`$SParg^"`g^:`varname^"`$SParg^)
    let `g^:`varname^`$SPop^=`$SPop^`val^
endif


XPT fun " fun! ..(..) .. endfunction
fun! `name^`$SPfun^(`:_args:^) "{{{
    `cursor^
endfunction "}}}

XPT member " tips
fun! `name^`$SPfun^(`:_args:^) dict "{{{
    `cursor^
endfunction "}}}



XPT while " while .. .. endwhile
while `cond^
    `cursor^
endwhile


XPT whilei " while i | let i += 1
let [`$SParg^`i^,`$SPop^`len^`$SParg^] = [`$SParg^`0^`$SPop^-`$SPop^1,`$SPop^`len_expr^`$SPop^-`$SPop^1`$SParg^]
while `i^`$SPop^<`$SPop^`len^ | let `i^`$SPop^+=`$SPop^1
    `cursor^
endwhile


XPT fordic " for [..,..] in .. .. endfor
for [`$SParg^`key^,`$SPop^`value^`$SParg^] in items(`$SParg^`dic^`$SParg^)
    `cursor^
endfor


XPT forin " for .. in .. .. endfor
for `value^ in `list^
    `cursor^
endfor

XPT foreach alias=forin " for .. in .. .. endfor


XPT try " try .. catch .. finally...
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


XPT if " if .. else ..
if `cond^
    `job^Echo()^
endif


XPT else " else ...
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

" The first placeholder wrapping 'com' keyword that causes ctags halt
XPT sid " // generate s:sid variable
exe 'map <Plug>xsid <SID>|let s:sid=matchstr(maparg("<Plug>xsid"), "\\d\\+_")|unmap <Plug>xsid'

..XPT


XPT str_ " transform SEL to string
string(`$SParg^`wrapped^`$SParg^)

XPT try_ " try .. catch .. finally...
XSET exception=.*
try
    `wrapped^
`:catch:^
endtry
