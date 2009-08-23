if exists("g:__WRAP_XPT_VIM__")
    finish
endif
let g:__WRAP_XPT_VIM__ = 1

XPTinclude
    \ _common/common

" ================================= Snippets ===================================
XPTemplateDef

XPT var_ hint=$(SEL)
$(`wrapped^)

