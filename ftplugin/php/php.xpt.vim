XPTemplate priority=lang keyword=# indent=auto

" containers
let [s:f, s:v] = XPTcontainer()

XPTvar $TRUE TRUE
XPTvar $FALSE FALSE
XPTvar $BRACKETSTYLE \n
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
while (`cond^)`$BRACKETSTYLE^{
  `cursor^
}


XPT for hint=for\ (..;..;++)
for ($`var^i^ = `init^; $`var^ < `val^; $`var^++)`$BRACKETSTYLE^{
  `cursor^
}


XPT forr hint=for\ (..;..;--)
for ($`var^i^ = `init^; $`var^ >= `val^0^; $`var^--)`$BRACKETSTYLE^{
  `cursor^
}


XPT foreach hint=foreach\ (..\ as\ ..)\ {..}
foreach ($`var^ as `container^)`$BRACKETSTYLE^{
  `cursor^
}


XPT fun hint=function\ ..(\ ..\ )\ {..}
function `funName^( `params^ )`$BRACKETSTYLE^{
  `cursor^
}


XPT class hint=class\ ..\ {\ ..\ }
class `className^`$BRACKETSTYLE^{
  function __construct( `args^ )`$BRACKETSTYLE^{
    `cursor^
  }
}


XPT interface hint=interface\ ..\ {\ ..\ }
interface `interfaceName^`$BRACKETSTYLE^{
  `cursor^
}


