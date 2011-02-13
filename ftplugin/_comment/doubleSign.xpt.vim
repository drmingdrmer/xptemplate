XPTemplate priority=all-

let s:f = g:XPTfuncs()

" snippets for language whose comment sign is 2 signs, like c:"/* */"
" TODO friendly cursor place holder

XPTinclude
      \ _common/common


XPT _d_comment hidden wrap=what		" $CL .. $CR
`$CL^ `what^^ `$CR^`^


XPT _d_commentBlock hidden wrap		" $CL ..
`$CL_STRIP^`$CM `cursor^
`$_xOFFSET$CM_OFFSET$CR^


XPT _d_commentDoc hidden wrap		" $CL$CM ..
`$CL^`$CM^
`$_xOFFSET^`$CM_OFFSET$CM `cursor^
`$_xOFFSET^`$CM_OFFSET$CR^


XPT _d_commentLine hidden wrap=what	" $CL .. $CR
XSET what=
`$CL `what` $CR^`^


XPT comment      alias=_d_comment
XPT commentBlock alias=_d_commentBlock
XPT commentDoc   alias=_d_commentDoc
XPT commentLine  alias=_d_commentLine

