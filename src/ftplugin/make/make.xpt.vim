XPTemplate priority=lang

let s:f = g:XPTfuncs()

XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL

XPTvar $VOID_LINE  # void
XPTvar $CURSOR_PH      # cursor

XPTvar $CS    #

XPTinclude
      \ _common/common
      \ _comment/singleSign


" ========================= Function and Variables =============================


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
    `job^
``else...`
{{^else
    `cursor^
`}}^endif


XPT ifeq hint=ifneq\ ...\ else\ ...\ endif
XSET job=$CS job
ifeq (`what^, `with^)
    `job^
``else...`
{{^else
    `cursor^
`}}^endif


XPT basevar hint=CC\ ...\ CFLAG\ ..
`lang^C^C := `compiler^gcc^
`lang^C^FLAGS := `switches^-Wall -Wextra^


" ================================= Wrapper ===================================

XPT var_ hint=$(SEL)
$(`wrapped^)
