XPTemplate priority=lang
let s:f = g:XPTfuncs()
XPTinclude
      \ _common/common

fun! s:f.noaction()
    return {}
endfunction

fun! s:f.err()
    let bla
endfunction

fun! s:f.text()
    return {"action": "text", "text": "text"}
endfunction

fun! s:f.build()
    return {"action": "build", "text": "xx`^"}
endfunction

fun! s:f.pum()
    return ["a", "b", "c"]
endfunction

XPTvar $HINT_VAR file_var

XPT hint-hint hint=hint=hint-hint

XPT quote-hint-0 "quote-hint
XPT quote-hint-1 " quote-hint
XPT quote-hint-2 "  quote-hint

XPT var-snip-name " $_xSnipName
XPT var-infile " $HINT_VAR
XPT var-insnip " $HINT_VAR
XSET $HINT_VAR=snip_var

XPT func-mixed " {$foo}tr("ab", "a", "A")bla{strlen("123")}
XSET $foo=bar

XPT origin " strlen("123")

XPT alias-nohint alias=origin
XPT alias-redefine-hint alias=origin " newhint-strlen("123")

XPT escape " tr\("a", "a", "A") \a \{ \$ \\a \\{ \\$foo
XSET $foo=bar
only escape [${(]

XPT action-func-noaction " noaction()
XPT action-func-err " err()
XPT action-func-text " text()
XPT action-func-build " build()
XPT action-func-pum " pum()

XPT mark " `^

