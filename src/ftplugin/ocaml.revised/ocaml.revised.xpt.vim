XPTemplate priority=lang

let s:f = g:XPTfuncs()

XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL

XPTvar $VOID_LINE  (* void *)
XPTvar $CURSOR_PH      (* cursor *)

XPTvar $BRif          ' '
XPTvar $BRloop        ' '
XPTvar $BRstc         ' '
XPTvar $BRfun         ' '

XPTvar $CL    (*
XPTvar $CM    *
XPTvar $CR    *)

XPTinclude
      \ _common/common
      \ _comment/doubleSign


" ========================= Function and Variables =============================

" ================================= Snippets ===================================
XPTemplateDef

XPT if hint=if\ ..\ then\ ..\ else\ ..
if `cond^
then `cursor^


XPT match hint=match\ ..\ with\ [..\ ->\ ..\ |\ ..]
match `expr^ with
  [ `what0^ -> `with0^`...^
  | `what^ -> `with^`...^
  ]


XPT moduletype hint=module\ type\ ..\ =\ sig\ ..\ end
module type `name^ `^ = sig
    `cursor^
end;


XPT module hint=module\ ..\ =\ struct\ ..\ end
XSET name|post=SV( '^\w', '\u&' )
module `name^ `^ = struct
    `cursor^
end;

XPT while hint=while\ ..\ do\ ..\ done
while `cond^ do
    `cursor^
done

XPT for hint=for\ ..\ to\ ..\ do\ ..\ done
XSET side=Choose(['to', 'downto'])
for `var^ = `val^ `side^ `expr^ do
    `cursor^
done

XPT class hint=class\ ..\ =\ object\ ..\ end
class `_^^ `name^ =
object (self)
    `cursor^
end;


XPT classtype hint=class\ type\ ..\ =\ object\ ..\ end
class type `name^ =
object
   method `field^ : `type^` `...^
   method `field^ : `type^` `...^
end;


XPT classtypecom hint=(**\ ..\ *)\ class\ type\ ..\ =\ object\ ..\ end
(** `class_descr^^ *)
class type `name^ =
object
   (** `method_descr^^ *)
   method `field^ : `type^` `...^
   (** `method_descr^^ *)
   method `field^ : `type^` `...^
end;


XPT typesum hint=type\ ..\ =\ ..\ |\ ..
XSET typeParams?|post=EchoIfNoChange( '' )
type `typename^` `typeParams?^ =
  [ `constructor^`...^
  | `constructor^`...^
  ];


XPT typesumcom hint=(**\ ..\ *)\ type\ ..\ =\ ..\ |\ ..
XSET typeParams?|post=EchoIfNoChange( '' )
(** `typeDescr^ *)
type `typename^` `typeParams?^ =
  [ `constructor^ (** `ctordescr^ *)`...^
  | `constructor^ (** `ctordescr^ *)`...^
  ];


XPT typerecord hint=type\ ..\ =\ {\ ..\ }
XSET typeParams?|post=EchoIfNoChange( '' )
type `typename^` `typeParams?^ =
    { `recordField^ : `fType^` `...^
    ; `recordField^ : `fType^` `...^
    };


XPT typerecordcom hint=(**\ ..\ *)type\ ..\ =\ {\ ..\ }
(** `type_descr^ *)
type `typename^ `_^^=
    { `recordField^ : `fType^ (** `desc^ *)`...^
    ; `otherfield^ : `othertype^ (** `desc^ *)`...^
    };


XPT try hint=try\ ..\ with\ ..\ ->\ ..
try `expr^
with [ `exc^ -> `rez^
`     `...`
{{^     | `exc2^ -> `rez2^
`     `...`
^`}}^     ]

XPT val hint=value\ ..\ :\ ..
value `thing^ : `cursor^

XPT ty hint=..\ ->\ ..
`t^`...^ -> `t2^`...^

XPT do hint=do\ {\ ..\ }
do {
    `cursor^
}

XPT begin hint=begin\ ..\ end
begin
    `cursor^
end

XPT fun hint=(fun\ ..\ ->\ ..)
(fun `args^ -> `^)

XPT func hint=value\ ..\ :\ ..\ =\ fun\ ..\ ->
value `funName^ : `ty^ =
fun `args^ ->
    `cursor^;


XPT letin hint=let\ ..\ =\ ..\ in
let `name^ `_^^ =
    `what^ `...^
and `subname^ `_^^ =
    `subwhat^`...^
in


XPT letrecin hint=let\ rec\ ..\ =\ ..\ in
let rec `name^ `_^^ =
    `what^ `...^
and `subname^ `_^^ =
    `subwhat^`...^
in

" ================================= Wrapper ===================================


XPT try_ hint=try\ SEL\ with\ ..\ ->\ ..
try
    `wrapped^
with [ `exc^ -> `rez^
`     `...`
{{^     | `exc2^ -> `rez2^
`     `...`
^`}}^     ]

