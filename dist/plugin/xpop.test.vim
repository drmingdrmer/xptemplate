if exists("g:__XPOP_TEST_VIM__")
  finish
endif
let g:__XPOP_TEST_VIM__ = 1
runtime plugin/xpopup.vim
let s:cb = {}
fun! s:cb.onEmpty(sess) 
endfunction 
fun! s:cb.onOneMatch(sess) 
  echom "match one:".a:sess.matched
endfunction 
fun! s:XPP() 
  let col = 1
  let sess = XPPopupNew(s:cb, {}, ['abccd', 'Abccd', 'abd', 'c', 'C', 'cd', 'cde'])
  return sess.popup(col)
endfunction 
imap <M-i> <C-r>=<SID>XPP()<cr>
