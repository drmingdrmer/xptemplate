XPTemplate priority=sub

" Setting priority of cpp to "sub" or "subset of language", makes it override
" all c snippet if conflict



XPTvar $TRUE          true
XPTvar $FALSE         false
XPTvar $NULL          NULL

XPTvar $IF_BRACKET_STL     \n
XPTvar $FOR_BRACKET_STL    \n
XPTvar $WHILE_BRACKET_STL  \n
XPTvar $STRUCT_BRACKET_STL \n
XPTvar $FUNC_BRACKET_STL   \n

XPTvar $VOID_LINE  /* void */;
XPTvar $CURSOR_PH      /* cursor */

XPTvar $CL  /*
XPTvar $CM   *
XPTvar $CR   */

XPTvar $CS   //



XPTinclude
      \ _common/common
      \ _comment/singleDouble
      \ _condition/c.like
      \ _func/c.like
      \ _loops/c.while.like
      \ _loops/java.for.like
      \ _preprocessor/c.like
      \ _structures/c.like
XPTinclude
            \ c/c

" ========================= Function and Varaibles =============================
let s:f = g:XPTfuncs() 

function! s:f.cleanTempl( ctx, ... )
  let notypename = substitute( a:ctx,"\\s*typename\\s*","","g" )
  let cleaned = substitute( notypename, "\\s*class\\s*", "", "g" )
  return cleaned
endfunction


" ================================= Snippets ===================================
XPTemplateDef

XPT all  hint=...begin,\ ...end,
`v^.begin(), `v^.end(), `cursor^
 

XPT vector hint=std::vector<..>\ ..;
std::vector<`type^> `var^;
`cursor^


XPT map hint=std::map<..,..>\ ..;
std::map<`typeKey^,`val^>   `name^;
`cursor^


XPT class   hint=class+ctor indent=keep
class `className^
{
public:
    `className^( `ctorParam^ );
    ~`className^();
    `className^( const `className^ &cpy );
    `cursor^
private:
};
 
`className^::`className^( `ctorParam^ )
{
}
 
`className^::~`className^()
{
}
 
`className^::`className^( const `className^ &cpy )
{
}
..XPT


XPT namespace hint=namespace\ {}
namespace `name^
{
    `cursor^
}
..XPT


XPT templateclass   hint=template\ <>\ class
template
    <`templateParam^>
class `className^
{
public:
    `className^( `ctorParam^ );
    ~`className^();
    `className^( const `className^ &cpy );
    `cursor^
private:
};
 
template <`templateParam^>
`className^<`_^cleanTempl(R('templateParam'))^^>::`className^( `ctorParam^ )
{
}
 
template <`templateParam^>
`className^<`_^cleanTempl(R('templateParam'))^^>::~`className^()
{
}
 
template <`templateParam^>
`className^<`_^cleanTempl(R('templateParam'))^^>::`className^( const `className^ &cpy )
{
}
..XPT

XPT try hint=try\ ...\ catch...
XSET handler=$CL void $CR
try
{
    `what^
}`...^
catch ( `except^ )
{
    `handler^
}`...^



XPT try_ hint=try\ {\ SEL\ }\ catch...
XSET handler=$CL void $CR
try
{
    `wrapped^
}
`...^catch ( `except^ )
{
    `handler^
}
`...^

..XPT
