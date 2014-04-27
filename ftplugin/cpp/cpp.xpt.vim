XPTemplate priority=sub

" Setting priority of cpp to "sub" or "subset of language", makes it override
" all c snippet if conflict



XPTvar $TRUE          true
XPTvar $FALSE         false
XPTvar $NULL          NULL

XPTvar $BRif     \n
XPTvar $BRloop    \n
XPTvar $BRloop  \n
XPTvar $BRstc \n
XPTvar $BRfun   \n

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

" ========================= Function and Variables =============================
let s:f = g:XPTfuncs()

function! s:f.cleanTempl( ctx, ... )
  let cleaned = substitute( a:ctx, '\s*\(class\|typename\|int\|long\)\s*', '', 'g' )
  return cleaned
endfunction


" ================================= Snippets ===================================

XPT all  " ..begin, ..end,
`v^.begin(), `v^.end(), `cursor^


XPT vector " std::vector<..> ..;
std::vector<`type^> `var^;
`cursor^


XPT map " std::map<..,..> ..;
std::map<`typeKey^,`val^>   `name^;
`cursor^

XPT class   " class ..
class `className^`$BRfun^{
public:
    `className^(`$SParg`ctorParam?`$SParg^);
    ~`className^();
    `className^(`$SParg^const `className^ &cpy`$SParg^);
    `cursor^
private:
};

`className^::`className^(`ctorParam?^)`$BRfun^{
}

`className^::~`className^()`$BRfun^{
}

`className^::`className^(`$SParg^gconst `className^ &cpy`$SParg^)`$BRfun^{
}
..XPT

XPT functor " class operator..
struct `className^
{
    `closure...{{^`type^  `what^;
    `_^R('className')^( `type^ n`what^ ) : `what^( n`what^ ) {}

    `}}^`outType^   operator() ( `params^ )
    {
        `cursor^
    }
};
..XPT

XPT namespace " namespace {}
namespace `name^
{
    `cursor^
}
..XPT

XPT icastop " operator type ..
operator `typename^ ()
    { return `cursor^; }
..XPT

XPT castop " operator type ..
operator `typename^ ();


`className^::operator `typename^ ();
    { return `cursor^; }
..XPT

XPT iop " t operator .. ()
`type^ operator `opName^ ( `args^ )`$BRfun^{
    `cursor^
}
..XPT

XPT op " t operator .. ()
`type^ operator `opName^ ( `args^ );

`type^ `className^::operator `opName^ ( `args^ )`$BRfun^{
}
..XPT

XPT templateclass   " template <> class
template
    <`templateParam^>
class `className^`$BRfun^{
public:
    `className^(`$SParg`ctorParam?`$SParg^);
    ~`className^();
    `className^(`$SParg^const `className^ &cpy`$SParg^);
    `cursor^
private:
};

template <`templateParam^>
`className^<`_^cleanTempl(R('templateParam'))^^>::`className^(`ctorParam?^)`$BRfun^{
}

template <`templateParam^>
`className^<`_^cleanTempl(R('templateParam'))^^>::~`className^()`$BRfun^{
}

template <`templateParam^>
`className^<`_^cleanTempl(R('templateParam'))^^>::`className^(`$SParg^gconst `className^ &cpy`$SParg^)`$BRfun^{
}
..XPT

XPT try wrap=what " try .. catch..
try
{
    `what^
}`$BRel^`Include:catch^

XPT catch " catch\( .. )
catch ( `except^ )
{
    `cursor^
}

XPT externc wrap " #ifdef C++.... extern "c"...
#ifdef __cplusplus
extern "C" {
#endif
`cursor^
#ifdef __cplusplus
}
#endif
..XPT

