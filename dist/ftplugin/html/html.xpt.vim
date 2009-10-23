XPTemplate priority=lang keyword=<

let s:f = g:XPTfuncs() 
 
XPTinclude 
      \ _common/common

XPTvar $CL    <!--
XPTvar $CM    
XPTvar $CR    -->
XPTinclude 
      \ _comment/doubleSign

XPTinclude 
      \ xml/xml

XPTembed
      \ javascript/javascript
      \ css/css

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
      \ 'HTML 3.2 Final'         : '"-//W3C//DTD HTML 3.2 Final//EN"',
      \ 'HTML 4.0 Frameset'      : '"-//W3C//DTD HTML 4.0 Frameset//EN" "http://www.w3.org/TR/REC-html40/frameset.dtd"',
      \ 'HTML 4.0 Transitional'  : '"-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd"',
      \ 'HTML 4.0'               : '"-//W3C//DTD HTML 4.0//EN" "http://www.w3.org/TR/REC-html40/strict.dtd"',
      \ 'HTML 4.01 Frameset'     : '"-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd"',
      \ 'HTML 4.01 Transitional' : '"-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd"',
      \ 'HTML 4.01'              : '"-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd"',
      \ 'XHTML 1.0 Frameset'     : '"-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd"',
      \ 'XHTML 1.0 Strict'       : '"-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"',
      \ 'XHTML 1.0 Transitional' : '"-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"',
      \ 'XHTML 1.1'              : '"-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"',
      \ 'XHTML Basic 1.0'        : '"-//W3C//DTD XHTML Basic 1.0//EN" "http://www.w3.org/TR/xhtml-basic/xhtml-basic10.dtd"',
      \ 'XHTML Basic 1.1'        : '"-//W3C//DTD XHTML Basic 1.1//EN" "http://www.w3.org/TR/xhtml-basic/xhtml-basic11.dtd"',
      \ 'XHTML Mobile 1.0'       : '"-//WAPFORUM//DTD XHTML Mobile 1.0//EN" "http://www.wapforum.org/DTD/xhtml-mobile10.dtd"',
      \ 'XHTML Mobile 1.1'       : '"-//WAPFORUM//DTD XHTML Mobile 1.1//EN" "http://www.openmobilealliance.org/tech/DTD/xhtml-mobile11.dtd"',
      \ 'XHTML Mobile 1.2'       : '"-//WAPFORUM//DTD XHTML Mobile 1.2//EN" "http://www.openmobilealliance.org/tech/DTD/xhtml-mobile12.dtd"',
      \}


fun! s:f.doctypeList()
  return keys( s:doctypes )
endfunction

fun! s:f.doctypePost(v)
  if has_key( s:doctypes, a:v )
    return s:doctypes[ a:v ]
  else
    return ''
  endif
endfunction

" TODO do not apply to following place holder 
fun! s:f.html_tagAttr()
  let tagName = self.V()
  if tagName ==? 'a'
    return tagName . ' href="' . self.ItemCreate( '#', {}, {} ) . '"'
  " elseif tagName ==? 'div'
  " elseif tagName ==? 'table'
  else

    return tagName
  endif

endfunction
" ================================= Snippets ===================================


call XPTemplate("id", {'syn' : 'tag'}, 'id="`^"')
call XPTemplate("class", {'syn' : 'tag'}, 'class="`^"')



XPTemplateDef



XPT table
<table>
    `Include:tr^` `tr...{{^
    `Include:tr^` `tr...^`}}^
</table>

XPT tr hint=<tr>\ ...
<tr>
    `Include:td^` `td...{{^
    `Include:td^` `td...^`}}^
</tr>

XPT td hint=<td>\ ...
<td>`^</td>

XPT th hint=<th>\ ...
<th>`^</th>



XPT table0 hidden=1
`createTable()^


XPT html hint=<html><head>..<head><body>...
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=`encoding^Echo(&fenc == '' ? 'utf-8' : &fenc)^"/>
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
XSET doctype=doctypeList()
XSET doctype|post=doctypePost( V() )
<!DOCTYPE html PUBLIC `doctype^>


XPT a hint=<a\ href...
<a href="`href^">`cursor^</a>
..XPT


XPT div hint=<div>\ ..\ </div>
<div`^>`cursor^</div>


XPT p hint=<p>\ ..\ </p>
XSET attr?|post=EchoIfNoChange('')
<p` `attr?^>`cursor^</p>


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
<br />


" <h1>`cr^^`cursor^`cr^^</h1>
XPT h hint=<h?>\ ..\ <h?>
XSET n=1
<h`n^>`cursor^</h`n^>


XPT script hint=<script\ language="javascript"...
<script language="javascript" type="text/javascript">
    `cursor^
</script>
..XPT

XPT scrlink hint=<script\ ..\ src=...
<script language="javascript" type="text/javascript" src="`cursor^"></script>


XPT <_ hint=
XSET span_disable|post=html_tagAttr()
<`span^>`wrapped^</`span^>

XPT p_ hint=
<p>`wrapped^</p>

XPT div_ hint=
<div>`wrapped^</div>

XPT h_ hint=<h?>\ ..\ </h?>
XSET n=1
<h`n^>`wrapped^</h`n^>



XPT a_ hint=<a\ href="">\ SEL\ </a>
<a href="`^">`wrapped^</a>


