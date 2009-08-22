XPTemplate priority=lang keyword=<

let [s:f, s:v] = XPTcontainer() 
 
XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL
XPTvar $INDENT_HELPER /* void */;
XPTvar $IF_BRACKET_STL \n

XPTinclude 
      \ _common/common
      \ _comment/xml
      \ xml/xml
      \ xml/wrap


" ========================= Function and Variables =============================



fun! s:f.createTable(...) "{{{
  let nrow_str = inputdialog("num of row:")
  let nrow = nrow_str + 0

  let ncol_str = inputdialog("num of column:")
  let ncol = ncol_str + 0
  

  let l = ""
  let i = 0 | while i < nrow | let i += 1
    let j = 0 | while j < ncol | let j += 1
      let l .= "<tr>\n<td id=\"`pre^_".i."_".j."\"></td>\n</tr>\n"
    endwhile
  endwhile
  return "<table id='`id^'>\n".l."</table>"
endfunction "}}}


let s:doctypes = {
      \ 'HTML 3.2 Final'         :  '"-//W3C//DTD HTML 3.2 Final//EN"',
      \ 'HTML 4.0 Frameset'      :  '"-//W3C//DTD HTML 4.0 Frameset//EN" "http://www.w3.org/TR/REC-html40/frameset.dtd"',
      \ 'HTML 4.0 Transitional'  :  '"-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd"',
      \ 'HTML 4.0'               :  '"-//W3C//DTD HTML 4.0//EN" "http://www.w3.org/TR/REC-html40/strict.dtd"',
      \ 'HTML 4.01 Frameset'     :  '"-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd"',
      \ 'HTML 4.01 Transitional' :  '"-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd"',
      \ 'HTML 4.01'              :  '"-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd"',
      \ 'XHTML 1.0 Frameset'     :  '"-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd"',
      \ 'XHTML 1.0 Strict'       :  '"-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"',
      \ 'XHTML 1.0 Transitional' :  '"-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"',
      \ 'XHTML 1.1'              :  '"-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/1999/xhtml"',
      \}


fun! s:f.doctypePost(v)
  if has_key( s:doctypes, a:v )
    return s:doctypes[ a:v ]
  else
    return ''
  endif
endfunction

" ================================= Snippets ===================================


call XPTemplate("id", {'syn' : 'tag'}, 'id="`^"')
call XPTemplate("class", {'syn' : 'tag'}, 'class="`^"')



XPTemplateDef 



XPT table2
<table>
  <tr>
    <td>`text^^</td>`...2^
    <td>`text^^</td>`...2^
  </tr>`...0^
  <tr>
    <td>`text^^</td>`...1^
    <td>`text^^</td>`...1^
  </tr>`...0^
</table>
..XPT

XPT table3
<table id="`id^">`CntStart("i", "0")^
  <tr>`CntStart("j", "0")^
    <td id="`^R("id")_{Cnt("i")}_{CntIncr("j")}^">`text^^</td>`...2^
    <td id="`^R("id")_{Cnt("i")}_{CntIncr("j")}^">`text^^</td>`...2^
  </tr>`tr...^
  <tr>
    <td id="\`\^CntStart("j","0")R("id")_{CntIncr("i")}_{CntIncr("j")}\^">\`text\^\^</td>\`td...\^
    <td id="\\\`\\\^R("id")_{Cnt("i")}_{CntIncr("j")}\\\^">\\\`text\\\^\\\^</td>\\\`td...\\\^\^\^
  </tr>\`tr...\^^^
</table>
..XPT

XPT table
`createTable()^


XPT html hint=<html><head>..<head><body>...
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=`encoding^utf-8^"/>
    <link rel="stylesheet" type="text/css" href="" />
    <style></style>
    <title>`title^E('%:r')^</title>
    <script language="javascript" type="text/javascript">
      <!-- -->
    </script>
  </head>
  <body>
    `cursor^
  </body>
</html>

XPT doctype hint=<!DOCTYPE\ ***
XSET doctype=ChooseStr( 'HTML 3.2 Final', 'HTML 4.0 Frameset', 'HTML 4.0 Transitional', 'HTML 4.0', 'HTML 4.01 Frameset', 'HTML 4.01 Transitional', 'HTML 4.01', 'XHTML 1.0 Frameset', 'XHTML 1.0 Strict', 'XHTML 1.0 Transitional', 'XHTML 1.1' )
XSET doctype|post=doctypePost( V() )
<!DOCTYPE html PUBLIC `doctype^>


XPT a hint=<a\ href...
<a href="`href^">`cursor^</a>
..XPT

XPT script hint=<script\ language="javascript"...
<script language="javascript" type="text/javascript">
`cursor^
</script>
..XPT

XPT scrlink hint=<script\ ..\ src=...
<script language="javascript" type="text/javascript" src="`cursor^"></script>

XPT div hint=<div>\ ..\ </div>
<div`^>`cursor^</div>


XPT p hint=<p>\ ..\ </p>
<p`^>`cursor^</p>


XPT ul hint=<ul>\ <li>...
<ul>
    <li>`val^</li>`...^
    <li>`val^</li>`...^
</ul>


XPT ol hint=<ol>\ <li>...
<ol>
    <li>`val^</li>`...^
    <li>`val^</li>`...^
</ol>


XPT br hint=<br\ />
<br/>


" <h1>`cr^^`cursor^`cr^^</h1>
XPT h hint=<h?>\ ..\ <h?>
XSET n=1
<h`n^>`cursor^</h`n^>




XPT p_ hint=
<p>`wrapped^</p>

XPT div_ hint=
<div>`wrapped^</div>

XPT h_ hint=<h?>\ ..\ </h?>
XSET n=1
<h`n^>`wrapped^</h`n^>



XPT a_ hint=<a\ href="">\ SEL\ </a>
<a href="">`wrapped^</a>


