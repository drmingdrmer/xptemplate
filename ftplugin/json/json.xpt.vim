XPTemplate priority=lang

let s:f = g:XPTfuncs()

" use snippet 'varConst' to generate contant variables
" use snippet 'varFormat' to generate formatting variables
" use snippet 'varSpaces' to generate spacing variables


XPTinclude
      \ _common/common

XPT array " [ ..., ... ]
[ `val^`...^, `val^`...^ ]

XPT obj " { "...":... }
{ "`key^":`val^`...^, "`key^":`val^`...^ }

XPT dic " { "...":..., ... }
{ "`key^":`val^`...^,
  "`key^":`val^`...^
}

