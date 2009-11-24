XPTemplate priority=like

let s:f = g:XPTfuncs()

XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL
XPTvar $VOID_LINE /* void */;
XPTvar $BRif \n


XPTinclude
      \ _common/common


" ========================= Function and Variables =============================


" ================================= Snippets ===================================
call XPTemplateMark('`', '^')

XPTemplateDef


XPT #inc		hint=include\ <>
#include <`^.h>


XPT #include_user	hint=include\ ""
XSET me=fileRoot()
#include "`me^.h"


XPT #ind alias=#include_user


XPT #if hint=#if\ ...
#if `0^
`cursor^
#endif


XPT #ifdef hint=#if\ ...
#ifdef `identifier^
`cursor^
#endif


XPT #ifndef	hint=#ifndef\ ..
XSET symbol=S(fileRoot(),'\.','_','g')
XSET symbol|post=UpperCase(V())
#ifndef `symbol^
#     define `symbol^

`cursor^
#endif `$CL^ `symbol^ `$CR^
..XPT


XPT once	hint=#ifndef\ ..\ #define\ ..
XSET symbol=headerSymbol()
#ifndef `symbol^
#     define `symbol^

`cursor^
#endif `$CL^ `symbol^ `$CR^




" ================================= Wrapper ===================================

XPT #if_ hint=#if\ ..\ SEL\ #endif
#if `0^
`wrapped^
`cursor^
#endif

XPT #ifdef_ hint=#if\ ..\ SEL\ #endif
#ifdef `identifier^
`wrapped^
`cursor^
#endif

XPT #ifndef_ hint=#if\ ..\ SEL\ #endif
#ifndef `identifier^
`wrapped^
`cursor^
#endif
