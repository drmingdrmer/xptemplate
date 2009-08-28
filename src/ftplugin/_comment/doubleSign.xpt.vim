XPTemplate priority=all


" snippets for language whose comment sign is 2 signs, like c:"/* */" 
" TODO friendly cursor place holder

XPTinclude 
      \ _comment/common


" ========================= Function and Variables =============================


" ================================= Snippets ===================================
XPTemplateDef 


XPT comment hint=$CL\ $CR
`$CL^ `cursor^ `$CR^


XPT comment_ hint=$CL\ $CR
`$CL^ `wrapped^ `$CR^

XPT commentBlock hint=$CL\ ...
`$CL^ 
 `$CM^ `cursor^
 `$CR^


XPT commentDoc hint=$CL$CM\ ...
`$CL^`$CM^ 
 `$CM^ `cursor^
 `$CR^

XPT commentLine hint=$CL\ ...\ $CR
`$CL^ `cursor^ `$CR^
