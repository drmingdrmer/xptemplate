XPTemplate priority=lang mark=~^

let [s:f, s:v] = XPTcontainer() 
 
XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL
XPTvar $VOID_LINE /* void */;
XPTvar $IF_BRACKET_STL \n

XPTinclude 
      \ _common/common
      \ _common/personal


" ========================= Function and Variables =============================


" ================================= Snippets ===================================

call XPTemplate('sh', "#!/bin/sh\n")
call XPTemplate('bash', "#!/bin/bash\n")
call XPTemplate('echodate', 'echo `date +~fmt^`')

call XPTemplate('forin', [
      \"for ~i^ in ~list^;do", 
      \"  ~cursor^", 
      \"done"
      \])

call XPTemplate('for', [
      \"for ((~i^ = 0; ~i^ < ~len^; ~i^++));do", 
      \"  ~cursor^", 
      \"done"
      \])

call XPTemplate('forr', [
      \'for ((~i^ = ~n^; ~i^ >~=^ ~start^; ~i^~--^));do', 
      \"  ~cursor^", 
      \"done"
      \])

call XPTemplate('while1', [
      \'while [ 1 ];do', 
      \'  ~cursor^', 
      \'done'
      \])

call XPTemplate('case', [
      \'case $~i^ in', 
      \'  ~c^)', 
      \'  ~cursor^', 
      \'  ;;', 
      \'', 
      \'  *)', 
      \'  ;;', 
      \'esac'
      \])


XPTemplateDef
