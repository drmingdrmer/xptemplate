XPTemplate priority=lang

let s:f = g:XPTfuncs()

XPTinclude
      \ _common/common

XPT choose-1
XSET pum=Choose(["foo"])
choose-1:`pum^;

XPT choose-2
XSET pum=Choose(["foo", "for"])
choose-2:`pum^;
