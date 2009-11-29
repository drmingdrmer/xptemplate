XPTemplate priority=lang

let s:f = g:XPTfuncs()

XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL
XPTvar $VOID_LINE /* void */;
XPTvar $BRif \n

XPTinclude
      \ _common/common


" ========================= Function and Variables =============================


" ================================= Snippets ===================================
XPTemplateDef


XPT acc hint=access
access 
..XPT

XPT ali hint=aliased
aliased 
..XPT

XPT beg hint=begin\ ..\ end;
begin
        `cursor^
end;
..XPT

XPT case hint=case\ ..\ is\ ..\ end\ case;
case `1^ is
        `cursor^
end case;
..XPT

XPT eli hint=elsif\ ..\ then\ ...
elsif `1^ then
        `cursor^
..XPT

XPT for hint=for\ ..\ in\ ..\ loop\ ...\ end\ loop;
for `1^ in `2^ loop
        `cursor^
end loop;
..XPT

XPT fun hint=function\ ..\ return\ ..\ is\ ..._ end;
function `1^name^ return `2^ is
        `3^
begin -- `1^
        `cursor^
end `1^;
..XPT

XPT if hint=if\ ..\ then\ ...\ end\ if;
if `1^ then
        `cursor^
end if;
..XPT

XPT loop hint=loop\ ..\ end\ loop;
loop
        `cursor^
end loop;
..XPT

XPT pbo hint=package\ body\ ..\ is\ ..\ end\ ;
package body `1^name^ is
        `cursor^
end `1^;
..XPT

XPT pac hint=package\ ..\ is\ ..\ end;
package `1^name^ is
        `cursor^
end `1^;
..XPT

XPT pne hint=package\ ..\ is\ ..
package `1^ is `cursor^
..XPT

XPT pro hint=procedure\ ..\ begin\ ..\ end;
procedure `1^Procedure^ is
        `2^
begin -- `mark^S(R('1'),'([a-zA-Z0-9_]*).*$','\1')^
        `cursor^
end `mark^;
..XPT

XPT rec hint=record\ ..\ end\ record;
record
        `cursor^
end record;
..XPT

XPT ret hint=return\ ..;
return `1^;
..XPT

XPT ty hint=type\ ..\ is\ ..;
type `1^ is `cursor^
..XPT

XPT u hint=use\ ..;
use `1^;
..XPT

XPT when hint=when\ ..\ =>\ ..
when `1^ =>
        `cursor^
..XPT

XPT whi hint=while\ ..\ loop\ ..\ end\ loop;
while `1^ loop
        `cursor^
end loop;
..XPT

XPT wu hint=with\ ..;\ use\ ..;
with `what^; use `1^;
`cursor^
..XPT

XPT w hint=with\ ..;
with `1^;
..XPT

