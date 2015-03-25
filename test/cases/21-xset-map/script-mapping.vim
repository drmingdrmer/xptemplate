so ./test/core_vimrc

inoremap <SID>(s) (S)
inoremap qqq QQQ
inoremap <buffer><script><CR> <SID>(s)qqq<CR>
