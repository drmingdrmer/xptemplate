if exists( "g:__XPTEMPLATE_PARSER_VIM__" ) && g:__XPTEMPLATE_PARSER_VIM__ >= XPT#ver
    finish
endif
let g:__XPTEMPLATE_PARSER_VIM__ = XPT#ver


"
" Special XSET[m] Keys
"   ComeFirst   : item names which come first before any other
"               // XSET ComeFirst=i,len
"
"   ComeLast    : item names which come last after any other
"               // XSET ComeLast=i,len
"
"   postQuoter  : Quoter to define repetition
"               // XSET postQuoter=<{[,]}>
"               // defulat : {{,}}
"
"
"

let s:oldcpo = &cpo
set cpo-=< cpo+=B


runtime plugin/xptemplate.vim



let s:log = xpt#debug#Logger( 'warn' )
let s:log = xpt#debug#Logger( 'debug' )


com! -nargs=* XPTemplate
      \   if xpt#parser#SnippetFileInit( expand( "<sfile>" ), <f-args> ) == 'finish'
      \ |     finish
      \ | endif

com! -nargs=* XPTemplateDef echom expand("<sfile>") . " XPTemplateDef is NOT needed any more. All right to remove it."
com! -nargs=* XPTvar        call xpt#parser#SetVar( <q-args> )

" TODO rename me to XSET
com! -nargs=* XPTsnipSet    call xpt#parser#SnipSet( <q-args> )
com! -nargs=+ XPTinclude    call xpt#parser#Include(<f-args>)
com! -nargs=+ XPTembed      call xpt#parser#Embed(<f-args>)
" com! -nargs=* XSET          call XPTbufferScopeSet( <q-args> )




let &cpo = s:oldcpo
