XPTemplate mark={}

let s:f = g:XPTfuncs() 

XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL

XPTvar $VOID_LINE  /* void */;
XPTvar $CURSOR_PH      CURSOR

XPTvar $IF_BRACKET_STL     \ 
XPTvar $ELSE_BRACKET_STL   \n
XPTvar $FOR_BRACKET_STL    \ 
XPTvar $WHILE_BRACKET_STL  \ 
XPTvar $STRUCT_BRACKET_STL \ 
XPTvar $FUNC_BRACKET_STL   \ 




" ========================= Function and Variables =============================

" ================================= Snippets ===================================
XPTemplateDef




XPT main
int main(int argc, const char *argv[])
\{
    {}
    return 0;
\}
XPT inc
#include <{stdio}.h>{}
XPT Inc
#include "{`Filename("$1.h")`}"{}
XPT Def
#ifndef $1
#define {SYMBOL} {value}
#endif{}
XPT def
#define 
XPT ifdef
#ifdef {FOO}
    {#define }
#endif
XPT #if
#if {FOO}
    {}
#endif
XPT once
#ifndef {`toupper(Filename('', 'UNTITLED').'_'.system("/usr/bin/ruby -e 'print (rand * 2821109907455).round.to_s(36)'"))`}

#define $1

{}

#endif /* end of include guard: $1 */
XPT if
if ({/* condition */}) \{
    {/* code */}
\}
XPT el
else \{
    {}
\}
XPT t
{/* condition */} ? {a} : {b}
XPT do
do \{
    {/* code */}
\} while ({/* condition */});
XPT wh
while ({/* condition */}) \{
    {/* code */}
\}
XPT for
for ({i} = 0; $2 < {count}; $2{++}) \{
    {/* code */}
\}
XPT forr
for ({i} = {}; {$1 < 10}; $1{++}) \{
    {/* code */}
\}
XPT fun
{void} {function_name}({})
\{
    {/* code */}
\}
XPT fund
{void} {function_name}({});{}
XPT td
typedef {int} {MyCustomType};{}
XPT st
struct {`Filename('$1_t', 'name')`} \{
    {/* data */}
\}{ /* optional variable list */};{}
XPT tds
typedef struct {_$1 }\{
    {/* data */}
\} {`Filename('$1_t', 'name')`};
XPT tde
typedef enum \{
    {/* data */}
\} {foo};
XPT pr
printf("{%s}\n"{});{}
XPT fpr
fprintf({stderr}, "{%s}\n"{});{}
XPT .
[{}]{}
XPT un
unsigned
