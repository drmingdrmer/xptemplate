if exists("g:__PHP_FTDETECT_VIM__")
    finish
endif
let g:__PHP_FTDETECT_VIM__ = 1


if &filetype !~ 'php'
    finish
endif



let s:skipPattern = 'synIDattr(synID(line("."), col("."), 0), "name") =~? "string\|comment"'
let s:pattern = {
            \   'php'    : {
            \       'start' : '\V\c<?php\>',
            \       'mid'   : '',
            \       'end'   : '\V\c?>',
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

" php_noShortTags

fun! b:XPTfiletypeDetect() "{{{
    let pos = [ line( "." ), col( "." ) ]
    let synName = g:xptutil.XPTgetCurrentOrPreviousSynName()

    if synName == ''
        return 'html'

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



