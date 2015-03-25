XPTemplate priority=lang

let s:f = g:XPTfuncs()

fun! s:f.MakeIntType( n )
    let n = a:n
    return matchstr(n, '\v^u') . "int" . matchstr(n, '\v\d+$' )
endfunction

XPTvar $TRUE          true
XPTvar $FALSE         false
XPTvar $NULL          nil
XPTvar $UNDEFINED     nil

XPTvar $SParg      ''

XPTinclude
      \ _common/common
      \ _comment/c.like


XPT _dec hidden " $_xSnipName
`$_xSnipName^ 

XPT package alias=_dec
XPT import alias=_dec
XPT type alias=_dec
XPT const alias=_dec
XPT var alias=_dec

XPT _int " MakeIntType($_xSnipName)
`MakeIntType($_xSnipName)^

XPT i8  alias=_int
XPT i16 alias=_int
XPT i32 alias=_int
XPT i64 alias=_int
XPT u8  alias=_int
XPT u16 alias=_int
XPT u32 alias=_int
XPT u64 alias=_int

XPT struct " struct {
struct {
    `cursor^
}

XPT func wrap " func () int {
func `n^(`p?^)` `int?^ {
    `cursor^
}
XPT meth wrap " func (*T) () int {
func (`^) `n^(`p?^)` `int?^ {
    `cursor^
}
XPT go " go func (){}()
go func (`p?^) {
    `cursor^
}()
XPT tfunc " func Test
func Test`^(t *testing.T) {
    `cursor^
}
XPT bfunc " func Test
func Benchmark`^(b *testing.B) {
    `cursor^

    for ii := 0; i < b.N; i++ {
    }
}
XPT main " func main\()
func main() {
    `cursor^
}

XPT println " fmt.Println\()
fmt.Println( `^ )
XPT sprintf " fmt.Sprintf\()
fmt.Sprintf( `^ )

XPT forever " for ;;
for ;; {
    `cursor^
}
XPT for wrap " for i=0; i<10; i++
for `i^ := `0^; `i^ < `10^; `i^++ {
    `cursor^
}
XPT forr wrap " for i=10; i>=0; i--
for `i^ := `10^; `i^ >= `0^; `i^-- {
    `cursor^
}
XPT forrange wrap " for range
for `_^, `^ := range `^ {
    `cursor^
}
XPT forin wrap alias=forrange

XPT if wrap " if {
if `^ {
    `cursor^
}
XPT iftype wrap " if _, ok := x.(type); ok { ... }
if _, ok := `x^.( `tp^ ); ok {
    `cursor^
}
XPT _ifeq wrap hidden " if x == $v {
XSET $v=0
if `^ == `$v^ {
    `cursor^
}
XPT _ifne wrap hidden " if x != $v {
XSET $v=0
if `x^ != `$v^ {
    `cursor^
}
XPT iferr " if err != nil {
if err != nil {
    `cursor^
}
XPT ifn alias=_ifeq
XSET $v=nil
XPT ifnn alias=_ifne
XSET $v=nil
XPT if0 alias=_ifeq
XSET $v=0
XPT ifn0 alias=_ifne
XSET $v=0
XPT else
else {
    `cursor^
}

XPT mps " map[string]
map[`string^]`T^
XPT mpi " map[string]
map[`int^]`T^

XPT mkc " make\(chan X, n, capa?)
make(chan `bool^, `0^`, `capa?^)
XPT mks " make\([]X, n, capa?)
make([]`bool^, `0^`, `capa?^)
XPT mkm " make\(map[X]Y, n, capa?)
make(map[`string^]`bool^`, `capa?^)
XPT mkms " make\(map[string]Y, n, capa?)
make(map[string]`bool^`, `capa?^)

XPT sel " select
select {
case `^:
    `cursor^
}
XPT selc " select x <-ch
select {
case ``x?` := ^<-`ch^:
    `cursor^
}

XPT switch " switch x {
switch `^ {
case `^:
    `cursor^
}
XPT default " default:
default:
    `cursor^

XPT test " if .. t.Errorf
if `^ {} else {
    t.Errorf( `^ )
}
XPT ttype " if _, ok := x.(type); ok { ... }
if _, ok := `x^.( `tp^ ); ok {} else {
    t.Errorf( "Expect `x^ to be `tp^ but: %v", `x^ )
}
XPT assert " if .. t.Errorf
if `^ {} else {
    t.Fatalf( `^ )
}
