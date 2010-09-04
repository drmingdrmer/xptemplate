if exists( "g:__HTMLDJANGO_FTDETECT_VIM__" )
    finish
endif
let g:__HTMLDJANGO_FTDETECT_VIM__ = 1



if &filetype !~ 'htmldjango'
    finish
endif


" TODO !!!!!!!!!!!

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

let s:topFT = 'html'

fun! XPT_htmldjangoFiletypeDetect() "{{{
    let pos = [ line( "." ), col( "." ) ]

    let synName = xpt#util#NearestSynName()

    if synName == ''

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

if exists( 'b:XPTfiletypeDetect' )
    unlet b:XPTfiletypeDetect
endif
let b:XPTfiletypeDetect = function( 'XPT_htmldjangoFiletypeDetect' )

