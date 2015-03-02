XPTemplate priority=lang

let s:f = g:XPTfuncs()

" Objective C can reuse all the C snippets, so include
" them by default.
XPTinclude
      \ _common/common
      \ c/c

XPT msg " [to ...]
[`to^ `msg^`args...{{^:`arg^`...{{^ `argName^:`argVal^`...^`}}^`}}^]

XPT forin " for (... in ...) { ... }
for (`type^id^ `var^ in `collection^)
{
    `cursor^
}

XPT import " #import "..."
#import "`hfile^"

XPT #import " #import <...>
#import <`hfile^>

XPT protocol " @protocol ... @end
@protocol `protocolName^
`cursor^
@end

XPT interface " @interface ... : ... ...
@interface `interfaceName^ `inherit...{{^ : `father^ `}}^{
    // put instances variable here
    `cursor^
}
// put methods here
@end

XPT implementation " @implementation ... @end
@implementation `className^
`cursor^
@end

XPT categorie " @interface ... (...) ... @end
@interface `existingClass^ (`categorieName^)
`cursor^
@end

XPT catimplem " @implementation ... (...) ... @end
@implementation `existingClass^ (`categorieName^)
`cursor^
@end

XPT alloc " [[... alloc] ...]
[[`className^ alloc] `cursor^]

XPT method " - (...) ....: ...
- (`retType^void^) `methodName^`args...{{^`...^ (`type^)name`...^`}}^;

XPT implmethod " - (...) ... {  ... }
- (`retType^) `methodName^ {
    `cursor^
}

XPT alloc " [[...  alloc] ...]
[[`className^  alloc] `cursor^]
