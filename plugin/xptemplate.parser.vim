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

exec XPT#importConst

let s:log = xpt#debug#Logger( 'warn' )

com! -nargs=* XPTemplate
      \   if xpt#parser#InitSnippetFile( expand( "<sfile>" ), <f-args> ) == 'finish'
      \ |     finish
      \ | endif

com! -nargs=* XPTemplateDef call s:XPTstartSnippetPart(expand("<sfile>")) | finish
com! -nargs=* XPT           call s:XPTstartSnippetPart(expand("<sfile>")) | finish
com! -nargs=* XPTvar        call xpt#parser#SetVar( <q-args> )
com! -nargs=* XPTsnipSet    call xpt#parser#SnipSet( <q-args> )
com! -nargs=+ XPTinclude    call xpt#parser#Include(<f-args>)
com! -nargs=+ XPTembed      call xpt#parser#Embed(<f-args>)

fun! XPTinclude(...) "{{{
    call xpt#parser#Load(a:000, 1)
endfunction "}}}
fun! XPTembed(...) "{{{
    call xpt#parser#Load(a:000, 0)
endfunction "}}}

fun! s:XPTstartSnippetPart(fn) "{{{
    call s:log.Log("parse file :".a:fn)
    let lines = readfile(a:fn)


    let i = match( lines, '\V\^XPTemplateDef' )
    if i == -1
        " so that XPT can not start at first line
        let i = match( lines, '\V\^XPT\s' ) - 1
    endif

    if i < 0
        return
    endif

    let lines = lines[ i : ]

    let x = b:xptemplateData
    let x.snippetToParse += [ { 'snipFileScope' : x.snipFileScope, 'lines' : lines } ]

    return

endfunction "}}}

let &cpo = s:oldcpo



