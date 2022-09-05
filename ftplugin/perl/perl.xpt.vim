XPTemplate priority=lang

let s:f = g:XPTfuncs()

XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL
XPTvar $UNDEFINED

XPTvar $VOID_LINE     # void;
XPTvar $CURSOR_PH     # cursor

XPTvar $BRif          ' '
XPTvar $BRel   \n
XPTvar $BRloop        ' '
XPTvar $BRstc         ' '
XPTvar $BRfun         ' '

XPTinclude
      \ _common/common

XPTvar $CS #
XPTinclude
      \ _comment/singleSign

XPTvar $VAR_PRE    $
XPTvar $FOR_SCOPE  'my '
XPTinclude
      \ _loops/for

XPTinclude
      \ _loops/c.while.like
	  \ _printf/c.like


" ========================= Function and Variables =============================


" ================================= Snippets ===================================


" perl has no NULL value
XPT fornn hidden=1

XPT whilenn hidden=1

" Not perl's way of doing things
XPT while1 hidden=1
XPT while0 hidden=1


XPT perl " #!/usr/bin/env perl
#!/usr/bin/env perl

use strict;
use warnings;


..XPT

XPT iff " if \( .. ) {{ .. }}
if`$SPcmd^(`$SParg^`condition^`$SParg^)`$BRif^{{
	`cursor^
}}

XPT whenn " when \( .. ) {{ .. }}
when`$SPcmd^(`$SParg^m/`regex^/`$SParg^)`$BRif^{{
	`cursor^
}}

XPT unlesss " unless \( .. ) {{ .. }}
unless`$SPcmd^(`$SParg^`condition^`$SParg^)`$BRif^{{
	`cursor^
}}

XPT sub " sub \( .. ) { .. }
XSET arg*|post=ExpandInsideEdge(', ', '')
sub `fun_name^`(`arg*`)^ {
	`cursor^
}

XPT subp " sub :prototype\( .. ) \( .. ) { .. }
XSET arg*|post=ExpandIfNotEmpty(', ', 'arg*')
sub `fun_name^ :prototype(`proto^) (`$SParg^`arg*^`$SParg^)`$BRfun^{
	`cursor^
}

XPT proto " sub .. \();
sub `fun_name^ (`proto^);

XPT unless " unless \( .. ) { .. }
unless`$SPcmd^(`$SParg^`cond^`$SParg^)`$BRif^{
	`cursor^
}

XPT eval wrap=risky " eval { .. };if...
eval`$BRif^{
	`risky^
};
if`$SPcmd^(`$SParg^$@`$SParg^)`$BRif^{
	`handle^
}

XPT _finally hidden 
finally`$BRif^{
	`cursor^
}

XPT try wrap=risky " try \( .. ) { .. } ...
try`$SPcmd^(`$SParg^`cond^`$SParg^)`$BRif^{
	`risky^
}`
catch`$SPcmd^(`$SParg^`except^`$SParg^)`$BRif^{
    `throw^
}
`finally...{{^`Include:_finally^`}}^

XPT defer " defer { .. }
defer`$BRif^{
	`cursor^
}

XPT block " { .. }
{
	`cursor^
}

XPT label " LABEL: { .. }
`LABEL^:`$BRif^{
	`cursor^
}

XPT _continue hidden
continue`$BRif^{
	`job^
}

XPT while " while \( \$line = <FILE>  )
while`$SPcmd^(`$SParg^`condition^`$SParg^)`$BRloop^{
	`cursor^
}
`continue...{{^`Include:_continue^`}}^

XPT while " while \( .. ) { .. }
while`$SPcmd^(`$SParg^`condition^`$SParg^)`$BRloop^{
	`cursor^
}
`continue...{{^`Include:_continue^`}}^

XPT until " until \( ... ) { .. }
until`$SPcmd^(`$SParg^`condition^`$SParg^)`$BRloop^{
	`cursor^
}
`continue...{{^`Include:_continue^`}}^

XPT _while hidden
`$BRloop^`while^ `condition^

XPT do wrap " do { .. } while ( .. )
do`$BRloop^{
    `cursor^
}`loop...{{^`Include:_while^`}}^;

XPT whileeach " while \( my \( key, val ) = hash )
while`$SPcmd^(`$SParg^my (`$SParg^$`key^,`$SPop^$`val^`$SParg^) = `hash^`$SParg^)`$BRloop^{
	`cursor^
}
`continue...{{^`Include:_continue^`}}^


XPT whileline " while \( my \$line = <FILE>  )
while`$SPcmd^(`$SParg^my $`line^`$SPop^=`$SPop^<`STDIN^>`$SParg^)`$BRloop^{
	`cursor^
}
`continue...{{^`Include:_continue^`}}^

XPT foreachx " foreach my .. \( .. ) { .. }
foreach`$SPcmd^my $`var^ (`$SParg^`list^`$SParg^)`$BRloop^{
	`cursor^
}
`continue...{{^`Include:_continue^`}}^

XPT foreachi " foreach my .. \( .. ) { .. }
foreach`$SPcmd^my (`$SParg^$`var^, $`var2^`$SParg^) (`$SParg^indexed `list^`$SParg^)`$BRloop^{
	`cursor^
}
`continue...{{^`Include:_continue^`}}^

XPT foreachy " foreach \( .. ) { .. } 
foreach`$SPcmd^(`$SParg^`list^`$SParg^)`$BRloop^{
	`cursor^
}
`continue...{{^`Include:_continue^`}}^

XPT grep " grep { .. } ..
grep`$BRloop^{ `block^ } `list^

XPT sort " sort { .. } ..
sort `$BRloop^{ `block^ }, `list^

XPT map " map { .. } ..
map`$BRloop^{ `block^ } `list^

XPT split " split /../, ..
split m/`regex^/, `string^

XPT join " split .., ..
join `string^, `list^

XPT bar " __XXX__
__`cursor^__

XPT open wrap=path " open .., .., ..
open my $`fh^, "`mode^", $`path^ or die "open: $!\n";

XPT opendir wrap=path " opendir .., .., ..
opendir my $`dh^, $`path^ or die "opendir: $!\n";

XPT _printfElts hidden 
XSET elts|pre=Echo('')
XSET elts=c_printf_elts( R( 'pattern' ), ',' )
"`pattern^"`elts^

XPT printf	" printf ...
printf `:_printfElts:^

XPT sprintf	" sprintf ...
sprintf `:_printfElts:^

XPT _if hidden
if`$SPcmd^(`$SParg^`condition^`$SParg^)`$BRif^{
	`cursor^
}

XPT if wrap " if \( .. ) { .. }
`Include:_if^

XPT elif wrap " else if \( .. ) { .. }
els`Include:_if^

XPT else wrap " else { ... }
else`$BRif^{
	`cursor^
}

XPT ifee		" if \( .. ) { .. } else if...
`:_if:^` `else_if...{{^`$BRel^`Include:elif^``else_if...^`}}^
`else...{{^`Include:else^`}}^

XPT _when hidden
when`$SPcmd^(`$SParg^m/`regex^/`$SParg^)`$BRif^{
    `cursor^
}

XPT _default hidden
default {
    `cursor^
}

XPT when " when \( .. ) { .. } ...
`:_when:^` `when...{{^`$BRel^`Include:_when^``when...^`}}^
`default...{{^`Include:_default^`}}^

XPT given wrap=var " given \( .. ) { .. }
given`$SPcmd^(`$SParg^$`var^^`$SParg^)`$BRif^{
	`cursor^
}

XPT use " use .. qw\(...);
use `module^ qw(`cursor^);

XPT package " package
package `className^;

use strict;
use warnings;

sub new`$BRfun^{
	my $class = shift;
	`my^
	my $self  = {}; 

	`body^
	bless $self, $class;
	return $self;
}

1;

`__END__^
..XPT

