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

XPT $ hint=$\()
$(`$SP_ARG^`e^`e^CmplQuoter_pre()^`, `context?^`$SP_ARG^)

XPT jq hint=jQuery\()
jQuery(`$SP_ARG^`e^`e^CmplQuoter_pre()^`, `context?^`$SP_ARG^)

XPT each hint=each\(...
each`:maybeFunction:^

XPT sz hint=size\()
size()

XPT eq hint=eq\(...)
eq(`$SP_ARG^`^`$SP_ARG^)

XPT get hint=get\(...)
get(`$SP_ARG^`^`$SP_ARG^)

XPT ind hint=index\(...)
index(`$SP_ARG^`^`$SP_ARG^)

XPT da hint=data\(..,\ ..)
data(`$SP_ARG^`name^`, `value?^`$SP_ARG^)

XPT rd hint=removeData\(..)
removeData(`$SP_ARG^`name^`$SP_ARG^)

XPT qu hint=queue\(..,\ ..)
queue(`$SP_ARG^`name^`, `toAdd?^`$SP_ARG^)

XPT dq hint=dequeue\(...)
dequeue(`$SP_ARG^`name^`$SP_ARG^)
..XPT




" ==================
" jQuery Attributes
" ==================

XPT attr hint=attr\(..
attr(`$SP_ARG^`name^`$SP_ARG^)

XPT ra hint=removeAttr\(..
removeAttr(`$SP_ARG^`name^`$SP_ARG^)

XPT ac hint=addClass\(..
addClass(`$SP_ARG^`class^`$SP_ARG^)

XPT hc hint=hasClass\(..
hasClass(`$SP_ARG^`class^`$SP_ARG^)

XPT tc hint=toggleClass\(..
toggleClass(`$SP_ARG^`class^`, `switch?^`$SP_ARG^)

XPT html hint=html\(..
html`:optionalVal:^

XPT text hint=text\(..
text`:optionalVal:^

XPT val hint=val\(..
val`:optionalVal:^
..XPT




" ===================
" CSS
" ===================

XPT css hint=css\(..
css`:optionalVal:^

XPT os hint=offset\()
offset()

XPT osp hint=offsetParent\()
offsetParent()

XPT pos hint=position\()
position()

XPT scrt hint=scroll..\()
scrollTop`:optionalVal:^

XPT scrl hint=scroll..\()
scrollLeft`:optionalVal:^

XPT ht hint=height\(..)
height`:optionalVal:^

XPT wth hint=width\(..)
width`:optionalVal:^

XPT ih hint=innerHeight\()
innerHeight()

XPT iw hint=innerWidth\()
innerWidth()

XPT oh hint=outerHeight\(..)
outerHeight(`$SP_ARG^`margin^`$SP_ARG^)

XPT ow hint=outerWidth\(..)
outerWidth(`$SP_ARG^`margin^`$SP_ARG^)
..XPT





" ===================
" Traversing
" ===================
XPT eq hint=eq\(..
eq(`$SP_ARG^`index^`$SP_ARG^)

XPT flt hint=filter\(..
filter`:maybeFunction:^

XPT is hint=is\(..
is`:expr:^

XPT map hint=map\(..
map`:maybeFunction:^

XPT not hint=not\(..)
not`:expr:^

XPT slc hint=slice\(start,\ end)
slice(`$SP_ARG^`start^`, `end?^`$SP_ARG^)

XPT add hint=add\(..)
add`:expr:^

XPT chd hint=children\(..)
children`:optionalExpr:^

XPT cls hint=closest\(..)
closest`:expr:^

XPT con hint=content\()
content()

XPT fd hint=find\(..)
find`:expr:^

XPT ne hint=next\(..)
next`:optionalExpr:^

XPT na hint=nextAll\(..)
nextAll`:optionalExpr:^

XPT pr hint=parent\(..)
parent`:optionalExpr:^

XPT prs hint=parents\(..)
parents`:optionalExpr:^

XPT prv hint=prev\(..)
prev`:optionalExpr:^

XPT pra hint=prevAll\(..)
prevAll`:optionalExpr:^

XPT sib hint=sibling\(..)
sibling`:optionalExpr:^

XPT as hint=andSelf\()
andSelf()

XPT end hint=end\()
end()
..XPT



" ===================
" Manipulation
" ===================
XPT ap hint=append\(..)
append`:expr:^

XPT apt hint=appendTo\(..)
appendTo`:expr:^

XPT pp hint=prepend\(..)
prepend`:expr:^

XPT ppt hint=prependTo\(..)
prependTo`:expr:^

XPT af hint=after\(..)
after`:expr:^

XPT bf hint=before\(..)
before`:expr:^

XPT insa hint=insertAfter\(..)
insertAfter`:expr:^

XPT insb hint=insertBefore\(..)
insertBefore`:expr:^

XPT wr hint=wrap\(..)
wrap`:expr:^

XPT wra hint=wrapAll\(..)
wrapAll`:expr:^

XPT wri hint=wrapInner\(..)
wrapInner`:expr:^

XPT rep hint=replaceWith\(..)
replaceWith`:expr:^

XPT repa hint=replaceAll\(..)
replaceAll`:expr:^

XPT emp hint=empty\()
empty()

XPT rm hint=remove\(..)
remove`:optionalExpr:^

XPT cl hint=clone\(..)
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



XPT aj hint=$JQ.ajax\(..)
`$JQ^.ajax(`$SP_ARG^`opt^`$SP_ARG^)

XPT ld hint=load\(url,\ ...)
load(`$SP_ARG^`url^`url^CmplQuoter_pre()^`, `data^`data^CmplQuoter_pre()^`, `function...{{^, `:_ld_callback:^`}}^`$SP_ARG^)

XPT ag hint=$JQ.get\(url,\ ...)
`$JQ^.get(`$SP_ARG^`url^`url^CmplQuoter_pre()^`, `data^`data^CmplQuoter_pre()^`, `callback^`:_aj_type:^`$SP_ARG^)

XPT agj hint=$JQ.getJSON\(url,\ ...)
`$JQ^.getJSON(`$SP_ARG^`url^`url^CmplQuoter_pre()^`, `data^`, `callback^`$SP_ARG^)

XPT ags hint=$JQ.getScript\(url,\ ...)
`$JQ^.getScript(`$SP_ARG^`url^`url^CmplQuoter_pre()^`, `callback^`$SP_ARG^)

XPT apost hint=$JQ.post\(url,\ ...)
`$JQ^.post(`$SP_ARG^`url^`url^CmplQuoter_pre()^`, `data^`data^CmplQuoter_pre()^`, `callback^`:_aj_type:^`$SP_ARG^)



XPT ajaxComplete hint=ajaxComplete\(callback)
ajaxComplete(`$SP_ARG^`fun...{{^function (`$SP_ARG^`event^`, `xhr^`, `ajaxOption^`$SP_ARG^){ `cursor^ }`}}^`$SP_ARG^)

XPT ajaxError hint=ajaxError\(callback)
ajaxError(`$SP_ARG^`fun...{{^function (`$SP_ARG^`event^`, `xhr^`, `ajaxOption^`, `err^`$SP_ARG^){ `cursor^ }`}}^`$SP_ARG^)

XPT ajaxSend hint=ajaxSend\(callback)
ajaxSend(`$SP_ARG^`fun...{{^function (`$SP_ARG^`event^`, `xhr^`, `ajaxOption^`$SP_ARG^){ `cursor^ }`}}^`$SP_ARG^)

XPT ajaxStart hint=ajaxStart\(callback)
ajaxStart(`$SP_ARG^`fun...{{^`:_fun0:^`}}^`$SP_ARG^)

XPT ajaxStop hint=ajaxStop\(callback)
ajaxStop(`$SP_ARG^`fun...{{^`:_fun0:^`}}^`$SP_ARG^)

XPT ajaxSuccess hint=ajaxSuccess\(callback)
ajaxSuccess(`$SP_ARG^`fun...{{^function (`$SP_ARG^`event^`, `xhr^`, `ajaxOption^`$SP_ARG^){ `cursor^ }`}}^`$SP_ARG^)



XPT asetup hint=$JQ.ajaxSetup\(opt)
`$JQ^.ajaxSetup(`$SP_ARG^`opt^`$SP_ARG^)

XPT ser hint=serialize\()
serialize()

XPT sera hint=serializeArray\()
serializeArray()
..XPT


" ===================
" Events
" ===================
" ===================
" Effects
" ===================
" ===================
" TODO select helper
" ===================



" ================================= Wrapper ===================================

