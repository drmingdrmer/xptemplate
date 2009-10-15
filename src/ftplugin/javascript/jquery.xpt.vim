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

XPTinclude 
    \ _common/common


" ========================= Function and Variables =============================


" ================================= Snippets ===================================
XPTemplateDef


" ============
" jQuery Core
" ============

XPT $ hint=$\()
XSET context?|post=EchoIfNoChange('')
$(`$SP_ARG^`e^`e^CompleteRightPart('''"')^`, `context?^`$SP_ARG^)

XPT jq hint=jQuery\()
jQuery(`$SP_ARG^`e^`e^CompleteRightPart('''"')^`, `context?^`$SP_ARG^)

XPT each hint=each\(...
XSET e?|post=EchoIfNoChange( '' )
each(`$SP_ARG^`function...{{^function(`i^`, `e?^) { `cursor^ }`}}^`$SP_ARG^)

XPT sz hint=size\()
size()

XPT eq hint=eq\(...)
eq(`$SP_ARG^`^`$SP_ARG^)

XPT get hint=get\(...)
get(`$SP_ARG^`^`$SP_ARG^)

XPT ind hint=index\(...)
index(`$SP_ARG^`^`$SP_ARG^)

XPT da hint=data\(..,\ ..)
XSET value?|post=EchoIfNoChange( '' )
data(`$SP_ARG^`name^`, `value?^`$SP_ARG^)

XPT rd hint=removeData\(..)
removeData(`$SP_ARG^`name^`$SP_ARG^)

XPT qu hint=queue\(..,\ ..)
XSET toAdd?|post=EchoIfNoChange( '' )
queue(`$SP_ARG^`name^`, `toAdd?^`$SP_ARG^)

XPT dq hint=dequeue\(...)
dequeue(`$SP_ARG^`name^`$SP_ARG^)
..XPT




" ============
" 
" ============








" ===================
" TODO select helper
" ===================



" ================================= Wrapper ===================================

