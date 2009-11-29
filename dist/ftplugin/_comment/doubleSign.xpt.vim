XPTemplate priority=all-


" snippets for language whose comment sign is 2 signs, like c:"/* */"
" TODO friendly cursor place holder

XPTinclude
      \ _common/common


" ========================= Function and Variables =============================


" ================================= Snippets ===================================
XPTemplateDef


XPT comment hint=$CL\ $CR
`$CL^ `what^ `$CR^


XPT commentBlock hint=$CL\ ...
`$CL^
 `$CM^ `cursor^
 `$CR^


XPT commentDoc hint=$CL$CM\ ...
`$CL^`$CM^
 `$CM^ `cursor^
 `$CR^


XPT commentLine hint=$CL\ ...\ $CR
`$CL^ `what^ `$CR^

" ================================= Wrapper ===================================

XPT comment_ hint=$CL\ $CR
`$CL^ `wrapped^ `$CR^


XPT commentBlock_ hint=$CL\ ...
`$CL^
 `$CM^ `wrapped^
 `$CR^


XPT commentDoc_ hint=$CL$CM\ ...
`$CL^`$CM^
 `$CM^ `wrapped^
 `$CR^


XPT commentLine_ hint=$CL\ ...\ $CR
`$CL^ `wrapped^ `$CR^
