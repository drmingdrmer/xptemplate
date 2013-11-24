finish
if exists( "g:__XPTEMPLATE_IMPORTER_VIM__" ) && g:__XPTEMPLATE_IMPORTER_VIM__ >= XPT#ver
    finish
endif
let g:__XPTEMPLATE_IMPORTER_VIM__ = XPT#ver



let fn = argv(0)

echom 'filename : ' . fn


let lines = readfile( fn )

for line in lines
    if line =~ '^#'
        " comment
        continue
    else
        if line =~ '^snippet'

    endif
endfor


quit
