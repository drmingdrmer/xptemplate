" File Description {{{
" =============================================================================
" Snippet File scope
"                                                  by drdr.xp
"                                                     drdr.xp@gmail.com
" Usage :
"
" =============================================================================
" }}}
if exists( "g:__AL_XPT_SNIPF_VIM__" ) && g:__AL_XPT_SNIPF_VIM__ >= XPT#ver
    finish
endif
let g:__AL_XPT_SNIPF_VIM__ = XPT#ver




let s:oldcpo = &cpo
set cpo-=< cpo+=B

let s:log = xpt#debug#Logger( 'warn' )
let s:log = xpt#debug#Logger( 'debug' )


fun! xpt#snipf#New( filename ) "{{{

  let b:xptemplateData.snipFileScope = {
      \ 'filename'  : a:filename,
      \ 'ptn'       : {'l':'`', 'r':'^'},
      \ 'priority'  : g:xpt_priorities.lang,
      \ 'filetype'  : '',
      \ 'inheritFT' : 0,
      \}

  " TODO move this function out
  call RedefinePattern()

  return b:xptemplateData.snipFileScope
endfunction "}}}

fun! xpt#snipf#Push() "{{{
    let x = b:xptemplateData
    let x.snipFileScopeStack += [x.snipFileScope]

    unlet x.snipFileScope
endfunction "}}}

fun! xpt#snipf#Pop() "{{{
    let x = b:xptemplateData
    if len(x.snipFileScopeStack) > 0
        let x.snipFileScope = x.snipFileScopeStack[ -1 ]
        call remove( x.snipFileScopeStack, -1 )
    else
        throw "snipFileScopeStack is empty"
    endif
endfunction "}}}


let &cpo = s:oldcpo
