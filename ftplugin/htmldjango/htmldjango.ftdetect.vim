if exists( "g:__HTMLDJANGO_FTDETECT_VIM__" )
    finish
endif
let g:__HTMLDJANGO_FTDETECT_VIM__ = 1


if &filetype !~ 'htmldjango'
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

let s:topFT = 'htmldjango'

fun! XPT_htmldjangoFiletypeDetect() "{{{
    let pos = [ line( "." ), col( "." ) ]

    let synName = g:xptutil.XPTgetCurrentOrPreviousSynName()

    if synName == ''

        return s:topFT

    else

        for [ name, ftPattern ] in items( s:pattern )
            let pos = searchpairpos( ftPattern.start, ftPattern.mid, ftPattern.end, 'nbW', ftPattern.skip )
            if pos != [0, 0]
                return name
            endif
        endfor

        if synName =~ '\v^\cjavascript'
            return 'javascript'
        elseif synName =~ '\v^\ccss'
            return 'css'
        endif

        return s:topFT

    endif

endfunction "}}}

if exists( 'b:XPTfiletypeDetect' )
    unlet b:XPTfiletypeDetect
endif
let b:XPTfiletypeDetect = function( 'XPT_htmldjangoFiletypeDetect' )

