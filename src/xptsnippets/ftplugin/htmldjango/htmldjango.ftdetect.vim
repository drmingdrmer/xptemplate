XPTemplate priority=lang-2


if &filetype !~ '\v^htmldjango$'
    finish
endif


" TODO use array instead of dict because of duplicated key could be possible
let s:skipPattern = 'synIDattr(synID(line("."), col("."), 0), "name") =~? "\\vstring|comment"'
let s:pattern = {
            \   'django'    : {
            \       'start' : '\V\c{%',
            \       'mid'   : '',
            \       'end'   : '\V\c%}',
            \       'skip'  : s:skipPattern,
            \   },
            \   'django_expr'    : {
            \       'start' : '\V\c{{',
            \       'mid'   : '',
            \       'end'   : '\V\c}}',
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

let s:topFT = 'html'

fun! XPT_htmldjangoFiletypeDetect() "{{{

    echom 'called'

    let pos = [ line( "." ), col( "." ) ]

    let synName = xpt#util#NearestSynName()

    echom 'synName=' . string( synName )

    if synName == ''

        return s:topFT

    else

        for [ name, ftPattern ] in items( s:pattern )
            let pos = searchpairpos( ftPattern.start, ftPattern.mid, ftPattern.end, 'nbW', ftPattern.skip )
            if pos != [0, 0]
                echom 'matched:' . string( [ pos, name ] )
                return name
            endif
        endfor

        echom 'no pair:' . synName

        if synName =~ '\v^\cjavascript'
            return 'javascript'
        elseif synName =~ '\v^\ccss'
            return 'css'
        endif

        return s:topFT

    endif

endfunction "}}}

call xpt#ng#SetFiletypeDetector( 'XPT_htmldjangoFiletypeDetect' )
