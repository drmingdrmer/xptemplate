XPTemplate priority=lang

let s:f = g:XPTfuncs()

" use snippet 'varConst' to generate contant variables
" use snippet 'varFormat' to generate formatting variables
" use snippet 'varSpaces' to generate spacing variables


XPTinclude
      \ _common/common


XPT package " package
package 

XPT import " import "*"
import 

" function

XPT func " func
func `name^(` `p?` ^)` `int?^ {
    `cursor^
}

XPT meth " func ( *T ) x 
func ( `^ ) `name^(` `p?` ^)` `int?^ {
    `cursor^
}

XPT tfunc " func Test
func Test`name^( t *testing.T ) {
    `cursor^
}

XPT main " func main\()
func main() {
    `cursor^
}

XPT println " fmt.Println\(  )
fmt.Println( `^ )

XPT sprintf " sprintf
fmt.Sprintf( `^ )


XPT for " for ;;
for `^; `cond^; `^ {
    `cursor^
}

XPT fori wrap " for i=0; i<len; i++
for `i^ = `0^; `i^ < `len^; `i^++ {
    `cursor^
}

XPT forrange wrap " for range
for `k^, `v^ := range `r^ {
    `cursor^
}

XPT forin wrap alias=forrange

XPT if " if { ... }
if `^ {
    `cursor^
}

XPT iftype " if _, ok := x.(type); ok { ... }
if _, ok := `x^.( `tp^ ); ok {
    `cursor^
}

XPT ifn " if x == nil
if `x^ == nil {
    `cursor^
}

XPT ifnn " if x != nil
if `x^ != nil {
    `cursor^
}

XPT else
else {
    `cursor^
}

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

