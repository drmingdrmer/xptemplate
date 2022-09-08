XPTemplate priority=lang

let s:f = g:XPTfuncs()

XPTinclude
      \ _common/common

XPT _included
-`x^=
    `y^=
    `cursor^=

XPT including
-`:_included:^=

XPT inc-cursor
-`Include:_included^=

XPT inc-set-def
XSET y=y-def
-`:_included:^=


XPT _inc-y
XSET y=y-included
-`y^=

XPT inc-override-def
XSET y=y-def
-`:_inc-y:^=

XPT inc-inherit-def
-`:_inc-y:^=

XPT _inc-x
-`x^=

XPT inc-param
-`Include:_inc-x({"x":"x-2"})^=
