XPTemplate priority=lang-


" TODO xhtml support

if &filetype !~ '\v^.?html$'
    finish
endif


let s:skipPattern = XPT#skipPattern
let s:pattern = {
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

fun! XPT_htmlFiletypeDetect() "{{{
    let pos = [ line( "." ), col( "." ) ]
    let synName = xpt#util#NearestSynName()

    if synName == ''
        " no character at current position or before curernt position
        return &filetype

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

        return &filetype

    endif

endfunction "}}}

call xpt#ng#SetFiletypeDetector( 'XPT_htmlFiletypeDetect' )

