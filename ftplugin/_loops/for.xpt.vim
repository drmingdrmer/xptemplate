"
" standard for( i = 0; i < 10; i++ ) snippets
"
XPTemplate priority=all-

let s:f = g:XPTfuncs()

XPTvar $NULL            NULL
XPTvar $BRloop          ' '


XPTvar $SParg      ' '
XPTvar $SPcmd      ' '
XPTvar $SPop       ' '

XPTvar $VAR_PRE         ''
XPTvar $FOR_SCOPE       ''

XPTinclude
      \ _common/common





XPT for wrap " for (..;..;++)
for`$SPcmd^(`$SParg^`$FOR_SCOPE^`$VAR_PRE`i^`$SPop^=`$SPop^`0^; `i^`$SPop^<`$SPop^`len^; `i^++`$SParg^)`$BRloop^{
    `cursor^
}


XPT forr wrap " for (..;..;--)
for`$SPcmd^(`$SParg^`$FOR_SCOPE^`$VAR_PRE`i^`$SPop^=`$SPop^`0^; `i^`$SPop^>`=$SPop`end^; `i^--`$SParg^)`$BRloop^{
    `cursor^
}


XPT fornn wrap " for (..; $NULL != var; .. )
for`$SPcmd^(`$SParg^`$FOR_SCOPE^`$VAR_PRE`ptr^`$SPop^=`$SPop^`init^; `$NULL^`$SPop^!=`$SPop^`ptr^; `^R('ptr')^`$SParg^)`$BRloop^{
    `cursor^
}


XPT forever " for (;;) ..
for`$SPcmd^(;;) `cursor^
..XPT

" Simplify
" XSET i|edgeLeft=$VAR_PRE
" XSET i|edgeRight=$VAR_PRE
" XSET $(=  ($SParg
" XSET $)=  $SParg)
" XSET $==  $SPop=$SPop
" XSET $>=  $SPop>
" XSET $e=  =$SPop

" for`$SPcmd`$(`$FOR_SCOPE``i`$=`0; `i`$>`$e`end; `i++`$)`$BRloop{
" ^
" ..XPT
"
" for`SP(`SP`FOR_SCOPE`i`SP=`SP`0;`SP`i`SP>`SP`end;`SP`i++`SP)`SP{
"
" for$ ($ $FOR_SCOPE$i$ =$ $0;$ $i$ >$ $end;$ $i++$ )$ {
"
" for$ ($ $FOR_SCOPE${$VAR_PRE `i`}$ =$ $0;$ $i$ >$ $end;$ $i++$ )$ {
"
" for` (` `FOR_SCOPE`{$VAR_PRE `i`}` =` `0;` `{i/\v(\S+)$/\1/}` >` `{end:0::post=::focus=::live=};` `i++` )` {
