XPTemplate priority=like


XPTvar $BRstc         ' '


let s:f = g:XPTfuncs()


XPTemplateDef


XPT enum hint=enum\ {\ ..\ }
XSET postQuoter={,}
enum `name^`$BRstc^{
    `^
}


XPT struct abbr hint=struct\ {\ ..\ }
struct `structName^`$BRstc^{
    `^
}
