if exists("g:__HTML_FTDETECT_VIM__")
    finish
endif
let g:__HTML_FTDETECT_VIM__ = 1


if &filetype !~ 'html'
    finish
endif


fun! b:XPTfiletypeDetect() "{{{
    let pos = [ line( "." ), col( "." ) ]
    let synName = synIDattr(synID(pos[0], pos[1], 1), "name")

    if synName == ''
        let prevPos == searchpos( '\S', 'bWn' )
        if prevPos == [0, 0]
            return &filetype
        endif

        let synName = synIDattr(synID(prevPos[0], prevPos[1], 1), "name")
    else

    endif

endfunction "}}}
