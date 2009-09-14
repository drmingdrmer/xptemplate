XPTemplate priority=lang mark=~^ keyword=$([{

let [s:f, s:v] = XPTcontainer() 
 
XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL

XPTvar $VOID_LINE     # void
XPTvar $CURSOR_PH     # cursor


XPTvar $IF_BRACKET_STL     \ 
XPTvar $ELSE_BRACKET_STL   \n
XPTvar $FOR_BRACKET_STL    \ 
XPTvar $WHILE_BRACKET_STL  \ 
XPTvar $STRUCT_BRACKET_STL \ 
XPTvar $FUNC_BRACKET_STL   \ 

XPTinclude 
      \ _common/common

XPTvar $CS    #
XPTinclude 
      \ _comment/singleSign


" ========================= Function and Variables =============================


" ================================= Snippets ===================================


XPTemplateDef


XPT sh hint=#!/bin/sh
#!/bin/sh

..XPT


XPT bash hint=#!/bin/bash
#!/bin/bash

..XPT


XPT echodate hint=echo\ `date\ +%...`
echo `date +~fmt^`



XPT forin
for ~i^ in ~list^;~$FOR_BRACKET_STL^do
    ~cursor^
done


XPT foreach alias=forin


XPT for
for ((~i^ = ~0^; ~i^ < ~len^; ~i^++));~$FOR_BRACKET_STL^do
    ~cursor^
done

XPT forr
for ((~i^ = ~n^; ~i^ >~=^ ~start^; ~i^--));~$FOR_BRACKET_STL^do
    ~cursor^
done


XPT while
while ~condition^;~$WHILE_BRACKET_STL^do
    ~cursor^
done


XPT while1 alias=while
XSET condition=Next( '[ 1 ]' )


XPT case
case $~var^ in
    ~pattern^)
    ~cursor^
    ;;

    *)
    ;;
esac


XPT if
if ~condition^;~$IF_BRACKET_STL^then
    ~cursor^
fi


XPT ife
if ~condition^;~$IF_BRACKET_STL^then
    ~job^
else
    ~cursor^
fi


XPT elif
elif ~condition^;~$IF_BRACKET_STL^then
    ~cursor^


XPT (
( ~cursor^ )


XPT {
{ ~cursor^ }


XPT [
[[ ~test^ ]]


XPT fun
function ~name^ (~args^)~$FUNC_BRACKET_STL^{
    ~cursor^
}
