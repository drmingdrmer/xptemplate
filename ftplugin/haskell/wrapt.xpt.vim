if exists("b:__HASKELL_WRAPT_XPT_VIM__") 
    finish 
endif
let b:__HASKELL_WRAPT_XPT_VIM__ = 1 

" containers
let [s:f, s:v] = XPTcontainer() 

" constant definition
call extend(s:v, {'$TRUE': '1', '$FALSE': '0', '$NULL': 'NULL', '$UNDEFINED': '', '$BRACKETSTYLE': "\n"})

" inclusion
XPTinclude
    \ _common/common

" ========================= Function and Variables =============================
call XPTemplateMark( '`', '~' )

" ================================= Snippets ===================================
XPTemplateDef 
XPT str_ hint="SEL"
"`wrapped~"

XPT cmt_ hint={-\ SEL\ -}
{-
`wrapped~
-}

XPT p_ hint=(\ SEL\ )
(`wrapped~)

