if exists("b:__LUA_XPT_VIM__")
  finish
endif
let b:__LUA_XPT_VIM__ = 1



" containers
let [s:f, s:v] = XPTcontainer()

" inclusion
XPTinclude
      \ _common/common

" ========================= Function and Variables =============================
" Remove an item if its value hasn't change
fun! s:f.RemoveIfUnchanged() "{{{
  let v = self.V()
  let [lft, rt] = self.ItemEdges()
  if v == lft . self.N() . rt
    return ''
  else
    return v
  end
endfunction "}}}

" ================================= Snippets ===================================

XPTemplateDef

XPT do hint=do\ ...\ end
do
`cursor^
end

XPT fn hint=function\ \(..) .. end
XSET arg..|post=ExpandIfNotEmpty(', ', 'arg..')
function (`arg..^) `cursor^ end

XPT for hint=for\ ..=..,..\ do\ ...\ end
XSET start=1
XSET end=10
XSET step|post=RemoveIfUnchanged()
for `var^ = `start^, `end^`, `step^ do
`cursor^
end

XPT forin hint=for\ ..\ in\ ..\ do\ ...\ end
XSET var..|post=ExpandIfNotEmpty(', ', 'var')
for `var..^ in `expr^ do
`cursor^
end

XPT forip hint=for\ ..,..\ in\ ipairs\(..)\ do\ ...\ end
XSET var1=i
XSET var2=v
for `var1^,`var2^ in ipairs(`table^) do
`cursor^
end

XPT forp hint=for\ ..,..\ in\ pairs\(..)\ do\ ...\ end
XSET var1=k
XSET var2=v
for `var1^,`var2^ in pairs(`table^) do
`cursor^
end

XPT fun hint=function\ ..\(..)\ ..\ end
XSET arg..|post=ExpandIfNotEmpty(', ', 'arg..')
function `name^(`arg..^)
`cursor^
end

XPT if hint=if\ ..\ then\ ..\ end
if `cond^ then
  `cursor^
end

XPT ife hint=if\ ..\ then\ ..\ else\ ..\ end
if `cond^ then
  `^
else
  `cursor^
end

XPT ifei hint=if\ ..\ then\ ..\ elseif\ ..\ else\ ..\ end
XSET elseif...|post=\nelseif `condn^ then\n`^`\n`elseif...^
XSET else...|post=\nelse\n  `cursor^
if `cond^ then
  `^
elseif `condn^ then
`^`
`elseif...^`
`else...^
end

XPT locf hint=local\ function\ ..\(..)\ ...\ end
XSET arg..|post=ExpandIfNotEmpty(', ', 'arg..')
local function `name^(`arg..^)
`cursor^
end

" !!! snippet ends with a space !!!
XPT locv hint=local\ ..\ =\ ..
local `var^ = 

XPT p hint=print\(..)
print(`cursor^)

" !!! snippet ends with a space !!!
XPT repeat hint=repeat\ ..\ until\ ..
repeat
`_^
until 

XPT while hint=while\ ..\ do\ ...\ end
while `cond^ do
  `cursor^
end
