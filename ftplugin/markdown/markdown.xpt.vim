XPTemplate priority=lang mark=~^

let s:f = g:XPTfuncs()

" use snippet 'varConst' to generate contant variables
" use snippet 'varFormat' to generate formatting variables
" use snippet 'varSpaces' to generate spacing variables

fun! s:f.ExpandMarkdownTitle( char )
    let txt = self.R( 'sectionName' )
    let bar = repeat( a:char, len( txt ) )
    return txt . "\n" . bar . "\n"
endfunction

fun! s:f.ExpandMarkdownSubSection()
    return "### " . self.R( 'sectionName' )
endfunction

fun! s:f.Reminder( field )
    let txt = self.R( a:field )
    " Memory leak?
    let s:f[ '_markdown_snipp_' . a:field ] = txt
    return ''
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


XPT title synonym=h1 " ... ===
XSET sectionName|post=ExpandMarkdownTitle('=')
~sectionName^

XPT section synonym=h2 " ... ---
XSET sectionName|post=ExpandMarkdownTitle('-')
~sectionName^

XPT subsection synonym=h3 " ### ...
XSET sectionName|post=ExpandMarkdownSubSection()
~sectionName^

XPT link synonym=lnk " [...](...)
[~textLink^](~url^~ title...{{^ ~title^~}}^)

XPT img " ![...](...)
![~alt text^](~url^~ title...{{^ ~title^~}}^)

XPT ref " [...][...]
XSET url|post=Reminder('url')
XSET title|post=Reminder('title')
XSET cursor=BuildRef()
[~text^][~refId^]~url^~ title...{{^ ~title^~}}^~cursor^

XPT ruler synonym=hr " -----------------
---------------------------------------

