if exists("g:__XPTEMPLATE_VIM__")
    finish
endif
let g:__XPTEMPLATE_VIM__ = 1
let s:oldcpo = &cpo
set cpo-=< cpo+=B
exe XPT#let_sid
runtime plugin/xptemplate.conf.vim
runtime plugin/debug.vim
runtime plugin/xptemplate.util.vim
runtime plugin/mapstack.vim
runtime plugin/xpreplace.vim
runtime plugin/xpmark.vim
runtime plugin/xpopup.vim
runtime plugin/MapSaver.class.vim
runtime plugin/SettingSwitch.class.vim
runtime plugin/FiletypeScope.class.vim
runtime plugin/FilterValue.class.vim
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
let s:nonEscaped            = '\%(' . '\%(\[^\\]\|\^\)' . '\%(\\\\\)\*' . '\)' . '\@<='
let s:repetitionPattern     = '\w\*...\w\*'
let g:XPTemplateSettingPrototype  = { 
      \    'preValues'        : { 'cursor' : "\n" . '$CURSOR_PH' }, 
      \    'defaultValues'    : {}, 
      \    'ontypeFilters'    : {}, 
      \    'postFilters'      : {}, 
      \    'comeFirst'        : [], 
      \    'comeLast'         : [], 
      \}
fun! g:XPTapplyTemplateSettingDefaultValue( setting ) 
    let s = a:setting
    let s.postQuoter        = get( s,           'postQuoter',   { 'start' : '{{', 'end' : '}}' } )
    let s.preValues.cursor  = get( s.preValues, 'cursor',       '$CURSOR_PH' )
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
let s:priorities = {'all' : 64, 'spec' : 48, 'like' : 32, 'lang' : 16, 'sub' : 8, 'personal' : 0}
let s:priPtn = 'all\|spec\|like\|lang\|sub\|personal\|\d\+'
let g:XPT_RC = {
      \   'ok' : {},
      \   'canceled' : {},
      \   'POST' : {
      \       'unchanged'     : {},
      \       'keepIndent'    : {},
      \   }
      \}
let s:buildingSeqNr = 0
let s:anonymouseIndex = 0
let s:pumCB = {}
fun! s:pumCB.onEmpty(sess) 
    echom "XPT: nothing matched"
    return ""
endfunction 
fun! s:pumCB.onOneMatch(sess) 
  if a:sess.matched == ''
      call feedkeys(eval('"\' . g:xptemplate_key . '"'), 'nt')
      return ''
  else
      return s:DoStart(a:sess)
  endif
endfunction 
let s:ItemPumCB = {}
fun! s:ItemPumCB.onOneMatch(sess) 
    if 0 == s:XPTupdate()
        return s:FinishCurrentAndGotoNextItem( '' )
    else
        return ""
    endif
endfunction 
fun! XPTemplateKeyword(val) 
    let x = b:xptemplateData
    let val = substitute(a:val, '\w', '', 'g')
    let keyFilter = 'v:val !~ ''\V\[' . escape(val, '\]') . ']'' '
    call filter( x.keywordList, keyFilter )
    let x.keywordList += split( val, '\s*' )
    let x.keyword = '\w\|\[' . escape( join( x.keywordList, '' ), '\]' ) . ']'
endfunction 
fun! XPTemplatePriority(...) 
    let x = b:xptemplateData
    let p = a:0 == 0 ? 'lang' : a:1
    let x.snipFileScope.priority = s:ParsePriorityString(p)
endfunction 
fun! XPTemplateMark(sl, sr) 
    let xp = g:XPTobject().snipFileScope.ptn
    let xp.l = a:sl
    let xp.r = a:sr
    call s:RedefinePattern()
endfunction 
fun! XPTmark() 
    let renderContext = s:getRenderContext()
    let xp = renderContext.tmpl.ptn
    return [ xp.l, xp.r ]
endfunction 
fun! g:XPTfuncs() 
    return g:GetSnipFileFtScope().funcs
endfunction 
fun! XPTemplateAlias( name, toWhich, setting ) 
    let xptObj = g:XPTobject()
    let xt = xptObj.filetypes[ g:GetSnipFileFT() ].normalTemplates
    if has_key( xt, a:toWhich )
        let toSnip = xt[ a:toWhich ]
        let xt[a:name] = {
                        \ 'name'        : a:name,
                        \ 'parsed'      : 0, 
                        \ 'ftScope'     : toSnip.ftScope, 
                        \ 'tmpl'        : toSnip.tmpl,
                        \ 'priority'    : toSnip.priority,
                        \ 'setting'     : deepcopy(toSnip.setting),
                        \ 'ptn'         : deepcopy(toSnip.ptn),
                        \ 'wrapped'     : toSnip.wrapped, 
                        \}
        call s:ParseTemplateSetting( xptObj, a:setting )
        call g:xptutil.DeepExtend( xt[ a:name ].setting, a:setting )
    endif
endfunction 
fun! g:GetSnipFileFT() 
    let x = b:xptemplateData
    return x.snipFileScope.filetype
endfunction 
fun! g:GetSnipFileFtScope() 
    let x = b:xptemplateData
    return x.filetypes[ x.snipFileScope.filetype ]
endfunction 
fun! s:GetTempSnipScope( x, ft ) 
    if !has_key( a:x, '__tmp_snip_scope' )
        let sc          = XPTnewSnipScope( '' )
        let sc.priority = 0
        let a:x.__tmp_snip_scope = sc
    endif
    let a:x.__tmp_snip_scope.filetype = '' == a:ft ? 'unknown' : a:ft
    return a:x.__tmp_snip_scope
endfunction 
fun! XPTemplate(name, str_or_ctx, ...) 
    call XPTsnipScopePush()
    let templateSetting = deepcopy(g:XPTemplateSettingPrototype)
    let x = b:xptemplateData
    if a:0 == 0 
        let x.snipFileScope = s:GetTempSnipScope( x, &filetype )
        let snip = a:str_or_ctx
        let setting = {}
    else
        if has_key( a:str_or_ctx, 'filetype' )
            let x.snipFileScope = s:GetTempSnipScope(x, a:str_or_ctx.filetype )
        else
            let x.snipFileScope = s:GetTempSnipScope(x, &filetype )
        endif
        let snip = a:1
        let setting = a:str_or_ctx
    endif
    if x.snipFileScope.filetype == 'unknown' 
                \&& !has_key(x.filetypes, 'unknown')
        call s:LoadSnippetFile( 'unknown/unknown' )
    endif
    if !has_key( x.filetypes, x.snipFileScope.filetype )
        return
    endif
    call XPTdefineSnippet( a:name, setting, snip )
    call XPTsnipScopePop()
endfunction 
fun! XPTdefineSnippet( name, setting, snip ) 
    let x         = b:xptemplateData
    let ftScope   = x.filetypes[ x.snipFileScope.filetype ]
    let templates = ftScope.normalTemplates
    let xp        = x.snipFileScope.ptn
    let templateSetting = deepcopy(g:XPTemplateSettingPrototype)
    call extend( templateSetting, a:setting, 'force' )
    call g:XPTapplyTemplateSettingDefaultValue( templateSetting )
    let prio =  has_key(templateSetting, 'priority')
                \ ? s:ParsePriorityString(templateSetting.priority)
                \ : x.snipFileScope.priority
    if has_key(templates, a:name) 
                \&& templates[a:name].priority <= prio
        return
    endif
    if type(a:snip) == type([])
        let snip = join(a:snip, "\n")
    else
        let snip = a:snip
    endif
    let isWrapped =  snip =~ ( '\V' . xp.lft . 'wrapped' . xp.rt )
    let templates[a:name] = {
                \ 'name'        : a:name,
                \ 'parsed'      : 0, 
                \ 'ftScope'     : ftScope, 
                \ 'tmpl'        : snip,
                \ 'priority'    : prio,
                \ 'setting'     : templateSetting,
                \ 'ptn'         : deepcopy(g:XPTobject().snipFileScope.ptn),
                \ 'wrapped'     : isWrapped, 
                \}
    call s:InitTemplateObject( x, templates[ a:name ] )
endfunction 
fun! s:InitTemplateObject( xptObj, tmplObj ) 
    call s:ParseTemplateSetting( a:xptObj, a:tmplObj.setting )
    call s:AddCursorToComeLast(a:tmplObj.setting)
    call s:initItemOrderDict( a:tmplObj.setting )
    if !has_key( a:tmplObj.setting.defaultValues, 'cursor' )
                \ || a:tmplObj.setting.defaultValues.cursor !~ 'Finish'
        let a:tmplObj.setting.defaultValues.cursor = "\n" . 'Finish()'
    endif
    if len( a:tmplObj.name ) == 1
          \ && 0 " diabled 
    else
        let nonWordChar = substitute( a:tmplObj.name, '\w', '', 'g' ) 
        if nonWordChar != '' && !a:tmplObj.wrapped
            call XPTemplateKeyword( nonWordChar )
        endif
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
    let a:tmplObject.tmpl = s:DoIncludeToSnip( a:tmplDict, a:tmplObject, a:tmplObject.tmpl, a:pattern )
endfunction 
fun! s:DoIncludeToXSET( tmplDict, tmplObject, dict, pattern ) 
    for [ key, val ] in items( a:dict )
        let a:dict[ key ] = s:DoIncludeToSnip( a:tmplDict, a:tmplObject, val, a:pattern )
    endfor
endfunction 
fun! s:DoIncludeToSnip( tmplDict, tmplObject, snip, pattern ) 
    let snip = "\n" . a:snip
    let included = { a:tmplObject.name : 1 }
    let pos = 0
    while 1
        let pos = match( snip, a:pattern.line, pos )
        if -1 == pos
            break
        endif
        let [ matching, indent, incName ] = matchlist( snip, a:pattern.line, pos )[ : 2 ]
        let indent = matchstr( split( matching, '\n' )[ -1 ], '^\s*' )
        if has_key( a:tmplDict, incName )
            if has_key( included, incName ) && included[ incName ] > 20
                throw "XPT : include too many snippet:" . incName . ' in ' . a:tmplObject.name
            endif
            let included[ incName ] = get( included, incName, 0 ) + 1
            let ph = matchstr( matching, a:pattern.ph )
            let incTmplObject = a:tmplDict[ incName ]
            call s:MergeSetting( a:tmplObject, incTmplObject )
            let incSnip = substitute( incTmplObject.tmpl, '\n', '&' . indent, 'g' )
            let leftEnd    = pos + len( matching ) - len( ph )
            let rightStart = pos + len( matching )
            let left  = snip[ : leftEnd - 1 ]
            let right = snip[ rightStart : ]
            let snip = left . incSnip . right
        else
            throw "XPT : include inexistent snippet:" . incName . ' in ' . a:tmplObject.name
        endif
    endwhile
    return snip[1:]
endfunction 
fun! s:MergeSetting( tmplObject, incTmplObject ) 
    let a:tmplObject.setting.comeFirst += a:incTmplObject.setting.comeFirst
    let a:tmplObject.setting.comeLast += a:incTmplObject.setting.comeLast
    call s:initItemOrderDict( a:tmplObject.setting )
    call extend( a:tmplObject.setting.preValues, a:incTmplObject.setting.preValues, 'keep' )
    call extend( a:tmplObject.setting.defaultValues, a:incTmplObject.setting.defaultValues, 'keep' )
    call extend( a:tmplObject.setting.postFilters, a:incTmplObject.setting.postFilters, 'keep' )
endfunction 
fun! s:ParseTemplateSetting( xptObj, setting ) 
    let setting = a:setting
    if has_key(setting, 'hint')
        let setting.hint = s:Eval( setting.hint )
    endif
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
fun! s:AddCursorToComeLast(setting) 
    let comeLast = copy( a:setting.comeLast )
    let cursorItem = filter( comeLast, 'v:val == "cursor"' )
    if cursorItem == []
        call add( a:setting.comeLast, 'cursor' )
    endif
endfunction 
fun! s:initItemOrderDict( setting ) 
    let setting = a:setting
    let setting.comeFirst = g:xptutil.RemoveDuplicate( a:setting.comeFirst )
    let setting.comeLast  = g:xptutil.RemoveDuplicate( a:setting.comeLast )
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
    call s:GetContextFTObj() " force initializing
    return copy( XPTbufData().filetypes[ &filetype ].normalTemplates )
endfunction 
fun! XPTemplatePreWrap(wrap) 
    let x = b:xptemplateData
    let x.wrap = a:wrap
    let sts = &l:softtabstop
    let ts  = &l:tabstop
    let usingTab = !&l:expandtab
    if 0 == sts 
        let sts = ts
    endif
    let tabspaces = repeat( ' ', ts )
    let x.wrap = substitute( x.wrap, '\n$', '', '' )
    let x.wrap = "\n" . x.wrap
    let last = '-'
    while x.wrap != last
        let last = x.wrap
        let x.wrap = substitute( x.wrap, '\n	*\zs	', tabspaces, 'g' )
    endwhile
    let x.wrap = x.wrap[ 1: ]
    if ( g:xptemplate_strip_left || x.wrap =~ '\n' ) && visualmode() ==# 'V'
        let x.wrapStartPos = virtcol(".")
        let indent = matchstr( x.wrap, '^\s*' )
        let x.wrap = x.wrap[ len( indent ) : ]
        let indent = substitute( indent, '	', tabspaces, 'g' )
        let x.wrap = 'Echo(' . string( x.wrap ) . ')'
        let x.wrap = s:BuildFilterIndent( x.wrap, len( indent ) )
    else
        let x.wrapStartPos = col(".")
        let indentNr = min( [ indent( line( "." ) ), virtcol('.') - 1 ] )
        let x.wrap = 'Echo(' . string( x.wrap ) . ')'
        let x.wrap = s:BuildFilterIndent( x.wrap, indentNr )
    endif
    if getline( line( "." ) ) =~ '^\s*$'
        let x.wrapStartPos = virtcol( '.' )
        normal! d0
        let leftSpaces = repeat( ' ', x.wrapStartPos - 1 )
    else
        let leftSpaces = ''
    endif
    return leftSpaces . "\<C-r>=XPTemplateDoWrap()\<cr>"
endfunction 
fun! XPTemplateDoWrap() 
    let x = b:xptemplateData
    let ppr = s:Popup("", x.wrapStartPos, {})
    return ppr
endfunction 
fun! XPTemplateStart(pos_unused_any_more, ...) 
    let x = b:xptemplateData
    let opt = a:0 == 1 ? a:1 : {}
    if has_key( opt, 'tmplName' )  
        let startColumn = opt.startPos[1]
        let templateName = opt.tmplName
        call cursor(opt.startPos)
        return  s:DoStart( {
                    \'line' : opt.startPos[0], 
                    \'col' : startColumn, 
                    \'matched' : templateName, 
                    \'data' : { 'ftScope' : s:GetContextFTObj() } } )
    else
        let cursorColumn = col(".")
        let startLineNr = line(".")
        let accEmp = 0
        if g:xptemplate_key ==? '<Tab>'
            let accEmp = 1
        endif
        if has_key( opt, 'popupOnly' ) 
            let startColumn = cursorColumn
        elseif x.wrapStartPos
            let startColumn = x.wrapStartPos
        else
            let lineToCursor = getline( startLineNr )[ 0 : col( "." ) - 2 ]
            let matched = matchstr( lineToCursor, '\V\%('. x.keyword . '\)\+\$' )
            let startColumn = col( "." ) - len( matched )
            if matched == ''
                let [startLineNr, startColumn] = [line("."), col(".")]
            endif
        endif
        let templateName = strpart( getline(startLineNr), startColumn - 1, cursorColumn - startColumn )
    endif
    return s:Popup( templateName, startColumn, {'acceptEmpty' : accEmp} )
endfunction 
fun! s:ParsePriorityString(s) 
    let x = b:xptemplateData
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
    let x = b:xptemplateData
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
    call s:CallPlugin( 'render', 'after' )
    if empty(x.stack)
        call s:ApplyMap()
    endif
    let x.wrap = ''
    let x.wrapStartPos = 0
    let action =  s:GotoNextItem()
    call s:CallPlugin( 'start', 'after' )
    return action
endfunction 
fun! s:FinishRendering(...) 
    let x = b:xptemplateData
    let renderContext = s:getRenderContext()
    let xp = renderContext.tmpl.ptn
    call XPMremoveMarkStartWith( renderContext.markNamePre )
    if empty(x.stack)
        let renderContext.processing = 0
        let renderContext.phase = 'finished'
        call s:ClearMap()
        call XPMflushWithHistory()
        let @" = x.savedReg
        call s:CallPlugin( 'finishAll', 'after' )
        return '' 
    else
        call s:PopCtx()
        call s:CallPlugin( 'finishSnippet', 'after' )
        let renderContext = s:getRenderContext()
        let behavior = renderContext.item.behavior
        if has_key( behavior, 'gotoNextAtOnce' ) && behavior.gotoNextAtOnce
            return s:GotoNextItem()
        else
            return ''
        endif
    endif
endfunction 
fun! s:Popup(pref, coln, opt) 
    let x = b:xptemplateData
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
    let pumsess = XPPopupNew(s:pumCB, { 'ftScope' : ftScope }, cmpl)
    call pumsess.SetAcceptEmpty(get(a:opt, 'acceptEmpty', 0))
    return pumsess.popup(a:coln, {})
endfunction 
fun! s:ApplyTmplIndent( templateObject, startPos ) 
    let tmpl = a:templateObject.tmpl
    let baseIndent = repeat(" ", indent(a:startPos[0]))
    return substitute(tmpl, '\n', '&' . baseIndent, 'g')
endfunction 
fun! s:ParseRepetition(str, tmplObject) 
    let tmplObj = a:tmplObject
    let xp = a:tmplObject.ptn
    let tmpl = a:str
    let bef = ""
    let rest = ""
    let rp = xp.lft . s:repetitionPattern . xp.rt
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
fun! s:ParseQuotedPostFilter( tmplObj ) 
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
    let x = b:xptemplateData
    let ctx = s:getRenderContext()
    let xp = s:getRenderContext().tmpl.ptn
    let ctx.phase = 'rendering'
    if !ctx.tmpl.parsed
        if ctx.tmpl.wrapped
            call s:ParseInclusion( ctx.ftScope.normalTemplates, ctx.tmpl )
        else
            call s:ParseInclusion( ctx.ftScope.normalTemplates, ctx.tmpl )
        endif
        let ctx.tmpl.tmpl = s:ParseQuotedPostFilter( ctx.tmpl )
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
    if 0 > s:BuildPlaceHolders( ctx.marks.tmpl )
        return s:Crash()
    endif
    let ctx = empty( x.stack ) ? x.renderContext : x.stack[0]
    let rg = XPMposList( ctx.marks.tmpl.start, ctx.marks.tmpl.end )
    exe 'silent! ' . rg[0][0] . ',' . rg[1][0] . 'foldopen!'
endfunction 
fun! s:GetNameInfo(end) 
    let x = b:xptemplateData
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
    let x = b:xptemplateData
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
    let leftEdge  = s:TextBetween( a:nameInfo[ 0 : 1 ] )
    let name      = s:TextBetween( a:nameInfo[ 1 : 2 ] )
    let rightEdge = s:TextBetween( a:nameInfo[ 2 : 3 ] )
    let [ leftEdge, name, rightEdge ] = [ leftEdge[1 : ], name[1 : ], rightEdge[1 : ] ]
    let fullname  = leftEdge . name . rightEdge
    if name =~ '\V' . xp.item_var . '\|' . xp.item_func
        return { 'value' : fullname }
    endif
    let incPattern = '\V\^:\zs\.\*\ze:\$\|\^Include:\zs\.\*\$'
    if name =~ incPattern
        return { 'include' : matchstr( name, incPattern ) }
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
        let val = s:TextBetween( a:valueInfo[ 0 : 1 ] )
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
fun! s:BuildMarksOfPlaceHolder(ctx, item, placeHolder, nameInfo, valueInfo) 
    let [ctx, item, placeHolder, nameInfo, valueInfo] = 
                \ [a:ctx, a:item, a:placeHolder, a:nameInfo, a:valueInfo]
    if item.name == ''
        let markName =  '``' . s:anonymouseIndex
        let s:anonymouseIndex += 1
    else
        let markName =  item.name . s:buildingSeqNr . '`' . ( placeHolder.isKey ? 'k' : (len(item.placeHolders)-1) )
    endif
    let markPre = ctx.markNamePre . markName . '`'
    call extend( placeHolder, {
                \ 'mark'     : {
                \       'start' : markPre . 'os', 
                \       'end'   : markPre . 'oe', 
                \   }, 
                \}, 'force' )
    if placeHolder.isKey
        call extend( placeHolder, {
                    \     'editMark'  : {
                    \           'start' : markPre . 'is', 
                    \           'end'   : markPre . 'ie', 
                    \       }, 
                    \}, 'force' )
        let placeHolder.innerMarks = placeHolder.editMark
    else
        let placeHolder.innerMarks = placeHolder.mark
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
fun! s:AddItemToRenderContext( ctx, item ) 
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
    let rc = 0
    let renderContext = s:getRenderContext()
    let tmplObj = renderContext.tmpl
    let xp = renderContext.tmpl.ptn
    let renderContext.action = 'build'
    if renderContext.firstList == []
        let renderContext.firstList = copy(renderContext.tmpl.setting.firstListSkeleton)
    endif
    if renderContext.lastList == []
        let renderContext.lastList = copy(renderContext.tmpl.setting.lastListSkeleton)
    endif
    let renderContext.buildingMarkRange = copy( a:markRange )
    call XPMgoto( a:markRange.start )
    let i = 0
    while i < 10000
        let i += 1
        let markPos = s:NextLeftMark( a:markRange )
        let end = XPMpos( a:markRange.end )
        let nEnd = end[0] * 10000 + end[1]
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
        let rc = 1
        if has_key( placeHolder, 'include' )
            call s:ApplyBuildTimeInclusion( placeHolder, nameInfo, valueInfo )
            call cursor( nameInfo[0] )
        elseif has_key( placeHolder, 'value' )
            call s:ApplyInstantValue( placeHolder, nameInfo, valueInfo )
        else
            let item = s:BuildItemForPlaceHolder( renderContext, placeHolder )
            call s:BuildMarksOfPlaceHolder( renderContext, item, placeHolder, nameInfo, valueInfo )
            call s:EvaluateEdge( xp, item, placeHolder )
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
    return rc
endfunction 
fun! s:NextLeftMark( markRange ) 
    let renderContext = s:getRenderContext()
    let xp = renderContext.tmpl.ptn
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
            break
        endif
        call cursor( [ markPos[0], markPos[1] + len( newEsc ) + 1 ] )
    endwhile
    return markPos
endfunction 
fun! s:EvaluateEdge( xp, item, ph ) 
    if !a:ph.isKey
        return
    endif
    if a:ph.leftEdge =~ '\V' . a:xp.item_var . '\|' . a:xp.item_func
        let ledge = s:Eval( a:ph.leftEdge )
        call XPRstartSession()
        try
            call XPreplaceByMarkInternal( a:ph.mark.start, a:ph.editMark.start, ledge )
        finally
            call XPRendSession()
        endtry
        let a:ph.leftEdge = ledge
        let a:ph.fullname   = a:ph.leftEdge . a:item.name . a:ph.rightEdge
        let a:item.fullname = a:ph.fullname
    endif
    if a:ph.rightEdge =~ '\V' . a:xp.item_var . '\|' . a:xp.item_func
        let redge = s:Eval( a:ph.rightEdge )
        call XPRstartSession()
        try
            call XPreplaceByMarkInternal( a:ph.editMark.end, a:ph.mark.end, redge )
        finally
            call XPRendSession()
        endtry
        let a:ph.rightEdge = redge
        let a:ph.fullname   = a:ph.leftEdge . a:item.name . a:ph.rightEdge
        let a:item.fullname = a:ph.fullname
    endif
endfunction 
fun! s:ApplyBuildTimeInclusion( placeHolder, nameInfo, valueInfo ) 
    let renderContext = b:xptemplateData.renderContext
    let tmplDict = renderContext.ftScope.normalTemplates
    let placeHolder = a:placeHolder
    let nameInfo    = a:nameInfo
    let valueInfo   = a:valueInfo
    if !has_key( tmplDict, placeHolder.include )
        echom "unknown inclusion :" . placeHolder.include
        return
    endif
    let incTmplObject = tmplDict[ placeHolder.include ]
    let indentSpace = repeat( ' ', indent( nameInfo[0][0] ) )
    call s:MergeSetting( renderContext.tmpl, incTmplObject )
    let incSnip = incTmplObject.tmpl
    let incSnip = substitute( incSnip, '\n', '&' . indentSpace, 'g' )
    let valueInfo[-1][1] += 1
    call XPreplace( nameInfo[0], valueInfo[-1], incSnip )
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
    let setting = tmplObj.setting
    let preValue = a:placeHolder.name == '' ? '' : 
          \ ( has_key( setting.preValues, a:placeHolder.name ) 
          \       ? setting.preValues[ a:placeHolder.name ] 
          \       : '' )
    if s:IsFilterEmpty( preValue ) 
        let preValue = a:placeHolder.ontimeFilter != ''
              \ ? a:placeHolder.ontimeFilter
              \ : has_key( setting.defaultValues, a:placeHolder.name ) 
              \     ? setting.defaultValues[ a:placeHolder.name ] 
              \     : ''
    endif
    if s:IsFilterEmpty( preValue ) 
        return
    endif
    let [ filterIndent, filterText ] = s:GetFilterIndentAndText( preValue )
    let obj = s:Eval( filterText )
    if type( obj ) == type( '' )
        call s:SetPreValue( a:placeHolder, filterIndent, obj )
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
                    \'initValue'    : a:placeHolder.name,
                    \'processed'    : 0,
                    \'placeHolders' : [],
                    \'keyPH'        : s:NullDict,
                    \'behavior'     : {},
                    \}
        call s:AddItemToRenderContext( a:ctx, item )
    endif
    if a:placeHolder.isKey
        let item.keyPH = a:placeHolder
        let item.fullname = a:placeHolder.fullname
    else
        call add( item.placeHolders, a:placeHolder )
    endif
    return item
endfunction 
fun! s:XPTvisual() 
    if &l:slm =~ 'cmd'
        normal! v\<C-g>
    else
        normal! v
    endif
endfunction 
fun! s:CleanupCurrentItem() 
    let renderContext = s:getRenderContext()
    let renderContext.lastFollowingSpace = ''
endfunction 
fun! s:ShipBack() 
    let renderContext = s:getRenderContext()
    if empty( renderContext.history )
        return ''
    endif
    call s:CleanupCurrentItem()
    let his = remove( renderContext.history, -1 )
    call s:PushBackItem()
    let renderContext.item = his.item
    let renderContext.leadingPlaceHolder = his.leadingPlaceHolder
    let leader = renderContext.leadingPlaceHolder
    call XPMsetLikelyBetween( leader.mark.start, leader.mark.end )
    let action = s:SelectCurrent(renderContext)
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
    let item.processed = 1
endfunction 
fun! s:FinishCurrentAndGotoNextItem( action ) 
    if pumvisible()
        return "\<C-y>"
    endif
    let renderContext = s:getRenderContext()
    let marks = renderContext.leadingPlaceHolder.mark
    call s:CleanupCurrentItem()
    let rc = s:XPTupdate()
    if rc == -1
        return ''
    endif
    let name = renderContext.item.name
    if a:action ==# 'clear'
        call XPreplace(XPMpos( marks.start ),XPMpos( marks.end ), '')
    endif
    let [ post, built ] = s:ApplyPostFilter()
    if renderContext.item.name != ''
        let renderContext.namedStep[renderContext.item.name] = post
    endif
    if built || a:action ==# 'clear'
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
    let typed = s:TextBetween( XPMposStartEnd( marks ) )
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
        if snip !=# typed
            if leader.isKey
                call XPMremove( leader.editMark.start )
                call XPMremove( leader.editMark.end )
            endif
            call XPreplace(start, end, snip)
        endif
        if ifToBuild
            call cursor( start )
            let renderContext.firstList = []
            let buildrc = s:BuildPlaceHolders( marks )
            if 0 > buildrc
                return [ s:Crash(), ifToBuild ]
            endif
            let ifToBuild = 0 < buildrc
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
        let leftMostIndentNr = XPT#getIndentNr( pos[0], pos[1] )
        if pos[1] - 1 < leftMostIndentNr
            let leftMostIndentNr = pos[1] - 1
        endif
        if pos[0] == a:lineNr && leftMostIndentNr < indent
            let indent = leftMostIndentNr
        endif
    endif
    let indentspaces = repeat(' ', indent)
    if len( indentspaces ) >= len( a:indent )
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
    let leaderMark = leader.innerMarks
    call XPMsetLikelyBetween( leaderMark.start, leaderMark.end )
    if renderContext.item.processed
        let renderContext.phase = 'fillin'
        let action = s:SelectCurrent(renderContext)
        call XPMupdateStat()
        return action
    endif
    let currentItem = renderContext.item
    let renderContext.item.initValue = s:TextBetween( XPMposStartEnd( leaderMark ) )
    let postaction = s:InitItem()
    if currentItem == renderContext.item
        let renderContext.item.initValue = s:TextBetween( XPMposStartEnd( leaderMark ) )
    endif
    let renderContext = s:getRenderContext()
    let leader =  renderContext.leadingPlaceHolder
    if renderContext.processing
          \ && empty( renderContext.itemList )
          \ && !has_key( renderContext.tmpl.setting.postFilters, renderContext.item.name )
          \ && leader.postFilter == ''
          \ && empty( renderContext.item.placeHolders )
          \ && XPMpos( leader.mark.end ) == XPMpos( renderContext.marks.tmpl.end )
          \ && postaction !~ ''
        call s:FinishRendering()
        return postaction
    endif
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
        elseif a:act.action ==# 'next' || a:act.action ==# 'remove'
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
            if a:act.action ==# 'remove'
                return s:FinishCurrentAndGotoNextItem( 'clear' )
            else
                return s:FinishCurrentAndGotoNextItem( '' )
            endif
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
    if 0 > s:BuildPlaceHolders( marks )
        return s:Crash('building place holder failed')
    endif
    call s:removeCurrentMarks()
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
        if 0 > s:BuildPlaceHolders( marks )
            return s:Crash()
        endif
        return s:GotoNextItem()
    endif
    call s:XPTupdate()
    let action = s:SelectCurrent(ctx)
    call XPMupdateStat()
    return action
endfunction 
fun! s:ApplyDefaultValueToPH( renderContext, filter ) 
    let renderContext = a:renderContext
    let leader = renderContext.leadingPlaceHolder
    let str = a:filter
    let [ filterIndent, filterText ] = s:GetFilterIndentAndText( str )
    let obj = s:Eval(filterText) 
    if type(obj) == type({})
        let rc = s:HandleDefaultValueAction( renderContext, obj )
        return ( rc is -1 ) ? s:FillinLeadingPlaceHolderAndSelect( renderContext, '' ) : rc
    elseif type(obj) == type([])
        if len(obj) == 0
            return s:FillinLeadingPlaceHolderAndSelect( renderContext, '' )
        endif
        let marks = leader.isKey ? leader.editMark : leader.mark
        let [ start, end ] = XPMposList( marks.start, marks.end )
        if len(obj) == 1
            call XPreplace( start, end, obj[0] )
            return s:FillinLeadingPlaceHolderAndSelect( renderContext, obj[0] )
        endif
        call XPreplace( start, end, '')
        call cursor(start)
        call s:CallPlugin( 'ph_pum', 'before' )
        let pumSess = XPPopupNew(s:ItemPumCB, {}, obj)
        call pumSess.SetAcceptEmpty(g:xptemplate_ph_pum_accept_empty)
        return pumSess.popup(col("."), { 'doCallback' : 1, 'enlarge' : 0 } )
    else 
        let filterText = obj
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
        let action = s:SelectCurrent(renderContext)
        call XPMupdateStat()
        return action
    endif
endfunction 
fun! s:SelectCurrent( renderContext ) 
    let ph = a:renderContext.leadingPlaceHolder
    let marks = ph.isKey ? ph.editMark : ph.mark
    let [ ctl, cbr ] = [ XPMpos( marks.start ), XPMpos( marks.end ) ]
    if ctl == cbr 
        call cursor( ctl )
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
        return "\<esc>gv\<C-g>"
    endif
endfunction 
fun! s:CreateStringMask( str ) 
    if a:str == ''
        return ''
    endif
    if has_key( b:_xpeval.strMaskCache, a:str )
        return b:_xpeval.strMaskCache[ a:str ]
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
    let b:_xpeval.strMaskCache[ a:str ] = mask
    return mask
endfunction 
fun! s:Eval(str, ...) 
    if a:str == ''
        return ''
    endif
    let expr = get( b:_xpeval.evalCache, a:str, '' )
    let x = b:xptemplateData
    let ctx = x.renderContext
    let xfunc = ctx.phase == 'uninit'
                \ ? x.filetypes[ x.snipFileScope.filetype ].funcs
                \ : ctx.ftScope.funcs
    let xfunc._ctx = ctx
    let typed = a:0 == 1 ? get(a:1, 'typed', '') : ''
    let ctx.evalCtx.value = ctx.processing ? typed : ''
    if '' == expr
        let expr = s:CompileExpr(a:str, xfunc)
        let b:_xpeval.evalCache[a:str] = expr
    endif
    try
        return eval(expr)
    catch /.*/
        call s:log.Warn(expr . "\n" . v:exception)
        return ''
    endtry
endfunction 
fun! s:CompileExpr(s, xfunc) 
    let nonEscaped =   '\%(' . '\%(\[^\\]\|\^\)' . '\%(\\\\\)\*' . '\)' . '\@<='
    let fptn = '\V' . '\w\+(\[^($]\{-})' . '\|' . nonEscaped . '{\w\+(\[^($]\{-})}'
    let vptn = '\V' . nonEscaped . '$\w\+' . '\|' . nonEscaped . '{$\w\+}'
    let sptn = '\V' . nonEscaped . '(\[^($]\{-})'
    let patternVarOrFunc = fptn . '\|' . vptn . '\|' . sptn
    if a:s !~  '\V\w(\|$\w'
        return string(g:xptutil.UnescapeChar(a:s, '{$( '))
    endif
    let stringMask = s:CreateStringMask( a:s )
    if stringMask !~ patternVarOrFunc
        return string(g:xptutil.UnescapeChar(a:s, '{$( '))
    endif
    let str = a:s
    let evalMask = repeat('-', len(stringMask))
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
        if matched[0:0] == '(' && matched[-1:-1] == ')'
            let contextedMatchedLen = len(matched)
            let spaces = repeat(' ', contextedMatchedLen)
            let stringMask = (matchedIndex == 0 ? "" : stringMask[:matchedIndex-1]) 
                        \ . spaces
                        \ . stringMask[matchedIndex + matchedLen :]
            continue
        elseif matched[-1:] == ')' && has_key(a:xfunc, matchstr(matched, '^\w\+'))
            let matched = "xfunc." . matched
        elseif matched[0:0] == '$' && has_key(a:xfunc, matched)
            let matched = 'xfunc["' . matched . '"]'
        endif
        let contextedMatchedLen = len(matched)
        let spaces = repeat(' ', contextedMatchedLen)
        let evalMask = (matchedIndex == 0 ? "" : evalMask[:matchedIndex-1]) 
                    \ . '+' . spaces[1:]
                    \ . evalMask[matchedIndex + matchedLen :]
        let stringMask = (matchedIndex == 0 ? "" : stringMask[:matchedIndex-1]) 
                    \ . spaces
                    \ . stringMask[matchedIndex + matchedLen :]
        let str  = (matchedIndex == 0 ? "" :  str[:matchedIndex-1])
                    \ . matched
                    \ . str[matchedIndex + matchedLen :]
    endwhile
    let idx = 0
    let expr = "''"
    while 1
        let matches = matchlist( evalMask, '\V\(-\*\)\(+ \*\)\?', idx )
        if '' == matches[0]
            break
        endif
        if '' != matches[1]
            let part = str[ idx : idx + len(matches[1]) - 1 ]
            let part = g:xptutil.UnescapeChar(part, '{$( ')
            let expr .= '.' . string(part)
        endif
        if '' != matches[2]
            let expr .= '.' . str[ idx + len(matches[1]) : idx + len(matches[0]) - 1 ]
        endif
        let idx += len(matches[0])
    endwhile
    let expr = matchstr(expr, "\\V\\^''.\\zs\\.\\*")
    return expr
endfunction 
fun! s:TextBetween( posList ) 
    let [ p1, p2 ] = a:posList
    if p1[0] > p2[0]
        return ""
    endif
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
fun! s:Goback() 
    let renderContext = s:getRenderContext()
    return s:SelectCurrent(renderContext)
endfunction 
fun! s:XPTinitMapping() 
    let disabledKeys = [
        \ 's_[%', 
        \ 's_]%', 
        \]
    let literalKeys = [
        \ 's_%', 
        \ 's_''', 
        \ 's_"', 
        \ 's_(', 
        \ 's_)', 
        \ 's_{', 
        \ 's_}', 
        \ 's_[', 
        \ 's_]', 
        \
        \ 's_g', 
        \ 's_m', 
        \ 's_a', 
        \]
    if g:xptemplate_brace_complete
        let literalKeys += [
            \ 'i_''', 
            \ 'i_"', 
            \ 'i_[', 
            \ 'i_(', 
            \ 'i_{', 
            \ 'i_]', 
            \ 'i_)', 
            \ 'i_}', 
            \ 'i_<BS>', 
            \ 'i_<C-h>', 
            \ 'i_<DEL>', 
            \]
    endif
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
        \
        \ 'n_' . g:xptemplate_goback, 
        \ 'i_' . g:xptemplate_goback, 
        \
        \ 's_<DEL>', 
        \ 's_<BS>', 
        \)
    let b:mapLiteral = g:MapSaver.New( 1 )
    call b:mapLiteral.AddList( literalKeys )
    let b:mapMask = g:MapSaver.New( 0 )
    call b:mapMask.AddList( disabledKeys )
    let b:xptemplateData.settingSwitch = g:SettingSwitch.New()
    call b:xptemplateData.settingSwitch.AddList(
          \[ '&l:textwidth', '0' ], 
          \)
endfunction 
fun! s:ApplyMap() 
    let x = b:xptemplateData
    call b:xptemplateData.settingSwitch.Switch()
    call b:mapSaver.Save()
    call b:mapLiteral.Save()
    call b:mapMask.Save()
    call b:mapSaver.UnmapAll()
    call b:mapLiteral.Literalize( { 'insertAsSelect' : 1 } )
    call b:mapMask.UnmapAll()
    exe 'inoremap <silent> <buffer> '.g:xptemplate_nav_prev  .' <C-r>=<SID>ShipBack()<cr>'
    exe 'snoremap <silent> <buffer> '.g:xptemplate_nav_prev  .' <Esc>`>a<C-r>=<SID>ShipBack()<cr>'
    exe 'inoremap <silent> <buffer> '.g:xptemplate_nav_next  .' <C-r>=<SID>FinishCurrentAndGotoNextItem("")<cr>'
    exe 'snoremap <silent> <buffer> '.g:xptemplate_nav_next  .' <Esc>`>a<C-r>=<SID>FinishCurrentAndGotoNextItem("")<cr>'
    exe 'snoremap <silent> <buffer> '.g:xptemplate_nav_cancel.' <Esc>i<C-r>=<SID>FinishCurrentAndGotoNextItem("clear")<cr>'
    exe 'nnoremap <silent> <buffer> '.g:xptemplate_goback . ' i<C-r>=<SID>Goback()<cr>'
    exe 'inoremap <silent> <buffer> '.g:xptemplate_goback . '  <C-r>=<SID>Goback()<cr>'
    snoremap <silent> <buffer> <Del> <Del>i
    snoremap <silent> <buffer> <BS> d<BS>
    if &selection == 'inclusive'
        exe "snoremap <silent> <buffer> ".g:xptemplate_to_right." <esc>`>a"
    else
        exe "snoremap <silent> <buffer> ".g:xptemplate_to_right." <esc>`>i"
    endif
endfunction 
fun! s:ClearMap() 
    call b:xptemplateData.settingSwitch.Restore()
    call b:mapMask.Restore()
    call b:mapLiteral.Restore()
    call b:mapSaver.Restore()
endfunction 
fun! XPTbufData() 
    if !exists("b:xptemplateData")
        call XPTemplateInit()
    endif
    return b:xptemplateData
endfunction 
let s:snipScopePrototype = {
      \'filename' : '', 
      \'ptn'      : {'l':'`', 'r':'^'},
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
    let x = b:xptemplateData
    let x.snipFileScopeStack += [x.snipFileScope]
    unlet x.snipFileScope
endfunction
fun! XPTsnipScopePop()
    let x = b:xptemplateData
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
    let a:x.renderContext.markNamePre = "X" . len( a:x.stack ) . '_'
    let a:x.renderContext.marks.tmpl = { 
                \ 'start' : a:x.renderContext.markNamePre . '`tmpl`s', 
                \ 'end'   : a:x.renderContext.markNamePre . '`tmpl`e', }
    return a:x.renderContext
endfunction 
fun! s:getRenderContext(...) 
    let x = a:0 == 1 ? a:1 : s:XPTobject()
    return x.renderContext
endfunction 
fun! g:XPTobject() 
    if !exists("b:xptemplateData")
        call XPTemplateInit()
    endif
    return b:xptemplateData
endfunction 
fun! s:XPTobject() 
    if !exists("b:xptemplateData")
        call XPTemplateInit()
    endif
    return b:xptemplateData
endfunction 
fun! XPTemplateInit() 
    let b:xptemplateData = {
                \   'filetypes'         : {}, 
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
    call s:XPTinitMapping()
    let b:_xpeval = { 'strMaskCache' : {}, 'evalCache' : {} }
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
    if a:filter =~ '\n'
        let filterIndent = matchstr( a:filter, '\s*\ze\n' )
        let filterText = matchstr( a:filter, '\n\zs\_.*' )
    else
        return ['', a:filter]
    endif
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
    call s:CallPlugin( 'finishAll', 'after' )
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
fun! s:XPTupdateTyping() 
    let rc = s:XPTupdate()
    if rc != 0
        return rc
    endif
    let renderContext = b:xptemplateData.renderContext
    if 'fillin' != renderContext.phase
        return rc
    endif
    let leader = renderContext.leadingPlaceHolder
    let ontypeFilters = renderContext.tmpl.setting.ontypeFilters
    let filter = get( ontypeFilters, leader.name, '' )
    if s:IsFilterEmpty( filter )
        return rc
    endif
    call s:HandleOntypeFilter( filter )
    return rc
endfunction 
fun! s:HandleOntypeFilter( filter ) 
    let renderContext = b:xptemplateData.renderContext
    let leader = renderContext.leadingPlaceHolder
    let contentTyped = s:TextBetween( XPMposStartEnd( leader.mark ) )
    let [ filterIndent, filterText ] = s:GetFilterIndentAndText( a:filter )
    let frst = s:Eval( filterText, { 'typed' : contentTyped } )
    if type( frst ) == type( '' )
        if frst != contentTyped
            call XPreplace( start, end, frst )
            call s:XPTupdate()
        endif
    elseif type( frst ) == type( [] )
    elseif type( frst ) == type( {} )
        if !has_key( frst, 'action' )
            return
        endif
        call s:HandleOntypeAction( frst, filterIndent )
    endif
endfunction 
fun! s:HandleOntypeAction( act, filterIndent ) 
    let filterIndent = a:filterIndent
    let renderContext = b:xptemplateData.renderContext
    let postaction = ''
    if a:act.action == 'next'
        if has_key( a:act, 'text' )
            let text = a:act.text
            if type( text ) == type( '' )
                if text =~ '\V\^\s\*\n'
                    let [ filterIndent, filterText ] = s:GetFilterIndentAndText( text )
                else
                    let [ filterIndent, filterText ] = [ filterIndent, text ]
                endif
            elseif type( text ) == type( {} ) && text.__class__ == g:FilterValue
                let [ filterIndent, filterText ] = [ repeat( ' ', text.nIndent ), text.text ]
            endif
            let leader = renderContext.leadingPlaceHolder
            let marks = leader.mark
            let indentedText = s:AdjustIndentAccordingToLine( filterText, filterIndent, XPMpos( marks.start )[0], leader )
            let [ start, end ] = XPMposList( marks.start, marks.end )
            call XPreplace( start, end, indentedText )
        endif
        let postaction = s:FinishCurrentAndGotoNextItem( '' )
    elseif a:act.action == '' 
    endif
    if '' != postaction
        call feedkeys( postaction, 'n' )
    endif
endfunction 
fun! s:isUpdateCondition( renderContext ) 
    if a:renderContext.phase == 'uninit'
        call XPMflushWithHistory()
        return 0
    endif
    if !a:renderContext.processing
        call XPMupdate()
        return 0
    endif
    return 1
endfunction 
fun! s:UpdateMarksAccordingToLeaderChanges( renderContext ) 
    let leaderMark = a:renderContext.leadingPlaceHolder.mark
    let [ start, end ] = XPMposList( leaderMark.start, leaderMark.end )
    if start[0] == 0 || end[0] == 0
        throw 'XPM:mark_lost:' . string( start[0] == 0 ? leaderMark.start : leaderMark.end )
    endif
    call XPMsetLikelyBetween( leaderMark.start, leaderMark.end )
    let rc = XPMupdate()
    if g:xptemplate_strict == 2
                \&& a:renderContext.phase == 'fillin'
                \&& rc is g:XPM_RET.updated
        throw 'XPT:changes outside of place holder'
    endif
    if g:xptemplate_strict == 1
                \&& a:renderContext.phase == 'fillin'
                \&& rc is g:XPM_RET.updated
        undo
        call XPMupdate()
        echohl WarningMsg
        echom "editing OUTSIDE place holder is not allowed whne g:xptemplate_strict=1, use " . g:xptemplate_goback . " to go back"
        echohl
        return g:XPT_RC.canceled
    endif
    return rc
endfunction 
fun! s:XPTupdate() 
    let renderContext = s:getRenderContext()
    if !s:isUpdateCondition( renderContext )
        return 0
    endif
    call s:fixCrCausedIndentProblem()
    try
        let rc = s:UpdateMarksAccordingToLeaderChanges( renderContext )
        if g:XPT_RC.canceled is rc
            return 0
        endif
        call s:DoUpdate( renderContext, rc )
        return 0
    catch /^XP.*/
        call s:Crash( v:exception )
        return -1
    finally
        call XPMupdateStat()
    endtry
endfunction 
fun! s:DoUpdate( renderContext, changeType ) 
    let renderContext = a:renderContext
    let contentTyped = s:TextBetween( XPMposStartEnd( renderContext.leadingPlaceHolder.mark ) )
    if contentTyped ==# renderContext.lastContent
        return
    endif
    call s:CallPlugin("update", 'before')
    if a:changeType is g:XPM_RET.likely_matched 
          \ || a:changeType is g:XPM_RET.no_updated_made
        let relPos = s:recordRelativePosToMark( [ line( '.' ), col( '.' ) ], renderContext.leadingPlaceHolder.mark.start )
        call s:UpdateFollowingPlaceHoldersWith( contentTyped, {} )
        call s:gotoRelativePosToMark( relPos, renderContext.leadingPlaceHolder.mark.start )
    else
    endif
    call s:CallPlugin('update', 'after')
    let renderContext.lastContent = contentTyped
    let renderContext.lastTotalLine = line( '$' )
endfunction 
fun! s:DoBreakUndo() 
    if pumvisible()
        return "\<UP>\<DOWN>"
    endif
    return "\<C-g>u"
endfunction 
inoremap <Plug>XPTdoBreakUndo <C-r>=<SID>DoBreakUndo()<CR>
fun! s:BreakUndo() 
    if mode() != 'i' || pumvisible()
        return
    endif
    let x = s:XPTobject()
    if x.renderContext.processing
        call feedkeys( "\<Plug>XPTdoBreakUndo", 'm' )
    endif
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
    if !renderContext.processing
        return
    endif
    let leader =  renderContext.leadingPlaceHolder
    let leaderMark = leader.mark
    let [ start, end ] = XPMposList(leaderMark.start, leaderMark.end)
    let pos = line( '.' ) * 10000 + col( '.' )
    let nStart = start[0] * 10000 + start[1]
    let nEnd = end[0] * 10000 + end[1]
    if pos < nStart || pos > nEnd
        return
    endif
    let currentPos = [ line( '.' ), col( '.' ) ]
    let currentFollowingSpace = getline( currentPos[0] )[ currentPos[1] - 1 : ]
    let currentFollowingSpace = matchstr( currentFollowingSpace, '^\s*' )
    let renderContext.lastFollowingSpace = currentFollowingSpace
endfunction 
fun! s:GetContextFT() 
    if exists( 'b:XPTfiletypeDetect' )
        return b:XPTfiletypeDetect()
    elseif &filetype == ''
        return 'unknown'
    else
        return &filetype
    endif
endfunction 
fun! s:GetContextFTObj() 
    let x = XPTbufData()
    let ft = s:GetContextFT()
    if ft == 'unknown' && !has_key(x.filetypes, ft)
        call s:LoadSnippetFile( 'unknown/unknown' )
    elseif !has_key(x.filetypes, ft)
        call XPTsnippetFileInit( '~~/xpt/pseudo/ftplugin/' . ft . '/' . ft . '.xpt.vim' )
        call XPTinclude( '_common/common' )
        call XPTfiletypeInit()
    endif
    let ftScope = get( x.filetypes, ft, {} )
    return ftScope
endfunction 
fun! s:LoadSnippetFile(snip) 
    exe 'runtime! ftplugin/' . a:snip . '.xpt.vim'
    call XPTfiletypeInit()
endfunction 
augroup XPT 
    au!
    au InsertEnter * call <SID>XPTcheck()
    au CursorMovedI * call <SID>XPTupdateTyping()
    au CursorMovedI * call <SID>BreakUndo()
    au CursorMoved * call <SID>XPTtrackFollowingSpace()
augroup END 
fun! g:XPTaddPlugin(event, when, func) 
    if has_key(s:plugins, a:event)
        call add(s:plugins[a:event][a:when], a:func)
    else
        throw "XPT does NOT support event:".a:event
    endif
endfunction 
let s:plugins = {}
fun! s:CreatePluginContainer( ... ) 
    for evt in a:000
        let s:plugins[evt] = { 'before' : [], 'after' : []}
    endfor
endfunction 
call s:CreatePluginContainer(
            \'start', 
            \'render', 
            \'build', 
            \'finishSnippet', 
            \'finishAll', 
            \'preValue', 
            \'defaultValue', 
            \'ph_pum', 
            \'postFilter', 
            \'initItem', 
            \'nextItem', 
            \'prevItem', 
            \'update', 
            \)
delfunc s:CreatePluginContainer
fun! s:CallPlugin(ev, when) 
    let cnt = get(s:plugins, a:ev, {})
    let evs = get(cnt, a:when, [])
    if evs == []
        return
    endif
    let x = s:XPTobject()
    for XPTplug in evs
        call XPTplug(x, x.renderContext)
    endfor
endfunction 
com! XPTreload call XPTreload()
com! XPTcrash call <SID>Crash()
let &cpo = s:oldcpo
