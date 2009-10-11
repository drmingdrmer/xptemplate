" priority is a bit lower than 'spec'
XPTemplate priority=spec+


let s:f = g:XPTfuncs() 


" XPTvar $CL  Warn_$CL_IS_NOT_SET
" XPTvar $CM  Warn_$CM_IS_NOT_SET
" XPTvar $CR  Warn_$CR_IS_NOT_SET
" XPTvar $CS  Warn_$CS_IS_NOT_SET

" ================================= Snippets ===================================

if has_key(s:v, '$CL') && has_key(s:v, '$CR')

  call XPTemplate('cc', {'hint' : '$CL $CR'}, [ '`$CL^ `cursor^ `$CR^' ])
  call XPTemplate('cc_', {'hint' : '$CL ... $CR'}, [ '`$CL^ `wrapped^ `$CR^' ])

  " block comment
  call XPTemplate('cb', {'hint' : '$CL ...'}, [
        \'`$CL^', 
        \' `$CM^ `cursor^', 
        \' `$CR^' ])

  " block doc comment
  call XPTemplate('cd', {'hint' : '$CL$CM ...'}, [
        \'`$CL^`$CM^', 
        \' `$CM^ `cursor^', 
        \' `$CR^' ])

endif

" line comment
if has_key(s:v, '$CS')
  call XPTemplate('cl', {'hint' : '$CS'}, [ '`$CS^ `cursor^' ])

else
  call XPTemplate('cl', {'hint' : '$CL .. $CR'}, [ '`$CL^ `cursor^ `$CR^' ])

endif


