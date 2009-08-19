if exists("b:___LOOPS_C_FOR_LIKE_XPT_VIM__")
  finish
endif
let b:___LOOPS_C_FOR_LIKE_XPT_VIM__ = 1

" containers
let [s:f, s:v] = XPTcontainer()

" constant definition
call extend(s:v, {'$TRUE': '1', '$FALSE' : '0', '$NULL' : 'NULL', '$INDENT_HELPER' : '/* void */;'}, 'keep')

" inclusion

call XPTemplatePriority('like')

" ========================= Function and Varaibles =============================


" ================================= Snippets ===================================
XPTemplateDef

XPT for hint=for\ (..;..;++)
for (`i^ = `0^; `i^ < `len^; ++`i^)`$IF_BRACKET_STL^{
  `cursor^
}


XPT forr hint=for\ (..;..;--)
for (`i^ = `n^; `i^ >`=^ `end^; --`i^)`$IF_BRACKET_STL^{
  `cursor^
}


XPT forever hint=for\ (;;)\ ..
XSET body=$INDENT_HELPER
for (;;) `body^


