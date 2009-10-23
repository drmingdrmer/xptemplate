XPTemplate priority=lang

let s:f = g:XPTfuncs() 
 
XPTvar $TRUE          1
XPTvar $FALSE         0

XPTinclude 
      \ _common/common

XPTvar $CS    "
XPTinclude 
      \ _comment/singleSign

" ========================= Function and Variables =============================


" ================================= Snippets ===================================
call XPTemplate('vimformat', [ '" vim:tw=78:ts=8:sw=2:sts=2:et:norl:fdm=marker:fmr={{{,}}}' ])

XPTemplateDef

XPT once hint=if\ exists..\ finish\ ..\ let
XSET i|pre=headerSymbol()
if exists("`g^:`i^")
    finish
endif
let `g^:`i^ = 1
`cursor^

XPT varconf hint=if\ !exists\ ".."\ let\ ..\ =\ ..\ endif
if !exists("`access^g^:`varname^")
    let `access^:`varname^ = `val^
endif


XPT fun hint=fun!\ ..(..)\ ..\ endfunction
XSET arg*|post=ExpandIfNotEmpty(', ', 'arg*')
fun! `name^(`arg*^) "{{{
    `cursor^
endfunction "}}}

XPT member hint=tips
XSET arg*|post=ExpandIfNotEmpty(', ', 'arg*')
fun! `name^(`arg*^) dict "{{{
    `cursor^
endfunction "}}}



XPT while hint=while\ ..\ ..\ endwhile
while `cond^
    `cursor^
endwhile


XPT whilei hint=while\ i\ |\ let\ i\ +=\ 1
let [ `i^, `len^ ] = [ `0^ - 1, `len_expr^ - 1 ]
while `i^ < `len^ | let `i^ += 1
    `cursor^
endwhile


XPT fordic hint=for\ [..,..]\ in\ ..\ ..\ endfor
for [`key^, `value^] in items(`dic^)
    `cursor^
endfor


XPT forin hint=for\ ..\ in\ ..\ ..\ endfor
for `value^ in `list^
    `cursor^
endfor

XPT foreach alias=forin hint=for\ ..\ in\ ..\ ..\ endfor




XPT try hint=try\ ..\ catch\ ..\ finally...
XSET exception=.*
try
    
catch /`exception^/
`
`finally...{{^
finally
    `cursor^`}}^
endtry



XPT if hint=if\ ..\ else\ ..
if `cond^
    `job^Echo()^
``else...`
{{^else
    `cursor^
`}}^endif


XPT fdesc hint=description\ of\ file
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
XPT sid hint=//\ generate\ s:sid\ variable
`Echo('com')^! `name^GetSID let s:sid =  matchstr("<SID>", '\zs\d\+_\ze')
`name^GetSID
delc `name^GetSID



XPT str_ hint=transform\ SEL\ to\ string
string(`wrapped^)

XPT try_ hint=try\ ..\ catch\ ..\ finally...
XSET exception=.*
try
    `wrapped^
catch /`exception^/
`
`finally...{{^
finally
    `cursor^`}}^
endtry
