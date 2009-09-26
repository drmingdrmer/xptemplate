if exists("g:__XPTEMPLATE_CONF_VIM__")
  finish
endif
let g:__XPTEMPLATE_CONF_VIM__ = 1
runtime plugin/debug.vim
let s:escapeHead   = '\v(\\*)\V'
let s:unescapeHead = '\v(\\*)\1\\?\V'
let s:ep           = '\%(' . '\%(\[^\\]\|\^\)' . '\%(\\\\\)\*' . '\)' . '\@<='
fun! s:SetIfNotExist(k, v) 
  if !exists(a:k)
    exe "let ".a:k."=".string(a:v)
  endif
endfunction 
call s:SetIfNotExist('g:xptemplate_strip_left',   1)
call s:SetIfNotExist('g:xptemplate_highlight'           , 1)
call s:SetIfNotExist('g:xptemplate_key'                 , '<C-\>')
call s:SetIfNotExist('g:xptemplate_goback'              , '<C-g>')
call s:SetIfNotExist('g:xptemplate_nav_next'            , '<tab>')
call s:SetIfNotExist('g:xptemplate_nav_cancel'          , '<cr>')
call s:SetIfNotExist('g:xptemplate_to_right'            , "<C-l>")
call s:SetIfNotExist('g:xptemplate_fix'                 , 1)
call s:SetIfNotExist('g:xptemplate_vars'                , '')
call s:SetIfNotExist('g:xptemplate_hl'                  , 1)
call s:SetIfNotExist('g:xptemplate_ph_pum_accept_empty' , 0)
call s:SetIfNotExist('g:xpt_post_action',         '')
let g:XPTpvs = {}
if !hlID('XPTCurrentItem') && g:xptemplate_hl
  hi XPTCurrentItem ctermbg=darkgreen gui=none guifg=#d59619 guibg=#efdfc1
endif
if !hlID('XPTIgnoredMark') && g:xptemplate_hl
  hi XPTIgnoredMark cterm=none term=none ctermbg=black ctermfg=darkgrey gui=none guifg=#dddddd guibg=white
endif
let s:oldcpo = &cpo
set cpo-=<
let g:XPTmappings = {
      \ 'popup'         : "<C-r>=XPTemplateStart(0,{'popupOnly':1})<cr>", 
      \ 'trigger'       : "<C-r>=XPTemplateStart(0)<cr>", 
      \ 'wrapTrigger_old'   : "\"0di<C-r>=XPTemplatePreWrap(@0)<cr>", 
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
let &cpo = s:oldcpo
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
fun! s:FiletypeInit() 
  let f = g:XPTfuncs()
  for [k, v] in items(g:XPTpvs)
    let f[k] = v
  endfor
  if &l:commentstring != ''
    let cms = split( &l:commentstring, '\V%s', 1 )
    if cms[1] == ''
      if !has_key( f, '$CS' )
        let f[ '$CS' ] = cms[0]
      endif
    else
      if !has_key( f, '$CL' ) && !has_key( f, '$CR' )
        let [ f[ '$CL' ], f[ '$CR' ] ] = cms
      endif
    endif
  endif
endfunction 
augroup XPTpvs
  au!
  au FileType * call <SID>FiletypeInit()
augroup END
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
