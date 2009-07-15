" XPTEMPLATE ENGIE:
"   code template engine
" VERSION: 0.3.9.0
" BY: drdr.xp | drdr.xp@gmail.com
"
" MARK USED:
"   <, >  visual marks
" REGISTER USED:
"   @"
"
" USAGE: "{{{
"   1) vim test.js
"   2) to type:
"     for<C-\>
"     generating a for-loop template. using <TAB> navigate through
"     template
" "}}}
"
" TODOLIST: "{{{
" TODO bug:coherent place holders span mark
" TODO ontime filter
" TODO ontime repetition
" TODO use i^gu to protect template
" expected mode() when cursor stopped to wait for input
" TODO highlight all pending item instead of using mark
" TODO protect register while template rendering
" TODO implement wrapping in more natural way. nested maybe.
" TODO hidden template or used only internally.
" TODO snippets bundle and bundle selection
" TODO 'completefunc' to re-popup item menu. Or using <tab> to force popup showing
" TODO snippets bundle and bundle selection
" TODO snippet-file scope XSET
" TODO block context check
" TODO eval default value in-time
" TODO expandable has to be adjuested
" TODO in windows & in select mode to trigger wrapped or normal?
" TODO change on previous item
" TODO lock key variables
" TODO as function call template
" TODO item popup: repopup
" TODO undo
" TODO test more : char before snippet, char after, last cursor position,
" TODO wrapping on different visual mode
" TODO prefixed template trigger
" TODO class-style
" TODO ruby snippet:cli indent problem
" TODO 'switch' snippet has indent problem. placeholder spanning multi lines
" is difficult to adjust indent for its expansion.
"
" TODO simplify if no need to popup, popup session
" TODO pre-build expression to evaluate
" TODO separately store wrapped templates and normal ones
" TODO match snippet names from middle
"
" "}}}
"
" 


if exists("g:__XPTEMPLATE_VIM__")
    finish
endif
let g:__XPTEMPLATE_VIM__ = 1


com! XPTgetSID let s:sid =  matchstr("<SID>", '\zs\d\+_\ze')
XPTgetSID
delc XPTgetSID

let s:log = CreateLogger( 'debug' )
" let s:log = CreateLogger( 'warn' )



" runtime plugin/position.vim
runtime plugin/debug.vim
runtime plugin/mapstack.vim
runtime plugin/xpreplace.vim
runtime plugin/xpmark.vim
runtime plugin/xpopup.vim
runtime plugin/xptemplate.conf.vim

call XPRaddPreJob( 'XPMupdateCursorStat' )
call XPRaddPostJob( 'XPMupdateSpecificChangedRange' )
" call XPMsetUpdateStrategy( 'manual' )  
" call XPMsetUpdateStrategy( 'auto' ) 
call XPMsetUpdateStrategy( 'normalMode' ) 

" escape rule:
" 0 a
" 1 \a
" 3 \\\a
" 7 \\\\\\\a
" 2 \\a
" 5 \\\\\a
"
" 2*n + 1

let s:NullDict              = {}
let s:NullList              = []
let s:ftNeedToRedraw        = '\<\%(' . join([ 'perl' ], '\|') . '\)\>'
let s:selectAction          = "\<esc>gv\<C-g>"
let s:escapeHead            = '\v(\\*)\V'
let s:unescapeHead          = '\v(\\*)\1\\?\V'

let s:nonEscaped            = '\%(' . '\%(\[^\\]\|\^\)' . '\%(\\\\\)\*' . '\)' . '\@<='
let s:escaped               = '\%(' . '\%(\[^\\]\|\^\)' . '\%(\\\\\)\*' . '\)' . '\@<=' . '\\'

let s:stripPtn              = '\V\^\s\*\zs\.\*'
let s:cursorName            = "cursor"
let s:wrappedName           = "wrapped"
let s:expandablePattern     = '\v^(\_.*\_W+)?' . '\w+\V...'
let s:repetitionPattern     = '^\.\.\.\d*$'
let s:repeatPtn             = '...\d\*'
let s:templateSettingPrototype  = { 'defaultValues' : {}, 'postFilters' : {}, 'comeFirst' : [], 'comeLast' : [] }


let s:renderContextPrototype      = {
            \    'tmpl'              : {},
            \    'evalCtx'           : {},
            \    'phase'             : 'uninit',
            \    'markNamePre'       : '', 
            \    'item'              : {}, 
            \    'leadingPlaceHolder' : {}, 
            \    'step'              : [],
            \    'namedStep'         : {},
            \    'processing'        : 0,
            \    'marks'             : {
            \       'tmpl'           : {'start' : '', 'end' : ''} },
            \    'itemDict'          : {},
            \    'itemList'          : [],
            \    'lastContent'       : '',
            \    'lastTotalLine'     : 0, 
            \    'lastFollowingSpace': '', 
            \}
let s:vrangeClosed = "\\%>'<\\%<'>"
let s:vrange       = '\V' . '\%(' . '\%(' . s:vrangeClosed .'\)' .  '\|' . "\\%'<\\|\\%'>" . '\)'

let s:plugins = {}
let s:plugins.beforeRender = []
let s:plugins.afterRender = []

let s:plugins.beforeFinish = []
let s:plugins.afterFinish = []

let s:plugins.beforeApplyPredefined = []
let s:plugins.afterApplyPredefined = []

let s:plugins.beforeInitItem = []
let s:plugins.afterInitItem = []

let s:plugins.beforeNextItem = []
let s:plugins.afterNextItem = []

let s:plugins.beforeUpdate = []
let s:plugins.afterUpdate = []

let s:priorities = {'all' : 64, 'spec' : 48, 'like' : 32, 'lang' : 16, 'sub' : 8, 'personal' : 0}
let s:priPtn = 'all\|spec\|like\|lang\|sub\|personal\|\d\+'

let s:f = {}
let g:XPT = s:f








let s:pumCB = {}

fun! s:pumCB.onEmpty(sess) "{{{
    return ""
endfunction "}}}

fun! s:pumCB.onOneMatch(sess) "{{{
  call s:log.Log( "match one:".a:sess.matched )
  return s:doStart(a:sess)
endfunction "}}}

let s:ItemPumCB = {}

fun! s:ItemPumCB.onOneMatch(sess) "{{{

    " TODO  next item is better?
    call s:XPTupdate()

    return ""
endfunction "}}}


" ===================================================
" API
" ===================================================

" which letter can be used in template name other than 'iskeyword'
fun! XPTemplateKeyword(val) "{{{
    let x = s:bufData()

    " word characters are already valid.
    let val = substitute(a:val, '\w', '', 'g')

    let x.keyword = '\[' . escape(val, '\]') . ']'
endfunction "}}}

fun! XPTemplatePriority(...) "{{{
    let x = s:bufData()
    let p = a:0 == 0 ? 'lang' : a:1

    let x.bufsetting.priority = s:ParsePriority(p)
endfunction "}}}

fun! XPTemplateMark(sl, sr) "{{{
    let x = s:bufData().bufsetting.ptn
    let x.l = a:sl
    let x.r = a:sr
    call s:RedefinePattern()
endfunction "}}}

fun! XPTemplateIndent(p) "{{{
    let x = s:bufData().bufsetting.indent
    call s:ParseIndent(x, a:p)
endfunction "}}}

fun! XPTmark() "{{{
    let x = s:bufData().bufsetting.ptn
    return [ x.l, x.r ]
endfunction "}}}

fun! XPTcontainer() "{{{
    return [s:bufData().vars, s:bufData().vars]
endfunction "}}}

" deprecated
fun! g:XPTvars() "{{{
    return s:bufData().vars
endfunction "}}}

" deprecated
fun! g:XPTfuncs() "{{{
    return s:bufData().funcs
endfunction "}}}


fun! XPTemplateAlias( name, toWhich, setting )
    " TODO wrapping templates
    let xt = s:bufData().normalTemplates

    if has_key( xt, a:toWhich )
        let xt[ a:name ] = deepcopy( xt[ a:toWhich ] )
        let xt[ a:name ].name = a:name
        call s:deepExtend( xt[ a:name ].setting, a:setting )
    endif

endfunction

fun! s:deepExtend( to, from )
    for key in keys( a:from )

        if type( a:from[ key ] ) == 4
            " dict 
            if has_key( a:to, key )
                call s:deepExtend( a:to[ key ], a:from[ key ] )
            else
                let a:to[ key ] = a:from[key]
            endif

        elseif type( a:from[key] ) == 3
            " list 

            if has_key( a:to, key )
                call extend( a:to[ key ], a:from[key] )
            else
                let a:to[ key ] = a:from[key]
            endif
        else
            let a:to[ key ] = a:from[key]
        endif

    endfor
endfunction

" ********* XXX ********* 
fun! XPTemplate(name, str_or_ctx, ...) " {{{
    " @param String name	 		tempalte name
    " @param String context			[optional] context syntax name
    " @param String|List|FunCRef str	template string

    let x = s:bufData()
    let xt = s:bufData().normalTemplates
    let xp = s:bufData().bufsetting.ptn

    let templateSetting = deepcopy(s:templateSettingPrototype)

    if a:0 == 0          " no syntax context
        let TmplObj = a:str_or_ctx

    elseif a:0 == 1      " with syntax context
        call extend( templateSetting, a:str_or_ctx )
        let TmplObj = a:1

    endif


    if type(TmplObj) == type([])
        let Str = join(TmplObj, "\n")

    elseif type(TmplObj) == type(function("tr"))
        let Str = TmplObj

    else
        let Str = TmplObj

    endif


    let name = a:name

    let idt = deepcopy(x.bufsetting.indent)
    " if '=' is a keyword, ignore indent setting
    if '=' !~ '\V' . x.keyword
        call s:log.Log("parse indent in template name")
        let istr = matchstr(name, '=[^!=]*')
        let name = substitute(name, '=[^!=]*', '', 'g')

        if istr != ""
            call s:ParseIndent(idt, istr)
        elseif has_key(templateSetting, 'indent')
            call s:ParseIndent(idt, templateSetting.indent)
        endif
    else
        if has_key(templateSetting, 'indent')
            call s:ParseIndent(idt, templateSetting.indent)
        endif
    endif


    call s:log.Log("keyword is : ".x.keyword)

    if '!' !~ '\V' . x.keyword
        call s:log.Log("parse priority in template name")
        " priority 9999 is the lowest
        let pstr = matchstr(name, '\V!\zs\.\+\$')

        if pstr != ""
            call s:log.Log("parse tmpl name priority")
            let override_priority = s:ParsePriority(pstr)
        elseif has_key(templateSetting, 'priority')
            call s:log.Log("parse templateSetting priority")
            let override_priority = s:ParsePriority(templateSetting.priority)
        else
            call s:log.Log("buf priority")
            let override_priority = x.bufsetting.priority
        endif

        let name = pstr == "" ? name : matchstr(name, '[^!]*\ze!')

    else
        if has_key(templateSetting, 'priority')
            call s:log.Log("parse templateSetting priority")
            let override_priority = s:ParsePriority(templateSetting.priority)
        else
            call s:log.Log("buf priority")
            let override_priority = x.bufsetting.priority
        endif
    endif



    call s:GetHint(templateSetting)


    " TODO refactor this step : check priority earlier than doing something to template.
    " TODO merge something into setting.
    if !has_key(xt, name) || xt[name].priority > override_priority
        call s:log.Log("tmpl :name=".name." priority=".override_priority)
        let xt[name] = {
                    \ 'name'        : name,
                    \ 'tmpl'        : Str,
                    \ 'priority'    : override_priority,
                    \ 'setting'     : templateSetting,
                    \ 'ptn'         : deepcopy(s:bufData().bufsetting.ptn),
                    \ 'indent'      : idt,
                    \ 'wrapped'     : type(Str) != type(function("tr")) && Str =~ '\V' . xp.lft . s:wrappedName . xp.rt }


        call s:initItemOrderDict( xt[ name ].setting )

        " apply some default settings 
        let xt[ name ].setting.defaultValues.cursor = 'Finish()'

    endif
endfunction " }}}

fun! s:initItemOrderDict( setting ) "{{{
    " create name-to-index dictionary
    " TODO move me to template creation phase

    let setting = a:setting
    let [ first, last ] = [ setting.comeFirst, setting.comeLast ]

    let setting.firstDict = {}
    let setting.lastDict = {}
    let setting.firstListTemplate = []
    let setting.lastListTemplate = []

    let [i, len] = [ 0, len( first ) ]
    while i < len
        let setting.firstDict[ first[ i ] ] = i
        call add( setting.firstListTemplate, {} )
        let i += 1
    endwhile
    
    let [i, len] = [ 0, len( last ) ]
    while i < len
        let setting.lastDict[ last[ i ] ] = i
        call add( setting.lastListTemplate, {} )
        let i += 1
    endwhile


    call s:log.Log( 'firstDict' . string( setting.firstDict ) )
    call s:log.Log( 'lastDict' . string( setting.lastDict ) )

endfunction "}}}

fun! XPTreload() "{{{
  try
    unlet b:__xpt_loaded
    unlet b:xptemplateData
  catch /.*/
  endtry
  e
endfunction "}}}

fun! XPTgetAllTemplates() "{{{
    return s:bufData().normalTemplates
endfunction "}}}


fun! XPTemplatePreWrap(wrap) "{{{
    let x = s:bufData()
    let x.wrap = a:wrap

    if x.wrap[-1:-1] == "\n"
        let x.wrap = x.wrap[0:-2]
        " TODO use XPreplace
        let @" = "\n"
        normal! ""P
    endif

    let x.wrapStartPos = col(".")

    if g:xptemplate_strip_left
        let x.wrap = substitute(x.wrap, '^\s*', '', '')
    endif

    let ppr = s:Popup("", x.wrapStartPos)

    call s:log.Log("popup result:".string(ppr))
    return ppr



    " if has_key( ppr, 'action' )
        " call s:ApplyPopupKeys()
        " return ppr.action
    " else
        " return XPTemplateStart(0)
    " endif
endfunction "}}}

fun! XPTemplateStart(pos, ...) " {{{
    let x = s:bufData()

    let popupOnly = ( a:0 == 1 ) && ( has_key( a:1, 'popupOnly' ) ) && a:1.popupOnly

    call s:log.Log("a:000".string(a:000))

    if a:0 == 1 &&  type(a:1) == type({}) && has_key( a:1, 'tmplName' )  " exact template trigger, without depending on any input
        let exact = 1

        let [lnn, startColumn] = a:1.startPos
        let tmplname = a:1.tmplName

        let cursorColumn = startColumn

        call cursor(lnn, startColumn)

    else " input mode
        let exact = 0

        let cursorColumn = col(".")

        if x.wrapStartPos
            " TODO store wrapping and normal tempalte separately

            let lnn = line(".")
            let startColumn = x.wrapStartPos

        else
            call s:log.Log("x.keyword=" . x.keyword)

            " TODO test escaping
            let [lnn, startColumn] = searchpos('\V\%(\w\|'. x.keyword .'\)\+\%#', "bn", line("."))

            if lnn == 0 || startColumn == 0
                let [lnn, startColumn] = [line("."), col(".")]
            endif

        endif

        let tmplname = strpart(getline(lnn), startColumn-1, cursorColumn-startColumn)

    endif

    let x.startColumn = startColumn

    return s:Popup(tmplname, startColumn, { 'popupOnly' : popupOnly })

endfunction " }}}


fun! s:ParseIndent(x, p) "{{{
    let x = a:x

    if a:p ==# "auto"
        let x.type = 'auto'


    elseif a:p =~ '/\d\+\(\*\d\+\)\?'
        " TODO deprecated 
        let x.type = 'rate'

        call s:log.Log("a:p=".a:p)
        let str = matchstr(a:p, '/\d\+\(\*\d\+\)\?')

        let x.rate =split(str, '/\|\*')

        if len(x.rate) == 1
            let x.rate[1] = &l:shiftwidth
        endif
    else
        " a:p == 'keep'
        let x.type = 'keep'
    endif

endfunction "}}}

" TODO refine me
fun! s:GetHint(ctx) "{{{
    let xp = s:bufData().bufsetting.ptn

    if has_key(a:ctx, 'hint')
        let a:ctx.hint = s:Eval(a:ctx.hint)
    else
        let a:ctx.hint = ""
    endif

endfunction "}}}

fun! s:ParsePriority(s) "{{{
    let x = s:bufData()

    let pstr = a:s
    let prio = 0

    if pstr == ""
        let prio = x.bufsetting.priority
    else

        let p = matchlist(pstr, '\V\^\(' . s:priPtn . '\)\%(\(\[+-]\)\(\d\+\)\?\)\?\$')

        let base   = 0
        let r      = 1
        let offset = 0

        if p[1] != ""
            if has_key(s:priorities, p[1])
                let base = s:priorities[p[1]]
            elseif p[1] =~ '^\d\+$'
                let base = 0 + p[1]
            else
                let base = 0
            endif
        else
            let base = 0
        endif

        let r = p[2] == '+' ? 1 : (p[2] == '-' ? -1 : 0)

        if p[3] != ""
            let offset = 0 + p[3]
        else
            let offset = 1
        endif

        let prio = base + offset * r

    endif

    call s:log.Log("parse priority : str=".a:s." value=".prio)

    return prio
endfunction "}}}




fun! s:newTemplateCtx( xptBufData, tmplName ) "{{{
    if s:getRenderContext().processing
        call s:PushCtx()
    endif

    let ctx = s:createRenderContext(a:xptBufData)

    let ctx.phase = 'inited'
    let ctx.tmpl  = a:xptBufData.normalTemplates[a:tmplName]

    return ctx
endfunction "}}}

fun! s:doStart(sess) " {{{
    " @param sess       xpopup call back argument

    let x = s:bufData()

    let [lineNr, column] = [ a:sess.line, a:sess.col ]
    let cursorColumn = col(".")
    let tmplname = a:sess.matched

    let ctx = s:newTemplateCtx( x, tmplname )


    " call SettingPush('&l:ve', 'all')

    call s:renderTemplate([ lineNr, column ], [ lineNr, cursorColumn ])

    " call SettingPop() " l:ve


    let ctx.phase = 'rendered'
    let ctx.processing = 1


    if empty(x.stack)
        call s:ApplyMap()
    endif

    let x.wrap = ''
    let x.wrapStartPos = 0

    let action =  s:gotoNextItem()

    call s:log.Debug("post action =".action)
    call s:log.Debug("mode:".mode())

    " g:xpt_post_action is for debug only
    return action . g:xpt_post_action

endfunction " }}}

" TODO deal with it in any condition
fun! s:XPTemplateFinish(...) "{{{
    let x = s:bufData()
    let ctx = s:getRenderContext()
    let xp = ctx.tmpl.ptn

    " call s:log.Log("XPTemplateFinish...........")

    match none

    let l = line(".")
    let toEnd = col(".") - len(getline("."))

    " unescape
    " exe "silent! %snomagic/\\V" .s:TmplRange() . xp.lft_e . '/' . xp.l . '/g'
    " exe "silent! %snomagic/\\V" .s:TmplRange() . xp.rt_e . '/' . xp.r . '/g'
    exe "silent! %snomagic/\\V" .s:TmplRange() . s:unescapeHead . xp.l . '/\1' . xp.l . '/g'
    exe "silent! %snomagic/\\V" .s:TmplRange() . s:unescapeHead . xp.r . '/\1' . xp.r . '/g'

    " format template text
    if &ft =~ s:ftNeedToRedraw
        redraw
    endif
    call s:Format(1)

    call cursor(l, toEnd + len(getline(l)))

    call s:removeMarksInRenderContext(ctx)

    if empty(x.stack)
        let ctx.processing = 0
        let ctx.phase = 'finished'
        call s:ClearMap()
    else
        " call s:log.Log("pop up")
        call s:PopCtx()
    endif

    return s:StartAppend()
endfunction "}}}

fun! s:removeMarksInRenderContext( renderContext ) "{{{

    let renderContext = a:renderContext

    call XPMremoveMarkStartWith( renderContext.markNamePre )


endfunction "}}}

fun! s:Popup(pref, coln, ...) "{{{

    let x = s:bufData()

    let popupOption = { 'popupOnly' : 0 }
    if a:0 == 1
        call extend( popupOption, a:1, 'force' )
    endif


    call s:log.Log("popupOption:".string(popupOption))

    let cmpl=[]
    let cmpl2 = []
    let dic = x.normalTemplates

    let ctxs = s:SynNameStack(line("."), a:coln)

    call s:log.Log("Popup, pref and coln=".a:pref." ".a:coln)


    let ignoreCase = a:pref !~# '\u'


    for [ key, templateObject ] in items(dic)

        if templateObject.wrapped && empty(x.wrap) || !templateObject.wrapped && !empty(x.wrap)
            continue
        endif

        if has_key(templateObject.setting, "syn") && templateObject.setting.syn != '' && match(ctxs, '\c'.templateObject.setting.syn) == -1
            continue
        endif

        " buildins come last
        if key =~# "^[A-Z]"
            call add(cmpl2, {'word' : key, 'menu' : templateObject.setting.hint})
        else
            call add(cmpl, {'word' : key, 'menu' : templateObject.setting.hint})
        endif

    endfor

    call sort(cmpl)
    call sort(cmpl2)
    let cmpl = cmpl + cmpl2



    " if !popupOption.popupOnly && ( len(cmpl) == 1 || ( len(cmpl) > 0 && a:pref ==# cmpl[0].word ) )
        " " let x.tmplPopupStates = ''
        " return { 'name' : cmpl[0].word }
    " endif

    return XPPopupNew(s:pumCB, {}, cmpl).popup(a:coln)

endfunction "}}}



" TODO use tabstop if expandtab is not set
" TODO bad name, bad arguments
fun! s:applyTmplIndent(renderContext, templateText) "{{{
    " TODO to single line snippets, ignore this step
    let renderContext = a:renderContext
    let tmpl = a:templateText

    let baseIndent = repeat(" ", indent("."))
    " at first, only use default indent
    if renderContext.tmpl.indent.type =~# 'keep\|rate\|auto'
        if renderContext.tmpl.indent.type ==# "rate"
            let patternOfOriginalIndent = repeat(' ', renderContext.tmpl.indent.rate[0])
            let patternOfOriginalIndent ='\(\%('.patternOfOriginalIndent.'\)*\)'

            let expandedIndent = repeat('\1', renderContext.tmpl.indent.rate[1] / renderContext.tmpl.indent.rate[0])

            call s:log.Log("indent:ptn, rep", patternOfOriginalIndent, expandedIndent)

            let tmpl = substitute(tmpl, '\%(^\|\n\)\zs'.patternOfOriginalIndent, expandedIndent, 'g')
        endif
        let tmpl = substitute(tmpl, '\n', '&' . baseIndent, 'g')
    endif

    return tmpl

endfunction "}}}

" TODO do it earlier?
" TODO whether it is necessary to support dynamically generated snippet
" defining repetition?
fun! s:parseRepetition(str, x) "{{{
    let x = a:x
    let xp = x.renderContext.tmpl.ptn

    let tmpl = a:str

    let bef = ""
    let rest = ""
    let rp = xp.lft . s:repeatPtn . xp.rt
    let repPtn     = '\V\(' . rp . '\)\_.\{-}' . '\1'
    let repContPtn = '\V\(' . rp . '\)\zs\_.\{-}' . '\1'


    let stack = []
    let start = 0
    while 1
        let smtc = match(tmpl, repPtn, start)
        if smtc == -1
            break
        endif
        let stack += [smtc]
        let start = smtc + 1
    endwhile


    while stack != []

        let matchpos = stack[-1]
        unlet stack[-1]

        let bef = tmpl[:matchpos-1]
        let rest = tmpl[matchpos : ]

        let rpt = matchstr(rest, repContPtn)
        let symbol = matchstr(rest, rp)

        " default value or post filter text must NOT contains item quotation
        " marks
        " make nonescaped to escaped, escaped to nonescaped
        " turned back when expression evaluated
        let rpt = escape(rpt, '\' . xp.l . xp.r)
        " let rpt = escape(rpt, '\')
        " let rpt = substitute(rpt, '\V'.xp.l, '\\'.xp.l, 'g')
        " let rpt = substitute(rpt, '\V'.xp.r, '\\'.xp.r, 'g')

        let bef .= symbol . rpt . xp.r .xp.r
        let rest = substitute(rest, repPtn, '', '')
        let tmpl = bef . rest

    endwhile

    return tmpl
endfunction "}}}

fun! s:renderTemplate(nameStartPosition, nameEndPosition) " {{{

    let x = s:bufData()
    let ctx = s:getRenderContext()
    let xp = s:getRenderContext().tmpl.ptn

    let tmpl = ctx.tmpl.tmpl

    if type(tmpl) == type(function("tr"))
        let tmpl = tmpl()
    else
        let tmpl = tmpl
    endif

    let tmpl = s:applyTmplIndent(ctx, tmpl)
    let tmpl = s:parseRepetition(tmpl, x)

    let tmpl = substitute(tmpl, '\V' . xp.lft . s:wrappedName . xp.rt, x.wrap, 'g')



    " update xpm status
    call XPMupdate()


    call XPMadd( ctx.marks.tmpl.start, a:nameStartPosition, 'l' )
    call XPMadd( ctx.marks.tmpl.end, a:nameEndPosition, 'r' )

    call XPreplace( a:nameStartPosition, a:nameEndPosition, tmpl )

    call s:log.Log( "template start and end=" . string( [ XPMpos( ctx.marks.tmpl.start ), XPMpos( ctx.marks.tmpl.end )] ) )


    " initialize lists
    let ctx.firstList = []
    let ctx.itemList = []
    let ctx.lastList = []


    if 0 != s:buildPlaceHolders( ctx.marks.tmpl )
        return s:crash()
    endif

    call s:log.Log("after buildvalues tmpl=\n", s:textBetween(s:TL(), s:BR()))



    " open all folds
    call s:TopTmplRange()
    silent! normal! gvzO



endfunction " }}}

" [ first, second, third, right-mark ]
" [ first, first, right-mark, right-mark ]
fun! s:GetNameInfo(end) "{{{
    let x = s:bufData()
    let xp = x.renderContext.tmpl.ptn

    if getline(".")[col(".") - 1] != xp.l
        throw "cursor is not at item start position:".string(getpos(".")[1:2])
    endif

    call s:log.Log("GetNameInfo from".string(getpos(".")[1:2]))
    call s:log.Log("to:".string(a:end))

    let endn = a:end[0] * 10000 + a:end[1]

    let l0 = getpos(".")[1:2]
    let r0 = searchpos(xp.rt, 'nW')

    let r0n = r0[0] * 10000 + r0[1]

    if r0 == [0, 0] || r0n >= endn
        " no item exists
        return [[0, 0], [0, 0], [0, 0], [0, 0]]
    endif

    let l1 = searchpos(xp.lft, 'W')
    let l2 = searchpos(xp.lft, 'W')

    let l1n = l1[0] * 10000 + l1[1]
    let l2n = l2[0] * 10000 + l2[1]

    if l1n > r0n || l1n >= endn
        let l1 = [0, 0]
    endif
    if l2n > r0n || l1n >= endn
        let l2 = [0, 0]
    endif

    if l1 != [0, 0] && l2 != [0, 0]
        " 2 edges
        return [l0, l1, l2, r0]
    elseif l1 == [0, 0] && l2 == [0, 0]
        " no edge
        return [l0, l0, r0, r0]
    else
        " only left edge
        return [l0, l1, r0, r0]
        " throw "unmatch item edge mark, at:".string([l0, r0])."=".s:textBetween(l0, r0)
    endif

endfunction "}}}

fun! s:GetValueInfo(end) "{{{
    let x = s:bufData()
    let xp = x.renderContext.tmpl.ptn

    if getline(".")[col(".") - 1] != xp.r
        throw "cursor is not at item end position:".string(getpos(".")[1:2])
    endif

    let nEnd = a:end[0] * 10000 + a:end[1]

    let r0 = [ line( "." ), col( "." ) ]

    let l0 = searchpos(xp.lft, 'nW', a:end[0])
    if l0 == [0, 0]
        let l0n = nEnd
    else
        let l0n = min([l0[0] * 10000 + l0[1], nEnd])
    endif

    call s:log.Log("GetValueInfo:end limit=" . l0n)

    let r1 = searchpos(xp.rt, 'W', a:end[0])
    if r1 == [0, 0] || r1[0] * 10000 + r1[1] > l0n
        return [r0, copy(r0), copy(r0)]
    endif

    let r2 = searchpos(xp.rt, 'W', a:end[0])
    if r2 == [0, 0] || r2[0] * 10000 + r2[1] > l0n
        return [r0, r1, copy(r1)]
    endif

    return [r0, r1, r2]
endfunction "}}}

fun! s:clearMinimalIndent( str, firstLineIndent ) "{{{
    let min = a:firstLineIndent

    " protect the first and last line break
    let list = split('=' . a:str . "=", "\n")

    " from the 2nd line, to the last 2nd line
    for line in list[ 2 : -2 ]

        let indentWidth = len( matchstr( line, '^\s*' ) )

        call s:log.Log("indent width:".indentWidth." line=".line)
        let min = min( [ min, indentWidth ] )
    endfor

    call s:log.Log("minimal indent:".min)

    let pattern = '\n\s\{' . min . '}'

    return substitute( a:str, pattern, "\n", 'g' )

    " let ptn = '\s\{' . min . '}'

    let result = [list]
    for line in list[]
        let result += [ line[ min : ] ]
    endfor

    let str = join(result, "\n")

    return str[ : -2 ] " remove last '=' which protect \n

endfunction "}}}

" XSET name|def=
" XSET name|post=
"
" `name^ per-item post-filter ^^
"
"
"


fun! s:createPlaceHolder( ctx, nameInfo, valueInfo ) "{{{

    " 1) Place holder with edge is the editable place holder, for edges of
    " uneditable place holder being ignored. So that only place holder is
    " edited can has edges that will take effect.
    "
    " 2) If none of place holders of one item has edge. The first place
    " holder will be the editable one.
    "
    " 3) if more than one place holders set with edge, the first
    " encountered one takes effect.

    let xp = a:ctx.tmpl.ptn


    " 1 is length of left mark 
    let leftEdge  = s:textBetween(a:nameInfo[0], a:nameInfo[1])
    let name      = s:textBetween(a:nameInfo[1], a:nameInfo[2])
    let rightEdge = s:textBetween(a:nameInfo[2], a:nameInfo[3])

    let [ leftEdge, name, rightEdge ] = [ leftEdge[1 : ], name[1 : ], rightEdge[1 : ] ]

    let fullname  = leftEdge . name . rightEdge

    call s:log.Log( "item is :" . string( [ leftEdge, name, rightEdge ] ) )


    if fullname =~ '\V' . xp.item_var . '\|' . xp.item_func
        " that is only a instant place holder
        return { 'value' : fullname }
    endif

    " PlaceHolder.item is set by caller.
    " At this step, to which item this placeHolder belongs is not concerned.
    let placeHolder = { 
                \ 'name'        : name, 
                \ 'isKey'       : (a:nameInfo[0] != a:nameInfo[1]), 
                \ 'ontimeFilter': '', 
                \ }


    if placeHolder.isKey
        call extend( placeHolder, {
                    \     'leftEdge'  : leftEdge,
                    \     'rightEdge' : rightEdge,
                    \     'fullname'  : fullname,
                    \ }, 'force' )
    endif

    " TODO support of group post filter and ph post filter
    if a:valueInfo[1] != a:valueInfo[0]
        " let isPostFilter = a:valueInfo[1][0] == a:valueInfo[2][0] && a:valueInfo[1][1] + len(xp.r) == a:valueInfo[2][1]

        let val = s:textBetween( a:valueInfo[0], a:valueInfo[1] )
        let val = val[1:]
        let val = s:clearMinimalIndent( val, indent( a:valueInfo[0][0] ) )


        let placeHolder.ontimeFilter = val

        call s:log.Debug("placeHolder post filter:key=val : " . name . "=" . val)
    endif

    return placeHolder

endfunction "}}}

" TODO move me to where I should be
" mark naming principle:
"   XPTM{ nested_level }_{ name }
"   nested_level starts from 0
"   name can be : 
"       `tmpl`start
"       `tmpl`end
"       itemname`placeholder_index`{start|end}
"       itemname`key`{start|end}
"       ``anonymous_index`{start|end}
" Using XPT-left mark as segments delimiter, for no left-mark can be used in
" itemname
"

let s:anonymouseIndex = 0

fun! s:buildMarksOfPlaceHolder(ctx, item, placeHolder, nameInfo, valueInfo) "{{{

    let [ctx, item, placeHolder, nameInfo, valueInfo] = 
                \ [a:ctx, a:item, a:placeHolder, a:nameInfo, a:valueInfo]

    if item.name == ''
        let markName =  '``' . s:anonymouseIndex
        let s:anonymouseIndex += 1

    else
        let markName =  item.name . '`' . ( placeHolder.isKey ? 'key' : (len(item.placeHolders)-1) )

    endif
    " TODO maybe using the mark-symbol variable is better?
    let markPre = ctx.markNamePre . markName . '`'

    call extend( placeHolder, {
                \ 'mark'     : {
                \       'start' : markPre . 'start', 
                \       'end'   : markPre . 'end', 
                \   }, 
                \}, 'force' )

    if placeHolder.isKey
        call extend( placeHolder, {
                    \     'editMark'  : {
                    \           'start' : markPre . 'eStart', 
                    \           'end'   : markPre . 'eEnd', 
                    \       }, 
                    \}, 'force' )
    endif


    " move to after the last right mark
    let valueInfo[2][1] += 1

    " Adjust position of nameInfo and valueInfo.
    " If 2 positions are at the same line, increase shifting width by 1.
    if placeHolder.isKey
        let shift = ( nameInfo[0] != nameInfo[1] && nameInfo[0][0] == nameInfo[1][0])
        let nameInfo[1][1] -= shift
        call s:log.Debug( 'nameInfo.1 decr=' . shift )

        let shift = (nameInfo[1][0] == nameInfo[2][0]) * shift + 1
        let nameInfo[2][1] -= shift
        call s:log.Debug( 'nameInfo.2 decr=' . shift )

        if nameInfo[2] != nameInfo[3]
            let shift = nameInfo[2][0] == nameInfo[3][0] * shift + 1
            let nameInfo[3][1] -= shift
            call s:log.Debug( 'nameInfo.3 decr=' . shift )
        endif

        call XPreplace(nameInfo[0], valueInfo[2], placeHolder.fullname)

    elseif nameInfo[0][0] == nameInfo[3][0]
        let nameInfo[3][1] -= 1
        call XPreplace(nameInfo[0], valueInfo[2], placeHolder.name)

    endif




    call XPMadd( placeHolder.mark.start, nameInfo[0], 'l' )
    call XPMadd( placeHolder.mark.end,   nameInfo[3], 'r' )

    " TODO remember to remove editMark
    if placeHolder.isKey
        call XPMadd( placeHolder.editMark.start, nameInfo[1], 'l' )
        call XPMadd( placeHolder.editMark.end,   nameInfo[2], 'r' )
    endif


endfunction "}}}

fun! s:addItemToRenderContext( ctx, item ) "{{{

    let [ctx, item] = [ a:ctx, a:item ]

    if item.name != ''
        let ctx.itemDict[ item.name ] = item
    endif

    " TODO precise phase, do not use false condition
    if ctx.phase != 'inited'
        " fillin phase 
        " call insert( ctx.itemList, item, 0 )
        call add( ctx.firstList, item )

        call s:log.Log( 'item insert to the head of itemList:' . string( item ) )
        return

    endif

    " rendering phase 

    let firstDict = ctx.tmpl.setting.firstDict
    let lastDict  = ctx.tmpl.setting.lastDict

    if item.name == ''
        call add( ctx.itemList, item )

    elseif has_key( firstDict, item.name )

        let ctx.firstList[ firstDict[ item.name ] ] = item
        call s:log.Log( item.name . ' added to firstList' . string( ctx.firstList ) )
        call s:log.Debug( 'index:' . firstDict[ item.name ] )

    elseif has_key( lastDict, item.name )
        let ctx.lastList[ lastDict[ item.name ] ] = item
        call s:log.Log( item.name . ' added to lastList :' . string( ctx.lastList ) )
        call s:log.Debug( 'index:' . lastDict[ item.name ] )

    else
        call add( ctx.itemList, item )
        call s:log.Log( item.name . ' added to itemList' )

    endif


endfunction "}}}

fun! s:buildPlaceHolders( markRange ) "{{{

    let ctx = s:getRenderContext()
    let xp = ctx.tmpl.ptn

    if ctx.firstList == []
        let ctx.firstList = copy(ctx.tmpl.setting.firstListTemplate)
    endif
    if ctx.lastList == []
        let ctx.lastList = copy(ctx.tmpl.setting.lastListTemplate)
    endif


    let start = XPMpos( a:markRange.start )
    call cursor( start )


    " TODO manually update marks?


    let i = 0
    while i < 10000

        call s:log.Log( "build from here" )


        let end = XPMpos( a:markRange.end )
        let nEnd = end[0] * 10000 + end[1]

        call s:log.Log("build values:end=".string(end))


        " TODO move this action to GetNameInfo
        let nn = searchpos(xp.lft, 'cW')
        if nn == [0, 0] || nn[0] * 10000 + nn[1] >= nEnd
            break
        endif

        let nameInfo = s:GetNameInfo(end)
        if nameInfo[0] == [0, 0]
            " no more items 
            break
        endif


        " locate at end of place holder
        call cursor(nameInfo[3])


        let valueInfo = s:GetValueInfo(end)
        if valueInfo[0] == [0, 0]
            " there is no right mark matching the left mark
            break
        endif


        call s:log.Log("got nameinfo, valueinfo:".string([nameInfo, valueInfo]))


        let placeHolder = s:createPlaceHolder(ctx, nameInfo, valueInfo)

        call s:log.Log( 'built placeHolder=' . string( placeHolder ) )

        if has_key( placeHolder, 'value' )
            " render it instantly
            call s:log.Debug( 'instant placeHolder' )

            " TODO save this 'value' variable?
            let value = s:Eval( placeHolder.value )
            if value =~ '\n'
                let indentSpace = repeat( ' ', indent( nameInfo[0][0] ) )
                let value = substitute( value, '\n', '&' . indentSpace, 'g' )
            endif

            let valueInfo[-1][1] += 1
            call XPreplace( nameInfo[0], valueInfo[-1], value )

            " Cursor left just after replacement, and it is where next search
            " start

        else
            " build item and marks, as a fillin place holder

            let item = s:buildItemForPlaceHolder( ctx, placeHolder )

            call s:buildMarksOfPlaceHolder( ctx, item, placeHolder, nameInfo, valueInfo )

            " nameInfo and valueInfo is updated according to new position
            call cursor(nameInfo[3])

        endif

        let i += 1
    endwhile

    call filter( ctx.firstList, 'v:val != {}' )
    call filter( ctx.lastList, 'v:val != {}' )

    let ctx.itemList = ctx.firstList + ctx.itemList + ctx.lastList

    let ctx.firstList = []
    let ctx.lastList = []
    call s:log.Log( "itemList:" . String( ctx.itemList ) )

    return 0
endfunction "}}}

fun! s:buildItemForPlaceHolder( ctx, placeHolder ) "{{{
    " anonymous item with name set to '' will never been added to a:ctx.itemDict

    if has_key(a:ctx.itemDict, a:placeHolder.name)
        let item = a:ctx.itemDict[ a:placeHolder.name ]

    else
        let item = { 'name'         : a:placeHolder.name, 
                    \'fullname'     : a:placeHolder.name, 
                    \'placeHolders' : [], 
                    \'keyPH'        : s:NullDict, 
                    \}

        call s:addItemToRenderContext( a:ctx, item )

    endif



    if a:placeHolder.isKey
        let item.keyPH = a:placeHolder
        let item.fullname = a:placeHolder.fullname
    else
        call add( item.placeHolders, a:placeHolder )
    endif

    call s:log.Log( 'item built=' . string( item ) )

    return item
endfunction "}}}


fun! s:GetStaticRange(p, q) "{{{
    let tl = a:p
    let br = a:q


    let r = ''
    if tl[0] == br[0]
        let r = r . '\%' . tl[0] . 'l'
        if tl[1] > 1
            let r = r . '\%>' . (tl[1]-1) .'c'
        endif

        let r = r . '\%<' . br[1] . 'c'
    else
        let r = r . '\%>' . tl[0] .'l' . '\%<' . br[0] . 'l'
        let r = r
                    \. '\|' .'\%('.'\%'.tl[0].'l\%>'.(tl[1]-1) .'c\)'
                    \. '\|' .'\%('.'\%'.br[0].'l\%<'.(br[1]+0) .'c\)'
    endif

    let r = '\%(' . r . '\)'
    return '\V'.r

endfunction "}}}

" TODO use syn-keyword
fun! s:HighLightItem(name, switchon) " {{{
    let xp = s:getRenderContext().tmpl.ptn
    if a:switchon
        let ptn = substitute(xp.itemContentPattern, "NAME", a:name, "")

        let ptn = xp.itemMarkLPattern
        exe "2match XPTIgnoredMark /". ptn ."/"

        let ptn = xp.itemMarkRPattern
        exe "3match XPTIgnoredMark /". ptn ."/"
    else
        exe "2match none"
        exe "3match none"
    endif
endfunction " }}}

fun! s:TopTmplRange() "{{{
    let x = s:bufData()
    if empty(x.stack)
        return s:TmplRange()
    else
        let old = x.renderContext
        let x.renderContext = x.stack[0]
        let r = s:TmplRange()
        let x.renderContext = old
    endif
    return r
endfunction "}}}

fun! s:TmplRange() "{{{
    let x = s:bufData()
    let p = [line("."), col(".")]

    call s:GetRangeBetween(s:TL(), s:BR())

    call cursor(p)
    return s:vrange
endfunction "}}}

fun! s:XPTvisual() "{{{
    if &l:slm =~ 'cmd'
	normal! v\<C-g>
    else
	normal! v
    endif
endfunction "}}}

fun! s:GetRangeBetween(p1, p2, ...) "{{{
    let pre = a:0 == 1 && a:1

    if pre
        let p = getpos(".")[1:2]
    endif

    if a:p1[0]*1000+a:p1[1] <= a:p2[0]*1000+a:p2[1]
        let [p1, p2] = [a:p1, a:p2]
    else
        let [p1, p2] = [a:p2, a:p1]
    endif

    " TODO &selection == 'old'
    if &selection == "inclusive"
        let p2 = s:LeftPos(p2)
    endif

    call cursor(p1)
    call s:XPTvisual()
    call cursor(p2)
    normal! v


    if pre
        call cursor(p)
    endif

    return s:vrange

endfunction "}}}

fun! s:finishCurrentAndGotoNextItem(flag) " {{{
    let x = s:bufData()
    let ctx = s:getRenderContext()
    let marks = ctx.leadingPlaceHolder.mark

    " if typing and <tab> pressed together, no update called
    " TODO do not call this if no need to update
    call s:XPTupdate()

    let ctx.phase = 'post'

    let left = XPMpos( marks.start )

    " let p = [line("."), col(".")]
    let name = ctx.item.name

    call s:HighLightItem(name, 0)

    call s:log.Log("finishCurrentAndGotoNextItem flag:" . a:flag)

    if a:flag ==# 'clear'
        call s:log.Log( 'to clear:' . string( [ XPMpos( marks.start ),XPMpos( marks.end ) ] ) )
        call XPreplace(XPMpos( marks.start ),XPMpos( marks.end ), '')
    endif

    let post = s:ApplyPostFilter()

    let ctx.step += [{ 'name' : ctx.item.name, 'value' : post }]
    if ctx.item.name != ''
        let ctx.namedStep[ctx.item.name] = post
    endif


    return s:gotoNextItem()

endfunction " }}}

fun! s:ApplyPostFilter() "{{{

    " *) Group-scope post filter goes first to apply to leading place holder.
    " *) Place-holder post filter then applies if there is one.
    " 
    " Thus, some place holder may be filtered twice.
    "

    let renderContext = s:getRenderContext()
    let xp            = renderContext.tmpl.ptn
    let posts         = renderContext.tmpl.setting.postFilters
    let name          = renderContext.item.name
    let fullname      = renderContext.item.fullname

    let marks = renderContext.leadingPlaceHolder.mark

    call s:log.Log("before post filtering, tmpl:\n" . s:textBetween(XPMpos(renderContext.marks.tmpl.start), XPMpos(renderContext.marks.tmpl.end)))

    let typed = s:textBetween(XPMpos( marks.start ), XPMpos( marks.end ))


    " TODO post filter for each place holder



    let hasPostFilter = 1

    if has_key(posts, name)
        let postFilter = posts[ name ]
    
    else
        let hasPostFilter = 0

    endif


    " elseif renderContext.leadingPlaceHolder.postFilter != ''
        " let postFilter = renderContext.leadingPlaceHolder.postFilter



    call s:log.Log("name:".name)
    call s:log.Log("typed:".typed)
    call s:log.Log("match:".(name =~ s:expandablePattern))
    call s:log.Log('has post filter ?:' . hasPostFilter)


    if hasPostFilter

        let isPlainExpansion = 
                    \   name =~ s:repetitionPattern 
                    \|| name =~ s:expandablePattern

        if isPlainExpansion
            let post = substitute(postFilter, '\V\\\(\.\)', '\1', 'g')

        else
            let post = s:Eval(postFilter, {'typed' : typed})

        endif



        " TODO use function to implement the following codes

        if name =~ s:repetitionPattern
            let isrep = typed =~# '\V\^\_s\*' . name . '\_s\*\$'

        elseif name =~ s:expandablePattern
            let isrep = typed =~# substitute(s:expandablePattern, '\V\\w+\\V...',  '\\V'.name, '')

        else
            let isrep = 1

        endif

        call s:log.Log("isrep?" . isrep)
        call s:log.Log("post:\n", post)
        call s:log.Log("before replace, tmpl=\n".s:textBetween(s:TL(), s:BR()))

        if isrep

            " adjust indent
            let indent = indent(XPMpos( marks.start )[0])
            call s:log.Debug( 'line to get indent:' . getline( XPMpos( marks.start )[0] ) )
            call s:log.Debug( 'post filter indent at line[' . XPMpos( marks.start )[0] . ']:' . indent )

            let indentspaces = repeat(' ', indent)
            let post = substitute( post, "\n", "\n" . indentspaces, 'g' )

            call XPreplace(XPMpos( marks.start ), XPMpos( marks.end ), post)
            call cursor(XPMpos( marks.start ))

            let renderContext.firstList = []
            if 0 != s:buildPlaceHolders( renderContext.leadingPlaceHolder.mark )
                return s:crash()
            endif

            call s:XPTupdate()
            return post
        endif
    else
        " let escapedTyped = substitute( typed, s:escapeHead . '\[' . xp.l . xp.r . ']', '\1\\&', 'g' )

        " call XPreplace(XPMpos( marks.start ), XPMpos( marks.end ), escapedTyped)
        " if typed !=# escapedTyped
            " call s:XPTupdate()
        " endif

    endif

    call s:XPTupdate()

    return typed

endfunction "}}}

" TODO rename me
fun! s:gotoNextItem() "{{{
    " @return   insert mode typing action
    " @param    position from where to start search.

    let renderContext = s:getRenderContext()
    let xmark = renderContext.marks

    call s:log.Log( 'renderContext=' . string( renderContext ) )
    let xp = renderContext.tmpl.ptn

    let placeHolder = s:extractOneItem()


    if placeHolder == s:NullDict
        call cursor( XPMpos( xmark.tmpl.end ) )
        return s:XPTemplateFinish(1)
    endif

    call s:log.Log("extractOneItem:".string(placeHolder))
    call s:log.Log("leadingPlaceHolder pos:".string(XPMpos( placeHolder.mark.start )))

    let phPos = XPMpos( placeHolder.mark.start )
    if phPos == [0, 0]
        " error found no position of mark
        call Error( 'failed to find position of mark:' . placeHolder.mark.*** )
        return s:crash()
    endif

    call s:log.Log( "all marks:" . XPMallMark() )


    let postaction = s:initItem()

    call s:log.Log( 'after initItem, postaction='.postaction )

    if !renderContext.processing
        return postaction

    elseif postaction != ''
        return postaction

    else
        call cursor( XPMpos( renderContext.leadingPlaceHolder.mark.end ) )
        return ""

    endif

endfunction "}}}

fun! s:Format(range) "{{{

    " TODO 
    return



    let x = s:bufData()
    let ctx = x.renderContext

    if ctx.tmpl.indent.type !=# "auto"
        return
    endif

    call s:PushBackPos()

    let pt = s:TL()
    let pt[1] = pt[1] - len(getline(pt[0]))




    if ctx.processing && ctx.pos.curpos != {}
        let pi = ctx.pos.editpos.start.pos
        let pi[1] = pi[1] - len(getline(pi[0]))

        let pc = s:CTL(x)
        let pc[1] = pc[1] - len(getline(pc[0]))
        " let bf = matchstr(x.renderContext.lastBefore, s:stripPtn)
    endif

    if a:range == 1
        call s:log.Log("template before last format:", s:textBetween(s:TL(), s:BR()))
        call s:log.Log("template range : ".string([s:TL(), s:BR()]))
        " call s:log.Log("current syntax:".string(SynNameStack(3, 1)))
        call s:TmplRange()
        normal! gv=
    elseif a:range == 2
        call s:TopTmplRange()
        normal! gv=
    else
        normal! ==
    endif
    call s:log.Log("template after last format:", s:textBetween(s:TL(), s:BR()))


    if ctx.processing && ctx.pos.curpos != {}
        call ctx.pos.editpos.start.set( pi[0], max([pi[1] + len(getline(pi[0])), 1]))
        " let x.renderContext.pos.curpos.l = max([pc[1] + len(getline(pc[0])), 1])
        " let x.renderContext.lastBefore = matchstr(getline(pc[0]), '\V\^\s\*'.escape(bf, '\'))
        " call s:log.Log("bf is:" . bf)
        call s:log.Log("current line:".getline(pc[0]))
        " call s:log.Log("lastBefore after format:".x.renderContext.lastBefore)
    endif


    call s:PopBackPos()
    " call cursor(p[0], p[1] + len(getline(".")))

endfunction "}}}

fun! s:TL(...)
    return XPMpos( s:bufData().renderContext.marks.tmpl.start )
endfunction
fun! s:BR(...)
    return XPMpos( s:bufData().renderContext.marks.tmpl.end )
endfunction

fun! s:extractOneItem() "{{{

    let renderContext = s:getRenderContext()
    let itemList = renderContext.itemList

    let [ renderContext.item, renderContext.leadingPlaceHolder ] = [ {}, {} ]

    if empty( itemList )
        return s:NullDict
    endif

    let item = itemList[ 0 ]

    let renderContext.itemList = renderContext.itemList[ 1 : ]
    if item.name != ''
        unlet renderContext.itemDict[ item.name ]
    endif

    let renderContext.item = item
    
    if empty( item.placeHolders ) && item.keyPH == s:NullDict
        echoerr "item without placeholders!"
        return s:NullDict
    endif


    " TODO when update, avoid updating leadingPlaceHolder
    if item.keyPH == s:NullDict
        let renderContext.leadingPlaceHolder = item.placeHolders[0]
    else
        let renderContext.leadingPlaceHolder = item.keyPH
        let item.fullname = item.keyPH.fullname
    endif

    return renderContext.leadingPlaceHolder

endfunction "}}}

fun! s:handleDefaultValueAction( ctx, act ) "{{{
    " @return   string  typing 
    "           -1      if this action can not be handled

    let ctx = a:ctx

    if has_key(a:act, 'action') " actions

        call s:log.Log( "type is ".type(a:act). ' {} type is '.type({}) )

        if a:act.action == 'expandTmpl' && has_key( a:act, 'tmplName' )
            " do NOT need to update position 
            call XPreplace(XPMpos( ctx.leadingPlaceHolder.mark.start ), XPMpos( ctx.leadingPlaceHolder.mark.end ), '')
            return XPTemplateStart(0, {'startPos' : getpos(".")[1:2], 'tmplName' : a:act.tmplName})

        elseif a:act.action == 'finishTemplate'
            " do NOT need to update position 
            call XPreplace(XPMpos( ctx.leadingPlaceHolder.mark.start ), XPMpos( ctx.leadingPlaceHolder.mark.end )
                        \, has_key( a:act, 'postTyping' ) ? a:act.postTyping : '' )

            return s:XPTemplateFinish()

        elseif a:act.action == 'embed'
            " embed a piece of snippet

            return s:embedSnippetInLeadingPlaceHolder( ctx, a:act.snippet )

        else " other action

        endif

        return -1

    else
        return -1
    endif

endfunction "}}}

fun! s:adjustIndentAccordToLine( str, lineNr ) "{{{
    let indent = indent(a:lineNr)
    let indentSpaces = repeat(' ', indent)
    let str = substitute( a:str, "\n", "\n" . indentSpaces, 'g' )
    return str
endfunction "}}}

fun! s:embedSnippetInLeadingPlaceHolder( ctx, snippet ) 
    " TODO remove needless marks
    let ph = a:ctx.leadingPlaceHolder
    
    let marks = ph.isKey ? ph.editMark : ph.mark
    let range = [ XPMpos( marks.start ), XPMpos( marks.end ) ]
    if range[0] == [0, 0] || range[1] == [0, 0]
        return s:crash( 'leading place holder''s mark lost:' . string( marks ) )
    endif

    call XPreplace( range[0], range[1] , a:snippet )

    if 0 != s:buildPlaceHolders( marks )
        return s:crash('building place holder failed')
    endif

    return s:gotoNextItem()
endfunction

fun! s:fillinLeadingPlaceHolderAndSelect( ctx, str ) "{{{
    " TODO remove needless marks

    let [ ctx, str ] = [ a:ctx, a:str ]
    let [ item, ph ] = [ ctx.item, ctx.leadingPlaceHolder ]

    let marks = ph.isKey ? ph.editMark : ph.mark
    let [ start, end ] = [ XPMpos( marks.start ), XPMpos( marks.end ) ]


    if start == [0, 0] || end == [0, 0]
        return s:crash()
    endif


    " set str to key place holder or the first normal place holder 
    call XPreplace( start, end, str )

    let xp = ctx.tmpl.ptn

    if str =~ '\V'.xp.lft.'\.\*'.xp.rt
        if 0 != s:buildPlaceHolders( marks )
            return s:crash()
        endif

        call s:log.Log( 'rebuild default values' )
        return s:gotoNextItem()
    endif


    call s:XPTupdate()

    return s:selectCurrent(ctx)

endfunction "}}}

fun! s:applyDefaultValueToPH( renderContext ) "{{{

    call s:log.Log( "**" )

    let renderContext = a:renderContext
    let str = renderContext.tmpl.setting.defaultValues[renderContext.item.name]

    " popup list, action dictionary or string
    let obj = s:Eval(str) 


    if type(obj) == type({})
        " action object
        let rc = s:handleDefaultValueAction( renderContext, obj )

        return ( rc is -1 ) ? s:fillinLeadingPlaceHolderAndSelect( renderContext, '' ) : rc

    elseif type(obj) == type([])
        " popup list

        if len(obj) == 0
            return s:fillinLeadingPlaceHolderAndSelect( renderContext, '' )
        endif

        " to popup 
        call XPreplace( XPMpos( renderContext.leadingPlaceHolder.mark.start ), XPMpos( renderContext.leadingPlaceHolder.mark.end ), '')
        call cursor(xpos.editpos.start.pos)

        return XPPopupNew(s:ItemPumCB, {}, obj).popup(col("."))

    else " string
        let str = s:adjustIndentAccordToLine( obj, XPMpos( renderContext.leadingPlaceHolder.mark.start )[0] )

        return s:fillinLeadingPlaceHolderAndSelect( renderContext, str )

    endif
endfunction "}}}

" return type action
fun! s:initItem() " {{{
    let renderContext = s:getRenderContext()
    let renderContext.phase = 'inititem'

    " apply default value
    if has_key(renderContext.tmpl.setting.defaultValues, renderContext.item.name)
        return s:applyDefaultValueToPH( renderContext )

    else
        let str = renderContext.item.name
        return s:fillinLeadingPlaceHolderAndSelect( renderContext, str )

    endif

    " return s:selectCurrent(renderContext)

endfunction " }}}

fun! s:selectCurrent( renderContext )
    let ph = a:renderContext.leadingPlaceHolder
    let marks = ph.isKey ? ph.editMark : ph.mark

    let [ ctl, cbr ] = [ XPMpos( marks.start ), XPMpos( marks.end ) ]

    let a:renderContext.phase = 'fillin'

    if ctl == cbr 
        return ''
    else
        call cursor( ctl )
        normal! v
        if &l:selection == 'exclusive'
            call cursor( cbr )
        else
            if cbr[1] == 1
                call cursor( cbr[0] - 1, col( [ cbr[0] - 1, '$' ] ) )
            else
                call cursor( cbr[0], cbr[1] - 1 )
            endif
        endif

        return s:SelectAction()
    endif

endfunction

" TODO
fun! s:UnescapeChar( str, chars )
    if chars == ''
        return
    endif


endfunction

fun! s:createStringMask( str ) "{{{

    if a:str == ''
        return ''
    endif

    if !exists( 'b:_xpeval' )
        let b:_xpeval = { 'cache' : {} }
    endif

    if has_key( b:_xpeval.cache, a:str )
        return b:_xpeval.cache[ a:str ]
    endif

    " non-escaped prefix
    let nonEscaped =   '\%(' . '\%(\[^\\]\|\^\)' . '\%(\\\\\)\*' . '\)' . '\@<='

    " non-escaped quotation
    let dqe = '\V\('. nonEscaped . '"\)'
    let sqe = '\V\('. nonEscaped . "'\\)"

    let dptn = dqe.'\_.\{-}\1'
    let sptn = sqe.'\_.\{-}\1'

    " create mask hiding all string literal with space
    let mask = substitute(a:str, '[ *]', '+', 'g')
    while 1 "{{{
        let d = match(mask, dptn)
        let s = match(mask, sptn)

        if d == -1 && s == -1
            break
        endif

        if d > -1 && (d < s || s == -1)
            let sub = matchstr(mask, dptn)
            let sub = repeat(' ', len(sub))
            let mask = substitute(mask, dptn, sub, '')
        elseif s > -1
            let sub = matchstr(mask, sptn)
            let sub = repeat(' ', len(sub))
            let mask = substitute(mask, sptn, sub, '')
        endif

    endwhile "}}}

    let b:_xpeval.cache[ a:str ] = mask

    return mask

endfunction "}}}

fun! S2l(a, b)
    return a:a - a:b
endfunction

fun! s:Eval(s, ...) "{{{
    let x = s:bufData()
    let ctx = s:getRenderContext()
    let xfunc = x.funcs

    let tmpEvalCtx = { 'typed' : '', 'usingCache' : 1 }

    if a:0 >= 1
        call extend( tmpEvalCtx, a:1, 'force' )
    endif


    " non-escaped prefix
    let nonEscaped =   '\%(' . '\%(\[^\\]\|\^\)' . '\%(\\\\\)\*' . '\)' . '\@<='


    let fptn = '\V' . '\w\+(\[^($]\{-})' . '\|' . nonEscaped . '{\w\+(\[^($]\{-})}'
    let vptn = '\V' . '$\w\+' . '\|' . nonEscaped . '{$\w\+}'

    let patternVarOrFunc = fptn . '\|' . vptn

    let stringMask = s:createStringMask( a:s )




    let xfunc._ctx = ctx.evalCtx
    let xfunc._ctx.tmpl = ctx.tmpl
    let xfunc._ctx.step = {}
    let xfunc._ctx.namedStep = {}
    let xfunc._ctx.value = ''
    if ctx.processing
        let xfunc._ctx.step = ctx.step
        let xfunc._ctx.namedStep = ctx.namedStep
        let xfunc._ctx.name = ctx.item.name
        let xfunc._ctx.fullname = ctx.item.fullname
        let xfunc._ctx.value = tmpEvalCtx.typed
    endif

    call s:log.Log("eval ctx:".string(xfunc._ctx))



    " parameter string list
    let rangesToEval = {}
    let str = a:s


    while 1

        let matchedIndex = match(stringMask, patternVarOrFunc)
        if matchedIndex == -1
            break
        endif


        let matchedLen = len(matchstr(stringMask, patternVarOrFunc))
        let matched = str[matchedIndex : matchedIndex + matchedLen - 1]


        if matched =~ '^{.*}$'
            let matched = matched[1:-2]
        endif



        if matched[-1:] == ')' && has_key(xfunc, matchstr(matched, '^\w\+'))
            let matched = "xfunc." . matched

        elseif matched[0:0] == '$' && has_key(xfunc, matched)
            let matched = 'xfunc["' . matched . '"]'

        endif


        let contextedMatchedLen = len(matched)


        " remove spanned sub expression
        for i in keys(rangesToEval)
            if i >= matchedIndex && i < matchedIndex + matchedLen
                call remove(rangesToEval, i)
            endif
        endfor

        " add unparsed string
        let rangesToEval[matchedIndex] = contextedMatchedLen


        let stringMask = (matchedIndex == 0 ? "" : stringMask[:matchedIndex-1]) 
                    \ . repeat(' ', contextedMatchedLen)
                    \ . stringMask[matchedIndex + matchedLen :]

        let str  = (matchedIndex == 0 ? "" :  str[:matchedIndex-1])
                    \ . matched
                    \ . str[matchedIndex + matchedLen :]

    endwhile




    let sp = ""
    let last = 0


    let offsetsOfEltsToEval = sort(keys(rangesToEval), "S2l")


    for k in offsetsOfEltsToEval

        let kn = 0 + k
        let vn = 0 + k + rangesToEval[k]


        " unescape \{ and \(
        " match the previous line )} - -..
        let tmp = k == 0 ? "" : (str[last : kn-1])
        let tmp = substitute(tmp, '\\\(.\)', '\1', 'g')
        let sp .= tmp


        let evaledResult = eval(str[kn : vn-1])

        if type(evaledResult) != type('')
            call s:log.Log( "Eval:evaluated type is not string but =" . type(evaledResult) . ' '.str[ kn : vn - 1 ] )
            " discard anything else
            return evaledResult
        endif

        let sp .= evaledResult


        let last = vn
    endfor

    let tmp = str[last : ]
    let tmp = substitute(tmp, '\\\(.\)', '\1', 'g')
    let sp .= tmp

    return sp

endfunction "}}}

fun! s:textBetween(p1, p2) "{{{
    if a:p1[0] > a:p2[0]
        return ""
    endif

    let [p1, p2] = [a:p1, a:p2]

    if p1[0] == p2[0]
        if p1[1] == p2[1]
            return ""
        else
            call s:log.Log( "content between " . string( [a:p1, a:p2] ) . ' is :' . getline(p1[0])[ p1[1] - 1 : p2[1] - 2] )
            return getline(p1[0])[ p1[1] - 1 : p2[1] - 2]
        endif
    endif


    let r = [ getline(p1[0])[p1[1] - 1:] ] + getline(p1[0]+1, p2[0]-1)

    if p2[1] > 1
        let r += [ getline(p2[0])[:p2[1] - 2] ]
    else
        let r += ['']
    endif

    call s:log.Log( "content between " . string( [a:p1, a:p2] ) . ' is :'.join( r, "\n" ) )
    return join(r, "\n")

endfunction "}}}

" Weird, but that's only way to select content
fun! s:SelectAction() "{{{
    return "\<esc>gv\<C-g>"

    if &l:slm =~ 'cmd'
        return "\<esc>gv"
    else
        return "\<esc>gv\<C-g>"
    endif
endfunction "}}}

fun! s:LeftPos(p) "{{{
    let p = a:p
    if p[1] == 1
        if p[0] > 1
            let p = [p[0]-1, col([p[0]-1, "$"])]
        endif
    else
        let p = [p[0], p[1]-1]
    endif

    let p[1] = max([p[1], 1])
    return p
endfunction "}}}

fun! s:CheckAndBS(k) "{{{
    let x = s:bufData()

    let p = [ line( "." ), col( "." ) ]
    let ctl = s:CTL(x)

    if p[0] == ctl[0] && p[1] == ctl[1]
        return ""
    else
        let k= eval('"\<'.a:k.'>"')
        return k
    endif
endfunction "}}}
fun! s:CheckAndDel(k) "{{{
    let x = s:bufData()

    let p = getpos(".")[1:2]
    let cbr = s:CBR(x)

    if p[0] == cbr[0] && p[1] == cbr[1]
        return ""
    else
        let k= eval('"\<'.a:k.'>"')
        return k
    endif
endfunction "}}}

fun! s:goback() "{{{
    let renderContext = s:getRenderContext()
    call cursor( XPMpos( renderContext.leadingPlaceHolder.mark.end ) )

    return ''
endfunction "}}}

fun! s:ApplyMap() " {{{
    let x = s:bufData()
    let savedMap = x.savedMap

    " let savedMap.i_bs       = g:MapPush("<bs>", "i", 1)
    " let savedMap.i_c_w      = g:MapPush("<C-w>", "i", 1)
    " let savedMap.i_del      = g:MapPush("<Del>", "i", 1)

    let savedMap.i_nav      = g:MapPush(g:xptemplate_nav_next  , "i", 1)
    let savedMap.s_nav      = g:MapPush(g:xptemplate_nav_next  , "s", 1)
    let savedMap.s_cancel   = g:MapPush(g:xptemplate_nav_cancel, "s", 1)

    let savedMap.s_del      = g:MapPush("<Del>", "s", 1)
    let savedMap.s_bs       = g:MapPush("<bs>", "s", 1)
    let savedMap.s_right    = g:MapPush(g:xptemplate_to_right, "s", 1)

    let savedMap.n_back     = g:MapPush(g:xptemplate_goback, "n", 1)




    " inoremap <silent> <buffer> <bs> <C-r>=<SID>CheckAndBS("bs")<cr>
    " inoremap <silent> <buffer> <C-w> <C-r>=<SID>CheckAndBS("C-w")<cr>
    " inoremap <silent> <buffer> <Del> <C-r>=<SID>CheckAndDel("Del")<cr>

    exe 'inoremap <silent> <buffer> '.g:xptemplate_nav_next  .' <C-r>=<SID>finishCurrentAndGotoNextItem("")<cr>'
    exe 'snoremap <silent> <buffer> '.g:xptemplate_nav_next  .' <Esc>`>a<C-r>=<SID>finishCurrentAndGotoNextItem("")<cr>'
    exe 'snoremap <silent> <buffer> '.g:xptemplate_nav_cancel.' <Esc>i<C-r>=<SID>finishCurrentAndGotoNextItem("clear")<cr>'

    exe 'nnoremap <silent> <buffer> '.g:xptemplate_goback . ' i<C-r>=<SID>goback()<cr>'

    snoremap <silent> <buffer> <Del> <Del>i
    snoremap <silent> <buffer> <bs> <esc>`>a<bs>
    exe "snoremap <silent> <buffer> ".g:xptemplate_to_right." <esc>`>a"

endfunction " }}}

fun! s:ClearMap() " {{{
    let x = s:bufData()
    let savedMap = x.savedMap

    " clear all
    " iunmap <buffer> <bs>
    " iunmap <buffer> <C-w>
    " iunmap <buffer> <Del>
    exe 'iunmap <buffer> '.g:xptemplate_nav_next
    exe 'sunmap <buffer> '.g:xptemplate_nav_next
    exe 'sunmap <buffer> '.g:xptemplate_nav_cancel

    exe 'nunmap <buffer> '.g:xptemplate_goback

    sunmap <buffer> <Del>
    sunmap <buffer> <bs>
    exe "sunmap <buffer> ".g:xptemplate_to_right


    " restore map, reversed order

    call g:MapPop(savedMap.n_back  )

    call g:MapPop(savedMap.s_right )
    call g:MapPop(savedMap.s_bs    )
    call g:MapPop(savedMap.s_del   )

    call g:MapPop(savedMap.s_cancel)
    call g:MapPop(savedMap.s_nav   )
    call g:MapPop(savedMap.i_nav   )

    " call g:MapPop(savedMap.i_del   )
    " call g:MapPop(savedMap.i_c_w   )
    " call g:MapPop(savedMap.i_bs    )

    let x.savedMap = {}

endfunction " }}}

fun! s:StartAppend() " {{{

    let emptyline = (getline(".") =~ '^\s*$')
    if emptyline
        return "\<END>;\<C-c>==A\<BS>"
    endif

    return ""

endfunction " }}}


fun! s:CTL(...) "{{{
    let x = a:0 == 1 ? a:1 : s:bufData()
    let cp = x.renderContext.pos.curpos
    return copy( cp.start.pos )
endfunction "}}}

fun! s:CBR(...) "{{{
    let x = a:0 == 1 ? a:1 : s:bufData()
    let cp = x.renderContext.pos.curpos
    return copy( cp.end.pos )
endfunction "}}}


" debug only
fun! XPTbufData() "{{{
    return s:bufData()
endfunction "}}}


fun! s:createRenderContext(x) "{{{
    call s:log.Log( 'new render context is created' )

    let a:x.renderContext = deepcopy( s:renderContextPrototype )
    let a:x.renderContext.lastTotalLine = line( '$' )
    let a:x.renderContext.markNamePre = "XPTM" . len( a:x.stack ) . '_'
    let a:x.renderContext.marks.tmpl = { 
                \ 'start' : a:x.renderContext.markNamePre . '`tmpl`start', 
                \ 'end'   : a:x.renderContext.markNamePre . '`tmpl`end', }

    return a:x.renderContext
endfunction "}}}

fun! s:getRenderContext(...) "{{{
    let x = a:0 == 1 ? a:1 : s:bufData()
    return x.renderContext
endfunction "}}}

fun! s:bufData() "{{{
    if !exists("b:xptemplateData")
        let b:xptemplateData = {'tmplarr' : [], 'normalTemplates' : {}, 'funcs' : {}, 'vars' : {}, 'wrapStartPos' : 0, 'startColumn' : 0, 'wrap' : '', 'functionContainer' : {}}
        let b:xptemplateData.funcs = b:xptemplateData.vars
        let b:xptemplateData.varPriority = {}
        let b:xptemplateData.posStack = []
        let b:xptemplateData.stack = []

        " which letter can be used in template name
        let b:xptemplateData.keyword = '\w'

        let b:xptemplateData.savedMap = {}

        call s:createRenderContext( b:xptemplateData )

        let b:xptemplateData.bufsetting = {
                    \'ptn' : {'l':'`', 'r':'^'},
                    \'indent' : {'type' : 'auto', 'rate' : []},
                    \'priority' : s:priorities.lang
                    \}

        call s:RedefinePattern()

    endif
    return b:xptemplateData
endfunction "}}}
fun! s:RedefinePattern() "{{{
    let xp = b:xptemplateData.bufsetting.ptn

    " even number of '\' or start of line
    let nonEscaped = s:nonEscaped

    let xp.lft = nonEscaped . xp.l
    let xp.rt  = nonEscaped . xp.r

    " for search
    let xp.lft_e = nonEscaped. '\\'.xp.l
    let xp.rt_e  = nonEscaped. '\\'.xp.r

    " regular pattern to match any template item.
    let xp.itemPattern       = xp.lft . '\%(NAME\)' . xp.rt
    let xp.itemContentPattern= xp.lft . '\zs\%(NAME\)\ze' . xp.rt

    let xp.item_var          = '$\w\+'
    let xp.item_qvar         = '{$\w\+}'
    let xp.item_func         = '\w\+(\.\*)'
    let xp.item_qfunc        = '{\w\+(\.\*)}'
    " let xp.itemContent       = xp.item_var . '\|' . xp.item_func . '\|' . '\_.\{-}'
    let xp.itemContent       = '\_.\{-}'
    let xp.item              = xp.lft . '\%(' . xp.itemContent . '\)' . xp.rt

    let xp.itemMarkLPattern  = '\zs'. xp.lft . '\ze\%(' . xp.itemContent . '\)' . xp.rt
    let xp.itemMarkRPattern  = xp.lft . '\%(' . xp.itemContent . '\)\zs' . xp.rt .'\ze'

    let xp.cursorPattern     = xp.lft . '\%('.s:cursorName.'\)' . xp.rt

    for [k, v] in items(xp)
        if k != "l" && k != "r"
            let xp[k] = '\V' . v
        endif
    endfor

endfunction "}}}

fun! s:PushCtx() "{{{
    let x = s:bufData()

    let x.stack += [s:getRenderContext()]
    call s:createRenderContext(x)
endfunction "}}}
fun! s:PopCtx() "{{{
    let x = s:bufData()
    let x.renderContext = x.stack[-1]
    call remove(x.stack, -1)
    " call s:HighLightItem(x.renderContext.name, 1)
endfunction "}}}


" TODO accept position argument
fun! s:GetBackPos() "{{{
    return [line(".") - line("$"), col(".") - len(getline("."))]
endfunction "}}}

fun! s:PushBackPos() "{{{
    call add(s:bufData().posStack, s:GetBackPos())
endfunction "}}}
fun! s:PopBackPos() "{{{
    let x = s:bufData()
    let bp = x.posStack[-1]
    call remove(x.posStack, -1)

    let l = bp[0] + line("$")
    let p = [l, bp[1] + len(getline(l))]
    call cursor(p)
    return p
endfunction "}}}


fun! s:SynNameStack(l, c) "{{{
    let ids = synstack(a:l, a:c)
    if empty(ids)
        return []
    endif

    let names = []
    for id in ids
        let names = names + [synIDattr(id, "name")]
    endfor
    return names
endfunction "}}}

fun! s:CurSynNameStack() "{{{
    return SynNameStack(line("."), col("."))
endfunction "}}}


fun! s:updateFollowingPlaceHoldersWith( contentTyped ) "{{{

    let ctx = s:getRenderContext()

    let phList = ctx.item.placeHolders
    let phList = ctx.leadingPlaceHolder.isKey ? phList : phList[1:]
    for ph in phList
        if ph.ontimeFilter != ''
            let ontimeResult = s:Eval( ph.ontimeFilter, { 'typed' : a:contentTyped } )
            " TODO ontime filter action support?
        else
            let ontimeResult = a:contentTyped
        endif


        call XPreplace( XPMpos( ph.mark.start ), XPMpos( ph.mark.end ), ontimeResult )

        call s:log.Debug( 'after update 1 place holder:', s:textBetween( XPMpos( ctx.marks.tmpl.start ), XPMpos( ctx.marks.tmpl.end ) ) )
    endfor

endfunction "}}}

fun! s:crash() "{{{

    let msg = "XPTemplate snippet crashed :"

    let x = s:bufData()

    for ctx in x.stack
        " TODO nicer message
        let msg .= ctx.tmpl.name . ' -> '
    endfor


    let x.stack = []
    call s:createRenderContext(x)
    call XPMflush()

    " TODO clear highlight

    echohl WarningMsg
    echom msg
    echohl

    " no post typing action
    return ''
endfunction "}}}

fun! s:fixCrCausedIndentProblem()
    let renderContext = s:getRenderContext()

    let currentTotalLine = line( '$' )
    let currentPos = [ line( '.' ), col( '.' ) ]
    let currentFollowingSpace = getline( currentPos[0] )[ currentPos[1] - 1 : ]
    let currentFollowingSpace = matchstr( currentFollowingSpace, '^\s*' )

    if renderContext.lastFollowingSpace == ''
                \ || renderContext.lastTotalLine >= currentTotalLine

        let renderContext.lastFollowingSpace = currentFollowingSpace
        return

    endif

    " let currentFollowingSpace = matchstr( currentFollowingSpace, '^\s*' )

    if currentFollowingSpace != renderContext.lastFollowingSpace
        call XPreplace( currentPos, [ currentPos[0], currentPos[1] + len( currentFollowingSpace ) ], renderContext.lastFollowingSpace, 0 )
        call cursor( currentPos )
    endif

endfunction

fun! s:XPTupdate(...) "{{{

    let renderContext = s:getRenderContext()


    if !renderContext.processing
        call XPMupdateStat()
        return
    endif


    call s:log.Log("XPTupdate called, mode:".mode())

    call s:log.Info( "marks before XPTupdate:\n" . XPMallMark() )

    call s:fixCrCausedIndentProblem()
    


    " TODO hint to indicate whether cursor is at the right place 

    " TODO check current cursor position for crashing or fixing


    call XPMupdate()



    let keyMark = renderContext.leadingPlaceHolder.mark
    let [ start, end ] = [ XPMpos( keyMark.start ), XPMpos( keyMark.end ) ]

    if start == [0, 0] || end == [0, 0]
        return s:crash()
    endif

    let typedContent = s:textBetween( start, end )


    if typedContent ==# renderContext.lastContent
        call s:log.Log( "the same typed" )
        call XPMupdateStat()
        return
    endif

    call s:log.Log( "typed:".typedContent )


    " TODO <cr> causing auto-indent swollow spaces before next non-space char
    " if 


    call s:CallPlugin("beforeUpdate")

    " update items


    call s:log.Log("-----------------------")
    call s:log.Log('mode='.mode())
    call s:log.Log("tmpl\n".s:textBetween(s:TL(), s:BR()))
    call s:log.Log("lastContent=".renderContext.lastContent)
    call s:log.Log("typedContent=".typedContent)


    let currentPosMark = '````'
    call XPMhere( currentPosMark )

    " in most cases there is no line break
    if len( renderContext.lastContent ) == len( typedContent ) && typedContent !~ '\n' && renderContext.lastContent !~ '\n'
        " ignore position fixing
        call s:updateFollowingPlaceHoldersWith( typedContent )
    else
        call s:updateFollowingPlaceHoldersWith( typedContent )
    endif





    let renderContext.lastContent = typedContent
    let renderContext.lastTotalLine = line( '$' )


    call cursor(XPMpos( currentPosMark ))

    call s:CallPlugin('afterUpdate')

    

    call s:log.Log( "cursor last stays at:" . string( XPMpos(currentPosMark) ) )

    call XPMremove( currentPosMark )
    call s:log.Info( "marks after XPTupdate:\n" . XPMallMark() )

    call XPMupdateStat()

endfunction "}}}

fun! s:XPTcheck() "{{{
    let x = s:bufData()

    if x.wrap != ''
        let x.wrapStartPos = 0
        let x.wrap = ''
    endif
endfunction "}}}

fun! s:XPTtrackFollowingSpace() "{{{
    let renderContext = s:getRenderContext()

    let currentPos = [ line( '.' ), col( '.' ) ]
    let currentFollowingSpace = getline( currentPos[0] )[ currentPos[1] - 1 : ]
    let currentFollowingSpace = matchstr( currentFollowingSpace, '^\s*' )

    let renderContext.lastFollowingSpace = currentFollowingSpace

endfunction "}}}

augroup XPT "{{{
    au!
    au InsertEnter * call <SID>XPTcheck()

    " au CursorHoldI * call <SID>XPTupdate()
    au CursorMovedI * call <SID>XPTupdate()
    au CursorMoved * call <SID>XPTtrackFollowingSpace()

    " InsertEnter is called in normal mode
    " au InsertEnter * call <SID>XPTupdate('n')

augroup END "}}}

fun! g:XPTaddPlugin(event, func) "{{{
    if has_key(s:plugins, a:event)
        call add(s:plugins[a:event], a:func)
    else
        throw "XPT does NOT support event:".a:event
    endif
endfunction "}}}

fun! s:CallPlugin(ev) "{{{
    if !has_key(s:plugins, a:ev)
        throw "calling invalid event:".a:ev
    endif

    let x = s:bufData()
    let v = 0

    for f in s:plugins[a:ev]
        let v = g:XPT[f](x)
        " if !v
        " return
        " endif
    endfor

endfunction "}}}

fun! s:Link(fs) "{{{
    let list = split(a:fs, ' ')
    for v in list
        let s:f[v] = function('<SNR>'.s:sid . v)
    endfor
endfunction "}}}

call <SID>Link('TmplRange GetRangeBetween textBetween GetStaticRange LeftPos')



com! XPTreload call XPTreload()
com! XPTcrash call <SID>crash()


fun! String( d, ... )
    " circle referencing can not be dealed well yet. 

    let str = string( a:d )
    let str = substitute( str, "\\V'\\%(\\[^']\\|''\\)\\{-}'" . '\s\*:\s\*function\[^)]),\s\*', '', 'g' )

    return str

endfunction


" vim: set sw=4 sts=4 :
