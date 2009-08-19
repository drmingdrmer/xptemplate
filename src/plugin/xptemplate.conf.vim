if exists("g:__XPTEMPLATE_CONF_VIM__")
  finish
endif
let g:__XPTEMPLATE_CONF_VIM__ = 1

  " finish

runtime plugin/debug.vim

let s:escapeHead   = '\v(\\*)\V'
let s:unescapeHead = '\v(\\*)\1\\?\V'
let s:ep           = '\%(' . '\%(\[^\\]\|\^\)' . '\%(\\\\\)\*' . '\)' . '\@<='



fun! s:setIfNull(k, v) "{{{
  if !exists(a:k)
    exe "let ".a:k."=".string(a:v)
  endif
endfunction "}}}



call s:setIfNull('g:xptemplate_strip_left',   1)
" TODO 
" call s:setIfNull('g:xptemplate_protect',      1) 
" call s:setIfNull('g:xptemplate_limit_curosr', 0)
" call s:setIfNull('g:xptemplate_show_stack',   1)
call s:setIfNull('g:xptemplate_highlight',    1)
call s:setIfNull('g:xptemplate_key',          '<C-\>')
" command?
call s:setIfNull('g:xptemplate_goback',       '<C-g>')
" call s:setIfNull('g:xptemplate_crash',        '<C-g>')
call s:setIfNull('g:xptemplate_nav_next',     '<tab>')
call s:setIfNull('g:xptemplate_nav_cancel',   '<cr>')
call s:setIfNull('g:xptemplate_to_right',     "<C-l>")
call s:setIfNull('g:xptemplate_fix',          1)
call s:setIfNull('g:xptemplate_vars',         '')
call s:setIfNull('g:xptemplate_hl',           1)

" for test script
call s:setIfNull('g:xpt_post_action',         '')

let g:XPTpvs = {}



"for high lighting current editing item
if !hlID('XPTCurrentItem') && g:xptemplate_hl
  hi XPTCurrentItem ctermbg=darkgreen gui=none guifg=#d59619 guibg=#efdfc1
endif
if !hlID('XPTIgnoredMark') && g:xptemplate_hl
  hi XPTIgnoredMark cterm=none term=none ctermbg=black ctermfg=darkgrey gui=none guifg=#dddddd guibg=white
endif



" TODO Be very careful with 'cpo' option!
" TODO test popup with cpo set with '<', that makes "\<...>" failed to work
"
let s:oldcpo = &cpo
" enable <key> encoding
set cpo-=<

" 'selTrigger' used in select mode trigger, but if 'selection' changed after this
" script loaded, incSelTrigger or excSelTrigger should be used according to
" runtime settings.
let g:XPTkeys = {
      \ 'popup'       : "<C-r>=XPTemplateStart(0,{'popupOnly':1})<cr>", 
      \ 'trigger'       : "<C-r>=XPTemplateStart(0)<cr>", 
      \ 'wrapTrigger'   : "\"0di<C-r>=XPTemplatePreWrap(@0)<cr>", 
      \ 'incSelTrigger' : "<C-c>`>a<C-r>=XPTemplateStart(0)<cr>", 
      \ 'excSelTrigger' : "<C-c>`>i<C-r>=XPTemplateStart(0)<cr>", 
      \ 'selTrigger'    : (&selection == 'inclusive') ?
      \                       "<C-c>`>a<C-r>=XPTemplateStart(0)<cr>" 
      \                     : "<C-c>`>i<C-r>=XPTemplateStart(0)<cr>", 
      \ }


exe "inoremap ".g:xptemplate_key." " . g:XPTkeys.trigger
exe "xnoremap ".g:xptemplate_key." " . g:XPTkeys.wrapTrigger
exe "snoremap ".g:xptemplate_key." " . g:XPTkeys.selTrigger

let &cpo = s:oldcpo



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


fun! s:ApplyPersonalVariables() "{{{
  let f = g:XPTfuncs()
  for [k, v] in items(g:XPTpvs)
    let f[k] = v
  endfor
endfunction "}}}

augroup XPTpvs
  au!
  au FileType * call <SID>ApplyPersonalVariables()
augroup END



" check critical setting:
"
" backspace	>2 or with start
" nocompatible
" selection 	inclusive
" selectmode 	"" without v

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
