XPTemplate priority=lang

let s:f = g:XPTfuncs() 
 
XPTvar $TRUE          True
XPTvar $FALSE         False
XPTvar $NULL          None
XPTvar $UNDEFINED     None

XPTvar $VOID_LINE     # nothing
XPTvar $CURSOR_PH     CURSOR

XPTvar $BRif \n

" int fun ** (
XPTvar $SPfun      ''

" int fun( ** arg ** )
XPTvar $SParg      ' '

" if ** ( 
XPTvar $SPcmd       ' '

" if ( ** condition ** )
XPTvar $SParg      ' '

" a ** = ** b
XPTvar $SPeq       ' '

" a = a ** + ** 1
XPTvar $SPop       ' '

" (a, ** b, ** )
XPTvar $SPcm       ' '

" class name ** (
XPTvar $SPcls      ''

" [ ** a, b ** ], { ** 'k' : 'v' ** }
XPTvar $SPar       ' '

XPTinclude 
      \ _common/common


XPTvar $CS    #
XPTinclude 
    \ _comment/singleSign


" ========================= Function and Variables =============================

fun! s:f.python_wrap_args_if_func( args )
    let v = self.V()
    if v != ''
        return v . '(' . a:args . ')'
    else
        return a:args
    endif
endfunction

fun! s:f.python_genexpr_cmpl( itemName )
    let v = self.V()
    if v =~ '\V(\$'
        let args = self.R( a:itemName )
        return self[ '$SParg' ] . args . self[ '$SParg' ] . ')'
    else
        return ''
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
def `func_name^`$SPfun^(`:args:^):
    `cursor^


XPT lambda hint=(lambda\ ..\ :\ ..)
XSET arg*|post=ExpandInsideEdge( ',$SPcm', '' )
lambda `arg*^: `expr^


XPT try hint=try:\ ..\ except:\ ...
try:
    `job^
`:except:^
`finally...{{^`:finally:^`}}^


XPT except " except *
except `Exception^:
    `pass^


XPT finally " finally:
finally:
    `cursor^


XPT class hint=class\ ..\ :\ def\ __init__\ ...
class `ClassName^`$SPcls^(`$SParg`parent?`$SParg^):
    `__init__...{{^`:init:^`}}^


XPT init " def __init__
XSET arg*|post=ExpandInsideEdge( ',$SPcm', '' )
def __init__`$SPfun^(`$SParg^self`,$SPcm`arg*^`$SParg^):
    `cursor^


XPT ifmain hint=if\ __name__\ ==\ __main__
if __name__`$SPop^==`$SPop^"__main__":
    `cursor^

XPT with hint=with\ ..\ as\ ..\ :
with `opener^ as `name^:
    `cursor^


XPT import hint=import\ ..
import `mod^` as `name?^


XPT from hint=from\ ..\ import\ ..
from `module^ import `item^` as `name?^


XPT fromfuture hint=from\ __future__\ import\ ..
from __future__ import `name^


XPT genExp hint=\(func\(x)\ for\ x\ in\ seq)
(`$SPar^`:generator:^`$SPar^)


XPT listComp hint=\[func\(x)\ for\ x\ in\ seq]
[`$SPar^`:generator:^`$SPar^]




XPT generator hidden " generator
XSET ComeFirst=elem seq func
`func^`func^python_genexpr_cmpl('elem')^ for `elem^ in `seq^` if `condition?^


XPT args hidden " expandable arguments
XSET arg*|post=ExpandInsideEdge( ',$SPcm', '' )
`$SParg`arg*`$SParg^


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
