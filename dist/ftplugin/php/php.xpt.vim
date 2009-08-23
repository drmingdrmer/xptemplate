XPTemplate priority=lang-

" containers
let [s:f, s:v] = XPTcontainer()

XPTvar $TRUE TRUE
XPTvar $FALSE FALSE
XPTvar $IF_BRACKET_STL \n
XPTvar $NULL NULL

" inclusion
XPTinclude
      \ _common/common
      \ _condition/c.like
      \ _loops/c.like

" ========================= Function and Variables =============================

" ================================= Snippets ===================================
" Based on snipmate's php templates
XPTemplateDef

XPT while hint=while\ (\ ..\ )\ {\ ..\ }
while (`cond^)`$IF_BRACKET_STL^{
  `cursor^
}


XPT for hint=for\ (..;..;++)
for ($`var^i^ = `init^; $`var^ < `val^; $`var^++)`$IF_BRACKET_STL^{
  `cursor^
}


XPT forr hint=for\ (..;..;--)
for ($`var^i^ = `init^; $`var^ >= `val^0^; $`var^--)`$IF_BRACKET_STL^{
  `cursor^
}


XPT foreach hint=foreach\ (..\ as\ ..)\ {..}
foreach ($`var^ as `container^)`$IF_BRACKET_STL^{
  `cursor^
}


XPT fun hint=function\ ..(\ ..\ )\ {..}
function `funName^( `params^ )`$IF_BRACKET_STL^{
  `cursor^
}


XPT class hint=class\ ..\ {\ ..\ }
class `className^`$IF_BRACKET_STL^{
  function __construct( `args^ )`$IF_BRACKET_STL^{
    `cursor^
  }
}


XPT interface hint=interface\ ..\ {\ ..\ }
interface `interfaceName^`$IF_BRACKET_STL^{
  `cursor^
}


