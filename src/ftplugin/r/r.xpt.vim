XPTemplate priority=lang

let s:f = g:XPTfuncs()

" use snippet 'varConst' to generate contant variables
" use snippet 'varFormat' to generate formatting variables
" use snippet 'varSpaces' to generate spacing variables


XPTinclude
      \ _common/common
      \ _condition/c.like


XPT for " for (... in ...) { ... }
for (`name^ in `vec^)
{
    `cursor^
}

XPT while " while ( ... ) { ... }
while ( `cond^ )
{ 
    `cursor^
}

XPT fun " ... <- function ( ... , ... ) { ... }
`funName^ <- function( `args^ )
{ 
    `cursor^
}

XPT operator " %...% <- function ( ... , ... ) { ... }
%`funName^% <- function( `args^ )
{ 
    `cursor^
}

