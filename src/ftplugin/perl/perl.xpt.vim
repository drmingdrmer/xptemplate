XPTemplate priority=lang

let [s:f, s:v] = XPTcontainer() 
 
XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL
XPTvar $INDENT_HELPER /* void */;
XPTvar $IF_BRACKET_STL \n

XPTvar $CS #

XPTinclude 
      \ _common/common
      \ _comment/singleSign


" ========================= Function and Variables =============================


" ================================= Snippets ===================================
XPTemplateDef 




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


XPT while hint=while\ (\ ..\ )\ {\ ..\ }
while (`cond^) {
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


XPT for hint=for\ (my\ ..;..;++)
for (my $`var^ = 0; $`var^ < `count^; $`var^++) {
    `cursor^
}


XPT foreach hint=foreach\ my\ ..\ (..){}
foreach my $`var^ (@`array^) {
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
    `body^
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


