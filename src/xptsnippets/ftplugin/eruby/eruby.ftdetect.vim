XPTemplate priority=lang-2


if &filetype !~ '\v^eruby$'
    finish
endif



let s:skipPattern = 'synIDattr(synID(line("."), col("."), 0), "name") =~? "\\vstring|comment"'
let s:pattern = {
            \   'ruby'    : {
            \       'start' : '\V\c<%',
            \       'mid'   : '',
            \       'end'   : '\V\c%>',
            \       'skip'  : s:skipPattern,
            \   },
            \   'javascript'    : {
            \       'start' : '\V\c<script\_[^>]\*>',
            \       'mid'   : '',
            \       'end'   : '\V\c</script>',
            \       'skip'  : s:skipPattern,
            \   },
            \   'css'           : {
            \       'start' : '\V\c<style\_[^>]\*>',
            \       'mid'   : '',
            \       'end'   : '\V\c</style>',
            \       'skip'  : s:skipPattern,
            \   },
            \}

let s:topFT = 'eruby'

fun! XPT_erubyFiletypeDetect() "{{{
    let pos = [ line( "." ), col( "." ) ]

    let synName = xpt#util#NearestSynName()

    if synName == ''
        " top level ft is html
        return s:topFT

    else

        for [ name, ftPattern ] in items( s:pattern )
            let pos = searchpairpos( ftPattern.start, ftPattern.mid, ftPattern.end, 'nbW', ftPattern.skip )
            if pos != [0, 0]
                return name
            endif
        endfor

        if synName =~ '^\cjavascript'
            return 'javascript'
        elseif synName =~ '^\ccss'
            return 'css'
        endif

        return s:topFT

    endif

endfunction "}}}

call xpt#ng#SetFiletypeDetector( 'XPT_erubyFiletypeDetect' )
