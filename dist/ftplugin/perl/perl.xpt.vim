XPTemplate priority=lang

let s:f = g:XPTfuncs() 
 
XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          
XPTvar $UNDEFINED     

XPTvar $VOID_LINE     # void;
XPTvar $CURSOR_PH     # cursor

XPTvar $IF_BRACKET_STL     \ 
XPTvar $ELSE_BRACKET_STL   \n
XPTvar $FOR_BRACKET_STL    \ 
XPTvar $WHILE_BRACKET_STL  \ 
XPTvar $STRUCT_BRACKET_STL \ 
XPTvar $FUNC_BRACKET_STL   \ 

XPTinclude 
      \ _common/common

XPTvar $CS #
XPTinclude 
      \ _comment/singleSign

XPTvar $VAR_PRE    $
XPTvar $FOR_SCOPE  my\ 
XPTinclude 
      \ _loops/for

XPTinclude 
      \ _loops/c.while.like


" ========================= Function and Variables =============================


" ================================= Snippets ===================================
XPTemplateDef


" perl has no NULL value
XPT fornn hidden=1

XPT whilenn hidden=1


XPT perl hint=#!/usr/bin/env\ perl
#!/usr/bin/env perl

..XPT


XPT xif hint=..\ if\ ..;
`expr^ if `cond^;


XPT xwhile hint=..\ while\ ..;
`expr^ while `cond^;


XPT xunless hint=..\ unless\ ..;
`expr^ unless `cond^;


XPT xforeach hint=..\ foreach\ ..;
`expr^ foreach @`array^;


XPT sub hint=sub\ ..\ {\ ..\ }
sub `fun_name^`$FUNC_BRACKET_STL^{
    `cursor^
}


XPT unless hint=unless\ (\ ..\ )\ {\ ..\ }
unless (`cond^)`$IF_BRACKET_STL^{
    `cursor^
}


XPT eval hint=eval\ {\ ..\ };if...
eval`$IF_BRACKET_STL^{
    `risky^
};
if ($@)`$IF_BRACKET_STL^{
    `handle^
}

XPT try alias=eval hint=eval\ {\ ..\ };\ if\ ...




XPT whileeach hint=while\ \(\ \(\ key,\ val\ )\ =\ each\(\ %**\ )\ )
while ( ( $`key^, $`val^ ) = each( %`array^ ) )`$WHILE_BRACKET_STL^{
    `cursor^
}

XPT whileline hint=while\ \(\ defined\(\ \$line\ =\ <FILE>\ )\ )
while ( defined( $`line^ = <`STDIN^> ) )`$WHILE_BRACKET_STL^{
    `cursor^
}


XPT foreach hint=foreach\ my\ ..\ (..){}
foreach my $`var^ (@`array^)`$FOR_BRACKET_STL^{
    `cursor^
}


XPT forkeys hint=foreach\ my\ var\ \(\ keys\ %**\ )
foreach my $`var^ ( keys @`array^ )`$FOR_BRACKET_STL^{
    `cursor^
}


XPT forvalues hint=foreach\ my\ var\ \(\ keys\ %**\ )
foreach my $`var^ ( values @`array^ )`$FOR_BRACKET_STL^{
    `cursor^
}


XPT if hint=if\ (\ ..\ )\ {\ ..\ }\ ...
XSET job=$CS job
if ( `cond^ )`$IF_BRACKET_STL^{
    `job^
}`
`...^`$ELSE_BRACKET_STL^elsif ( `cond2^ )`$IF_BRACKET_STL^{
    `job^
}`
`...^`
`else...{{^`$ELSE_BRACKET_STL^else`$IF_BRACKET_STL^{
    `cursor^
}`}}^

XPT package hint=
package `className^;

use base qw(`parent^);

sub new`$FUNC_BRACKET_STL^{
    my $class = shift;
    $class = ref $class if ref $class;
    my $self = bless {}, $class;
    $self;
}

1;

..XPT


" ================================= Wrapper ===================================

XPT if_ hint=if\ (..)\ {\ SEL\ }\ ...
XSET job=$CS job
if ( `cond^ )`$IF_BRACKET_STL^{
    `wrapped^
}`
`...^`$ELSE_BRACKET_STL^elsif ( `cond2^ )`$IF_BRACKET_STL^{
    `job^
}`
`...^`
`else...{{^`$ELSE_BRACKET_STL^else`$IF_BRACKET_STL^{
    `cursor^
}`}}^


XPT eval_ hint=eval\ {\ ..\ };if...
eval`$IF_BRACKET_STL^{
    `wrapped^
};
if ($@)`$IF_BRACKET_STL^{
    `handle^
}

XPT try_ alias=eval_ hint=eval\ {\ ..\ };\ if\ ...
