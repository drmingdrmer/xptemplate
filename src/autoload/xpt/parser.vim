if exists( "g:__AL_XPT_PARSER_VIM__" ) && g:__AL_XPT_PARSER_VIM__ >= XPT#ver
    finish
endif
let g:__AL_XPT_PARSER_VIM__ = XPT#ver




let s:oldcpo = &cpo
set cpo-=< cpo+=B

fun! xpt#parser#Compact( lines ) "{{{

    let compacted = []

    let iSnipPart = match( a:lines, '\V\^XPT\s' )
    if iSnipPart < 0
        let iSnipPart = len( a:lines )
    endif


    let [ i, len ] = [ 0 - 1, iSnipPart - 1 ]
    while i < len | let i += 1
        let l = a:lines[ i ]
        if l != '' && l !~ '\v^"[^"]*$'
            call add( compacted, l )
        endif
    endwhile


    let [s, e, lastNonblank] = [-1, -1, 100000]

    let [ i, len ] = [ iSnipPart - 1, len( a:lines ) - 1 ]
    while i < len | let i += 1
        let l = a:lines[ i ]

        if l == '' || l =~ '\v^"[^"]*$'
            let lastNonblank = min([lastNonblank, i - 1])
            continue
        endif


        if l =~# '\V\^..XPT\>'

            if s == -1
                let [s, e, lastNonblank] = [-1, -1, 100000]
                continue

            else

                let compacted += a:lines[ s : i - 1 ]
                let [s, e, lastNonblank] = [-1, -1, 100000]

            endif

        elseif l =~# '\V\^XPT\>'

            if s == -1
                let [ s, lastNonblank ] = [ i, i ]
            else
                " template with no end
                let e = min([i - 1, lastNonblank])
                let compacted += a:lines[ s : e ]
                let [s, e, lastNonblank] = [i, -1, 100000]
            endif

        else
            let lastNonblank = i
        endif

    endwhile

    if s != -1
        let compacted += a:lines[ s : min([lastNonblank, i]) ]
    endif

    for l in compacted
        echom l
    endfor

    return compacted
endfunction "}}}

" fun! xpt#parser#Compile( lines ) "{{{
"     let x = b:xptemplateData

"     let iSnipPart = match( lines, '\V\^XPT\s' )

"     if iSnipPart < 0
"         return
"     endif

"     let lines = lines[ i : ]

"     " let x.snipFileScope = a:p.snipFileScope
"     let lines = lines


"     let [i, len] = [0, len(lines)]

"     call s:AdjustIndentWidth( lines )

"     " parse lines
"     " start end and blank start
"     let [s, e, blk] = [-1, -1, 100000]
"     while i < len-1 | let i += 1

"         let v = lines[i]

"         if v == '' || v =~ '\v^"[^"]*$'
"             let blk = min([blk, i - 1])
"             continue
"         endif


"         if v =~# '\V\^..XPT\>'

"             let e = i - 1
"             call s:XPTemplateParseSnippet(lines[s : e])
"             let [s, e, blk] = [-1, -1, 100000]

"         elseif v =~# '\V\^XPT\>'

"             if s != -1
"                 " template with no end
"                 let e = min([i - 1, blk])
"                 call s:XPTemplateParseSnippet(lines[s : e])
"                 let [s, e, blk] = [i, -1, 100000]
"             else
"                 let s = i
"                 let blk = i
"             endif

"         elseif v =~# '\V\^\\XPT'
"             let lines[i] = v[ 1 : ]
"         else
"             let blk = i
"         endif

"     endwhile

"     if s != -1
"         call s:XPTemplateParseSnippet(lines[s : min([blk, i])])
"     endif
    
" endfunction "}}}



" Converting indent to real space-chars( like spaces or tabs ) must be done at
" runtime.
" Here we only convert it to tabs, to ease further usage.
fun! xpt#parser#ConvertIndentToTab( snipLines ) "{{{

    let tabspaces = repeat( ' ', &tabstop )
    " let indentRep = repeat( '\1', &shiftwidth )
    let indentRep = '	'

    let cmdExpand = 'substitute(v:val, ''^\( *\)\1\1\1'', ''' . indentRep . ''', "g" )'

    call map( a:snipLines, cmdExpand )

endfunction "}}}
" getftime()

let &cpo = s:oldcpo
