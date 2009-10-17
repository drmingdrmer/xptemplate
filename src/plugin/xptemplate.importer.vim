finish
if exists("g:__XPTEMPLATE_IMPORTER_VIM__")
    finish
endif
let g:__XPTEMPLATE_IMPORTER_VIM__ = 1


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
