XPTemplate priority=lang
let s:f = g:XPTfuncs()
XPTinclude
      \ _common/common

XPT pre-no-arg
XSET x|pre=Next()
(`x^)

XPT pre-text
XSET x|pre=Next('user-text')
(`x^)

XPT pre-snippet-text
XSET x|pre=Next('`a^-`a^')
(`x^)


XPT def-no-arg
XSET x=Next()
(`x^)

XPT def-text-one
XSET x=Next('user-text')
(`x^)

XPT def-snippet-text
XSET x=Next('`a^-`a^')
(`x^)


XPT instant-value-text
(`Next('x')^)

XPT instant-value-snippet-text
(`Next('\`a\^-\`a\^')^)


XPT post-no-arg
XSET x|post=Next()
(`x^)

XPT post-text
XSET x|post=Next('user-text')
(`x^)

XPT post-snippet-text
XSET x|post=Next('`a^-`a^')
(`x^)

