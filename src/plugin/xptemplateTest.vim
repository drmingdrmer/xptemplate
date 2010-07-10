runtime plugin/xptemplate.vim

if exists( "g:__XPTEMPLATETEST_VIM__" ) && g:__XPTEMPLATETEST_VIM__ >= XPT#ver
    finish
endif
let g:__XPTEMPLATETEST_VIM__ = XPT#ver


let s:oldcpo = &cpo
set cpo-=< cpo+=B

let s:log = xpt#debug#Logger( 'warn' )
" let s:log = xpt#debug#Logger( 'debug' )

if !exists( 'g:xptmode' )
    let g:xptmode = ''
endif

let s:fn = 'test.page' . g:xptmode

" TODO indent test 

" test suite support

let s:phases = [ 1, 2, 3, 4 ]
let [ s:DEFAULT, s:TYPED, s:CHAR_AROUND, s:NESTED ] = s:phases
let s:FIRST_PHASE = s:phases[ 0 ]
let s:LAST_PHASE = s:phases[ -1 ]


" Note: using a/b instead of -/= to avoid indent problem that cause text auto
"       wrapped which make XPM not work well
let s:preinputs = {
            \'before' : " b\<left>\<left>",
            \'between' : "`^\<left>",
            \'after' : "a ",
            \}


" com! XPTSlow redraw! | sleep 100m
" com! XPTSlow redraw! | sleep 1000m
com! XPTSlow echo




fun! s:Feedkeys( text, mode )
    call s:log.Debug( 'Feedkeys=' . string( [ a:text, a:mode ] ) )
    return feedkeys( a:text, a:mode )
endfunction

fun s:XPTtrigger(name) "{{{
    call s:Feedkeys(a:name, 'nt')
    call s:Feedkeys( eval('"\' . g:xptemplate_key . '"' ), 'mt' )
    " call s:Feedkeys("", 'mt')
endfunction "}}}
fun s:XPTtype(...) "{{{
    let ln = line( '.' )
    let lns = [ ln - 10, ln + 10 ]
    if lns[0] < 1 
        let lns[0] = 1
    endif
    call s:log.Debug( 'lines context=' . join( getline( lns[0], lns[1] ), "\n" ) )

    for v in a:000
        call s:Feedkeys(v, 'nt')
        call s:Feedkeys("\<tab>", 'mt')
    endfor
endfunction "}}}

fun! s:XPTchoosePum( ... ) "{{{

    for v in a:000
        call s:Feedkeys(v, 'nt')
        if g:xptemplate_pum_tab_nav
            call s:Feedkeys("\<CR>", 'mt')
        else
            call s:Feedkeys("\<TAB>", 'mt')
        endif
    endfor
    
endfunction "}}}
fun s:XPTcancel(...) "{{{
    call s:Feedkeys("\<cr>", 'mt')
endfunction "}}}
fun! s:LastLine() "{{{
    let @q = "\n"
    call s:Feedkeys("\<C-c>G\"qpG", 'nt')
endfunction "}}}
fun s:XPTnew(name, preinput) "{{{
    " 'S' for indent test. it takes the indent from line above
    call s:Feedkeys("S", 'nt')
    call s:Feedkeys(a:preinput, 'nt')
    call s:XPTtrigger(a:name)
endfunction "}}}
fun s:XPTwrapNew(name, preinput) "{{{

    " virtualedit need to be set to correct pasting
    let ve = &virtualedit
    set virtualedit=onemore,insert,block

    " 'S' for indent test. it takes the indent from line above
    call s:Feedkeys("S", 'nt')
    call s:Feedkeys( a:preinput, 'nt' )

    " call s:Feedkeys("\<C-o>maWRAPPED_TEXT\<cr>WRAPPED_TEXT_line2\<left>\<C-o>mb", 'nt')
    call s:Feedkeys("\<C-o>ma" , 'nt' )
    let @p="WRAPPED_TEXT\nWRAPPED_TEXT_line2"
    call s:Feedkeys("\<C-o>\"pgP\<Left>\<C-o>mb" , 'nt' )

    call s:Feedkeys( "\<C-o>:XPTSlow\<cr>", '' )


    call s:Feedkeys( "\<C-o>:set virtualedit=" . ve . "\<cr>", '' )


    call s:Feedkeys("\<C-c>`a", 'nt')

    " " TODO very bad!
    " if ve !~ 'all\|onemore' && a:preinput == s:preinputs.after
    "     call s:Feedkeys( 'l', 'nt' )
    " endif

    call s:Feedkeys("v", 'nt')
    if &slm =~ 'cmd'
        call s:Feedkeys("\<C-g>", 'nt')
    endif


    call s:Feedkeys("`b", 'nt')

    if &sel == 'exclusive'
        call s:Feedkeys("l", 'nt')
    endif


    call s:Feedkeys( eval('"\' . g:xptemplate_key . '"' ), 'mt' )
    call s:Feedkeys(a:name, 'nt')

    if g:xptemplate_pum_tab_nav
        call s:Feedkeys("\<CR>", 'mt')
    else
        call s:Feedkeys("	", 'mt')
    endif


endfunction "}}}


fun! s:NewTestFile(ft) "{{{
    let subft = matchstr(a:ft, '[^.]*')

    let tempPath = globpath(&rtp, 'ftplugin/_common/common.xpt.vim')
    let tempPath = split(tempPath, "\n")[0]
    let tempPath = matchstr(tempPath, '.*\ze[\\/]_common[\\/]common.xpt.vim') . '/' . subft 
    " . '/.test'

    " try
    "     call mkdir(tempPath, 'p')
    " catch /.*/
    " endtry

    let s:tempPath = tempPath

    exe 'e ' . tempPath . '/' . s:fn
    exe '0,$d'

    " set buftype=nofile

    " " standard test setting
    " setlocal tabstop=8
    " setlocal shiftwidth=4
    " setlocal softtabstop=4



    silent! wincmd o

    let &ft = a:ft

    let b:cms = split(&cms, '\V%s')

    if len(b:cms) == 0
        let b:cms = ['', '']
    elseif len(b:cms) == 1
        let b:cms += ['']
    endif

endfunction "}}}

fun! XPTtestSort(a, b) "{{{
    if a:a.name ==? a:b.name
        return 0
    elseif a:a.name <? a:b.name
        return -1
    else
        return 1
    endif
endfunction "}}}

fun! XPTtestPseudoDate(...) "{{{
    return "2009 Oct 08"
endfunction "}}}

fun! s:XPTtest(ft) "{{{
    let g:xpt_post_action = "\<C-r>=TestProcess()\<cr>"
    augroup XPTtestGroup
        au!
        au CursorHoldI * call TestProcess()
        au CursorMoved * call TestProcess()
        au CursorMovedI * call TestProcess()
    augroup END

    if exists( ':AcpLock' )
        AcpLock
    endif

    call s:NewTestFile(a:ft)

    let b:currentTmpl    = {}
    let b:testProcessing = 0
    let b:phaseIndex     = 0
    let b:testPhase      = s:phases[ b:phaseIndex ]


    call XPTparseSnippets()

    let tmpls = XPTgetAllTemplates()

    let x = XPTbufData()
    let fts = x.filetypes
    for ft in values( fts )
        let ft.funcs.strftime = function( 'XPTtestPseudoDate' )
        let ft.funcs.date = function( 'XPTtestPseudoDate' )
    endfor

    " disable embedded language
    if exists( 'b:XPTfiletypeDetect' )
        unlet b:XPTfiletypeDetect
    endif


    " remove 'Path' and 'Date' template0
    unlet tmpls.Path
    unlet tmpls.Date

    call filter( tmpls, '!has_key(v:val.setting, "hidden") || !v:val.setting.hidden' )

    " call filter( tmpls, 'v:val.name =~ "^comment"' )

    
    " for [k, v] in items(tmpls)
        " if k != '"'
            " unlet tmpls[k]
        " endif
    " endfor

    let tmplList = values(tmpls)
    call filter( tmplList, '!has_key(v:val.setting, "syn")' )
    let tmplList = sort( tmplList, "XPTtestSort" )


    let b:tmplToTest = tmplList

    " let b:tmplToTest = []
    " for v in tmplList
        " if v.item.name =~ 'invoke_' 
            " let b:tmplToTest += [ v ]
            " break
        " endif
    " endfor
    

    " trigger test to start
    normal o

    call TestProcess()

endfunction "}}}

fun s:TestFinish() "{{{
    augroup XPT
        au!
    augroup END

    augroup XPTtestGroup
        au!
    augroup END

    exe 'wqa'

    return

endfunction "}}}


fun! TestProcess() "{{{
    XPTSlow

    call s:log.Debug( "TestProcess" )

    if b:testProcessing == 0
        call s:log.Log("processing = 0, to start new")
        call s:StartNewTemplate()

        XPTSlow

    else " b:testProcessing = 1


        let x = XPTbufData()
        let ctx = x.renderContext
        if ctx.phase == 'uninit' || ctx.phase == 'popup'
            return ""
        endif
        call s:log.Log("processing = 1, handle action")

        " Insert mode or select mode.
        " If it is in normal mode, maybe something else is going. In normal mode,
        " just ignore it
        
        " call s:log.Log("processing, mode=".mode())
        if mode() =~? "[is]"
            call s:FillinTemplate()
        endif
    endif

    " call s:Feedkeys("", '')

    XPTSlow

    return ""
endfunction "}}}

fun! s:StartNewTemplate() "{{{

    let b:testProcessing = 1

    let b:itemSteps = []

    if len(b:tmplToTest) == 0 
        call s:TestFinish()
        return
    endif


    " Each template is rendered multi times.

    let b:currentTmpl = b:tmplToTest[0]
    if b:testPhase == s:LAST_PHASE
        call remove(b:tmplToTest, 0)
    endif


    call s:LastLine()

    " if no comment string found, do not risk to draw template in comment.
    if b:testPhase == s:FIRST_PHASE && b:cms != ['', '']
        " first time rendering the template, show original template definition

        let tmpl0 = [ ' ' . '-------------' . b:currentTmpl.name . '---------------' ] 
                    \+ split( b:currentTmpl.snipText , "\n" )

        let maxLength = 0
        for line in tmpl0
            let maxLength = max( [ len(line), maxLength ] )
        endfor

        let tmpl = []
        for line in tmpl0
            if b:cms[0] != ''
                let line = substitute( line, '\V'.b:cms[0], '_CMT_', 'g' )
            endif
            if b:cms[1] != ''
                let line = substitute( line, '\V'.b:cms[1], '_cmt_', 'g' )
            endif

            let line2 = ''
            let line2 .= b:cms[0] . ' ' . line                      " content 
            let line2 .= repeat( ' ', maxLength - len( line ) )     " padding
            let line2 .= ' ' . b:cms[ 1 ]                           " eend

            let tmpl += [ line2 ]

        endfor

        let text = '    ' . join( tmpl, "\n    " )
        let text = "" . text . "\n\n\n\n"

        let @o = text

        call s:Feedkeys( '"op', 'nt' )
        call s:LastLine()
    endif

    if s:TYPED == b:testPhase
        let charAround = s:preinputs.before

    elseif s:CHAR_AROUND == b:testPhase
        let charAround = s:preinputs.between

    elseif s:NESTED == b:testPhase
        let charAround = s:preinputs.after

    else
        let charAround = ''

    endif


    " render template
    if b:currentTmpl.setting.iswrap
        call s:XPTwrapNew( b:currentTmpl.name, charAround )
    else
        call s:XPTnew( b:currentTmpl.name, charAround )
    endif



endfunction "}}}

" TODO bug: c:ifee in the repetition part, condition followed by a space with full .vimrc but not with simple .vimrc
fun! s:FillinTemplate() "{{{
    let x = XPTbufData()
    let ctx = x.renderContext

    " if pumvisible()
        " call confirm(  "can not be!" )
    " endif

    call s:log.Log( "template name=" . ctx.snipObject.name . ' ============================================================ ' )
    call s:log.Log( "mode=".mode()." popup=".pumvisible() )
    call s:log.Log( "render phase:" . ctx.phase)
    call s:log.Log( 'b:testPhase=' . b:testPhase )
    call s:log.Log( 'itemList=' . string( ctx.itemList ) )
    call s:log.Log( 'item=' . string( ctx.item ) )


    if ctx.phase == 'fillin' 

        XPTSlow

        " repitition, expandable or super repetition
        if ctx.item.name =~ '\V..\|?\|*'
            let b:itemSteps += [ ctx.item.name ]

            " keep at most 5 steps
            if len( b:itemSteps ) > 8 
                call remove(b:itemSteps, 0)
            endif
        endif

        if pumvisible()
            call s:log.Log( "has pum, select the first" )
            call s:XPTchoosePum( "\<C-n>" )


        elseif len( b:itemSteps ) >= 4 
                    \&& ( b:itemSteps[-3] == ctx.item.name 
                    \    || b:itemSteps[ -4 ] == ctx.item.name )
            call s:log.Log( "too many repetition done, cancel it" )
            " too many repetition 
            call s:XPTcancel()

        elseif b:testPhase == s:DEFAULT
            call s:log.Log( 'type nothing, goto next' )
            " next
            call s:XPTtype('')

        elseif b:testPhase == s:TYPED
            " pseudo type
            call s:log.Log( 'to type, item name=' . string( ctx.item.name ) )
            call s:XPTtype(substitute(ctx.item.name, '\W', '', 'g') . "_TYPED")


        else
            call s:log.Log( "other, just goto next" )
            " not implemented yet
            call s:XPTtype('')
        endif

        XPTSlow

    elseif ctx.phase == 'finished'
        " template finished

        if empty( x.stack )
            call s:log.Log( "finished" )
            let b:phaseIndex = (b:phaseIndex + 1) % len(s:phases)
            let b:testPhase = s:phases[ b:phaseIndex ]
            let b:testProcessing = 0

            let @r="\n"

            call s:Feedkeys("\<C-c>G\"rp\<C-c>", 'nt')
        else
            call s:log.Log( "finish nested" )
            call s:XPTtype( 'NESTED_TYPED' )
        endif
    endif


endfunction "}}}


com -nargs=1 XPTtest call <SID>XPTtest(<f-args>)
com XPTtestEnd call <SID>TestFinish()

let &cpo = s:oldcpo

