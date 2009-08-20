if exists("g:__XPTEMPLATE_VIM__")
    finish
endif
let g:__XPTEMPLATE_VIM__ = 1
com! XPTgetSID let s:sid =  matchstr("<SID>", '\zs\d\+_\ze')
XPTgetSID
delc XPTgetSID
runtime plugin/mapstack.vim
runtime plugin/xpreplace.vim
runtime plugin/xpmark.vim
runtime plugin/xpopup.vim
runtime plugin/xptemplate.conf.vim
call XPRaddPreJob( 'XPMupdateCursorStat' )
call XPRaddPostJob( 'XPMupdateSpecificChangedRange' )
call XPMsetUpdateStrategy( 'normalMode' ) 
fun! XPTmarkCompare( o, markToAdd, existedMark )
    let renderContext = s:getRenderContext()
    if has_key( renderContext, 'buildingMarkRange' ) 
                \&& renderContext.buildingMarkRange.end ==  a:existedMark
        return -1
    endif
    return 1
endfunction
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
let s:repetitionPattern     = '^\.\.\.\d*$'
let s:templateSettingPrototype  = { 'defaultValues' : {}, 'postFilters' : {}, 
            \'comeFirst' : [], 'comeLast' : [], 
            \'postQuoter' : { 'start' : '{{', 'end' : '}}' } }
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
fun! s:pumCB.onEmpty(sess) 
    return ""
endfunction 
fun! s:pumCB.onOneMatch(sess) 
  return s:doStart(a:sess)
endfunction 
let s:ItemPumCB = {}
fun! s:ItemPumCB.onOneMatch(sess) 
    call s:XPTupdate()
    return ""
endfunction 
fun! XPTemplateKeyword(val) 
    let x = s:bufData()
    let val = substitute(a:val, '\w', '', 'g')
    let keyFilter = 'v:val !~ ''\V\[' . escape(val, '\]') . ']'' '
    call filter( x.keywordList, keyFilter )
    let x.keywordList += split( val, '\s*' )
    let x.keyword = '\[' . escape( join( x.keywordList, '' ), '\]' ) . ']'
endfunction 
fun! XPTemplatePriority(...) 
    let x = s:bufData()
    let p = a:0 == 0 ? 'lang' : a:1
    let x.bufsetting.priority = s:ParsePriority(p)
endfunction 
fun! XPTemplateMark(sl, sr) 
    let x = s:bufData().bufsetting.ptn
    let x.l = a:sl
    let x.r = a:sr
    call s:RedefinePattern()
endfunction 
fun! XPTemplateIndent(p) 
    let x = s:bufData().bufsetting.indent
    call s:ParseIndent(x, a:p)
endfunction 
fun! XPTmark() 
    let x = s:bufData().bufsetting.ptn
    return [ x.l, x.r ]
endfunction 
fun! XPTcontainer() 
    return [s:bufData().vars, s:bufData().vars]
endfunction 
fun! g:XPTvars() 
    return s:bufData().vars
endfunction 
fun! g:XPTfuncs() 
    return s:bufData().funcs
endfunction 
fun! XPTemplateAlias( name, toWhich, setting ) 
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
            if has_key( a:to, key )
                call s:deepExtend( a:to[ key ], a:from[ key ] )
            else
                let a:to[ key ] = a:from[key]
            endif
        elseif type( a:from[key] ) == 3
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
fun! XPTemplate(name, str_or_ctx, ...) 
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
    if '=' !~ '\V' . x.keyword
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
    if '!' !~ '\V' . x.keyword
        let pstr = matchstr(name, '\V!\zs\.\+\$')
        if pstr != ""
            let override_priority = s:ParsePriority(pstr)
        elseif has_key(templateSetting, 'priority')
            let override_priority = s:ParsePriority(templateSetting.priority)
        else
            let override_priority = x.bufsetting.priority
        endif
        let name = pstr == "" ? name : matchstr(name, '[^!]*\ze!')
    else
        if has_key(templateSetting, 'priority')
            let override_priority = s:ParsePriority(templateSetting.priority)
        else
            let override_priority = x.bufsetting.priority
        endif
    endif
    call s:GetHint(templateSetting)
    if !has_key(xt, name) || xt[name].priority > override_priority
        let xt[name] = {
                    \ 'name'        : name,
                    \ 'tmpl'        : Str,
                    \ 'priority'    : override_priority,
                    \ 'setting'     : templateSetting,
                    \ 'ptn'         : deepcopy(s:bufData().bufsetting.ptn),
                    \ 'indent'      : idt,
                    \ 'wrapped'     : type(Str) != type(function("tr")) && Str =~ '\V' . xp.lft . s:wrappedName . xp.rt }
        if type( Str ) == type( '' )
            let xt[ name ].tmpl = s:parseQuotedPostFilter( xt[ name ], Str )
        endif
        call s:initItemOrderDict( xt[name].setting )
        let xt[ name ].setting.defaultValues.cursor = 'Finish()'
    endif
endfunction 
fun! s:initItemOrderDict( setting ) 
    let setting = a:setting
    let [ first, last ] = [ setting.comeFirst, setting.comeLast ]
    let setting.firstDict = {}
    let setting.lastDict = {}
    let setting.firstListSkeleton = []
    let setting.lastListSkeleton = []
    let [i, len] = [ 0, len( first ) ]
    while i < len
        let setting.firstDict[ first[ i ] ] = i
        call add( setting.firstListSkeleton, {} )
        let i += 1
    endwhile
    let [i, len] = [ 0, len( last ) ]
    while i < len
        let setting.lastDict[ last[ i ] ] = i
        call add( setting.lastListSkeleton, {} )
        let i += 1
    endwhile
endfunction 
fun! XPTreload() 
  try
    unlet b:__xpt_loaded
    unlet b:xptemplateData
  catch /.*/
  endtry
  e
endfunction 
fun! XPTgetAllTemplates() 
    return s:bufData().normalTemplates
endfunction 
fun! XPTemplatePreWrap(wrap) 
    let x = s:bufData()
    let x.wrap = a:wrap
    if x.wrap[-1:-1] == "\n"
        let x.wrap = x.wrap[0:-2]
        let @" = "\n"
        normal! ""P
    endif
    let x.wrapStartPos = col(".")
    if g:xptemplate_strip_left
        let x.wrap = substitute(x.wrap, '^\s*', '', '')
    endif
    let ppr = s:Popup("", x.wrapStartPos)
    return ppr
endfunction 
fun! XPTemplateStart(pos, ...) 
    let x = s:bufData()
    if a:0 == 1 &&  type(a:1) == type({}) && has_key( a:1, 'tmplName' )  
        let exact = 1
        let startColumn = a:1.startPos[1]
        let templateName = a:1.tmplName
        call cursor(a:1.startPos)
        return  s:doStart( { 'line' : a:1.startPos[0], 'col' : startColumn, 'matched' : templateName } )
    else 
        let exact = 0
        let cursorColumn = col(".")
        if x.wrapStartPos
            let startLineNr = line(".")
            let startColumn = x.wrapStartPos
        else
            let [startLineNr, startColumn] = searchpos('\V\%(\w\|'. x.keyword .'\)\+\%#', "bn", line("."))
            if startLineNr == 0
                let [startLineNr, startColumn] = [line("."), col(".")]
            endif
        endif
        let templateName = strpart( getline(startLineNr), startColumn - 1, cursorColumn - startColumn )
    endif
    return s:Popup( templateName, startColumn )
endfunction 
fun! s:ParseIndent(x, p) 
    let x = a:x
    if a:p ==# "auto"
        let x.type = 'auto'
    elseif a:p =~ '/\d\+\(\*\d\+\)\?'
        let x.type = 'rate'
        let str = matchstr(a:p, '/\d\+\(\*\d\+\)\?')
        let x.rate =split(str, '/\|\*')
        if len(x.rate) == 1
            let x.rate[1] = &l:shiftwidth
        endif
    else
        let x.type = 'keep'
    endif
endfunction 
fun! s:GetHint(ctx) 
    let xp = s:bufData().bufsetting.ptn
    if has_key(a:ctx, 'hint')
        let a:ctx.hint = s:Eval(a:ctx.hint)
    else
        let a:ctx.hint = ""
    endif
endfunction 
fun! s:ParsePriority(s) 
    let x = s:bufData()
    let pstr = a:s
    let prio = 0
    if pstr == ""
        let prio = x.bufsetting.priority
    else
        let p = matchlist(pstr, '\V\^\(' . s:priPtn . '\)' . '\%(' . '\(\[+-]\)' . '\(\d\+\)\?\)\?\$')
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
    return prio
endfunction 
fun! s:newTemplateRenderContext( xptBufData, tmplName ) 
    if s:getRenderContext().processing
        call s:PushCtx()
    endif
    let renderContext = s:createRenderContext(a:xptBufData)
    let renderContext.phase = 'inited'
    let renderContext.tmpl  = a:xptBufData.normalTemplates[a:tmplName]
    return renderContext
endfunction 
fun! s:doStart(sess) 
    let x = s:bufData()
    if !has_key( x.normalTemplates, a:sess.matched )
        return g:xpt_post_action
    endif
    let [lineNr, column] = [ a:sess.line, a:sess.col ]
    let cursorColumn = col(".")
    let tmplname = a:sess.matched
    let ctx = s:newTemplateRenderContext( x, tmplname )
    call s:RenderTemplate([ lineNr, column ], [ lineNr, cursorColumn ])
    let ctx.phase = 'rendered'
    let ctx.processing = 1
    if empty(x.stack)
        call s:ApplyMap()
    endif
    let x.wrap = ''
    let x.wrapStartPos = 0
    let action =  s:gotoNextItem()
    return action . g:xpt_post_action
endfunction 
fun! s:finishRendering(...) 
    let x = s:bufData()
    let renderContext = s:getRenderContext()
    let xp = renderContext.tmpl.ptn
    match none
    let l = line(".")
    let toEnd = col(".") - len(getline("."))
    exe "silent! %snomagic/\\V" .s:TmplRange() . s:unescapeHead . xp.l . '/\1' . xp.l . '/g'
    exe "silent! %snomagic/\\V" .s:TmplRange() . s:unescapeHead . xp.r . '/\1' . xp.r . '/g'
    if &ft =~ s:ftNeedToRedraw
        redraw
    endif
    call s:Format(1)
    call cursor(l, toEnd + len(getline(l)))
    call s:removeMarksInRenderContext(renderContext)
    if empty(x.stack)
        let renderContext.processing = 0
        let renderContext.phase = 'finished'
        call s:ClearMap()
    else
        call s:popCtx()
    endif
    return ''
endfunction 
fun! s:removeMarksInRenderContext( renderContext ) 
    let renderContext = a:renderContext
    call XPMremoveMarkStartWith( renderContext.markNamePre )
endfunction 
fun! s:Popup(pref, coln) 
    let x = s:bufData()
    let cmpl=[]
    let cmpl2 = []
    let dic = x.normalTemplates
    let ctxs = s:SynNameStack(line("."), a:coln)
    let ignoreCase = a:pref !~# '\u'
    for [ key, templateObject ] in items(dic)
        if templateObject.wrapped && empty(x.wrap) || !templateObject.wrapped && !empty(x.wrap)
            continue
        endif
        if has_key(templateObject.setting, "syn") && templateObject.setting.syn != '' && match(ctxs, '\c'.templateObject.setting.syn) == -1
            continue
        endif
        if key =~# "^[A-Z]"
            call add(cmpl2, {'word' : key, 'menu' : templateObject.setting.hint})
        else
            call add(cmpl, {'word' : key, 'menu' : templateObject.setting.hint})
        endif
    endfor
    call sort(cmpl)
    call sort(cmpl2)
    let cmpl = cmpl + cmpl2
    return XPPopupNew(s:pumCB, {}, cmpl).popup(a:coln)
endfunction 
fun! s:applyTmplIndent(renderContext, templateText) 
    let renderContext = a:renderContext
    let tmpl = a:templateText
    let baseIndent = repeat(" ", indent("."))
    if renderContext.tmpl.indent.type =~# 'keep\|rate\|auto'
        if renderContext.tmpl.indent.type ==# "rate"
            let patternOfOriginalIndent = repeat(' ', renderContext.tmpl.indent.rate[0])
            let patternOfOriginalIndent ='\(\%('.patternOfOriginalIndent.'\)*\)'
            let expandedIndent = repeat('\1', renderContext.tmpl.indent.rate[1] / renderContext.tmpl.indent.rate[0])
            let tmpl = substitute(tmpl, '\%(^\|\n\)\zs'.patternOfOriginalIndent, expandedIndent, 'g')
        endif
        let tmpl = substitute(tmpl, '\n', '&' . baseIndent, 'g')
    endif
    return tmpl
endfunction 
let s:oldRepPattern = '\w\*...\w\*'
fun! s:parseRepetition(str, x) 
    let x = a:x
    let xp = x.renderContext.tmpl.ptn
    let tmplObj = x.renderContext.tmpl
    let tmpl = a:str
    let bef = ""
    let rest = ""
    let rp = xp.lft . s:oldRepPattern . xp.rt
    let repPtn = '\V\(' . rp . '\)\_.\{-}' . '\1'
    let repContPtn = '\V\(' . rp . '\)\zs\_.\{-}' . '\1'
    let stack = []
    let from = 0
    while 1
        let startOfMatch = match(tmpl, repPtn, from)
        if startOfMatch == -1
            break
        endif
        let stack += [startOfMatch]
        let from = startOfMatch + 1
    endwhile
    while stack != []
        let matchpos = stack[-1]
        unlet stack[-1]
        let bef = tmpl[:matchpos-1]
        let rest = tmpl[matchpos : ]
        let indent = s:getIndentBeforeEdge( tmplObj, bef )
        let repeatPart = matchstr(rest, repContPtn)
        let repeatPart = s:clearMaxCommonIndent( repeatPart, indent )
        let repeatPart = 'BuildIfNoChange(' . string( repeatPart ) . ')'
        let symbol = matchstr(rest, rp)
        let name = substitute( symbol, '\V' . xp.lft . '\|' . xp.rt, '', 'g' )
        let tmplObj.setting.postFilters[ name ] = repeatPart
        let bef .= symbol
        let rest = substitute(rest, repPtn, '', '')
        let tmpl = bef . rest
    endwhile
    return tmpl
endfunction 
fun! s:getIndentBeforeEdge( tmplObj, textBeforeLeftMark )
    let xp = a:tmplObj.ptn
    if a:textBeforeLeftMark =~ '\V' . xp.lft . '\_[^' . xp.r . ']\*\%$'
        let tmpBef = substitute( a:textBeforeLeftMark, '\V' . xp.lft . '\_[^' . xp.r . ']\*\%$', '', '' )
        let indentOfFirstLine = matchstr( tmpBef, '.*\n\zs\s*' )
    else
        let indentOfFirstLine = matchstr( a:textBeforeLeftMark, '.*\n\zs\s*' )
    endif
    return len( indentOfFirstLine )
endfunction
fun! s:parseQuotedPostFilter( tmplObj, snippet ) 
    let xp = a:tmplObj.ptn
    let postFilters = a:tmplObj.setting.postFilters
    let quoter = a:tmplObj.setting.postQuoter
    let startPattern = '\V\_.\*\zs' . xp.lft . '\_[^' . xp.r . ']\{-}' . quoter.start . xp.rt
    let endPattern = '\V' . xp.lft . quoter.end . xp.rt
    let snip = a:snippet
    while 1
        let startPos = match(snip, startPattern)
        if startPos == -1
            break
        endif
        let endPos = match( snip, endPattern, startPos + 1 )
        if endPos == -1
            break
        endif
        let startText = matchstr( snip, startPattern, startPos )
        let endText   = matchstr( snip, endPattern, endPos )
        let name = startText[ 1 : -1 - len( quoter.start ) - 1 ]
        if name =~ xp.lft
            let name = matchstr( name, '\V' . xp.lft . '\zs\_.\*' )
            if name =~ xp.lft
                let name = matchstr( name, '\V\_.\*\ze' . xp.lft )
            endif
        endif
        let plainPostFilter = snip[ startPos + len( startText ) : endPos - 1 ]
        let plainPostFilter = s:clearMaxCommonIndent( plainPostFilter, s:getIndentBeforeEdge( a:tmplObj, snip[ : startPos - 1 ] ) )
        let postFilters[ name ] = 'BuildIfNoChange(' . string( plainPostFilter ) . ')'
        let snip = snip[ : startPos + len( startText ) - 1 - 1 - len( quoter.start ) ] 
                    \. snip[ endPos + len( endText ) - 1 : ]
    endwhile
    return snip
endfunction 
fun! s:RenderTemplate(nameStartPosition, nameEndPosition) 
    let x = s:bufData()
    let ctx = s:getRenderContext()
    let xp = s:getRenderContext().tmpl.ptn
    let tmpl = ctx.tmpl.tmpl
    if type(tmpl) == type(function("tr"))
        let tmpl = tmpl()
    else
        let tmpl = tmpl
    endif
    if tmpl =~ '\n'
        let tmpl = s:applyTmplIndent(ctx, tmpl)
    endif
    let tmpl = s:parseRepetition(tmpl, x)
    let tmpl = substitute(tmpl, '\V' . xp.lft . s:wrappedName . xp.rt, x.wrap, 'g')
    call XPMupdate()
    call XPMadd( ctx.marks.tmpl.start, a:nameStartPosition, g:XPMpreferLeft )
    call XPMadd( ctx.marks.tmpl.end, a:nameEndPosition, g:XPMpreferRight )
    call XPMsetLikelyBetween( ctx.marks.tmpl.start, ctx.marks.tmpl.end )
    call XPreplace( a:nameStartPosition, a:nameEndPosition, tmpl )
    let ctx.firstList = []
    let ctx.itemList = []
    let ctx.lastList = []
    if 0 != s:buildPlaceHolders( ctx.marks.tmpl )
        return s:crash()
    endif
    call s:TopTmplRange()
    silent! normal! gvzO
endfunction 
fun! s:getNameInfo(end) 
    let x = s:bufData()
    let xp = x.renderContext.tmpl.ptn
    if getline(".")[col(".") - 1] != xp.l
        throw "cursor is not at item start position:".string(getpos(".")[1:2])
    endif
    let endn = a:end[0] * 10000 + a:end[1]
    let l0 = getpos(".")[1:2]
    let r0 = searchpos(xp.rt, 'nW')
    let r0n = r0[0] * 10000 + r0[1]
    if r0 == [0, 0] || r0n >= endn
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
        return [l0, l1, l2, r0]
    elseif l1 == [0, 0] && l2 == [0, 0]
        return [l0, l0, r0, r0]
    else
        return [l0, l1, r0, r0]
    endif
endfunction 
fun! s:getValueInfo(end) 
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
    let r1 = searchpos(xp.rt, 'W', a:end[0])
    if r1 == [0, 0] || r1[0] * 10000 + r1[1] > l0n
        return [r0, copy(r0), copy(r0)]
    endif
    let r2 = searchpos(xp.rt, 'W', a:end[0])
    if r2 == [0, 0] || r2[0] * 10000 + r2[1] > l0n
        return [r0, r1, copy(r1)]
    endif
    return [r0, r1, r2]
endfunction 
fun! s:clearMaxCommonIndent( str, firstLineIndent ) 
    let min = a:firstLineIndent
    let list = split('=' . a:str . "=", "\n")
    for line in list[ 2 : -2 ]
        let indentWidth = len( matchstr( line, '^\s*' ) )
        let min = min( [ min, indentWidth ] )
    endfor
    let pattern = '\n\s\{' . min . '}'
    return substitute( a:str, pattern, "\n", 'g' )
endfunction 
fun! s:createPlaceHolder( ctx, nameInfo, valueInfo ) 
    let xp = a:ctx.tmpl.ptn
    let leftEdge  = s:textBetween(a:nameInfo[0], a:nameInfo[1])
    let name      = s:textBetween(a:nameInfo[1], a:nameInfo[2])
    let rightEdge = s:textBetween(a:nameInfo[2], a:nameInfo[3])
    let [ leftEdge, name, rightEdge ] = [ leftEdge[1 : ], name[1 : ], rightEdge[1 : ] ]
    let fullname  = leftEdge . name . rightEdge
    if fullname =~ '\V' . xp.item_var . '\|' . xp.item_func
        return { 'value' : fullname }
    endif
    let placeHolder = { 
                \ 'name'        : name, 
                \ 'isKey'       : (a:nameInfo[0] != a:nameInfo[1]), 
                \ 'ontimeFilter': '', 
                \ 'postFilter'  : '', 
                \ }
    if placeHolder.isKey
        call extend( placeHolder, {
                    \     'leftEdge'  : leftEdge,
                    \     'rightEdge' : rightEdge,
                    \     'fullname'  : fullname,
                    \ }, 'force' )
    endif
    if a:valueInfo[1] != a:valueInfo[0]
        let isPostFilter = a:valueInfo[1][0] == a:valueInfo[2][0] 
                    \&& a:valueInfo[1][1] + 1 == a:valueInfo[2][1]
        let val = s:textBetween( a:valueInfo[0], a:valueInfo[1] )
        let val = val[1:]
        let val = s:clearMaxCommonIndent( val, indent( a:valueInfo[0][0] ) )
        if isPostFilter
            let placeHolder.postFilter = val
        else
            let placeHolder.ontimeFilter = val
        endif
    endif
    return placeHolder
endfunction 
let s:anonymouseIndex = 0
fun! s:buildMarksOfPlaceHolder(ctx, item, placeHolder, nameInfo, valueInfo) 
    let [ctx, item, placeHolder, nameInfo, valueInfo] = 
                \ [a:ctx, a:item, a:placeHolder, a:nameInfo, a:valueInfo]
    if item.name == ''
        let markName =  '``' . s:anonymouseIndex
        let s:anonymouseIndex += 1
    else
        let markName =  item.name . s:buildingNr . '`' . ( placeHolder.isKey ? 'key' : (len(item.placeHolders)-1) )
    endif
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
    let valueInfo[2][1] += 1
    if placeHolder.isKey
        let shift = ( nameInfo[0] != nameInfo[1] && nameInfo[0][0] == nameInfo[1][0])
        let nameInfo[1][1] -= shift
        let shift = (nameInfo[1][0] == nameInfo[2][0]) * (shift + 1)
        let nameInfo[2][1] -= shift
        if nameInfo[2] != nameInfo[3]
            let shift = (nameInfo[2][0] == nameInfo[3][0]) * (shift + 1)
            let nameInfo[3][1] -= shift
        endif
        call XPreplace(nameInfo[0], valueInfo[2], placeHolder.fullname)
    elseif nameInfo[0][0] == nameInfo[3][0]
        let nameInfo[3][1] -= 1
        call XPreplace(nameInfo[0], valueInfo[2], placeHolder.name)
    endif
    call XPMadd( placeHolder.mark.start, nameInfo[0], 'l' )
    if placeHolder.isKey
        call XPMadd( placeHolder.editMark.start, nameInfo[1], 'l' )
        call XPMadd( placeHolder.editMark.end,   nameInfo[2], 'r' )
    endif
    call XPMadd( placeHolder.mark.end,   nameInfo[3], 'r' )
endfunction 
fun! s:addItemToRenderContext( ctx, item ) 
    let [ctx, item] = [ a:ctx, a:item ]
    if item.name != ''
        let ctx.itemDict[ item.name ] = item
    endif
    if ctx.phase != 'inited'
        call add( ctx.firstList, item )
        return
    endif
    let firstDict = ctx.tmpl.setting.firstDict
    let lastDict  = ctx.tmpl.setting.lastDict
    if item.name == ''
        call add( ctx.itemList, item )
    elseif has_key( firstDict, item.name )
        let ctx.firstList[ firstDict[ item.name ] ] = item
    elseif has_key( lastDict, item.name )
        let ctx.lastList[ lastDict[ item.name ] ] = item
    else
        call add( ctx.itemList, item )
    endif
endfunction 
let s:buildingNr = 0
fun! s:buildPlaceHolders( markRange ) 
    let s:buildingNr += 1
    let renderContext = s:getRenderContext()
    let xp = renderContext.tmpl.ptn
    if renderContext.firstList == []
        let renderContext.firstList = copy(renderContext.tmpl.setting.firstListSkeleton)
    endif
    if renderContext.lastList == []
        let renderContext.lastList = copy(renderContext.tmpl.setting.lastListSkeleton)
    endif
    let renderContext.buildingMarkRange = copy( a:markRange )
    let start = XPMpos( a:markRange.start )
    call cursor( start )
    let i = 0
    while i < 10000
        let i += 1
        let end = XPMpos( a:markRange.end )
        let nEnd = end[0] * 10000 + end[1]
        let nn = searchpos(xp.lft, 'cW')
        if nn == [0, 0] || nn[0] * 10000 + nn[1] >= nEnd
            break
        endif
        let nameInfo = s:getNameInfo(end)
        if nameInfo[0] == [0, 0]
            break
        endif
        call cursor(nameInfo[3])
        let valueInfo = s:getValueInfo(end)
        if valueInfo[0] == [0, 0]
            break
        endif
        let placeHolder = s:createPlaceHolder(renderContext, nameInfo, valueInfo)
        if has_key( placeHolder, 'value' )
            let value = s:Eval( placeHolder.value )
            if value =~ '\n'
                let indentSpace = repeat( ' ', indent( nameInfo[0][0] ) )
                let value = substitute( value, '\n', '&' . indentSpace, 'g' )
            endif
            let valueInfo[-1][1] += 1
            call XPreplace( nameInfo[0], valueInfo[-1], value )
        else
            let item = s:buildItemForPlaceHolder( renderContext, placeHolder )
            call s:buildMarksOfPlaceHolder( renderContext, item, placeHolder, nameInfo, valueInfo )
            call cursor(nameInfo[3])
        endif
    endwhile
    call filter( renderContext.firstList, 'v:val != {}' )
    call filter( renderContext.lastList, 'v:val != {}' )
    let renderContext.itemList = renderContext.firstList + renderContext.itemList + renderContext.lastList
    let renderContext.firstList = []
    let renderContext.lastList = []
    let end = XPMpos( a:markRange.end )
    call cursor( end )
    return 0
endfunction 
fun! s:buildItemForPlaceHolder( ctx, placeHolder ) 
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
    return item
endfunction 
fun! s:GetStaticRange(p, q) 
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
endfunction 
fun! s:HighLightItem(name, switchon) 
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
endfunction 
fun! s:TopTmplRange() 
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
endfunction 
fun! s:TmplRange() 
    let x = s:bufData()
    let p = [line("."), col(".")]
    call s:GetRangeBetween(s:TL(), s:BR())
    call cursor(p)
    return s:vrange
endfunction 
fun! s:XPTvisual() 
    if &l:slm =~ 'cmd'
	normal! v\<C-g>
    else
	normal! v
    endif
endfunction 
fun! s:GetRangeBetween(p1, p2, ...) 
    let pre = a:0 == 1 && a:1
    if pre
        let p = getpos(".")[1:2]
    endif
    if a:p1[0]*1000+a:p1[1] <= a:p2[0]*1000+a:p2[1]
        let [p1, p2] = [a:p1, a:p2]
    else
        let [p1, p2] = [a:p2, a:p1]
    endif
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
endfunction 
fun! s:finishCurrentAndGotoNextItem(action) 
    let renderContext = s:getRenderContext()
    let marks = renderContext.leadingPlaceHolder.mark
    call s:XPTupdate()
    let name = renderContext.item.name
    call s:HighLightItem(name, 0)
    if a:action ==# 'clear'
        call XPreplace(XPMpos( marks.start ),XPMpos( marks.end ), '')
    endif
    let post = s:applyPostFilter()
    let renderContext.step += [{ 'name' : renderContext.item.name, 'value' : post }]
    if renderContext.item.name != ''
        let renderContext.namedStep[renderContext.item.name] = post
    endif
    call s:removeCurrentMarks()
    return s:gotoNextItem()
endfunction 
fun! s:removeCurrentMarks()
    let renderContext = s:getRenderContext()
    let item = renderContext.item
    let leader = renderContext.leadingPlaceHolder
    call XPMremove( leader.mark.start )
    call XPMremove( leader.mark.end )
    if leader.isKey
        call XPMremove( leader.editMark.start )
        call XPMremove( leader.editMark.end )
    endif
    for ph in item.placeHolders
        call XPMremove( ph.mark.start )
        call XPMremove( ph.mark.end )
    endfor
endfunction
fun! s:RemovePlaceHolderMark( placeHolder )
    call XPMremove( a:placeHolder.mark.start )
    call XPMremove( a:placeHolder.mark.end )
    if a:placeHolder.isKey
        call XPMremove( a:placeHolder.editMark.start )
        call XPMremove( a:placeHolder.editMark.end )
    endif
endfunction
fun! s:applyPostFilter() 
    let renderContext = s:getRenderContext()
    let xp     = renderContext.tmpl.ptn
    let posts  = renderContext.tmpl.setting.postFilters
    let name   = renderContext.item.name
    let leader = renderContext.leadingPlaceHolder
    let marks  = renderContext.leadingPlaceHolder.mark
    let renderContext.phase = 'post'
    let typed = s:textBetween(XPMpos( marks.start ), XPMpos( marks.end ))
    if has_key(posts, name)
        let groupPostFilter = posts[ name ]
    else
        let groupPostFilter = ''
    endif
    let leaderPostFilter = leader.postFilter
    if groupPostFilter != ''
        let filter = groupPostFilter
    else
        let filter = leaderPostFilter
    endif
    if filter != ''
        let [ text, ifToBuild, rc ] = s:evalPostFilter( filter, typed )
        let [ start, end ] = XPMposList( marks.start, marks.end )
        let snip = s:adjustIndentAccordingTo( text, start[0] )
        call XPMsetLikelyBetween( marks.start, marks.end )
        call XPreplace(start, end, snip)
        if ifToBuild
            call cursor( start )
            let renderContext.firstList = []
            if 0 != s:buildPlaceHolders( marks )
                return s:crash()
            endif
        endif
    endif
    if groupPostFilter != ''
        call s:updateFollowingPlaceHoldersWith( typed, { 'post' : text } )
        return text
    else
        call s:updateFollowingPlaceHoldersWith( typed, {} )
        return typed
    endif
endfunction 
fun! s:evalPostFilter( filter, typed ) 
    let renderContext = s:getRenderContext()
    let post = s:Eval(a:filter, {'typed' : a:typed})
    if type( post ) == 4
        if post.action == 'build'
            let res = [ post.text, 1, 0 ]
        else
            let res = [ post.text, 0, 0 ]
        endif
    elseif type( post ) == 1
        let res = [ post, 1, 0 ]
    else
        let res = [ string( post ), 0, 0 ]
    endif
    return res
endfunction 
fun! s:adjustIndentAccordingTo( snip, lineNr ) 
    let indent = indent( a:lineNr )
    let indentspaces = repeat(' ', indent)
    return substitute( a:snip, "\n", "\n" . indentspaces, 'g' )
endfunction 
fun! s:gotoNextItem() 
    let renderContext = s:getRenderContext()
    let placeHolder = s:extractOneItem()
    if placeHolder == s:NullDict
        call cursor( XPMpos( renderContext.marks.tmpl.end ) )
        return s:finishRendering(1)
    endif
    let phPos = XPMpos( placeHolder.mark.start )
    if phPos == [0, 0]
        call s:log.Error( 'failed to find position of mark:' . placeHolder.mark.start )
        return s:crash()
    endif
    let postaction = s:initItem()
    if !renderContext.processing
        return postaction
    elseif postaction != ''
        return postaction
    else
        call cursor( XPMpos( renderContext.leadingPlaceHolder.mark.end ) )
        return ""
    endif
endfunction 
fun! s:Format(range) 
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
    endif
    if a:range == 1
        call s:TmplRange()
        normal! gv=
    elseif a:range == 2
        call s:TopTmplRange()
        normal! gv=
    else
        normal! ==
    endif
    if ctx.processing && ctx.pos.curpos != {}
        call ctx.pos.editpos.start.set( pi[0], max([pi[1] + len(getline(pi[0])), 1]))
    endif
    call s:PopBackPos()
endfunction 
fun! s:TL(...)
    return XPMpos( s:bufData().renderContext.marks.tmpl.start )
endfunction
fun! s:BR(...)
    return XPMpos( s:bufData().renderContext.marks.tmpl.end )
endfunction
fun! s:extractOneItem() 
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
    if item.keyPH == s:NullDict
        let renderContext.leadingPlaceHolder = item.placeHolders[0]
        let item.placeHolders = item.placeHolders[1:]
    else
        let renderContext.leadingPlaceHolder = item.keyPH
    endif
    return renderContext.leadingPlaceHolder
endfunction 
fun! s:handleDefaultValueAction( ctx, act ) 
    let ctx = a:ctx
    if has_key(a:act, 'action') " actions
        if a:act.action ==# 'expandTmpl' && has_key( a:act, 'tmplName' )
            let marks = ctx.leadingPlaceHolder.mark
            call XPreplace(XPMpos( marks.start ), XPMpos( marks.end ), '')
            call XPMsetLikelyBetween( marks.start, marks.end )
            return XPTemplateStart(0, {'startPos' : getpos(".")[1:2], 'tmplName' : a:act.tmplName})
        elseif a:act.action ==# 'finishTemplate'
            call XPreplace(XPMpos( ctx.leadingPlaceHolder.mark.start ), XPMpos( ctx.leadingPlaceHolder.mark.end )
                        \, has_key( a:act, 'postTyping' ) ? a:act.postTyping : '' )
            return s:finishRendering()
        elseif a:act.action ==# 'embed'
            return s:embedSnippetInLeadingPlaceHolder( ctx, a:act.snippet )
        elseif a:act.action ==# 'next'
            let text = has_key( a:act, 'text' ) ? a:act.text : ''
            call s:fillinLeadingPlaceHolderAndSelect( ctx, text )
            return s:finishCurrentAndGotoNextItem( '' )
        else " other action
        endif
        return -1
    else
        return -1
    endif
endfunction 
fun! s:addIndent( str, lineNr ) 
    let indent = indent(a:lineNr)
    let indentSpaces = repeat(' ', indent)
    let str = substitute( a:str, "\n", "\n" . indentSpaces, 'g' )
    return str
endfunction 
fun! s:embedSnippetInLeadingPlaceHolder( ctx, snippet ) 
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
fun! s:fillinLeadingPlaceHolderAndSelect( ctx, str ) 
    let [ ctx, str ] = [ a:ctx, a:str ]
    let [ item, ph ] = [ ctx.item, ctx.leadingPlaceHolder ]
    let marks = ph.isKey ? ph.editMark : ph.mark
    let [ start, end ] = [ XPMpos( marks.start ), XPMpos( marks.end ) ]
    if start == [0, 0] || end == [0, 0]
        return s:crash()
    endif
    call XPreplace( start, end, str )
    let xp = ctx.tmpl.ptn
    if str =~ '\V' . xp.lft . '\.\*' . xp.rt
        if 0 != s:buildPlaceHolders( marks )
            return s:crash()
        endif
        return s:gotoNextItem()
    endif
    call s:XPTupdate()
    let action = s:selectCurrent(ctx)
    call XPMupdateStat()
    return action
endfunction 
fun! s:applyDefaultValueToPH( renderContext ) 
    let renderContext = a:renderContext
    let leader = renderContext.leadingPlaceHolder
    let str = renderContext.tmpl.setting.defaultValues[renderContext.item.name]
    if leader.ontimeFilter != ''
        let str = leader.ontimeFilter
    endif
    let obj = s:Eval(str) 
    if type(obj) == type({})
        let rc = s:handleDefaultValueAction( renderContext, obj )
        return ( rc is -1 ) ? s:fillinLeadingPlaceHolderAndSelect( renderContext, '' ) : rc
    elseif type(obj) == type([])
        if len(obj) == 0
            return s:fillinLeadingPlaceHolderAndSelect( renderContext, '' )
        endif
        let marks = leader.isKey ? leader.editMark : leader.mark
        let [ start, end ] = XPMposList( marks.start, marks.end )
        call XPreplace( start, end, '')
        call cursor(start)
        return XPPopupNew(s:ItemPumCB, {}, obj).popup(col("."))
    else 
        let str = s:addIndent( obj, XPMpos( renderContext.leadingPlaceHolder.mark.start )[0] )
        return s:fillinLeadingPlaceHolderAndSelect( renderContext, str )
    endif
endfunction 
fun! s:initItem() 
    let renderContext = s:getRenderContext()
    let renderContext.phase = 'inititem'
    if has_key(renderContext.tmpl.setting.defaultValues, renderContext.item.name)
        return s:applyDefaultValueToPH( renderContext )
    else
        let str = renderContext.item.name
        call s:XPTupdate()
        let action = s:selectCurrent(renderContext)
        call XPMupdateStat()
        return action
    endif
endfunction 
fun! s:selectCurrent( renderContext ) 
    let ph = a:renderContext.leadingPlaceHolder
    let marks = ph.isKey ? ph.editMark : ph.mark
    let [ ctl, cbr ] = [ XPMpos( marks.start ), XPMpos( marks.end ) ]
    let a:renderContext.phase = 'fillin'
    if ctl == cbr 
        return ''
    else
        call cursor( ctl )
        call s:XPTvisual()
        if &l:selection == 'exclusive'
            call cursor( cbr )
        else
            if cbr[1] == 1
                call cursor( cbr[0] - 1, col( [ cbr[0] - 1, '$' ] ) )
            else
                call cursor( cbr[0], cbr[1] - 1 )
            endif
        endif
        normal! v
        return s:SelectAction()
    endif
endfunction 
fun! s:createStringMask( str ) 
    if a:str == ''
        return ''
    endif
    if !exists( 'b:_xpeval' )
        let b:_xpeval = { 'cache' : {} }
    endif
    if has_key( b:_xpeval.cache, a:str )
        return b:_xpeval.cache[ a:str ]
    endif
    let nonEscaped =   '\%(' . '\%(\[^\\]\|\^\)' . '\%(\\\\\)\*' . '\)' . '\@<='
    let dqe = '\V\('. nonEscaped . '"\)'
    let sqe = '\V\('. nonEscaped . "'\\)"
    let dptn = dqe.'\_.\{-}\1'
    let sptn = sqe.'\_.\{-}\%(\^\|\[^'']\)\(''''\)\*'''
    let mask = substitute(a:str, '[ *]', '+', 'g')
    while 1 
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
    endwhile 
    let b:_xpeval.cache[ a:str ] = mask
    return mask
endfunction 
fun! S2l(a, b)
    return a:a - a:b
endfunction
fun! s:Eval(s, ...) 
    let x = s:bufData()
    let ctx = s:getRenderContext()
    let xfunc = x.funcs
    let tmpEvalCtx = { 'typed' : '', 'usingCache' : 1 }
    if a:0 >= 1
        call extend( tmpEvalCtx, a:1, 'force' )
    endif
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
    let xfunc._ctx.item = {}
    let xfunc._ctx.leadingPlaceHolder = {}
    if ctx.processing
        let xfunc._ctx.step = ctx.step
        let xfunc._ctx.namedStep = ctx.namedStep
        let xfunc._ctx.name = ctx.item.name
        let xfunc._ctx.fullname = ctx.item.fullname
        let xfunc._ctx.value = tmpEvalCtx.typed
        let xfunc._ctx.item = ctx.item
        let xfunc._ctx.leadingPlaceHolder = ctx.leadingPlaceHolder
    endif
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
        for i in keys(rangesToEval)
            if i >= matchedIndex && i < matchedIndex + matchedLen
                call remove(rangesToEval, i)
            endif
        endfor
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
        let tmp = k == 0 ? "" : (str[last : kn-1])
        let tmp = substitute(tmp, '\\\(.\)', '\1', 'g')
        let sp .= tmp
        let evaledResult = eval(str[kn : vn-1])
        if type(evaledResult) != type('')
            return evaledResult
        endif
        let sp .= evaledResult
        let last = vn
    endfor
    let tmp = str[last : ]
    let tmp = substitute(tmp, '\\\(.\)', '\1', 'g')
    let sp .= tmp
    return sp
endfunction 
fun! s:textBetween(p1, p2) 
    if a:p1[0] > a:p2[0]
        return ""
    endif
    let [p1, p2] = [a:p1, a:p2]
    if p1[0] == p2[0]
        if p1[1] == p2[1]
            return ""
        else
            return getline(p1[0])[ p1[1] - 1 : p2[1] - 2]
        endif
    endif
    let r = [ getline(p1[0])[p1[1] - 1:] ] + getline(p1[0]+1, p2[0]-1)
    if p2[1] > 1
        let r += [ getline(p2[0])[:p2[1] - 2] ]
    else
        let r += ['']
    endif
    return join(r, "\n")
endfunction 
fun! s:SelectAction() 
    return "\<esc>gv\<C-g>"
    if &l:slm =~ 'cmd'
        return "\<esc>gv"
    else
        return "\<esc>gv\<C-g>"
    endif
endfunction 
fun! s:LeftPos(p) 
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
endfunction 
fun! s:CheckAndBS(k) 
    let x = s:bufData()
    let p = [ line( "." ), col( "." ) ]
    let ctl = s:CTL(x)
    if p[0] == ctl[0] && p[1] == ctl[1]
        return ""
    else
        let k= eval('"\<'.a:k.'>"')
        return k
    endif
endfunction 
fun! s:CheckAndDel(k) 
    let x = s:bufData()
    let p = getpos(".")[1:2]
    let cbr = s:CBR(x)
    if p[0] == cbr[0] && p[1] == cbr[1]
        return ""
    else
        let k= eval('"\<'.a:k.'>"')
        return k
    endif
endfunction 
fun! s:goback() 
    let renderContext = s:getRenderContext()
    call cursor( XPMpos( renderContext.leadingPlaceHolder.mark.end ) )
    return ''
endfunction 
fun! s:ApplyMap() 
    let x = s:bufData()
    let savedMap = x.savedMap
    let savedMap.i_nav      = g:MapPush(g:xptemplate_nav_next  , "i", 1)
    let savedMap.s_nav      = g:MapPush(g:xptemplate_nav_next  , "s", 1)
    let savedMap.s_cancel   = g:MapPush(g:xptemplate_nav_cancel, "s", 1)
    let savedMap.s_del      = g:MapPush("<Del>", "s", 1)
    let savedMap.s_bs       = g:MapPush("<bs>", "s", 1)
    let savedMap.s_right    = g:MapPush(g:xptemplate_to_right, "s", 1)
    let savedMap.n_back     = g:MapPush(g:xptemplate_goback, "n", 1)
    exe 'inoremap <silent> <buffer> '.g:xptemplate_nav_next  .' <C-r>=<SID>finishCurrentAndGotoNextItem("")<cr>'
    exe 'snoremap <silent> <buffer> '.g:xptemplate_nav_next  .' <Esc>`>a<C-r>=<SID>finishCurrentAndGotoNextItem("")<cr>'
    exe 'snoremap <silent> <buffer> '.g:xptemplate_nav_cancel.' <Esc>i<C-r>=<SID>finishCurrentAndGotoNextItem("clear")<cr>'
    exe 'nnoremap <silent> <buffer> '.g:xptemplate_goback . ' i<C-r>=<SID>goback()<cr>'
    snoremap <silent> <buffer> <Del> <Del>i
    snoremap <silent> <buffer> <bs> <esc>`>a<bs>
    exe "snoremap <silent> <buffer> ".g:xptemplate_to_right." <esc>`>a"
endfunction 
fun! s:ClearMap() 
    let x = s:bufData()
    let savedMap = x.savedMap
    exe 'iunmap <buffer> '.g:xptemplate_nav_next
    exe 'sunmap <buffer> '.g:xptemplate_nav_next
    exe 'sunmap <buffer> '.g:xptemplate_nav_cancel
    exe 'nunmap <buffer> '.g:xptemplate_goback
    sunmap <buffer> <Del>
    sunmap <buffer> <bs>
    exe "sunmap <buffer> ".g:xptemplate_to_right
    call g:MapPop(savedMap.n_back  )
    call g:MapPop(savedMap.s_right )
    call g:MapPop(savedMap.s_bs    )
    call g:MapPop(savedMap.s_del   )
    call g:MapPop(savedMap.s_cancel)
    call g:MapPop(savedMap.s_nav   )
    call g:MapPop(savedMap.i_nav   )
    let x.savedMap = {}
endfunction 
fun! s:CTL(...) 
    let x = a:0 == 1 ? a:1 : s:bufData()
    let cp = x.renderContext.pos.curpos
    return copy( cp.start.pos )
endfunction 
fun! s:CBR(...) 
    let x = a:0 == 1 ? a:1 : s:bufData()
    let cp = x.renderContext.pos.curpos
    return copy( cp.end.pos )
endfunction 
fun! XPTbufData() 
    return s:bufData()
endfunction 
fun! s:createRenderContext(x) 
    let a:x.renderContext = deepcopy( s:renderContextPrototype )
    let a:x.renderContext.lastTotalLine = line( '$' )
    let a:x.renderContext.markNamePre = "XPTM" . len( a:x.stack ) . '_'
    let a:x.renderContext.marks.tmpl = { 
                \ 'start' : a:x.renderContext.markNamePre . '`tmpl`start', 
                \ 'end'   : a:x.renderContext.markNamePre . '`tmpl`end', }
    return a:x.renderContext
endfunction 
fun! s:getRenderContext(...) 
    let x = a:0 == 1 ? a:1 : s:bufData()
    return x.renderContext
endfunction 
fun! s:bufData() 
    if !exists("b:xptemplateData")
        let b:xptemplateData = {'tmplarr' : [], 'normalTemplates' : {}, 'funcs' : {}, 'vars' : {}, 'wrapStartPos' : 0, 'wrap' : '', 'functionContainer' : {}}
        let b:xptemplateData.funcs = b:xptemplateData.vars
        let b:xptemplateData.varPriority = {}
        let b:xptemplateData.posStack = []
        let b:xptemplateData.stack = []
        let b:xptemplateData.keyword = '\w'
        let b:xptemplateData.keywordList = []
        let b:xptemplateData.savedMap = {}
        call s:createRenderContext( b:xptemplateData )
        let b:xptemplateData.bufsetting = {
                    \'ptn' : {'l':'`', 'r':'^'},
                    \'indent' : {'type' : 'auto', 'rate' : []},
                    \'priority' : s:priorities.lang
                    \}
        call s:RedefinePattern()
        call XPMsetBufSortFunction( function( 'XPTmarkCompare' ) )
    endif
    return b:xptemplateData
endfunction 
fun! s:RedefinePattern() 
    let xp = b:xptemplateData.bufsetting.ptn
    let nonEscaped = s:nonEscaped
    let xp.lft = nonEscaped . xp.l
    let xp.rt  = nonEscaped . xp.r
    let xp.lft_e = nonEscaped. '\\'.xp.l
    let xp.rt_e  = nonEscaped. '\\'.xp.r
    let xp.itemPattern       = xp.lft . '\%(NAME\)' . xp.rt
    let xp.itemContentPattern= xp.lft . '\zs\%(NAME\)\ze' . xp.rt
    let xp.item_var          = '$\w\+'
    let xp.item_qvar         = '{$\w\+}'
    let xp.item_func         = '\w\+(\.\*)'
    let xp.item_qfunc        = '{\w\+(\.\*)}'
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
endfunction 
fun! s:PushCtx() 
    let x = s:bufData()
    let x.stack += [s:getRenderContext()]
    call s:createRenderContext(x)
endfunction 
fun! s:popCtx() 
    let x = s:bufData()
    let x.renderContext = x.stack[-1]
    call remove(x.stack, -1)
endfunction 
fun! s:GetBackPos() 
    return [line(".") - line("$"), col(".") - len(getline("."))]
endfunction 
fun! s:PushBackPos() 
    call add(s:bufData().posStack, s:GetBackPos())
endfunction 
fun! s:PopBackPos() 
    let x = s:bufData()
    let bp = x.posStack[-1]
    call remove(x.posStack, -1)
    let l = bp[0] + line("$")
    let p = [l, bp[1] + len(getline(l))]
    call cursor(p)
    return p
endfunction 
fun! s:SynNameStack(l, c) 
    let ids = synstack(a:l, a:c)
    if empty(ids)
        return []
    endif
    let names = []
    for id in ids
        let names = names + [synIDattr(id, "name")]
    endfor
    return names
endfunction 
fun! s:CurSynNameStack() 
    return SynNameStack(line("."), col("."))
endfunction 
fun! s:updateFollowingPlaceHoldersWith( contentTyped, option ) 
    let renderContext = s:getRenderContext()
    if renderContext.phase == 'post' && has_key( a:option, 'post' )
        let groupPost = a:option.post
    else
        let groupPost = a:contentTyped
    endif
    call XPRstartSession()
    let phList = renderContext.item.placeHolders
    for ph in phList
        let filter = ( renderContext.phase == 'post' ? ph.postFilter : ph.ontimeFilter )
        let filter = filter == '' ? ph.ontimeFilter : filter
        if filter != ''
            let filtered = s:Eval( filter, { 'typed' : a:contentTyped } )
        else
            let filtered = groupPost
        endif
        call XPreplaceByMarkInternal( ph.mark.start, ph.mark.end, filtered )
    endfor
    call XPRendSession()
endfunction 
fun! s:crash() 
    let msg = "XPTemplate snippet crashed :"
    let x = s:bufData()
    for ctx in x.stack
        let msg .= ctx.tmpl.name . ' -> '
    endfor
    call s:ClearMap()
    let x.stack = []
    call s:createRenderContext(x)
    call XPMflush()
    echohl WarningMsg
    echom msg
    echohl
    return ''
endfunction 
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
    if currentFollowingSpace != renderContext.lastFollowingSpace
        call XPreplace( currentPos, 
                    \[ currentPos[0], currentPos[1] + len( currentFollowingSpace ) ], 
                    \renderContext.lastFollowingSpace, 
                    \{ 'doJobs' : 0 } )
        call cursor( currentPos )
    endif
endfunction 
fun! s:XPTupdate(...) 
    let renderContext = s:getRenderContext()
    if !renderContext.processing
        call XPMupdate()
        return
    endif
    call s:log.Info( "marks before XPTupdate:\n" . XPMallMark() )
    call s:fixCrCausedIndentProblem()
    let leaderMark = renderContext.leadingPlaceHolder.mark
    call XPMsetLikelyBetween( leaderMark.start, leaderMark.end )
    let rc = XPMupdate()
    let [ start, end ] = [ XPMpos( leaderMark.start ), XPMpos( leaderMark.end ) ]
    if start == [0, 0] || end == [0, 0]
        call s:log.Info( 'fail to get start/end mark:' . string( [ start, end ] ) . ' of name=' . string( leaderMark ) )
        return s:crash()
    endif
    let contentTyped = s:textBetween( start, end )
    if contentTyped ==# renderContext.lastContent
        call XPMupdateStat()
        return
    endif
    call s:CallPlugin("beforeUpdate")
    if rc == g:XPM_RET.likely_matched
        let relPos = s:recordRelativePosToMark( [ line( '.' ), col( '.' ) ], renderContext.leadingPlaceHolder.mark.start )
        call s:log.Info( "marks before updating following:\n" . XPMallMark() )
        call s:updateFollowingPlaceHoldersWith( contentTyped, {} )
        call s:gotoRelativePosToMark( relPos, renderContext.leadingPlaceHolder.mark.start )
    else
    endif
    call s:CallPlugin('afterUpdate')
    let renderContext.lastContent = contentTyped
    let renderContext.lastTotalLine = line( '$' )
    call s:log.Info( "marks after XPTupdate:\n" . XPMallMark() )
    call XPMupdateStat()
endfunction 
fun! s:recordRelativePosToMark( pos, mark ) 
    let p = XPMpos( a:mark )
    if a:pos[0] == p[0] 
        return [0, a:pos[1] - p[1]]
    else
        return [ a:pos[0] - p[0], a:pos[1] ]
    endif
endfunction 
fun! s:gotoRelativePosToMark( rPos, mark ) 
    let p = XPMpos( a:mark )
    if a:rPos[0] == 0
        call cursor( p[0], a:rPos[1] + p[1] )
    else
        call cursor( p[0] + a:rPos[0], a:rPos[1] )
    endif
endfunction 
fun! s:XPTcheck() 
    let x = s:bufData()
    if x.wrap != ''
        let x.wrapStartPos = 0
        let x.wrap = ''
    endif
endfunction 
fun! s:XPTtrackFollowingSpace() 
    let renderContext = s:getRenderContext()
    let currentPos = [ line( '.' ), col( '.' ) ]
    let currentFollowingSpace = getline( currentPos[0] )[ currentPos[1] - 1 : ]
    let currentFollowingSpace = matchstr( currentFollowingSpace, '^\s*' )
    let renderContext.lastFollowingSpace = currentFollowingSpace
endfunction 
augroup XPT 
    au!
    au InsertEnter * call <SID>XPTcheck()
    au CursorMovedI * call <SID>XPTupdate()
    au CursorMoved * call <SID>XPTtrackFollowingSpace()
augroup END 
fun! g:XPTaddPlugin(event, func) 
    if has_key(s:plugins, a:event)
        call add(s:plugins[a:event], a:func)
    else
        throw "XPT does NOT support event:".a:event
    endif
endfunction 
fun! s:CallPlugin(ev) 
    if !has_key(s:plugins, a:ev)
        throw "calling invalid event:".a:ev
    endif
    let x = s:bufData()
    let v = 0
    for f in s:plugins[a:ev]
        let v = g:XPT[f](x)
    endfor
endfunction 
fun! s:Link(fs) 
    let list = split(a:fs, ' ')
    for v in list
        let s:f[v] = function('<SNR>'.s:sid . v)
    endfor
endfunction 
call <SID>Link('TmplRange GetRangeBetween textBetween GetStaticRange LeftPos')
com! XPTreload call XPTreload()
com! XPTcrash call <SID>crash()
fun! String( d, ... )
    let str = string( a:d )
    let str = substitute( str, "\\V'\\%(\\[^']\\|''\\)\\{-}'" . '\s\*:\s\*function\[^)]),\s\*', '', 'g' )
    return str
endfunction
