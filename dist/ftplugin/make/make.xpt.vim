if exists("g:__MAKE_XPT_VIM__")
    finish
endif
let g:__MAKE_XPT_VIM__ = 1

XPTinclude
    \ _common/common

" ================================= Snippets ===================================
XPTemplateDef

XPT addprefix hint=$(addprefix\ ...)
$(addprefix `prefix^, `elemList^)

XPT addsuffix hint=$(addsuffix\ ...)
$(addsuffix `suffix^, `elemList^)

XPT filterout hint=$(filter-out\ ...)
$(filter-out `toRemove^, `elemList^)

XPT patsubst hint=$(patsubst\ ...)
$(patsubst `sourcePattern^%.c^,  `destPattern^%.o^, `list^)

XPT shell hint=$(shell\ ...)
$(shell `command^)

XPT subst hint=$(subst\ ...)
$(subst `sourceString^, `destString^, `string^)

XPT wildcard hint=$(wildcard\ ...)
$(wildcard `globpattern^)

XPT ifneq hint=ifneq\ ...\ else\ ...\ endif
ifneq (`what^, `with^)
    `cursor^`else...^
else
^^
endif

XPT ifeq hint=ifneq\ ...\ else\ ...\ endif
ifeq (`what^, `with^)
    `cursor^`else...^
else
^^
endif

XPT basevar hint=CC\ ...\ CFLAG\ ..
`lang^C^C := `compiler^gcc^
`lang^C^FLAGS := `switches^-Wall -Wextra^


