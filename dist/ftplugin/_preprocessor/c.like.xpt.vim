XPTemplate priority=like keyword=#

let [s:f, s:v] = XPTcontainer() 
 
XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL
XPTvar $INDENT_HELPER /* void */;
XPTvar $IF_BRACKET_STL \n


XPTinclude 
      \ _common/common


" ========================= Function and Variables =============================


" ================================= Snippets ===================================
XPTemplateDef 


XPT #include		hint=include\ <>
#include <`^.h>


XPT #include_user	hint=include\ ""
XSET me=fileRoot()
#include "`me^.h"
XPT #ind	alias=#include_user


XPT once	hint=#ifndef\ ..\ #define\ ..
XSET symbol=headerSymbol()
#ifndef `symbol^
#     define `symbol^

`cursor^
#endif `$CL^ `symbol^ `$CR^


XPT #ifndef	hint=#ifndef\ ..
XSET symbol=S(fileRoot(),'\.','_','g')
XSET symbol|post=UpperCase(V())
#ifndef `symbol^
#     define `symbol^

`cursor^ 
#endif `$CL^ `symbol^ `$CR^


