XPTemplate priority=lang

let s:f = g:XPTfuncs() 
 
XPTvar $TRUE          True
XPTvar $FALSE         False
XPTvar $NULL          None
XPTvar $UNDEFINED     None

XPTvar $VOID_LINE     # nothing
XPTvar $CURSOR_PH     pass

XPTvar $BRif \n

XPTinclude 
      \ _common/common


" ========================= Function and Variables =============================

fun! s:f.python_wrap_args_if_func(func, args)
    if a:func != ''
        return a:func.'('.a:args.')'
    else
        return a:args
    endif
endfunction

" ================================= Snippets ===================================
XPTemplateDef


XPT python hint=#!/usr/bin/env\ python\ #\ coding:\ ..
XSET encoding|pre=Echo(&fenc ? &fenc : &enc)
#!/usr/bin/env python
# coding: `encoding^

..XPT

XPT shebang alias=python

XPT sb alias=python


XPT if hint=if\ ..:\ ..\ else...
if `cond^:
    `pass^
`else...{{^`:else:^`}}^

XPT elif hint=else:
elif `cond^:
    `cursor^


XPT else hint=else:
else:
    `cursor^


XPT for hint=for\ ..\ in\ range\(\ ..\ )
for `var^ in range(`$SParg^``0?`,$SPcm^`end^`$SParg^):
    `cursor^

XPT forin hint=for\ ..\ in\ ..:\ ...
for `vars^ in `seq^:
    `cursor^


XPT def hint=def\ ..(\ ..\ ):\ ...
XSET args*|post=ExpandIfNotEmpty( ', ', 'args*' )
def `func_name^`$SPfun^(`$SParg^`args*^`$SParg^):
    `cursor^


XPT lambda hint=(lambda\ ..\ :\ ..)
XSET args*|post=ExpandIfNotEmpty( ', ', 'args*' )
lambda `args*^: `expr^


XPT try hint=try:\ ..\ except:\ ...
try:
    `pass^
`:except:^
`finally...{{^`:finally:^`}}^


XPT except " except *
except `Exception^:
    `cursor^


XPT finally " finally:
    `cursor^


XPT class hint=class\ ..\ :\ def\ __init__\ ...
XSET args*|post=ExpandIfNotEmpty( ', ', 'args*' )
class `ClassName^`$SPcls^(`$SParg``$SParg^):
    def __init__(self`, `args*^):
        `cursor^


XPT ifmain hint=if\ __name__\ ==\ __main__
if __name__ == "__main__" :
    `cursor^

XPT with hint=with\ ..\ as\ ..\ :
with `opener^ as `name^:
    `cursor^

XPT import hint=import\ ..
import `mod^

XPT importas hint=import\ ..\ as
import `module^ as `name^

XPT fromas hint=from\ ..\ import\ ..\ as
from `module^ import `item^ as `name^

XPT from hint=from\ ..\ import\ ..
from `module^ import `item^


XPT fromfuture hint=from\ __future__\ import\ ..
from __future__ import `name^

XPT genExp hint=\(func\(x)\ for\ x\ in\ seq)
XSET ComeFirst=elem seq
XSET func|post=python_wrap_args_if_func(V(), Reference('elem'))
(`func^ for `elem^ in `seq^)

XPT listComp hint=\[func\(x)\ for\ x\ in\ seq]
XSET ComeFirst=elem seq
XSET func|post=python_wrap_args_if_func(V(), Reference('elem'))
[`func^ for `elem^ in `seq^]
..XPT


" ================================= Wrapper ===================================


XPT try_ hint=try:\ ..\ except:\ ...
try:
    `wrapped^
except `Exception^:
    `pass^
``more_except...`
^``else...`
^`finally...^
XSETm more_except...|post
except `Exception^:
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
