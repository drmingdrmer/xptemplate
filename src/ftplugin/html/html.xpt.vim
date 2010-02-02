" TODO entity char
" TODO back at 'base'
XPTemplate priority=lang

let s:f = g:XPTfuncs()

XPTinclude
      \ _common/common
      \ xml/xml



XPTvar $CURSOR_PH 

XPTvar $CL    <!--
XPTvar $CM
XPTvar $CR    -->
XPTinclude
      \ _comment/doubleSign

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


fun! s:f.html_doctype_list()
    return keys( s:doctypes )
endfunction

fun! s:f.html_doctype_post(v)
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

fun! s:f.html_enc()
    return &fenc == '' ? &encoding : &fenc
endfunction

fun! s:f.html_cr_cmpl()
    let v = self.V()
    if v =~ '\V\^\n'
        return "\n"
    else
        return ''
    endif
endfunction
" ================================= Snippets ===================================


call XPTdefineSnippet("id", {'syn' : 'tag'}, 'id="`^"')
call XPTdefineSnippet("class", {'syn' : 'tag'}, 'class="`^"')



XPTemplateDef



XPT table " <table> ...<tr><td> ... </table>
<table>
    `Include:tr^` `tr...{{^
    `Include:tr^` `tr...^`}}^
</table>

XPT tr " <tr>\ ...
<tr>
    `Include:td^` `td...{{^
    `Include:td^` `td...^`}}^
</tr>

XPT td " <td>\ ...
<td>`^</td>

XPT th " <th>\ ...
<th>`^</th>



XPT table0 hidden=1
`createTable()^


XPT html " <html><head>..<head><body>...
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
    `:head:^
    <body>
        `cursor^
    </body>
</html>


XPT head " <head>..</head>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=`encoding^html_enc()^"/>
    <link rel="stylesheet" type="text/css" href="" />
    `:title:^
    <script language="javascript" type="text/javascript">
        <!-- -->
    </script>
</head>



XPT title " <title>..</title>
<title>`title^E('%:t:r')^</title>


XPT style " <style>..</style>
<style type="text/css" media="screen">
    `cursor^
</style>


XPT meta " <meta ..>
<meta name="`meta_name^" content="`meta_content^" />


XPT link " <link ..>
<link rel="`stylesheet^" type="`type^text/css^" href="`url^" />


XPT script " <script language="javascript"...
<script language="javascript" type="text/javascript">
    `cursor^
</script>
..XPT


XPT scriptsrc " <script .. src=...
<script language="javascript" type="text/javascript" src="`js^"></script>

XPT body " <body>..</body>
<body>
    `cursor^
</body>

XPT doctype " <!DOCTYPE ***
XSET doctype=html_doctype_list()
XSET doctype|post=html_doctype_post( V() )
<!DOCTYPE html PUBLIC `doctype^>


XPT a " <a href...
<a href="`href^">`cursor^</a>
..XPT


" TODO auto cr complete
XPT div " <div> .. </div>
XSET what=Echo('')
<div` `attr?^>`what^</div>


XPT p " <p> .. </p>
<p` `attr?^>`cursor^</p>


XPT ul " <ul> <li>...
<ul>
    <li>`val^</li>`...^
    <li>`val^</li>`...^
</ul>


XPT ol " <ol> <li>...
<ol>
    <li>`val^</li>`...^
    <li>`val^</li>`...^
</ol>


XPT br " <br />
<br />


" <h1>`cr^^`cursor^`cr^^</h1>
XPT h " <h?>\ ..\ <h?>
XSET n=1
<h`n^>`cursor^</h`n^>

XPT h1 alias=h " <h1>..</h1>
XSET n=Next('1')
XPT h2 alias=h " <h2>..</h2>
XSET n=Next('2')
XPT h3 alias=h " <h3>..</h3>
XSET n=Next('3')
XPT h4 alias=h " <h4>..</h4>
XSET n=Next('4')
XPT h5 alias=h " <h5>..</h5>
XSET n=Next('5')
XPT h6 alias=h " <h6>..</h6>
XSET n=Next('6')
..XPT



" TODO auto complete method
XPT form " <form ..>..</form>
<form action="`action^" method="`method^POST^" accept-charset="`html_enc()^">
    `cursor^
</form>

XPT textarea " <textarea></textarea>
<textarea name="`name^" rows="" cols="">`cursor^</textarea>


" TODO for different type of input generate attributes
XPT input " <input ..
XSET type=ChooseStr( 'text', 'password', 'checkbox', 'radio', 'submit', 'reset', 'file', 'hidden', 'image', 'button' )
<input type="`type^" name="`name^" value="`value^" />


XPT label " <lable for=".." ..
<label for="`which^">`what^</label>


XPT select " <select ..
<select name="`name^">
    `:option:^
</select>


XPT option " <option value=..
<option value="`value^">`what^</option>


XPT fieldset " <fieldset ..
<fieldset>
    <legend></legend>
    `cursor^
</fieldset>


XPT <_ " <..>SEL</..>
XSET span_disable|post=html_tagAttr()
<`span^>`wrapped^</`span^>


XPT p_ " <p>SEL</p>
<p>`wrapped^</p>

XPT div_ " <div>SEL</div>
<div>`wrapped^</div>

XPT h_ " <h?>SEL</h?>
XSET n=1
<h`n^>`wrapped^</h`n^>



XPT a_ " <a href="">SEL</a>
<a href="`^">`wrapped^</a>


