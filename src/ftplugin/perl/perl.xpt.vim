XPTemplate priority=lang

let [s:f, s:v] = XPTcontainer() 
 
XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL

XPTvar $INDENT_HELPER # void;
XPTvar $CURSOR_PH     # cursor

XPTvar $IF_BRACKET_STL     \n
XPTvar $FOR_BRACKET_STL    \n
XPTvar $WHILE_BRACKET_STL  \n
XPTvar $STRUCT_BRACKET_STL \n
XPTvar $FUNC_BRACKET_STL   \n

XPTvar $CS #

XPTinclude 
      \ _common/common
      \ _comment/singleSign
      \ _loops/c.while.like


" ========================= Function and Variables =============================


" ================================= Snippets ===================================
XPTemplateDef 



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
sub `fun_name^ {
    `cursor^
}


XPT unless hint=unless\ (\ ..\ )\ {\ ..\ }
unless (`cond^) {
    `cursor^
}


XPT eval hint=eval\ {\ ..\ };if...
eval {
    `risky^
};
if ($@) {
    `handle^
}


XPT whileeach hint=while\ \\(\ \\(\ key,\ val\ )\ =\ each\\(\ %**\ )\ )
while ( ( $`key^, $`val^ ) = each( %`array^ ) )`WHILE_BRACKET_STL^{
    `cursor^
}

XPT for hint=for\ (my\ ..;..;++)
for (my $`var^ = 0; $`var^ < `count^; $`var^++) {
    `cursor^
}


XPT foreach hint=foreach\ my\ ..\ (..){}
foreach my $`var^ (@`array^) {
    `cursor^
}


XPT forkeys hint=foreach\ my\ var\ \\(\ keys\ %**\ )
foreach my $`var^ ( keys @`array^ ) {
    `cursor^
}


XPT forvalues hint=foreach\ my\ var\ \\(\ keys\ %**\ )
foreach my $`var^ ( values @`array^ ) {
    `cursor^
}


XPT if hint=if\ (\ ..\ )\ {\ ..\ }\ ...
if ( `cond^ )
{
    `code^
}`
`...^
elif ( `cond2^ )
{
    `body^
}`
`...^`
`else...{{^
else
{
    `cursor^
}`}}^

XPT package hint=
package `className^;

use base qw(`parent^);

sub new {
    my $class = shift;
    $class = ref $class if ref $class;
    my $self = bless {}, $class;
    $self;
}

1;


