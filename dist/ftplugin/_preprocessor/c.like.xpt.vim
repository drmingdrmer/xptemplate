XPTemplate priority=like

let s:f = g:XPTfuncs()


XPTinclude
      \ _common/common




XPT #inc		" include <>
#include <`^.h>


XPT #include_user	" include ""
XSET me=fileRoot()
#include "`me^.h"


XPT #ind alias=#include_user


XPT #if wrap " #if ..
#if `0^
`cursor^
#endif


XPT #ifdef wrap " #ifdef ..
#ifdef `symbol^
`cursor^
#endif `$CL^ `symbol^ `$CR^


XPT #ifndef wrap	" #ifndef ..
#ifndef `symbol^
`cursor^
#endif `$CL^ `symbol^ `$CR^


XPT once wrap	" #ifndef .. #define ..
XSET symbol=headerSymbol()
#ifndef `symbol^
#     define `symbol^

`cursor^
#endif `$CL^ `symbol^ `$CR^
