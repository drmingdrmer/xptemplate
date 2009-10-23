" finish " not finished 
if !g:XPTloadBundle( 'javascript', 'jquery' )
    finish
endif

XPTemplate priority=lang-2

let s:f = g:XPTfuncs() 

XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL

XPTvar $IF_BRACKET_STL     ' '
XPTvar $ELSE_BRACKET_STL   \n
XPTvar $FOR_BRACKET_STL    ' '
XPTvar $WHILE_BRACKET_STL  ' '
XPTvar $STRUCT_BRACKET_STL ' '
XPTvar $FUNC_BRACKET_STL   ' '

" XPTvar $JQ jQuery
XPTvar $JQ $

XPTinclude 
    \ _common/common


" ========================= Function and Variables =============================
let s:options = {
            \'async'         : 1,
            \'beforeSend'    : 1,
            \'cache'         : 1,
            \'complete'      : 1,
            \'contentType'   : 1,
            \'data'          : 1,
            \'dataFilter'    : 1,
            \'dataType'      : 1,
            \'error'         : 1,
            \'global'        : 1,
            \'ifModified'    : 1,
            \'jsonp'         : 1,
            \'password'      : 1,
            \'processData'   : 1,
            \'scriptCharset' : 1,
            \'success'       : 1,
            \'timeout'       : 1,
            \'type'          : 1,
            \'url'           : 1,
            \'username'      : 1,
            \'xhr'           : 1,
            \}
fun! s:f.jquery_ajaxOptions()
    
endfunction

" ================================= Snippets ===================================
XPTemplateDef

" ===============
" Snippet Pieces
" ===============

XPT optionalExpr hidden=1
(`$SP_ARG^`expr?^`expr?^CmplQuoter_pre()^`$SP_ARG^)

XPT expr hidden=1
(`$SP_ARG^`expr^`expr^CmplQuoter_pre()^`$SP_ARG^)

XPT maybeFunction hidden=1
(`$SP_ARG^`function...{{^function(`i^`, `e?^) { `cursor^ }`}}^`$SP_ARG^)

XPT optionalVal hidden=1
(`$SP_ARG^`val?^`$SP_ARG^)

XPT _funExp hidden=1
`function...{{^function(`i^`, `e?^) { `cursor^ }`}}^
..XPT

" ============
" jQuery Core
" ============

XPT $ " $\()
$(`$SP_ARG^`e^`e^CmplQuoter_pre()^`, `context?^`$SP_ARG^)

XPT jq " jQuery\()
jQuery(`$SP_ARG^`e^`e^CmplQuoter_pre()^`, `context?^`$SP_ARG^)

XPT each " each\(...
each`:maybeFunction:^

XPT sz " size\()
size()

XPT eq " eq\(...)
eq(`$SP_ARG^`^`$SP_ARG^)

XPT get " get\(...)
get(`$SP_ARG^`^`$SP_ARG^)

XPT ind " index\(...)
index(`$SP_ARG^`^`$SP_ARG^)

XPT da " data\(..,\ ..)
data(`$SP_ARG^`name^`, `value?^`$SP_ARG^)

XPT rmd " removeData\(..)
removeData(`$SP_ARG^`name^`$SP_ARG^)

XPT qu " queue\(..,\ ..)
queue(`$SP_ARG^`name^`, `toAdd?^`$SP_ARG^)

XPT dq " dequeue\(...)
dequeue(`$SP_ARG^`name^`$SP_ARG^)
..XPT




" ==================
" jQuery Attributes
" ==================

XPT attr " attr\(..
attr(`$SP_ARG^`name^`$SP_ARG^)

XPT rma " removeAttr\(..
removeAttr(`$SP_ARG^`name^`$SP_ARG^)

XPT ac " addClass\(..
addClass(`$SP_ARG^`class^`$SP_ARG^)

XPT hc " hasClass\(..
hasClass(`$SP_ARG^`class^`$SP_ARG^)

XPT tc " toggleClass\(..
toggleClass(`$SP_ARG^`class^`, `switch?^`$SP_ARG^)

XPT html " html\(..
html`:optionalVal:^

XPT text " text\(..
text`:optionalVal:^

XPT val " val\(..
val`:optionalVal:^
..XPT




" ===================
" CSS
" ===================

XPT css " css\(..
css`:optionalVal:^

XPT os " offset\()
offset()

XPT osp " offsetParent\()
offsetParent()

XPT pos " position\()
position()

XPT scrt " scrollTop\()
scrollTop`:optionalVal:^

XPT scrl " scrollLeft\()
scrollLeft`:optionalVal:^

XPT ht " height\(..)
height`:optionalVal:^

XPT wth " width\(..)
width`:optionalVal:^

XPT ih " innerHeight\()
innerHeight()

XPT iw " innerWidth\()
innerWidth()

XPT oh " outerHeight\(..)
outerHeight(`$SP_ARG^`margin^`$SP_ARG^)

XPT ow " outerWidth\(..)
outerWidth(`$SP_ARG^`margin^`$SP_ARG^)
..XPT





" ===================
" Traversing
" ===================

XPT flt " filter\(..
filter`:maybeFunction:^

XPT is " is\(..
is`:expr:^

XPT map " map\(..
map`:maybeFunction:^

XPT not " not\(..)
not`:expr:^

XPT slc " slice\(start,\ end)
slice(`$SP_ARG^`start^`, `end?^`$SP_ARG^)

XPT add " add\(..)
add`:expr:^

XPT chd " children\(..)
children`:optionalExpr:^

XPT cls " closest\(..)
closest`:expr:^

XPT con " content\()
content()

XPT fd " find\(..)
find`:expr:^

XPT ne " next\(..)
next`:optionalExpr:^

XPT na " nextAll\(..)
nextAll`:optionalExpr:^

XPT pr " parent\(..)
parent`:optionalExpr:^

XPT prs " parents\(..)
parents`:optionalExpr:^

XPT prv " prev\(..)
prev`:optionalExpr:^

XPT pra " prevAll\(..)
prevAll`:optionalExpr:^

XPT sib " sibling\(..)
sibling`:optionalExpr:^

XPT as " andSelf\()
andSelf()

XPT end " end\()
end()
..XPT



" ===================
" Manipulation
" ===================
XPT ap " append\(..)
append`:expr:^

XPT apt " appendTo\(..)
appendTo`:expr:^

XPT pp " prepend\(..)
prepend`:expr:^

XPT ppt " prependTo\(..)
prependTo`:expr:^

XPT af " after\(..)
after`:expr:^

XPT bf " before\(..)
before`:expr:^

XPT insa " insertAfter\(..)
insertAfter`:expr:^

XPT insb " insertBefore\(..)
insertBefore`:expr:^

XPT wr " wrap\(..)
wrap`:expr:^

XPT wra " wrapAll\(..)
wrapAll`:expr:^

XPT wri " wrapInner\(..)
wrapInner`:expr:^

XPT rep " replaceWith\(..)
replaceWith`:expr:^

XPT repa " replaceAll\(..)
replaceAll`:expr:^

XPT emp " empty\()
empty()

XPT rm " remove\(..)
remove`:optionalExpr:^

XPT cl " clone\(..)
cloen`:optionalExpr:^
..XPT

" =========================
" Ajax
" =========================
" TODO callback
" TODO ajax option
" TODO universial behavior for clearing optional argument

XPT _ld_callback hidden=1
function(`$SP_ARG^`resText^`, `textStatus^`, `xhr^`$SP_ARG^) { `cursor^ }

XPT _aj_type hidden=1
XSET type=ChooseStr( '"xml"', '"html"', '"script"', '"json"', '"jsonp"', '"text"' )
`, `type^

XPT _fun0 hidden=1
function() { `cursor^ }



XPT aj " $JQ.ajax\(..)
`$JQ^.ajax(`$SP_ARG^`opt^`$SP_ARG^)

XPT load " load\(url,\ ...)
load(`$SP_ARG^`url^`url^CmplQuoter_pre()^`, `data^`data^CmplQuoter_pre()^`, `function...{{^, `:_ld_callback:^`}}^`$SP_ARG^)

XPT ag " $JQ.get\(url,\ ...)
`$JQ^.get(`$SP_ARG^`url^`url^CmplQuoter_pre()^`, `data^`data^CmplQuoter_pre()^`, `callback^`:_aj_type:^`$SP_ARG^)

XPT agj " $JQ.getJSON\(url,\ ...)
`$JQ^.getJSON(`$SP_ARG^`url^`url^CmplQuoter_pre()^`, `data^`, `callback^`$SP_ARG^)

XPT ags " $JQ.getScript\(url,\ ...)
`$JQ^.getScript(`$SP_ARG^`url^`url^CmplQuoter_pre()^`, `callback^`$SP_ARG^)

XPT apost " $JQ.post\(url,\ ...)
`$JQ^.post(`$SP_ARG^`url^`url^CmplQuoter_pre()^`, `data^`data^CmplQuoter_pre()^`, `callback^`:_aj_type:^`$SP_ARG^)



XPT ajaxComplete " ajaxComplete\(callback)
ajaxComplete(`$SP_ARG^`fun...{{^function (`$SP_ARG^`event^`, `xhr^`, `ajaxOption^`$SP_ARG^){ `cursor^ }`}}^`$SP_ARG^)

XPT ajaxError " ajaxError\(callback)
ajaxError(`$SP_ARG^`fun...{{^function (`$SP_ARG^`event^`, `xhr^`, `ajaxOption^`, `err^`$SP_ARG^){ `cursor^ }`}}^`$SP_ARG^)

XPT ajaxSend " ajaxSend\(callback)
ajaxSend(`$SP_ARG^`fun...{{^function (`$SP_ARG^`event^`, `xhr^`, `ajaxOption^`$SP_ARG^){ `cursor^ }`}}^`$SP_ARG^)

XPT ajaxStart " ajaxStart\(callback)
ajaxStart(`$SP_ARG^`fun...{{^`:_fun0:^`}}^`$SP_ARG^)

XPT ajaxStop " ajaxStop\(callback)
ajaxStop(`$SP_ARG^`fun...{{^`:_fun0:^`}}^`$SP_ARG^)

XPT ajaxSuccess " ajaxSuccess\(callback)
ajaxSuccess(`$SP_ARG^`fun...{{^function (`$SP_ARG^`event^`, `xhr^`, `ajaxOption^`$SP_ARG^){ `cursor^ }`}}^`$SP_ARG^)



XPT asetup " $JQ.ajaxSetup\(opt)
`$JQ^.ajaxSetup(`$SP_ARG^`opt^`$SP_ARG^)

XPT ser " serialize\()
serialize()

XPT sera " serializeArray\()
serializeArray()
..XPT


" ===================
" Events
" ===================
XPT _ev_fun_a hidden=1
XSET job=VoidLine()
function (`$SP_ARG^`ev^`$SP_ARG^) { `job^ }

XPT _ev_fun hidden=1
function (`$SP_ARG^`ev^`$SP_ARG^) { `cursor^ }

XPT _ev_arg hidden=1
(`$SP_ARG^`type^`type^CmplQuoter_pre()^`, `data^`, `fun...{{^, `:_ev_fun:^`}}^`$SP_ARG^)

XPT _ev_tr_arg hidden=1
(`$SP_ARG^`ev^`ev^CmplQuoter_pre()^`, `data^`$SP_ARG^)

XPT _ev_arg_fun hidden=1
(`$SP_ARG^`fun...{{^`:_ev_fun:^`}}^`$SP_ARG^)



XPT rd " ready\(fun)
ready(`$SP_ARG^`fun...{{^`:_fun0:^`}}^`$SP_ARG^)

XPT bd " bind\(type,\ data,\ fun)
bind`:_ev_arg:^

XPT one " one\(type,\ data,\ fun)
one`:_ev_arg:^

XPT tr " trigger\(ev,\ data)
trigger`:_ev_tr_arg:^

XPT trh " triggerHandler\(ev,\ data)
triggerHandler`:_ev_tr_arg:^

XPT ub " unbind\(type,\ fun)
unbind(`$SP_ARG^`type^`type^CmplQuoter_pre()^`, `fun^`$SP_ARG^)

XPT lv " live\(type,\ fun)
live`:_ev_arg:^

XPT die " die\(type,\ fun)
die(`$SP_ARG^`type^`type^CmplQuoter_pre()^`, `fun^`$SP_ARG^)

XPT ho " hover\(over,\ out)
hover(`$SP_ARG^`over...{{^, `:_ev_fun_a:^`}}^`, `out..{{^, `:_ev_fun:^`}}^`$SP_ARG^)

XPT tg " toggle\(fn1,\ fn2,\ ...)
toggle(`$SP_ARG^`fn1...{{^, `:_ev_fun_a:^`}}^`, `fn2...{{^, `:_ev_fun:^`}}^`$SP_ARG^)



XPT bl " blur\(fun)
blur`:_ev_arg_fun:^

XPT res " resize\(fun)
resize`:_ev_arg_fun:^

XPT scr " scroll\(fun)
scroll`:_ev_arg_fun:^

XPT sel " select\(fun)
select`:_ev_arg_fun:^

XPT sub " submit\(fun)
submit`:_ev_arg_fun:^

XPT unl " unload\(fun)
unload`:_ev_arg_fun:^



XPT kdown " keydown\(fun)
keydown`:_ev_arg_fun:^

XPT kup " keyup\(fun)
keyup`:_ev_arg_fun:^

XPT kpress " keypress\(fun)
keypress`:_ev_arg_fun:^

XPT clk " click\(fun)
click`:_ev_arg_fun:^

XPT dclk " dbclick\(fun)
dbclick`:_ev_arg_fun:^



XPT foc " focus\(fun)
focus`:_ev_arg_fun:^

XPT err " error\(fun)
error`:_ev_arg_fun:^



XPT mup " mouseup\(fun)
mouseup`:_ev_arg_fun:^

XPT mdown " mousedown\(fun)
mousedown`:_ev_arg_fun:^

XPT mmove " mousemove\(fun)
mousemove`:_ev_arg_fun:^

XPT menter " mouseenter\(fun)
mouseenter`:_ev_arg_fun:^

XPT mleave " mouseleave\(fun)
mouseleave`:_ev_arg_fun:^

XPT mout " mouseout\(fun)
mouseout`:_ev_arg_fun:^




XPT ld " load\(fun)
load`:_ev_arg_fun:^

XPT ch " change\(fun)
change`:_ev_arg_fun:^
..XPT



" ===================
" Effects
" ===================

XPT _ef_arg hidden=1
(`$SP_ARG^`speed^`speed^CmplQuoter_pre()^`, `fun...{{^, `:_fun0:^`}}^`$SP_ARG^)

XPT sh " show\(speed,\ callback)
show`:_ef_arg:^

XPT hd " hide\(speed,\ callback)
hide`:_ef_arg:^

XPT sld " slideDown\(speed,\ callback)
slideDown`:_ef_arg:^

XPT slu " slideUp\(speed,\ callback)
slideUp`:_ef_arg:^

XPT slt " slideToggle\(speed,\ callback)
slideToggle`:_ef_arg:^



XPT fi " fadeIn\(speed,\ callback)
fadeIn`:_ef_arg:^

XPT fo " fadeOut\(speed,\ callback)
fadeOut`:_ef_arg:^

XPT ft " fadeTo\(speed,\ callback)
fadeTo(`$SP_ARG^`speed^`speed^CmplQuoter_pre()^`, `opacity^`opacity^CmplQuoter_pre()^`, `fun...{{^, `:_fun0:^`}}^`$SP_ARG^)

XPT ani " animate\(params,\ ...)
animate(`$SP_ARG^`params^`, `param^`$SP_ARG^)

XPT stop " stop\()
stop()
..XPT

" ===================
" TODO select helper
" ===================



" ================================= Wrapper ===================================

