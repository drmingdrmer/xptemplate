if exists("g:__XPTEMPLATE_CONF_VIM__")
  finish
endif
let g:__XPTEMPLATE_CONF_VIM__ = 1

let s:oldcpo = &cpo
set cpo-=< cpo+=B


runtime plugin/debug.vim

let s:escapeHead   = '\v(\\*)\V'
let s:unescapeHead = '\v(\\*)\1\\?\V'
let s:ep           = '\%(' . '\%(\[^\\]\|\^\)' . '\%(\\\\\)\*' . '\)' . '\@<='



fun! s:SetIfNotExist(k, v) "{{{
  if !exists(a:k)
    exe "let ".a:k."=".string(a:v)
  endif
endfunction "}}}



" call s:SetIfNotExist('g:xptemplate_protect'           , 1	)
" call s:SetIfNotExist('g:xptemplate_limit_curosr'      , 0	)
" call s:SetIfNotExist('g:xptemplate_show_stack'        , 1	)
call s:SetIfNotExist('g:xptemplate_key'                 , '<C-\>'	)
call s:SetIfNotExist('g:xptemplate_key_pum_only'        , '<C-r>' . g:xptemplate_key	)
" call s:SetIfNotExist('g:xptemplate_crash'             , '<C-g>'	)
call s:SetIfNotExist('g:xptemplate_nav_next'            , '<Tab>'	)
call s:SetIfNotExist('g:xptemplate_nav_prev'            , '<S-Tab>'	)
call s:SetIfNotExist('g:xptemplate_nav_cancel'          , '<cr>'	)
call s:SetIfNotExist('g:xptemplate_goback'              , '<C-g>'	)
call s:SetIfNotExist('g:xptemplate_to_right'            , "<C-l>"	)

call s:SetIfNotExist('g:xptemplate_strict'              , 2	)
call s:SetIfNotExist('g:xptemplate_highlight'           , 'next'	)
call s:SetIfNotExist('g:xptemplate_brace_complete'      , 0	)
call s:SetIfNotExist('g:xptemplate_strip_left'          , 1	)
call s:SetIfNotExist('g:xptemplate_fix'                 , 1	)
call s:SetIfNotExist('g:xptemplate_ph_pum_accept_empty' , 1	)

call s:SetIfNotExist('g:xptemplate_vars'                , ''	)
call s:SetIfNotExist('g:xptemplate_bundle'              , ''	)
" TODO add doc
call s:SetIfNotExist('g:xptemplate_snippet_folders'     , []	)

" for test script
call s:SetIfNotExist('g:xpt_post_action', '')


" setup other snippets folder {{{

let s:path = expand( "<sfile>" )
let s:filename = 'xptemplate.conf.vim'
let s:path = substitute( s:path, '\', '/', 'g' )
let s:path = matchstr( s:path, '\V\.\*\ze/plugin/' . s:filename )

let &runtimepath .= ',' . s:path . '/personal'

for s:path in g:xptemplate_snippet_folders
    let &runtimepath .= ',' . s:path
endfor

unlet s:path
unlet s:filename

" }}}




let g:XPTpvs = {}


" 'selTrigger' used in select mode trigger, but if 'selection' changed after this
" script loaded, incSelTrigger or excSelTrigger should be used according to
" runtime settings.
let g:XPTmappings = {
      \ 'popup'         : "<C-r>=XPTemplateStart(0,{'popupOnly':1})<cr>", 
      \ 'trigger'       : "<C-r>=XPTemplateStart(0)<cr>", 
      \ 'wrapTrigger'   : "\"0s<C-r>=XPTemplatePreWrap(@0)<cr>", 
      \ 'incSelTrigger' : "<C-c>`>a<C-r>=XPTemplateStart(0)<cr>", 
      \ 'excSelTrigger' : "<C-c>`>i<C-r>=XPTemplateStart(0)<cr>", 
      \ 'selTrigger'    : (&selection == 'inclusive') ?
      \                       "<C-c>`>a<C-r>=XPTemplateStart(0)<cr>" 
      \                     : "<C-c>`>i<C-r>=XPTemplateStart(0)<cr>", 
      \ }


exe "inoremap <silent> " . g:xptemplate_key . " " . g:XPTmappings.trigger
exe "xnoremap <silent> " . g:xptemplate_key . " " . g:XPTmappings.wrapTrigger
exe "snoremap <silent> " . g:xptemplate_key . " " . g:XPTmappings.selTrigger

exe "inoremap <silent> " . g:xptemplate_key_pum_only . " " . g:XPTmappings.popup


" let &cpo = s:oldcpo



" parse personal variable
let s:pvs = split(g:xptemplate_vars, '\V'.s:ep.'&')

for s:v in s:pvs
  let s:key = matchstr(s:v, '\V\^\[^=]\*\ze=')
  if s:key == ''
    continue
  endif

  if s:key !~ '^\$'
    let s:key = '$'.s:key
  endif

  let s:val = matchstr(s:v, '\V\^\[^=]\*=\zs\.\*')
  let g:XPTpvs[s:key] = substitute(s:val, s:unescapeHead.'&', '\1\&', 'g')
endfor


" bundle support
if type( g:xptemplate_bundle ) == type( '' )
    let s:bundle = split( g:xptemplate_bundle, ',' )
else
    let s:bundle = g:xptemplate_bundle
endif

let g:xptBundle = {}
for ftAndBundle in s:bundle
    let [ ft, bundle ] = split( ftAndBundle, '_' )
    if !has_key( g:xptBundle, ft )
        let g:xptBundle[ ft ] = {}
    endif

    let g:xptBundle[ ft ][ bundle ] = 1
endfor

fun! g:XPTaddBundle(ft, bundle) "{{{
    let g:xptBundle[ a:ft ] = get( g:xptBundle, a:ft, {} )
    let g:xptBundle[ a:ft ][ a:bundle ] = 1

    " TODO NOTE: problem: last snipFileScop is used in XPTembed. any side effect?
    call XPTembed( a:ft . '/' . a:bundle )
endfunction "}}}

fun! g:XPTloadBundle(ft, bundle) "{{{
    if !has_key( g:xptBundle, a:ft )
        return 0
    elseif !has_key( g:xptBundle[ a:ft ], a:bundle ) && !has_key( g:xptBundle[ a:ft ], '*' )
        return 0
    else
        return 1
    endif
endfunction "}}}



fun! XPTfiletypeInit() "{{{
    
    let x = g:XPTobject()

    let fts = x.filetypes
    for [ ft, ftScope ] in items( fts )

        " add user set variables
        let f = ftScope.funcs
        for [k, v] in items(g:XPTpvs)
            let f[k] = v
        endfor


        " add default comment strings
        if &l:commentstring != ''
            let cms = split( &l:commentstring, '\V%s', 1 )
            if cms[1] == ''
                let f[ '$CS' ] = get( f, '$CS', cms[0] )
            else
                if !has_key( f, '$CL' ) && !has_key( f, '$CR' )
                    let [ f[ '$CL' ], f[ '$CR' ] ] = cms
                endif
            endif
        endif

    endfor
endfunction "}}}


augroup XPTftInit
  au!
  au FileType * call XPTfiletypeInit()
augroup END






" check critical setting:
"
" backspace >2 or with start
" nocompatible
" selection inclusive
" selectmode "" without v

let bs=&bs

if bs != 2 && bs !~ "start" 
  if g:xptemplate_fix 
    set bs=2
  else
    echom "'backspace' option must be set with 'start'. set bs=2 or let g:xptemplate_fix=1 to fix it"
  endif
endif

if &compatible == 1 
  if g:xptemplate_fix 
    set nocompatible
  else
    echom "'compatible' option must be set. set compatible or let g:xptemplate_fix=1 to fix it"
  endif
endif

let &cpo = s:oldcpo


" vim:tw=78:ts=90:sw=4:sts=4
