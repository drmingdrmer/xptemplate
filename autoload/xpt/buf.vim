exec xpt#once#init

let s:oldcpo = &cpo
set cpo-=< cpo+=B

fun! xpt#buf#New() "{{{

    if exists( 'b:xptemplateData' )
        return
    endif

    let b:xptemplateData = {
          \     'filetypes'         : {},
          \     'wrapStartPos'      : 0,
          \     'wrap'              : '',
          \     'savedReg'          : '',
          \     'snippetToParse'    : [],
          \     'abbrPrefix'        : {},
          \     'fallbacks'         : [],
          \     'posStack'          : [],
          \     'stack'             : [],
          \     'keyword'           : '\w',
          \     'keywordList'       : [],
          \     'snipFileScope'     : {},
          \     'snipFileScopeStack': [],
          \ }

    let b:xptemplateData.renderContext = xpt#rctx#New( b:xptemplateData )

    return b:xptemplateData

endfunction "}}}

fun! xpt#buf#Pushrctx() "{{{
    let x = b:xptemplateData

    call add( x.stack, x.renderContext )
    let x.renderContext = xpt#rctx#New( x )
endfunction "}}}

fun! xpt#buf#Poprctx() "{{{
    let x = b:xptemplateData
    let x.renderContext = remove(x.stack, -1)
endfunction "}}}

let &cpo = s:oldcpo
