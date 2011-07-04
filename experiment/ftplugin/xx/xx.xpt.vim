XPTemplate priority=personal

let s:f = g:XPTfuncs()

XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL
XPTvar $VOID_LINE     /* void */;
XPTvar $BRif \n

XPTinclude
      \ _common/common

fun! s:f.build_choice( choices )
    let s:choice = s:f.Build( ( a:choices )[ s:f.V() ] )
    return s:choice
endfunction

fun! s:f.include_choice( choices )
    let s:choice = s:f.Build( '`:' . ( ( a:choices )[ s:f.V() ] ) . ':^' )
    return s:choice
endfunction

XPT _loop_conditional hidden
` `_loop_if_when_unless_popup^` `form^` `:_loop_selectable_clauses:^` `else...{{^` `:_loop_conditional_else:^`}}^
XSET _loop_if_when_unless_popup=ChooseStr( 'if', 'when', 'unless' )

XPT _loop_conditional_else hidden
else `:_loop_selectable_clauses:^

XPT _loop_unconditional_return hidden
 return` `_loop_form_or_it_popup^
XSET _loop_form_or_it_popup=ChooseStr( 'form', 'it' )
XSET _loop_form_or_it_popup|post=build_choice( { " form" : " `form^", " it" : " it" } )

XPT _loop_compound_forms hidden
`compound_form...{{^` `compound-form^` `compound_form...^`}}^

XPT _loop_do_or_doing hidden
` `_loop_do_or_doing_popup^` `:_loop_compound_forms:^
XSET _loop_do_or_doing_popup=ChooseStr( 'do', 'doing' )

XPT _loop_main_clause hidden
`_loop_main_clause_popup^
XSET _loop_main_clause_popup=ChooseStr( 'unconditional', 'accumulation', 'conditional', 'termination-test', 'initial-final' )
XSET _loop_main_clause_popup|post=include_choice( { " unconditional" : "_loop_unconditional", " conditional" : "_loop_conditional" } )

XPT _loop_selectable_clause hidden
` `_loop_selectable_clause_popup^
XSET _loop_selectable_clause_popup=ChooseStr( 'unconditional', 'accumulation', 'conditional' )
XSET _loop_selectable_clause_popup|post=include_choice( { " unconditional" : "_loop_unconditional", " conditional" : "_loop_conditional" } )

XPT _loop_selectable_clauses hidden
`selectable_clause...{{^`:_loop_selectable_clause:^` `selectable_clause...^`}}^

XPT _loop_unconditional hidden
` `_loop_unconditional_popup^
XSET _loop_unconditional_popup=ChooseStr( 'do or doing', 'return' )
XSET _loop_unconditional_popup|post=build_choice( { " do or doing" : "` `:_loop_do_or_doing:^", " return" : "` `:_loop_unconditional_return:^" } )

XPT loop " (loop ...)
(loop` `main_clause...{{^` `:_loop_main_clause:^` `main_clause...^`}}^)

XPT a
`x...{{^  `:b:^` `x...^`}}^

XPT b hidden
foo

XPT * " tips
this is *

XPT a* " tips
this is a*

XPT *ac " tips
this is *ac
XPT *ab " tips
this is *ab

