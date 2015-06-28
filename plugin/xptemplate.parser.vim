if exists( "g:__XPTEMPLATE_PARSER_VIM__" ) && g:__XPTEMPLATE_PARSER_VIM__ >= XPT#ver
	finish
endif
let g:__XPTEMPLATE_PARSER_VIM__ = XPT#ver
let s:oldcpo = &cpo
set cpo-=< cpo+=B
runtime plugin/xptemplate.conf.vim
exec XPT#importConst
com! -nargs=* XPTemplate if xpt#parser#InitSnippetFile( expand( "<sfile>" ), <f-args> ) == 'finish' | finish | endif
com! -nargs=* XPTemplateDef call xpt#parser#LoadSnippetToParseList(expand("<sfile>")) | finish
com! -nargs=* XPT           call xpt#parser#LoadSnippetToParseList(expand("<sfile>")) | finish
com! -nargs=* XPTvar call xpt#parser#SetVar(<q-args>)
com! -nargs=* XPTsnipSet call xpt#parser#SnipSet(<q-args>)
com! -nargs=+ XPTinclude call xpt#parser#Include(<f-args>)
com! -nargs=+ XPTembed call xpt#parser#Embed(<f-args>)
fun! XPTinclude(...)
	call xpt#parser#Load(a:000,1)
endfunction
fun! XPTembed(...)
	call xpt#parser#Load(a:000,0)
endfunction
let &cpo = s:oldcpo
