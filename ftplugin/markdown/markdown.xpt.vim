XPTemplate priority=lang mark=~^

let s:f = g:XPTfuncs()

fun! s:f.HeaderPref()
    let snipname = self.GetVar('$_xSnipName')
    let nr = snipname[ 1 : 1 ] * 1
    return repeat('#', nr)
endfunction

fun! s:f.UnderLine(char)
    let v = self.ItemValue()
    if v == ''
        return ''
    else
        " line break before "===" and after "==="
        return "\n" . repeat(a:char, len(v)) . "\n"
    endif
endfunction

fun! s:f.QuitContition()
    let v = self.ItemValue()
    if v == '' || v =~ '\V\n'
        let q = self.Next(substitute(v, '\V\n', '', 'g'))
        return q
    endif
endfunction

fun! s:f.BuildRef()
    let title = ''
    let id = self.R( 'refId' )

    let url = s:f[ '_markdown_snipp_url' ]
    unlet s:f[ '_markdown_snipp_url' ]

    if has_key( s:f, '_markdown_snipp_title' )
        let title = '"' . s:f[ '_markdown_snipp_title' ] . '"'
        unlet s:f[ '_markdown_snipp_title' ]
    endif

    call append( line('$'), '[' . id . ']: <' . url . '> ' . title )
    return '\n'
endfunction

XPTinclude
      \ _common/common

XPT sharp_header hidden " HeaderPref() title
~HeaderPref() ~t^

XPT h1 alias=sharp_header
XPT h2 alias=sharp_header
XPT h3 alias=sharp_header
XPT h4 alias=sharp_header
XPT h5 alias=sharp_header
XPT h6 alias=sharp_header

XPT header_alt hidden " ... repeat($decoration,3)
XSET $decoration==
XSET t|ontype=QuitContition()
~t^~t^UnderLine($decoration)^~^

XPT ha1 alias=header_alt
XSET $decoration==

XPT ha2 alias=header_alt
XSET $decoration=-

XPT title alias=ha1
XPT section alias=ha2
XPT subsection alias=h3


XPT link " [...](...)
[~text^](~url^~ ~title?^)

XPT img " ![...](...)
![~alt-text^](~url^~ ~title?^)

XPT ref " [...][...]
[~text^][~text^]

XPT def " [name]: url
[~refid^]: ~url^

XPT hr " ---
---

XPT checkbox " [ ]
[ ] ~cursor^

XPT - " -   xxx
-   ~cursor^

XPT ruler alias=hr

XPT table " | header | ... |
|     |     |
| :-- | --: |
|     |     |

