if exists("g:__XPTEMPLATE_VIM__")
    finish
endif
let g:__XPTEMPLATE_VIM__ = 1
com! XPTgetSID let s:sid =  matchstr("<SID>", '\zs\d\+_\ze')
XPTgetSID
delc XPTgetSID
runtime plugin/debug.vim
runtime plugin/xptemplate.util.vim
runtime plugin/mapstack.vim
runtime plugin/xpreplace.vim
runtime plugin/xpmark.vim
runtime plugin/xpopup.vim
runtime plugin/xptemplate.conf.vim
runtime plugin/MapSaver.class.vim
runtime plugin/FiletypeScope.class.vim
let s:log = CreateLogger( 'warn' )
let s:log = CreateLogger( 'debug' )
call XPRaddPreJob( 'XPMupdateCursorStat' )
call XPRaddPostJob( 'XPMupdateSpecificChangedRange' )
call XPMsetUpdateStrategy( 'normalMode' ) 
fun! XPTmarkCompare( o, markToAdd, existedMark )
    let renderContext = s:getRenderContext()
    if renderContext.phase == 'rendering' 
        let [ lm, rm ] = [ a:o.changeLikelyBetween.start, a:o.changeLikelyBetween.end ]
        if a:existedMark ==# rm
            return -1
        endif
    elseif renderContext.action == 'build' && has_key( renderContext, 'buildingMarkRange' ) 
                \&& renderContext.buildingMarkRange.end ==  a:existedMark
        return -1
    endif
    return 1
endfunction
let s:NullDict              = {}
let s:NullList              = []
let s:ftNeedToRedraw        = '\<\%(' . join([ 'perl' ], '\|') . '\)\>'
let s:unescapeHead          = '\v(\\*)\1\\?\V'
let s:nonEscaped            = '\%(' . '\%(\[^\\]\|\^\)' . '\%(\\\\\)\*' . '\)' . '\@<='
let s:escaped               = '\%(' . '\%(\[^\\]\|\^\)' . '\%(\\\\\)\*' . '\)' . '\@<=' . '\\'
let s:stripPtn              = '\V\^\s\*\zs\.\*'
let s:wrappedName           = "wrapped"
let g:XPTemplateSettingPrototype  = { 
            \    'preValues'        : { 'cursor' : "\n" . '$CURSOR_PH' }, 
            \    'defaultValues'    : {}, 
            \    'postFilters'      : {}, 
            \    'comeFirst'        : [], 
            \    'comeLast'         : [], 
            \}
fun! g:XPTapplyTemplateSettingDefaultValue( setting ) 
    let s = a:setting
    call s:SetIfEmpty( s,           'postQuoter', { 'start' : '{{', 'end' : '}}' } )
    call s:SetIfEmpty( s.preValues, 'cursor', '$CURSOR_PH' )
endfunction 
let s:defaultPostFilter = {
            \   '\V\w\+?' : 'EchoIfNoChange( '''' )', 
            \}
fun! s:SetDefaultFilters( tmplObj, ph ) 
    if !has_key( a:tmplObj.setting.postFilters, a:ph.name )
        for [ptn, filter] in items(s:defaultPostFilter)
            if a:ph.name =~ ptn
                let a:tmplObj.setting.postFilters[ a:ph.name ] = "\n" . filter
            endif
        endfor
    endif
endfunction 
let s:renderContextPrototype      = {
            \   'ftScope'           : {},
            \   'tmpl'              : {},
            \   'evalCtx'           : {},
            \   'phase'             : 'uninit',
            \   'action'            : '',
            \   'markNamePre'       : '', 
            \   'item'              : {}, 
            \   'leadingPlaceHolder' : {}, 
            \   'history'           : [], 
            \   'step'              : [],
            \   'namedStep'         : {},
            \   'processing'        : 0,
            \   'marks'             : {
            \      'tmpl'           : {'start' : '', 'end' : ''} },
            \   'itemDict'          : {},
            \   'itemList'          : [],
            \   'lastContent'       : '',
            \   'lastTotalLine'     : 0, 
            \   'lastFollowingSpace': '', 
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
let g:XPT_RC = {
            \   'ok' : {}, 
            \   'POST' : {
            \       'unchanged'     : {}, 
            \       'keepIndent'    : {}, 
            \   }
            \}
let s:buildingSeqNr = 0
let s:pumCB = {}
fun! s:pumCB.onEmpty(sess) 
    return ""
endfunction 
fun! s:pumCB.onOneMatch(sess) 
  return s:DoStart(a:sess)
endfunction 
let s:ItemPumCB = {}
fun! s:ItemPumCB.onOneMatch(sess) 
    call s:XPTupdate()
    return s:FinishCurrentAndGotoNextItem( '' )
endfunction 
fun! XPTemplateKeyword(val) 
    let x = g:XPTobject()
    let val = substitute(a:val, '\w', '', 'g')
    let keyFilter = 'v:val !~ ''\V\[' . escape(val, '\]') . ']'' '
    call filter( x.keywordList, keyFilter )
    let x.keywordList += split( val, '\s*' )
    let x.keyword = '\[' . escape( join( x.keywordList, '' ), '\]' ) . ']'
endfunction 
fun! XPTemplatePriority(...) 
    let x = g:XPTobject()
    let p = a:0 == 0 ? 'lang' : a:1
    let x.snipFileScope.priority = s:ParsePriorityString(p)
endfunction 
fun! XPTemplateMark(sl, sr) 
    let xp = g:XPTobject().snipFileScope.ptn
    let xp.l = a:sl
    let xp.r = a:sr
    call s:RedefinePattern()
endfunction 
fun! XPTemplateIndent(p) 
    let x = g:XPTobject().snipFileScope.indent
    call s:ParseIndent(x, a:p)
endfunction 
fun! XPTmark() 
    let renderContext = s:getRenderContext()
    let xp = renderContext.tmpl.ptn
    return [ xp.l, xp.r ]
endfunction 
fun! XPTcontainer() 
    echom "deprecated function:XPTcontainer, use g:XPTfuncs"
    return [ g:XPTfuncs(), g:XPTfuncs() ]
endfunction 
fun! g:XPTvars() 
    echom "deprecated function:XPTcontainer, use g:XPTfuncs"
    return g:XPTfuncs()
endfunction 
fun! g:XPTfuncs() 
    return g:GetSnipFileFtScope().funcs
endfunction 
fun! XPTemplateAlias( name, toWhich, setting ) 
    let xptObj = g:XPTobject()
    let xt = xptObj.filetypes[ g:GetSnipFileFT() ].normalTemplates
    if has_key( xt, a:toWhich )
        let xt[ a:name ] = deepcopy( xt[ a:toWhich ] )
        let xt[ a:name ].name = a:name
        call s:ParseTemplateSetting( xptObj, a:setting )
        call g:xptutil.DeepExtend( xt[ a:name ].setting, a:setting )
    endif
endfunction 
fun! g:GetSnipFileFT() 
    let x = g:XPTobject()
    return x.snipFileScope.filetype
endfunction 
fun! g:GetSnipFileFtScope() 
    let x = g:XPTobject()
    return x.filetypes[ x.snipFileScope.filetype ]
endfunction 
fun! XPTemplate(name, str_or_ctx, ...) 
    let x         = g:XPTobject()
    let ftScope   = x.filetypes[ g:GetSnipFileFT() ]
    let templates = ftScope.normalTemplates
    let xp        = x.snipFileScope.ptn
    let foo       = { 'snip' : '' }
    let templateSetting = deepcopy(g:XPTemplateSettingPrototype)
    if a:0 == 0          " no syntax context
        let foo.snip = a:str_or_ctx
    elseif a:0 == 1      " with syntax context
        call extend( templateSetting, a:str_or_ctx, 'force' )
        let foo.snip = a:1
    endif
    call g:XPTapplyTemplateSettingDefaultValue( templateSetting )
    let prio =  has_key(templateSetting, 'priority') ? 
                \ s:ParsePriorityString(templateSetting.priority) :
                \ x.snipFileScope.priority
    if has_key(templates, a:name) && templates[a:name].priority <= prio
        return
    endif
    call s:CleanupSnippet( x, foo )
    let isWrapped = type(foo.snip) != type(function("tr")) && foo.snip =~ '\V' . xp.lft . s:wrappedName . xp.rt
    let templates[a:name] = {
                \ 'name'        : a:name,
                \ 'parsed'      : 0, 
                \ 'ftScope'     : ftScope, 
                \ 'tmpl'        : foo.snip,
                \ 'priority'    : prio,
                \ 'setting'     : templateSetting,
                \ 'ptn'         : deepcopy(g:XPTobject().snipFileScope.ptn),
                \ 'wrapped'     : isWrapped, 
                \}
    call s:InitTemplateObject( x, templates[ a:name ] )
endfunction 
fun! s:CleanupSnippet( xptObj, foo ) 
    if type( a:foo.snip ) == type( 'tr' )
        return a:foo.snip
    endif
    let foo = a:foo
    if type(foo.snip) == type([])
        let foo.snip = join(foo.snip, "\n")
    endif
    if type( foo.snip ) == type( '' )
        let tabspace = repeat( ' ', &l:tabstop )
    endif
    return foo.snip
endfunction 
fun! s:InitTemplateObject( xptObj, tmplObj ) 
    call s:ParseTemplateSetting( a:xptObj, a:tmplObj.setting )
    if type( a:tmplObj.tmpl ) == type( '' )
    endif
    call s:addCursorToComeLast(a:tmplObj.setting)
    call s:initItemOrderDict( a:tmplObj.setting )
    if has_key( a:tmplObj.setting.defaultValues, 'cursor' )
    else
    endif
    if !has_key( a:tmplObj.setting.defaultValues, 'cursor' )
                \ || a:tmplObj.setting.defaultValues.cursor !~ 'Finish'
        let a:tmplObj.setting.defaultValues.cursor = "\n" . 'Finish()'
    endif
    let nonWordChar = substitute( a:tmplObj.name, '\w', '', 'g' ) 
    if nonWordChar != '' && !a:tmplObj.wrapped
        call XPTemplateKeyword( nonWordChar )
    endif
endfunction 
fun! s:ParseInclusion( tmplDict, tmplObject ) 
    if type( a:tmplObject.tmpl ) == type( function( 'tr' ) )
        return
    endif
    let xp = a:tmplObject.ptn
    let phPattern = '\V' . xp.lft . 'Include:\(\.\{-}\)' . xp.rt
    let linePattern = '\V' . '\n\(\s\*\)\.\{-}' . phPattern
    call s:DoInclude( a:tmplDict, a:tmplObject, { 'ph' : phPattern, 'line' : linePattern } )
    let phPattern = '\V' . xp.lft . ':\(\.\{-}\):' . xp.rt
    let linePattern = '\V' . '\n\(\s\*\)\.\{-}' . phPattern
    call s:DoInclude( a:tmplDict, a:tmplObject, { 'ph' : phPattern, 'line' : linePattern } )
endfunction 
fun! s:DoInclude( tmplDict, tmplObject, pattern ) 
    let included = { a:tmplObject.name : 1 }
    let snip = "\n" . a:tmplObject.tmpl
    let pos = 0
    while 1
        let pos = match( snip, a:pattern.line, pos )
        if -1 == pos
            break
        endif
        let [ matching, indent, incName ] = matchlist( snip, a:pattern.line, pos )[ : 2 ]
        let indent = matchstr( split( matching, '\n' )[ -1 ], '^\s*' )
        if has_key( a:tmplDict, incName )
            if has_key( included, incName )
                let included[ incName ] += 1
                if included[ incName ] > 100
                    throw "XPT : include too many snippet:" . incName . ' in ' . a:tmplObject.name
                endif
            else
                let included[ incName ] = 1
            endif
            let ph = matchstr( matching, a:pattern.ph )
            let incTmplObject = a:tmplDict[ incName ]
            call s:MergeSetting( a:tmplObject, incTmplObject )
            let incSnip = substitute( incTmplObject.tmpl, '\n', '&' . indent, 'g' )
            let snip = snip[ : pos + len( matching ) - len( ph ) - 1 ] . incSnip . snip[ pos + len( matching ) : ]
        else
            throw "XPT : include invalid snippet:" . incName . ' in ' . a:tmplObject.name
        endif
    endwhile
    let a:tmplObject.tmpl = snip[1:]
endfunction 
fun! s:MergeSetting( tmplObject, incTmplObject ) 
    call extend( a:tmplObject.setting.preValues, a:incTmplObject.setting.preValues, 'keep' )
    call extend( a:tmplObject.setting.defaultValues, a:incTmplObject.setting.defaultValues, 'keep' )
    call extend( a:tmplObject.setting.postFilters, a:incTmplObject.setting.postFilters, 'keep' )
endfunction 
fun! s:ParseTemplateSetting( xptObj, setting ) 
    let setting = a:setting
    let idt = deepcopy(a:xptObj.snipFileScope.indent)
    if has_key(setting, 'indent')
        call s:ParseIndent(idt, setting.indent)
    endif
    let setting.indent = idt
    call s:GetHint(setting)
    call s:ParsePostQuoter( setting )
endfunction 
fun! s:ParsePostQuoter( setting ) 
    if !has_key( a:setting, 'postQuoter' ) 
                \ || type( a:setting.postQuoter ) == type( {} )
        return
    endif
    let quoters = split( a:setting.postQuoter, ',' )
    if len( quoters ) < 2
        throw 'postQuoter must be separated with ","! :' . a:setting.postQuoter
    endif
    let a:setting.postQuoter = { 'start' : quoters[0], 'end' : quoters[1] }
endfunction 
fun! s:addCursorToComeLast(setting) 
  let comeLast = copy( a:setting.comeLast )
  let cursorItem = filter( comeLast, 'v:val == "cursor"' )
  if cursorItem == []
    call add( a:setting.comeLast, 'cursor' )
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
    unlet b:xptemplateData
  catch /.*/
  endtry
  e
endfunction 
fun! XPTgetAllTemplates() 
    return copy( XPTbufData().filetypes[ &filetype ].normalTemplates )
endfunction 
fun! XPTemplatePreWrap(wrap) 
    let x = g:XPTobject()
    let x.wrap = a:wrap
    let x.wrap = substitute( x.wrap, '\n$', '', '' )
    let x.wrapStartPos = col(".")
    if g:xptemplate_strip_left || x.wrap =~ '\n'
        let indent = matchstr( x.wrap, '^\s*' )
        let x.wrap = x.wrap[ len( indent ) : ]
        let x.wrap = s:BuildFilterIndent( x.wrap, len( indent ) )
        let x.wrap = 'Echo(' . string( x.wrap ) . ')'
    endif
    if getline( line( "." ) ) =~ '^\s*$'
        while col( "." ) != 1
            exe "normal! \<bs>"
        endwhile
        let leftSpaces = repeat( ' ', x.wrapStartPos - 1 )
    else
        let leftSpaces = ''
    endif
    return leftSpaces . "\<C-r>=XPTemplateDoWrap()\<cr>"
endfunction 
fun! XPTemplateDoWrap() 
    let x = g:XPTobject()
    let ppr = s:Popup("", x.wrapStartPos)
    return ppr
endfunction 
fun! XPTemplateStart(pos_nonused_any_more, ...) 
    let x = g:XPTobject()
    if a:0 == 1 &&  type(a:1) == type({}) && has_key( a:1, 'tmplName' )  
        let startColumn = a:1.startPos[1]
        let templateName = a:1.tmplName
        call cursor(a:1.startPos)
        return  s:DoStart( {
                    \'line' : a:1.startPos[0], 
                    \'col' : startColumn, 
                    \'matched' : templateName, 
                    \'data' : { 'ftScope' : s:GetContextFTObj() } } )
    else 
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
    if has_key(a:ctx, 'hint')
        let a:ctx.hint = s:Eval(a:ctx.hint)
    else
    endif
endfunction 
fun! s:ParsePriorityString(s) 
    let x = g:XPTobject()
    let pstr = a:s
    let prio = 0
    if pstr == ""
        let prio = x.snipFileScope.priority
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
fun! s:newTemplateRenderContext( xptBufData, ftScope, tmplName ) 
    if s:getRenderContext().processing
        call s:PushCtx()
    endif
    let renderContext = s:createRenderContext(a:xptBufData)
    let renderContext.phase = 'inited'
    let renderContext.tmpl  = s:GetContextFTObj().normalTemplates[a:tmplName]
    let renderContext.ftScope = a:ftScope
    return renderContext
endfunction 
fun! s:DoStart(sess) 
    let x = g:XPTobject()
    if !has_key( s:GetContextFTObj().normalTemplates, a:sess.matched )
        return ''
    endif
    let x.savedReg = @"
    let [lineNr, column] = [ a:sess.line, a:sess.col ]
    let cursorColumn = col(".")
    let tmplname = a:sess.matched
    let ctx = s:newTemplateRenderContext( x, a:sess.data.ftScope, tmplname )
    call s:RenderTemplate([ lineNr, column ], [ lineNr, cursorColumn ])
    let ctx.phase = 'rendered'
    let ctx.processing = 1
    if empty(x.stack)
        call s:ApplyMap()
    endif
    let x.wrap = ''
    let x.wrapStartPos = 0
    let action =  s:GotoNextItem()
    let action .= ''
    return action
endfunction 
fun! s:FinishRendering(...) 
    let x = g:XPTobject()
    let renderContext = s:getRenderContext()
    let xp = renderContext.tmpl.ptn
    call s:removeMarksInRenderContext(renderContext) 
    if empty(x.stack)
        let renderContext.processing = 0
        let renderContext.phase = 'finished'
        call s:ClearMap()
        call XPMflushWithHistory()
        let @" = x.savedReg
        return '' 
    else
        call s:PopCtx()
        let renderContext = s:getRenderContext()
        let behavior = renderContext.item.behavior
        if has_key( behavior, 'gotoNextAtOnce' ) && behavior.gotoNextAtOnce
            return s:GotoNextItem()
        else
            return ''
        endif
    endif
endfunction 
fun! s:removeMarksInRenderContext( renderContext ) 
    let renderContext = a:renderContext
    call XPMremoveMarkStartWith( renderContext.markNamePre )
endfunction 
fun! s:Popup(pref, coln) 
    let x = g:XPTobject()
    let ctx = s:getRenderContext()
    if ctx.phase == 'finished'
        let ctx.phase = 'popup'
    endif
    let cmpl=[]
    let cmpl2 = []
    let ftScope = s:GetContextFTObj()
    if ftScope == {}
        return ''
    endif
    let dic = ftScope.normalTemplates
    let ctxs = s:SynNameStack(line("."), a:coln)
    let ignoreCase = a:pref !~# '\u'
    for [ key, templateObject ] in items(dic)
        if templateObject.wrapped && empty(x.wrap) || !templateObject.wrapped && !empty(x.wrap)
            continue
        endif
        if has_key(templateObject.setting, "syn") && templateObject.setting.syn != '' && match(ctxs, '\c'.templateObject.setting.syn) == -1
            continue
        endif
        if has_key( templateObject.setting, 'hidden' ) && templateObject.setting.hidden == '1'
            continue
        endif
        let hint = has_key( templateObject.setting, 'hint' ) ? templateObject.setting.hint : ''
        if key =~# "^[A-Z]"
            call add(cmpl2, {'word' : key, 'menu' : hint })
        else
            call add(cmpl, {'word' : key, 'menu' : hint})
        endif
    endfor
    call sort(cmpl)
    call sort(cmpl2)
    let cmpl = cmpl + cmpl2
    return XPPopupNew(s:pumCB, { 'ftScope' : ftScope }, cmpl).popup(a:coln, {})
endfunction 
fun! s:ApplyTmplIndent( templateObject, startPos ) 
    let indent = a:templateObject.setting.indent
    let tmpl = a:templateObject.tmpl
    let baseIndent = repeat(" ", indent(a:startPos[0]))
    if indent.type =~# 'keep\|rate\|auto'
        if indent.type ==# "rate"
            let patternOfOriginalIndent = repeat(' ', indent.rate[0])
            let patternOfOriginalIndent ='\(\%('.patternOfOriginalIndent.'\)*\)'
            let expandedIndent = repeat('\1', indent.rate[1] / indent.rate[0])
            let tmpl = substitute(tmpl, '\%(^\|\n\)\zs'.patternOfOriginalIndent, expandedIndent, 'g')
        endif
        let tmpl = substitute(tmpl, '\n', '&' . baseIndent, 'g')
    endif
    return tmpl
endfunction 
let s:oldRepPattern = '\w\*...\w\*'
fun! s:ParseRepetition(str, tmplObject) 
    let tmplObj = a:tmplObject
    let xp = a:tmplObject.ptn
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
        let indent = s:GetIndentBeforeEdge( tmplObj, bef )
        let repeatPart = matchstr(rest, repContPtn)
        let repeatPart = 'BuildIfNoChange(' . string( repeatPart ) . ')'
        let repeatPart = s:BuildFilterIndent( repeatPart, indent )
        let symbol = matchstr(rest, rp)
        let name = substitute( symbol, '\V' . xp.lft . '\|' . xp.rt, '', 'g' )
        let tmplObj.setting.postFilters[ name ] = repeatPart
        let bef .= symbol
        let rest = substitute(rest, repPtn, '', '')
        let tmpl = bef . rest
    endwhile
    return tmpl
endfunction 
fun! s:GetIndentBeforeEdge( tmplObj, textBeforeLeftMark ) 
    let xp = a:tmplObj.ptn
    if a:textBeforeLeftMark =~ '\V' . xp.lft . '\_[^' . xp.r . ']\*\%$'
        let tmpBef = substitute( a:textBeforeLeftMark, '\V' . xp.lft . '\_[^' . xp.r . ']\*\%$', '', '' )
        let indentOfFirstLine = matchstr( tmpBef, '.*\n\zs\s*' )
    else
        let indentOfFirstLine = matchstr( a:textBeforeLeftMark, '.*\n\zs\s*' )
    endif
    return len( indentOfFirstLine )
endfunction 
fun! s:parseQuotedPostFilter( tmplObj ) 
    let xp = a:tmplObj.ptn
    let postFilters = a:tmplObj.setting.postFilters
    let quoter = a:tmplObj.setting.postQuoter
    let flagPattern = '\V\[!]\$'
    let startPattern = '\V\_.\{-}\zs' . xp.lft . '\_[^' . xp.r . ']\*' . quoter.start . xp.rt
    let endPattern = '\V' . xp.lft . quoter.end . xp.rt
    let snip = a:tmplObj.tmpl
    let stack = []
    let startPos = 0
    while startPos != -1
      let startPos = match(snip, startPattern, startPos)
      if startPos != -1
          call add( stack, startPos)
          let startPos += len( matchstr( snip, startPattern, startPos ) )
      endif
    endwhile
    while 1
        if empty( stack )
          break
        endif
        let startPos = remove( stack, -1 )
        let endPos = match( snip, endPattern, startPos + 1 )
        if endPos == -1
            break
        endif
        let startText = matchstr( snip, startPattern, startPos )
        let endText   = matchstr( snip, endPattern, endPos )
        let name = startText[ 1 : -1 - len( quoter.start ) - 1 ]
        let flag = matchstr( name, flagPattern )
        if flag != ''
            let name = name[ : -1 - len( flag ) ]
        endif
        if name =~ xp.lft
            let name = matchstr( name, '\V' . xp.lft . '\zs\_.\*' )
            if name =~ xp.lft
                let name = matchstr( name, '\V\_.\*\ze' . xp.lft )
            endif
        endif
        let plainPostFilter = snip[ startPos + len( startText ) : endPos - 1 ]
        let firstLineIndent = s:GetIndentBeforeEdge( a:tmplObj, snip[ : startPos - 1 ] )
        if flag == '!'
            let plainPostFilter = 'BuildIfChanged(' . string( plainPostFilter ) . ')'
        else
            let plainPostFilter = 'BuildIfNoChange(' . string( plainPostFilter ) . ')'
        endif
        let plainPostFilter = s:BuildFilterIndent( plainPostFilter, firstLineIndent )
        let postFilters[ name ] = plainPostFilter
        let snip = snip[ : startPos + len( startText ) - 1 - 1 - len( quoter.start ) - len( flag ) ] 
                    \. snip[ endPos + len( endText ) - 1 : ]
    endwhile
    return snip
endfunction 
fun! s:RenderTemplate(nameStartPosition, nameEndPosition) 
    let x = g:XPTobject()
    let ctx = s:getRenderContext()
    let xp = s:getRenderContext().tmpl.ptn
    let ctx.phase = 'rendering'
    if !ctx.tmpl.parsed
        if ctx.tmpl.wrapped
            call s:ParseInclusion( ctx.ftScope.normalTemplates, ctx.tmpl )
        else
            call s:ParseInclusion( ctx.ftScope.normalTemplates, ctx.tmpl )
        endif
        let ctx.tmpl.tmpl = s:parseQuotedPostFilter( ctx.tmpl )
        let ctx.tmpl.tmpl = s:ParseRepetition(ctx.tmpl.tmpl, ctx.tmpl)
        let ctx.tmpl.parsed = 1
    endif
    let tmpl = ctx.tmpl.tmpl
    if tmpl =~ '\n'
        let tmpl = s:ApplyTmplIndent( ctx.tmpl, a:nameStartPosition )
    endif
    if ctx.tmpl.wrapped
        let ctx.tmpl.setting.preValues.wrapped = x.wrap
        let ctx.tmpl.setting.defaultValues.wrapped = "Next()"
    endif
    call XPMupdate()
    call XPMadd( ctx.marks.tmpl.start, a:nameStartPosition, g:XPMpreferLeft )
    call XPMadd( ctx.marks.tmpl.end, a:nameEndPosition, g:XPMpreferRight )
    call XPMsetLikelyBetween( ctx.marks.tmpl.start, ctx.marks.tmpl.end )
    call XPreplace( a:nameStartPosition, a:nameEndPosition, tmpl )
    let ctx.firstList = []
    let ctx.itemList = []
    let ctx.lastList = []
    if 0 != s:BuildPlaceHolders( ctx.marks.tmpl )
        return s:Crash()
    endif
    call s:TopTmplRange()
    silent! normal! gvzO
endfunction 
fun! s:GetNameInfo(end) 
    let x = g:XPTobject()
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
fun! s:GetValueInfo(end) 
    let x = g:XPTobject()
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
fun! s:BuildFilterIndent( str, firstLineIndent ) 
    let [ nIndent, str ] = s:RemoveCommonIndent( a:str, a:firstLineIndent )
    return repeat( ' ', a:firstLineIndent - nIndent ) . "\n" . str
endfunction 
fun! s:RemoveCommonIndent( str, largerThan ) 
    let min = a:largerThan
    let list = split( a:str, "\n", 1 )
    call filter( list, 'v:val !~ ''^\s*$''' )
    for line in list[ 1 : ]
        let indentWidth = len( matchstr( line, '^\s*' ) )
        let min = min( [ min, indentWidth ] )
    endfor
    let pattern = '\n\s\{' . min . '}'
    return [min, substitute( a:str, pattern, "\n", 'g' )]
endfunction 
fun! s:CreatePlaceHolder( ctx, nameInfo, valueInfo ) 
    let xp = a:ctx.tmpl.ptn
    let leftEdge  = s:TextBetween(a:nameInfo[0], a:nameInfo[1])
    let name      = s:TextBetween(a:nameInfo[1], a:nameInfo[2])
    let rightEdge = s:TextBetween(a:nameInfo[2], a:nameInfo[3])
    let [ leftEdge, name, rightEdge ] = [ leftEdge[1 : ], name[1 : ], rightEdge[1 : ] ]
    let fullname  = leftEdge . name . rightEdge
    if name =~ '\V' . xp.item_var . '\|' . xp.item_func
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
        let val = s:TextBetween( a:valueInfo[0], a:valueInfo[1] )
        let val = val[1:]
        let val = g:xptutil.UnescapeChar( val, xp.l . xp.r )
        let val = s:BuildFilterIndent( val, indent( a:valueInfo[0][0] ) )
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
        let markName =  item.name . s:buildingSeqNr . '`' . ( placeHolder.isKey ? 'key' : (len(item.placeHolders)-1) )
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
    if ctx.phase != 'rendering'
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
fun! s:BuildPlaceHolders( markRange ) 
    let s:buildingSeqNr += 1
    let renderContext = s:getRenderContext()
    let tmplObj = renderContext.tmpl
    let xp = renderContext.tmpl.ptn
    let [ start, end ] = XPMposList( a:markRange.start, a:markRange.end )
    let renderContext.action = 'build'
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
        while 1
            let end = XPMpos( a:markRange.end )
            let nEnd = end[0] * 10000 + end[1]
            let markPos = searchpos( '\V\\\*\[' . xp.l . xp.r . ']', 'cW' )
            if markPos == [0, 0] || markPos[0] * 10000 + markPos[1] >= nEnd
                break
            endif
            let content = getline( markPos[0] )[ markPos[1] - 1 : ]
            let char = matchstr( content, '[' . xp.l . xp.r . ']' )
            let content = matchstr( content, '^\\*' )
            let newEsc = repeat( '\', len( content ) / 2 )
            call XPreplace( markPos, [ markPos[0], markPos[1] + len( content ) ], newEsc )
            if len( content ) % 2 == 0 && char == xp.l
                call cursor( [ markPos[0], markPos[1] + len( newEsc ) ] )
                let end = XPMpos( a:markRange.end )
                let nEnd = end[0] * 10000 + end[1]
                break
            endif
            call cursor( [ markPos[0], markPos[1] + len( newEsc ) + 1 ] )
        endwhile
        if markPos == [0, 0] || markPos[0] * 10000 + markPos[1] >= nEnd
            break
        endif
        let nn = [ line( "." ), col( "." ) ]
        let nameInfo = s:GetNameInfo(end)
        if nameInfo[0] == [0, 0]
            break
        endif
        call cursor(nameInfo[3])
        let valueInfo = s:GetValueInfo(end)
        if valueInfo[0] == [0, 0]
            break
        endif
        let placeHolder = s:CreatePlaceHolder(renderContext, nameInfo, valueInfo)
        if has_key( placeHolder, 'value' )
            call s:ApplyInstantValue( placeHolder, nameInfo, valueInfo )
        else
            let item = s:BuildItemForPlaceHolder( renderContext, placeHolder )
            call s:buildMarksOfPlaceHolder( renderContext, item, placeHolder, nameInfo, valueInfo )
            call s:EvaluateEdge( xp, placeHolder )
            call s:ApplyPreValues( placeHolder )
            call s:SetDefaultFilters( tmplObj, placeHolder )
            call cursor( XPMpos( placeHolder.mark.end ) )
        endif
    endwhile
    call filter( renderContext.firstList, 'v:val != {}' )
    call filter( renderContext.lastList, 'v:val != {}' )
    let renderContext.itemList = renderContext.firstList + renderContext.itemList + renderContext.lastList
    let renderContext.firstList = []
    let renderContext.lastList = []
    let end = XPMpos( a:markRange.end )
    call cursor( end )
    let renderContext.action = ''
    return 0
endfunction 
fun! s:EvaluateEdge( xp, ph ) 
    if !a:ph.isKey
        return
    endif
    if a:ph.leftEdge =~ '\V' . a:xp.item_var . '\|' . a:xp.item_func
        let ledge = s:Eval( a:ph.leftEdge )
        call XPRstartSession()
        call XPreplaceByMarkInternal( a:ph.mark.start, a:ph.editMark.start, ledge )
        call XPRendSession()
    endif
    if a:ph.rightEdge =~ '\V' . a:xp.item_var . '\|' . a:xp.item_func
        let redge = s:Eval( a:ph.rightEdge )
        call XPRstartSession()
        call XPreplaceByMarkInternal( a:ph.editMark.end, a:ph.mark.end, redge )
        call XPRendSession()
    endif
endfunction 
fun! s:ApplyInstantValue( placeHolder, nameInfo, valueInfo ) 
    let placeHolder = a:placeHolder
    let nameInfo    = a:nameInfo
    let valueInfo   = a:valueInfo
    let value = s:Eval( placeHolder.value )
    if value == "\n"
        let indentSpace = repeat( ' ', indent( nameInfo[0][0] ) )
        let value = substitute( value, '\n', '&' . indentSpace, 'g' )
    elseif value !~ '\n'
    else
        let [ filterIndent, filterText ] = s:GetFilterIndentAndText( value )
        let value = s:AdjustIndentAccordingToLine( filterText, filterIndent, nameInfo[0][0] )
    endif
    let valueInfo[-1][1] += 1
    call XPreplace( nameInfo[0], valueInfo[-1], value )
endfunction 
fun! s:ApplyPreValues( placeHolder ) 
    let renderContext = s:getRenderContext()
    let tmplObj = renderContext.tmpl
    let xp = tmplObj.ptn
    let setting = tmplObj.setting
    let preValue = a:placeHolder.name == '' ? '' : 
                \ (has_key( setting.preValues, a:placeHolder.name ) ? setting.preValues[ a:placeHolder.name ] : '')
    if !s:IsFilterEmpty( preValue ) 
        let preValue = s:Eval( preValue )
        let [ filterIndent, filterText ] = s:GetFilterIndentAndText( preValue )
        call s:SetPreValue( a:placeHolder, filterIndent, filterText )
    else
        let preValue = has_key( setting.defaultValues, a:placeHolder.name ) ? 
                    \setting.defaultValues[ a:placeHolder.name ] 
                    \: a:placeHolder.ontimeFilter
        if !s:IsFilterEmpty( preValue ) 
            if preValue !~ '\V' . xp.item_func . '\|' . xp.item_qfunc 
                        \|| preValue =~ '\V_pre()'
                let text = s:Eval( preValue )
                let [ filterIndent, filterText ] = s:GetFilterIndentAndText( text )
                call s:SetPreValue( a:placeHolder, filterIndent, filterText )
            endif
        endif
    endif
endfunction 
fun! s:SetPreValue( placeHolder, indent, text ) 
    let marks = a:placeHolder.isKey ? a:placeHolder.editMark : a:placeHolder.mark
    let text = s:AdjustIndentAccordingToLine( a:text, a:indent, XPMpos( marks.start )[0], a:placeHolder )
    call XPRstartSession()
    try
        call XPreplaceByMarkInternal( marks.start, marks.end, text )
    catch /.*/
    finally
        call XPRendSession()
    endtry
endfunction 
fun! s:BuildItemForPlaceHolder( ctx, placeHolder ) 
    if has_key(a:ctx.itemDict, a:placeHolder.name)
        let item = a:ctx.itemDict[ a:placeHolder.name ]
    else
        let item = { 'name'         : a:placeHolder.name, 
                    \'fullname'     : a:placeHolder.name, 
                    \'processed'    : 0, 
                    \'placeHolders' : [], 
                    \'keyPH'        : s:NullDict, 
                    \'behavior'     : {}, 
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
    let x = g:XPTobject()
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
    let x = g:XPTobject()
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
fun! s:ShipBack() 
    let renderContext = s:getRenderContext()
    if empty( renderContext.history )
        return ''
    endif
    let his = remove( renderContext.history, -1 )
    call s:PushBackItem()
    let renderContext.item = his.item
    let renderContext.leadingPlaceHolder = his.leadingPlaceHolder
    let leader = renderContext.leadingPlaceHolder
    call XPMsetLikelyBetween( leader.mark.start, leader.mark.end )
    let action = s:selectCurrent(renderContext)
    call XPMupdateStat()
    return action
endfunction 
fun! s:PushBackItem() 
    let renderContext = s:getRenderContext()
    let item = renderContext.item
    if !renderContext.leadingPlaceHolder.isKey 
        call insert( item.placeHolders, renderContext.leadingPlaceHolder, 0 )
    endif
    call insert( renderContext.itemList, item, 0 )
    if item.name != ''
        let renderContext.itemDict[ item.name ] = item
    endif
endfunction 
fun! s:FinishCurrentAndGotoNextItem(action) 
    let renderContext = s:getRenderContext()
    let marks = renderContext.leadingPlaceHolder.mark
    let rc = s:XPTupdate()
    if rc == -1
        return ''
    endif
    let name = renderContext.item.name
    if a:action ==# 'clear'
        call XPreplace(XPMpos( marks.start ),XPMpos( marks.end ), '')
    endif
    let [ post, built ] = s:ApplyPostFilter()
    let renderContext.step += [{ 'name' : renderContext.item.name, 'value' : post }]
    if renderContext.item.name != ''
        let renderContext.namedStep[renderContext.item.name] = post
    endif
    if built
        call s:removeCurrentMarks()
    else
        let renderContext.history += [ {
                    \'item' : renderContext.item, 
                    \'leadingPlaceHolder' : renderContext.leadingPlaceHolder } ]
    endif
    let postaction =  s:GotoNextItem()
    return postaction
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
fun! s:ApplyPostFilter() 
    let renderContext = s:getRenderContext()
    let posts  = renderContext.tmpl.setting.postFilters
    let name   = renderContext.item.name
    let leader = renderContext.leadingPlaceHolder
    let marks  = renderContext.leadingPlaceHolder.mark
    let renderContext.phase = 'post'
    let typed = s:TextBetween(XPMpos( marks.start ), XPMpos( marks.end ))
    if renderContext.item.name != ''
        let renderContext.namedStep[renderContext.item.name] = typed
    endif
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
    let filterIndent = matchstr( filter, '\s*\ze\n' )
    let filterText = matchstr( filter, '\n\zs\_.*' )
    let ifToBuild = 0
    if filterText != ''
        let [ text, ifToBuild, rc ] = s:EvalPostFilter( filterText, typed, leader )
        let [ start, end ] = XPMposList( marks.start, marks.end )
        if rc is g:XPT_RC.POST.keepIndent
            let snip = text
        else
            let snip = s:AdjustIndentAccordingToLine( text, filterIndent, start[0], leader )
        endif
        call XPMsetLikelyBetween( marks.start, marks.end )
        call XPreplace(start, end, snip)
        if ifToBuild
            call cursor( start )
            let renderContext.firstList = []
            if 0 != s:BuildPlaceHolders( marks )
                return [ s:Crash(), ifToBuild ]
            endif
            let renderContext.phase = 'post'
        endif
    endif
    if s:IsFilterEmpty( groupPostFilter )
        call s:UpdateFollowingPlaceHoldersWith( typed, {} )
        return [ typed, ifToBuild ]
    else
        call s:UpdateFollowingPlaceHoldersWith( typed, { 'indent' : filterIndent, 'post' : text } )
        return [ text, ifToBuild ]
    endif
endfunction 
fun! s:EvalPostFilter( filter, typed, leader ) 
    let renderContext = s:getRenderContext()
    let post = s:Eval(a:filter, {'typed' : a:typed})
    if type( post ) == 4
        if post.action == 'build'
            let res = [ post.text, 1, g:XPT_RC.ok ]
        elseif post.action == 'keepIndent'
            let res = [ post.text, 0, g:XPT_RC.POST.keepIndent ]
        else
            let res = [ post.text, 0, g:XPT_RC.ok ]
        endif
    elseif type( post ) == 1
        let res = [ post, 1, g:XPT_RC.POST.keepIndent ]
    else
        let res = [ string( post ), 0, g:XPT_RC.ok ]
    endif
    return res
endfunction 
fun! s:AdjustIndentAccordingToLine( snip, indent, lineNr, ... ) 
    let indent = indent( a:lineNr )
    if a:0 == 1
        let ph = a:1
        let leftMostMark = ph.mark.start
        let pos = XPMpos( leftMostMark )
        if pos[0] == a:lineNr && pos[1] - 1 < indent
            let indent = pos[1] - 1
        endif
    endif
    let indentspaces = repeat(' ', indent)
    if len( indentspaces ) > len( a:indent )
      let indentspaces = substitute( indentspaces, a:indent, '', '' )
    else
      let indentspaces = ''
    endif
    return substitute( a:snip, "\n", "\n" . indentspaces, 'g' )
endfunction 
fun! s:GotoNextItem() 
    let renderContext = s:getRenderContext()
    let placeHolder = s:ExtractOneItem()
    if placeHolder == s:NullDict
        call cursor( XPMpos( renderContext.marks.tmpl.end ) )
        return s:FinishRendering(1)
    endif
    let phPos = XPMpos( placeHolder.mark.start )
    if phPos == [0, 0]
        return s:Crash('failed to find position of mark:' . placeHolder.mark.start)
    endif
    let leader =  renderContext.leadingPlaceHolder
    let leaderMark = leader.isKey ? leader.editMark : leader.mark
    call XPMsetLikelyBetween( leaderMark.start, leaderMark.end )
    if renderContext.item.processed
        let action = s:selectCurrent(renderContext)
        call XPMupdateStat()
        return action
    endif
    let postaction = s:InitItem()
    let renderContext = s:getRenderContext()
    let leader =  renderContext.leadingPlaceHolder
    if !renderContext.processing
        return postaction
    endif
    call XPMsetLikelyBetween( leader.mark.start, leader.mark.end )
    if postaction != ''
        return postaction
    else
        if renderContext.leadingPlaceHolder.isKey
            call cursor( XPMpos( renderContext.leadingPlaceHolder.editMark.end ) )
        else
            call cursor( XPMpos( renderContext.leadingPlaceHolder.mark.end ) )
        endif
        return ""
    endif
endfunction 
fun! s:TL(...)
    return XPMpos( g:XPTobject().renderContext.marks.tmpl.start )
endfunction
fun! s:BR(...)
    return XPMpos( g:XPTobject().renderContext.marks.tmpl.end )
endfunction
fun! s:ExtractOneItem() 
    let renderContext = s:getRenderContext()
    let itemList = renderContext.itemList
    let [ renderContext.item, renderContext.leadingPlaceHolder ] = [ {}, {} ]
    if empty( itemList )
        return s:NullDict
    endif
    let item = itemList[ 0 ]
    let renderContext.itemList = renderContext.itemList[ 1 : ]
    if item.name != '' && has_key( renderContext.itemDict, item.name )
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
fun! s:HandleDefaultValueAction( ctx, act ) 
    let ctx = a:ctx
    if has_key(a:act, 'action') " actions
        if a:act.action ==# 'expandTmpl' && has_key( a:act, 'tmplName' )
            let ctx.item.behavior.gotoNextAtOnce = 1
            let marks = ctx.leadingPlaceHolder.mark
            call XPreplace(XPMpos( marks.start ), XPMpos( marks.end ), '')
            call XPMsetLikelyBetween( marks.start, marks.end )
            return XPTemplateStart(0, {'startPos' : getpos(".")[1:2], 'tmplName' : a:act.tmplName})
        elseif a:act.action ==# 'finishTemplate'
            call XPreplace(XPMpos( ctx.leadingPlaceHolder.mark.start ), XPMpos( ctx.leadingPlaceHolder.mark.end )
                        \, has_key( a:act, 'postTyping' ) ? a:act.postTyping : '' )
            let xptObj = g:XPTobject() 
            if empty( xptObj.stack )
                return s:FinishRendering()
            else
                return ''
            endif
        elseif a:act.action ==# 'embed'
            return s:EmbedSnippetInLeadingPlaceHolder( ctx, a:act.snippet )
        elseif a:act.action ==# 'next'
            if has_key( a:act, 'text' )
                let text = has_key( a:act, 'text' ) ? a:act.text : ''
                if text != ''
                    if text =~ '\n'
                        let [ filterIndent, filterText ] = s:GetFilterIndentAndText( text )
                        let leader = ctx.leadingPlaceHolder
                        let marks = leader.isKey ? leader.editMark : leader.mark
                        let text = s:AdjustIndentAccordingToLine( filterText, filterIndent, XPMpos( marks.start )[0], leader )
                    else
                    endif
                endif
                call s:FillinLeadingPlaceHolderAndSelect( ctx, text )
            endif
            return s:FinishCurrentAndGotoNextItem( '' )
        else " other action
        endif
        return -1
    else
        return -1
    endif
endfunction 
fun! s:EmbedSnippetInLeadingPlaceHolder( ctx, snippet ) 
    let ph = a:ctx.leadingPlaceHolder
    let marks = ph.isKey ? ph.editMark : ph.mark
    let range = [ XPMpos( marks.start ), XPMpos( marks.end ) ]
    if range[0] == [0, 0] || range[1] == [0, 0]
        return s:Crash( 'leading place holder''s mark lost:' . string( marks ) )
    endif
    call XPreplace( range[0], range[1] , a:snippet )
    if 0 != s:BuildPlaceHolders( marks )
        return s:Crash('building place holder failed')
    endif
    return s:GotoNextItem()
endfunction 
fun! s:FillinLeadingPlaceHolderAndSelect( ctx, str ) 
    let [ ctx, str ] = [ a:ctx, a:str ]
    let [ item, ph ] = [ ctx.item, ctx.leadingPlaceHolder ]
    let marks = ph.isKey ? ph.editMark : ph.mark
    let [ start, end ] = [ XPMpos( marks.start ), XPMpos( marks.end ) ]
    if start == [0, 0] || end == [0, 0]
        return s:Crash()
    endif
    call XPreplace( start, end, str )
    let xp = ctx.tmpl.ptn
    if str =~ '\V' . xp.lft . '\.\*' . xp.rt
        if 0 != s:BuildPlaceHolders( marks )
            return s:Crash()
        endif
        return s:GotoNextItem()
    endif
    call s:XPTupdate()
    let action = s:selectCurrent(ctx)
    call XPMupdateStat()
    return action
endfunction 
fun! s:ApplyDefaultValueToPH( renderContext, filter ) 
    let renderContext = a:renderContext
    let leader = renderContext.leadingPlaceHolder
    let str = a:filter
    let obj = s:Eval(str) 
    if type(obj) == type({})
        let rc = s:HandleDefaultValueAction( renderContext, obj )
        return ( rc is -1 ) ? s:FillinLeadingPlaceHolderAndSelect( renderContext, '' ) : rc
    elseif type(obj) == type([])
        if len(obj) == 0
            return s:FillinLeadingPlaceHolderAndSelect( renderContext, '' )
        endif
        let marks = leader.isKey ? leader.editMark : leader.mark
        let [ start, end ] = XPMposList( marks.start, marks.end )
        call XPreplace( start, end, '')
        call cursor(start)
        let pumSess = XPPopupNew(s:ItemPumCB, {}, obj)
        call pumSess.SetAcceptEmpty(g:xptemplate_ph_pum_accept_empty)
        return pumSess.popup(col("."), { 'doCallback' : 1, 'enlarge' : 0 } )
    else 
        let filterIndent = matchstr( obj, '\s*\ze\n' )
        let filterText = matchstr( obj, '\n\zs\_.*' )
        let str = s:AdjustIndentAccordingToLine( filterText, filterIndent, XPMpos( renderContext.leadingPlaceHolder.mark.start )[0], renderContext.leadingPlaceHolder )
        return s:FillinLeadingPlaceHolderAndSelect( renderContext, str )
    endif
endfunction 
fun! s:InitItem() 
    let renderContext = s:getRenderContext()
    let renderContext.phase = 'fillin'
    if has_key(renderContext.tmpl.setting.defaultValues, renderContext.item.name)
        return s:ApplyDefaultValueToPH( renderContext, 
                    \renderContext.tmpl.setting.defaultValues[ renderContext.item.name ])
    elseif renderContext.leadingPlaceHolder.ontimeFilter != ''
        return s:ApplyDefaultValueToPH( renderContext, 
                    \renderContext.leadingPlaceHolder.ontimeFilter)
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
fun! s:CreateStringMask( str ) 
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
    let sptn = sqe.'\%(\_[^'']\)\{-}'''
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
fun! XPTS2l(a, b)
    return a:a - a:b
endfunction
fun! s:Eval(s, ...) 
    let x = g:XPTobject()
    let ctx = s:getRenderContext()
    if ctx.phase == 'uninit'
        let xfunc = g:GetSnipFileFtScope().funcs
    else
        let xfunc = ctx.ftScope.funcs
    endif
    let tmpEvalCtx = { 'typed' : '', 'usingCache' : 1 }
    if a:0 >= 1
        call extend( tmpEvalCtx, a:1, 'force' )
    endif
    let nonEscaped =   '\%(' . '\%(\[^\\]\|\^\)' . '\%(\\\\\)\*' . '\)' . '\@<='
    let fptn = '\V' . '\w\+(\[^($]\{-})' . '\|' . nonEscaped . '{\w\+(\[^($]\{-})}'
    let vptn = '\V' . nonEscaped . '$\w\+' . '\|' . nonEscaped . '{$\w\+}'
    let patternVarOrFunc = fptn . '\|' . vptn
    let stringMask = s:CreateStringMask( a:s )
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
    let offsetsOfEltsToEval = sort(keys(rangesToEval), "XPTS2l")
    for k in offsetsOfEltsToEval
        let kn = 0 + k
        let vn = 0 + k + rangesToEval[k]
        let tmp = k == 0 ? "" : (str[last : kn-1])
        let tmp = g:xptutil.UnescapeChar( tmp, '[{$(' )
        let sp .= tmp
        let evaledResult = eval(str[kn : vn-1])
        if type(evaledResult) != type('')
            return evaledResult
        endif
        let sp .= evaledResult
        let last = vn
    endfor
    let tmp = str[last : ]
    let tmp = g:xptutil.UnescapeChar( tmp, '[{$(' )
    let sp .= tmp
    return sp
endfunction 
fun! s:TextBetween(p1, p2) 
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
    let x = g:XPTobject()
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
    let x = g:XPTobject()
    let p = getpos(".")[1:2]
    let cbr = s:CBR(x)
    if p[0] == cbr[0] && p[1] == cbr[1]
        return ""
    else
        let k= eval('"\<'.a:k.'>"')
        return k
    endif
endfunction 
fun! s:Goback() 
    let renderContext = s:getRenderContext()
    call cursor( XPMpos( renderContext.leadingPlaceHolder.mark.end ) )
    return ''
endfunction 
fun! s:XPTinit() 
    let disabledKeys = [
                \ 's_[%', 
                \ 's_]%', 
                \]
    let literalKeys = [
                \ 's_%', 
                \ 's_''', 
                \ 's_[', 
                \ 's_]', 
                \
                \ 'i_''', 
                \ 'i_"', 
                \ 'i_[', 
                \ 'i_(', 
                \ 'i_{', 
                \ 'i_<BS>', 
                \ 'i_<C-h>', 
                \ 'i_<DEL>', 
                \]
    let b:mapSaver = g:MapSaver.New(1)
    call b:mapSaver.AddList(
                \ 'i_' . g:xptemplate_nav_next, 
                \ 's_' . g:xptemplate_nav_next, 
                \
                \ 'i_' . g:xptemplate_nav_prev, 
                \ 's_' . g:xptemplate_nav_prev, 
                \
                \ 's_' . g:xptemplate_nav_cancel, 
                \ 's_' . g:xptemplate_to_right, 
                \ 'n_' . g:xptemplate_goback, 
                \
                \ 's_<DEL>', 
                \ 's_<BS>', 
                \)
    let b:mapLiteral = g:MapSaver.New( 1 )
    call b:mapLiteral.AddList( literalKeys )
    let b:mapMask = g:MapSaver.New( 0 )
    call b:mapMask.AddList( disabledKeys )
endfunction 
fun! s:ApplyMap() 
    let x = g:XPTobject()
    call SettingPush( '&l:textwidth', '0' )
    call b:mapSaver.Save()
    call b:mapLiteral.Save()
    call b:mapMask.Save()
    call b:mapSaver.UnmapAll()
    call b:mapLiteral.Literalize()
    call b:mapMask.UnmapAll()
    exe 'inoremap <silent> <buffer> '.g:xptemplate_nav_prev  .' <C-r>=<SID>ShipBack()<cr>'
    exe 'snoremap <silent> <buffer> '.g:xptemplate_nav_prev  .' <Esc>`>a<C-r>=<SID>ShipBack()<cr>'
    exe 'inoremap <silent> <buffer> '.g:xptemplate_nav_next  .' <C-r>=<SID>FinishCurrentAndGotoNextItem("")<cr>'
    exe 'snoremap <silent> <buffer> '.g:xptemplate_nav_next  .' <Esc>`>a<C-r>=<SID>FinishCurrentAndGotoNextItem("")<cr>'
    exe 'snoremap <silent> <buffer> '.g:xptemplate_nav_cancel.' <Esc>i<C-r>=<SID>FinishCurrentAndGotoNextItem("clear")<cr>'
    exe 'nnoremap <silent> <buffer> '.g:xptemplate_goback . ' i<C-r>=<SID>Goback()<cr>'
    snoremap <silent> <buffer> <Del> <Del>i
    if &selection == 'inclusive'
        snoremap <silent> <buffer> <BS> <esc>`>a<BS>
        exe "snoremap <silent> <buffer> ".g:xptemplate_to_right." <esc>`>a"
    else
        snoremap <silent> <buffer> <BS> <esc>`>i<BS>
        exe "snoremap <silent> <buffer> ".g:xptemplate_to_right." <esc>`>i"
    endif
endfunction 
fun! s:ClearMap() 
    call SettingPop( '&l:textwidth' )
    call b:mapMask.Restore()
    call b:mapLiteral.Restore()
    call b:mapSaver.Restore()
endfunction 
fun! s:CTL(...) 
    let x = a:0 == 1 ? a:1 : g:XPTobject()
    let cp = x.renderContext.pos.curpos
    return copy( cp.start.pos )
endfunction 
fun! s:CBR(...) 
    let x = a:0 == 1 ? a:1 : g:XPTobject()
    let cp = x.renderContext.pos.curpos
    return copy( cp.end.pos )
endfunction 
fun! XPTbufData() 
    return g:XPTobject()
endfunction 
let s:snipScopePrototype = {
            \'filename' : '', 
      \'ptn' : {'l':'`', 'r':'^'},
      \'indent' : {'type' : 'auto', 'rate' : []},
      \'priority' : s:priorities.lang, 
      \'filetype' : '', 
      \'inheritFT' : 0, 
      \}
fun! XPTnewSnipScope( filename )
  let x = b:xptemplateData
  let x.snipFileScope = deepcopy( s:snipScopePrototype )
  let x.snipFileScope.filename = a:filename
  call s:RedefinePattern()
  return x.snipFileScope
endfunction
fun! XPTsnipScope()
  return g:XPTobject().snipFileScope
endfunction
fun! XPTsnipScopePush()
  let x = g:XPTobject()
  let x.snipFileScopeStack += [x.snipFileScope]
  unlet x.snipFileScope
endfunction
fun! XPTsnipScopePop()
  let x = g:XPTobject()
  if len(x.snipFileScopeStack) > 0
    let x.snipFileScope = x.snipFileScopeStack[ -1 ]
    call remove( x.snipFileScopeStack, -1 )
  else
    throw "snipFileScopeStack is empty"
  endif
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
    let x = a:0 == 1 ? a:1 : g:XPTobject()
    return x.renderContext
endfunction 
fun! g:XPTobject() 
    if !exists("b:xptemplateData")
        let b:xptemplateData = {
                    \   'filetypes'         : { '**' : g:FiletypeScope.New() }, 
                    \   'wrapStartPos'      : 0, 
                    \   'wrap'              : '', 
                    \   'savedReg'          : '', 
                    \}
        let b:xptemplateData.posStack = []
        let b:xptemplateData.stack = []
        let b:xptemplateData.keyword = '\w'
        let b:xptemplateData.keywordList = []
        let b:xptemplateData.snipFileScopeStack = []
        let b:xptemplateData.snipFileScope = {}
        call s:createRenderContext( b:xptemplateData )
        call XPMsetBufSortFunction( function( 'XPTmarkCompare' ) )
        call s:XPTinit()
    endif
    return b:xptemplateData
endfunction 
fun! s:RedefinePattern() 
    let xp = b:xptemplateData.snipFileScope.ptn
    let nonEscaped = s:nonEscaped
    let xp.lft = nonEscaped . xp.l
    let xp.rt  = nonEscaped . xp.r
    let xp.lft_e = nonEscaped. '\\'.xp.l
    let xp.rt_e  = nonEscaped. '\\'.xp.r
    let xp.item_var          = '$\w\+'
    let xp.item_qvar         = '{$\w\+}'
    let xp.item_func         = '\w\+(\.\*)'
    let xp.item_qfunc        = '{\w\+(\.\*)}'
    let xp.itemContent       = '\_.\{-}'
    let xp.item              = xp.lft . '\%(' . xp.itemContent . '\)' . xp.rt
    let xp.itemMarkLPattern  = '\zs'. xp.lft . '\ze\%(' . xp.itemContent . '\)' . xp.rt
    let xp.itemMarkRPattern  = xp.lft . '\%(' . xp.itemContent . '\)\zs' . xp.rt .'\ze'
    for [k, v] in items(xp)
        if k != "l" && k != "r"
            let xp[k] = '\V' . v
        endif
    endfor
endfunction 
fun! s:PushCtx() 
    let x = g:XPTobject()
    let x.stack += [s:getRenderContext()]
    call s:createRenderContext(x)
endfunction 
fun! s:PopCtx() 
    let x = g:XPTobject()
    let x.renderContext = x.stack[-1]
    call remove(x.stack, -1)
endfunction 
fun! s:GetBackPos() 
    return [line(".") - line("$"), col(".") - len(getline("."))]
endfunction 
fun! s:PushBackPos() 
    call add(g:XPTobject().posStack, s:GetBackPos())
endfunction 
fun! s:PopBackPos() 
    let x = g:XPTobject()
    let bp = x.posStack[-1]
    call remove(x.posStack, -1)
    let l = bp[0] + line("$")
    let p = [l, bp[1] + len(getline(l))]
    call cursor(p)
    return p
endfunction 
fun! s:SynNameStack(l, c) 
    if exists( '*synstack' )
        let ids = synstack(a:l, a:c)
        if empty(ids)
            return []
        endif
        let names = []
        for id in ids
            let names = names + [synIDattr(id, "name")]
        endfor
        return names
    else
        return [synIDattr( synID( a:l, a:c, 0 ), "name" )]
    endif
endfunction 
fun! s:CurSynNameStack() 
    return SynNameStack(line("."), col("."))
endfunction 
fun! s:UpdateFollowingPlaceHoldersWith( contentTyped, option ) 
    let renderContext = s:getRenderContext()
    let useGroupPost = renderContext.phase == 'post' && has_key( a:option, 'post' )
    if useGroupPost
        let groupIndent = a:option.indent
        let groupPost = a:option.post
    else
        let groupPost = a:contentTyped
    endif
    call XPRstartSession()
    let phList = renderContext.item.placeHolders
    try
        for ph in phList
            let filter = ( renderContext.phase == 'post' ? ph.postFilter : ph.ontimeFilter )
            let filter = s:IsFilterEmpty( filter ) ? ph.ontimeFilter : filter
            if !s:IsFilterEmpty( filter )
                let [ filterIndent, filterText ] = s:GetFilterIndentAndText( filter )
                let filtered = s:Eval( filterText, { 'typed' : a:contentTyped } )
                let filtered = s:AdjustIndentAccordingToLine( filtered, filterIndent, XPMpos( ph.mark.start )[0] )
            elseif useGroupPost
                let filterIndent = groupIndent
                let filtered = groupPost
                let filtered = s:AdjustIndentAccordingToLine( filtered, filterIndent, XPMpos( ph.mark.start )[0] )
            else
                let filtered = a:contentTyped
            endif
            call XPreplaceByMarkInternal( ph.mark.start, ph.mark.end, filtered )
        endfor
    catch /.*/
    finally
        call XPRendSession()
    endtry
endfunction 
fun! s:IsFilterEmpty( filter )
    return a:filter !~ '\n.'
endfunction
fun! s:GetFilterIndentAndText( filter ) 
    let filterIndent = matchstr( a:filter, '\s*\ze\n' )
    let filterText = matchstr( a:filter, '\n\zs\_.*' )
    return [ filterIndent, filterText ]
endfunction 
fun! s:Crash(...) 
    let msg = "XPTemplate snippet crashed :" . join( a:000, "\n" ) 
    call XPPend()
    let x = g:XPTobject()
    call s:ClearMap()
    let x.stack = []
    call s:createRenderContext(x)
    call XPMflushWithHistory()
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
    if renderContext.phase == 'uninit'
        call XPMflushWithHistory()
        return 0
    endif
    if !renderContext.processing
        call XPMupdate()
        return 0
    endif
    call s:fixCrCausedIndentProblem()
    let leaderMark = renderContext.leadingPlaceHolder.mark
    let [ start, end ] = [ XPMpos( leaderMark.start ), XPMpos( leaderMark.end ) ]
    if start == [0, 0] || end == [0, 0]
        call s:Crash( 'mark lost :' . string( leaderMark ) )
        return -1
    endif
    call XPMsetLikelyBetween( leaderMark.start, leaderMark.end )
    let rc = XPMupdate()
    let [ start, end ] = [ XPMpos( leaderMark.start ), XPMpos( leaderMark.end ) ]
    let contentTyped = s:TextBetween( start, end )
    if contentTyped ==# renderContext.lastContent
        call XPMupdateStat()
        return 0
    endif
    call s:CallPlugin("beforeUpdate")
    if rc == g:XPM_RET.likely_matched
        let relPos = s:recordRelativePosToMark( [ line( '.' ), col( '.' ) ], renderContext.leadingPlaceHolder.mark.start )
        try
            call s:UpdateFollowingPlaceHoldersWith( contentTyped, {} )
        catch /^XPM:.*/
            return s:Crash( v:exception )
        endtry
        call s:gotoRelativePosToMark( relPos, renderContext.leadingPlaceHolder.mark.start )
    else
    endif
    call s:CallPlugin('afterUpdate')
    let renderContext.lastContent = contentTyped
    let renderContext.lastTotalLine = line( '$' )
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
    let x = g:XPTobject()
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
fun! s:GetContextFT() 
    if exists( 'b:XPTfiletypeDetect' )
        return b:XPTfiletypeDetect()
    elseif &filetype == ''
        return '**'
    else
        return &filetype
    endif
endfunction 
fun! s:GetContextFTObj() 
    let x = XPTbufData()
    return get( x.filetypes, s:GetContextFT(), {} )
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
    let x = g:XPTobject()
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
fun! s:SetIfEmpty( dict, name, value ) 
    if !has_key( a:dict, a:name )
        let a:dict[ a:name ] = a:value
    endif
endfunction 
call <SID>Link('TmplRange GetRangeBetween TextBetween GetStaticRange LeftPos')
com! XPTreload call XPTreload()
com! XPTcrash call <SID>Crash()
fun! String( d, ... )
    let str = string( a:d )
    let str = substitute( str, "\\V'\\%(\\[^']\\|''\\)\\{-}'" . '\s\*:\s\*function\[^)]),\s\*', '', 'g' )
    return str
endfunction
