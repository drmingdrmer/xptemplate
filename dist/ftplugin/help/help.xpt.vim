XPTemplate priority=lang


" containers
let s:f = g:XPTfuncs()

" inclusion
XPTinclude
      \ _common/common

" ========================= Function and Variables =============================

" ================================= Snippets ===================================
XPTemplateDef

XPT ln hint=\ ========...
==============================================================================


XPT fmt hint=vim:\ options...
vim:tw=78:ts=8:sw=8:sts=8:noet:ft=help:norl:


XPT q hint=:\ >\ ...\ <
: >
	`cursor^
<


XPT r hint=|...|
|`content^|

