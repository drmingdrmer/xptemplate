XPTemplate priority=lang

let [s:f, s:v] = XPTcontainer() 
 
XPTvar $TRUE          True
XPTvar $FALSE         False
XPTvar $NULL          None
XPTvar $UNDEFINED     None

XPTvar $VOID_LINE     # nothing
XPTvar $CURSOR_PH     # cursor

XPTvar $IF_BRACKET_STL \n

XPTinclude 
      \ _common/common


" ========================= Function and Variables =============================


" ================================= Snippets ===================================
XPTemplateDef


XPT if hint=if\ ..:\ ..\ else...
if `cond^:
    `pass^
``elif...`
{{^elif `cond2^:
    `pass^
``elif...`
^`}}^`else...{{^else:
    `cursor^`}}^


XPT forin hint=for\ ..\ in\ ..:\ ...
for `vars^ in range(`0^):
    `cursor^


XPT def hint=def\ ..(\ ..\ ):\ ...
XSET para*|post=ExpandIfNotEmpty( ', ', 'para*' )
def `fun_name^( `para*^ ):
    `cursor^


XPT lambda hint=(labmda\ ..\ :\ ..)
(lambda `args^ : `expr^)


XPT try hint=try:\ ..\ except:\ ...
XSET what=$VOID_LINE
try:
    `what^
except `except^:
    `handler^
``more_except...`
^``else...`
^`finally...^
XSETm more_except...|post
except `except^:
    `pass^
``more_except...`
^
XSETm END
XSETm else...|post
else:
    ``pass`
^
XSETm END
XSETm finally...|post
finally:
    `cursor^
XSETm END


XPT class hint=class\ ..\ :\ def\ __init__\ ...
class `className^ `inherit^^:
    def __init__( self `args^^):
        `cursor^


XPT ifmain hint=if\ __name__\ ==\ __main__
if __name__ == "__main__" :
    `cursor^


" ================================= Wrapper ===================================


XPT try_ hint=try:\ ..\ except:\ ...
try:
    `wrapped^
except `except^:
    `pass^
``more_except...`
^``else...`
^`finally...^
XSETm more_except...|post
except `except^:
    `pass^
``more_except...`
^
XSETm END
XSETm else...|post
else:
    ``pass`
^
XSETm END
XSETm finally...|post
finally:
    `cursor^
XSETm END
