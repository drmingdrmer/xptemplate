" XPTEMPLATE ENGIE:
"   snippet template engine
" BY: drdr.xp | drdr.xp@gmail.com
"
"
" USAGE: "{{{
"   1) vim test.c
"   2) to type:
"     for<C-\>
"     generating a for-loop template:
"     for ( i = 0; i < n; ++i ) {
"       /* cursor */
"     }
"     using <TAB> navigate through
"     template
" "}}}
"
" TODOLIST: "{{{
" TODO bug: in *.css: type: "* {<CR>" prodcues another "* }" at the next line.
" in future
" TODO efficiently loading long snippet file
" TODO lazy load of scripts
" TODO add: be able to load textmate snippet or snipmate snippet.
" TODO add: <BS> at ph start to shift backward.
" TODO add: php snippet <% for .. %> in html
" TODO improve: 3 quotes in python
" TODO fix: register handling when snippet expand
" TODO goto next or trigger?
" TODO fix: after undo, highlight is not cleared.
" TODO with strict = 0/1 XPT does not work well
" TODO add: XSET to set edge.
" TODO add: short snippet syntax
" TODO add: global shortcuts
" TODO add: context detect
" TODO doc of ontype filters, XSET what|map
" TODO cross file support, .h and .cpp skeletion generator.
" TODO bug in 114.74, ' and then <C-n> complete, and then <C-y> accept, now ' is between complete start and complete end
" TODO xpreplace with gp
" TODO crazy test no error guarantee.
" TODO super cancel : clear/default all and finish
" TODO autocomplete doc
" TODO license snippets.
" TODO ocmal snippets
" TODO repopup when ship-back or re-tab to place holder.
" TODO <CR> in insert mode
" TODO 2 <tab> to accept empty
" TODO /../../ ontime filter shortcut
" TODO ( ) shortcut of Echo
" TODO if no template found fall <C-\>/<tab> to other plugins
" TODO import utils
" TODO key map to trigger in template, secondary key
" TODO more key mapping : [si]_<C-h> to go to head, n_<C-g> to go to back to end
" TODO improve context detection
" TODO snippet only inside others
" TODO standardize html/xml snippets.
" TODO snippet-file scope XSET
" TODO block context check
" TODO in windows & in select mode to trigger wrapped or normal?
" TODO to optimize, treat all paste as at end
" TODO change on previous item
" TODO <Plug>mapping
" TODO file listing snippet in _common
" TODO item popup: repopup
" TODO do not let xpt throw error if calling undefined s:f.function..
" TODO simple place holder : just a postion waiting for user input
" TODO wrapping on different visual mode
" TODO simplify if no need to popup, popup session
" TODO simplify wrapper snippets
" TODO match snippet names from middle
" TODO without template rendering, xpmark update complains error.
" TODO 'completefunc' to re-popup item menu. Or using <tab> to force popup showing
"
" "}}}
"
" Log of This version:
"   fix: slowly loading *.xpt.vim
"   fix: mistakely using $SPop in brackets snippet. It should be $SParg
"   fix: bug pre-parsing spaces
"   fix: bug that non-key place holder does not clear  '`' and '^'
"   fix: bug snippet starts with "..." repetition can not be rendered correctly.
"   add: g:xptemplate_highlight_nested
"   add: g:xptemplate_minimal_prefix_nested
"
"   improve: critical: do not update 'k' and 'l' marks of xpmark if no marks defined
"
"
"


if exists( "g:__XPTEMPLATE_VIM__" ) && g:__XPTEMPLATE_VIM__ >= XPT#ver
    finish
endif
let g:__XPTEMPLATE_VIM__ = XPT#ver



let s:oldcpo = &cpo
set cpo-=< cpo+=B


exe XPT#let_sid


runtime plugin/xptemplate.conf.vim
runtime plugin/xpreplace.vim
runtime plugin/xpmark.vim
runtime plugin/xpopup.vim

exec XPT#importConst

let s:log = xpt#debug#Logger( 'warn' )
let s:log = xpt#debug#Logger( 'debug' )

let s:close_pum = "\<C-v>\<C-v>\<BS>"
let s:renderPhase = xpt#rctx#phase

call XPRaddPreJob( 'XPMupdateCursorStat' )
call XPRaddPostJob( 'XPMupdateSpecificChangedRange' )
call XPMsetUpdateStrategy( 'normalMode' )


fun! XPTmarkCompare( o, markToAdd, existedMark ) "{{{
    call s:log.Log( 'compare : ' . a:markToAdd . ' and ' . a:existedMark )
    let renderContext = b:xptemplateData.renderContext

    if renderContext.phase == 'rendering'
        let [ lm, rm ] = [ a:o.changeLikelyBetween.start, a:o.changeLikelyBetween.end ]
        if a:existedMark ==# rm
              " \ || s:IsEndMark( a:existedMark )
            return -1
        endif

    elseif renderContext.action == 'build'
          \ && has_key( renderContext, 'buildingMarkRange' )
          \ && renderContext.buildingMarkRange.end ==  a:existedMark
        call s:log.Debug( a:markToAdd . ' < ' . a:existedMark )
        return -1

    endif

    call s:log.Debug( a:markToAdd . ' > ' . a:existedMark )
    return 1
endfunction "}}}

let s:repetitionPattern     = '\w\*...\w\*'
let s:expandablePattern     = '\V\S\+...\$'
let s:nullDict = {}
let s:nullList = []
let s:nonEscaped =
      \   '\%('
      \ .     '\%(\[^\\]\|\^\)'
      \ .     '\%(\\\\\)\*'
      \ . '\)'
      \ . '\@<='

" TODO move more init values here, comeLast for cursor, default value for cursor
let g:XPTemplateSettingPrototype  = {
      \    'hidden'           : 0,
      \    'variables'        : {},
      \    'preValues'        : { 'cursor' : xpt#flt#New( 0, '$CURSOR_PH' ) },
      \    'defaultValues'    : {},
      \    'mappings'         : {},
      \    'ontypeFilters'    : {},
      \    'postFilters'      : {},
      \    'comeFirst'        : [],
      \    'comeLast'         : [],
      \}


fun! g:XPTapplyTemplateSettingDefaultValue( setting ) "{{{
    let s = a:setting
    let s.postQuoter        = get( s,           'postQuoter',   { 'start' : '{{', 'end' : '}}' } )
    let s.preValues.cursor  = get( s.preValues, 'cursor',       '$CURSOR_PH' )
endfunction "}}}

let g:XPT_RC = {
      \   'ok' : {},
      \   'canceled' : {},
      \}

let s:buildingSeqNr = 0
let s:anonymouseIndex = 0




let s:pumCB = {}

fun! s:pumCB.onEmpty(sess) "{{{
    if g:xptemplate_fallback ==? '<NOP>'
        call XPT#warn( "XPT: No snippet matches" )
        return ''
    else
        let x = b:xptemplateData
        let x.fallbacks = [ [ "\<Plug>XPTfallback", 'feed' ] ] + x.fallbacks
        return XPT#fallback( x.fallbacks )
    endif
endfunction "}}}

fun! s:pumCB.onOneMatch(sess) "{{{
    call s:log.Log( "match one:".a:sess.matched )
    if a:sess.matched == ''
        " empty input accepted

        call feedkeys( eval('"\' . g:xptemplate_key . '"' ), 'nt')
        return ''
    else
        return s:DoStart(a:sess)
    endif
endfunction "}}}


let s:ItemPumCB = {}

fun! s:ItemPumCB.onOneMatch( sess ) "{{{

    " TODO XPTupdateTyping
    if 0 == s:XPTupdate()
        return s:ShiftForward( '' )
    else
        return ""
    endif

endfunction "}}}


fun! s:FallbackKey() "{{{
    call feedkeys( "\<Plug>XPTfallback", 'mt' )
    return ''
endfunction "}}}




" ===================================================
" API
" ===================================================

" which letter can be used in template name other than 'iskeyword'
fun! XPTemplateKeyword(val) "{{{

    let x = b:xptemplateData
    let ftScope   = x.filetypes[ x.snipFileScope.filetype ]
    let ftkeyword = ftScope.ftkeyword

    " word characters are already valid.
    let val = substitute(a:val, '\w', '', 'g')
    let val = string( val )[ 1 : -2 ]
    let needEscape = '^\]-'


    let ftkeyword.list += split( val, '\v\s*' )
    call sort( ftkeyword.list )
    let ftkeyword.list = split( substitute( join( ftkeyword.list, '' ), '\v(.)\1+', '\1', 'g' ), '\v\s*' )


    let ftkeyword.regexp = '\[0-9A-Za-z_' . escape( join( ftkeyword.list, '' ), needEscape ) . ']'

endfunction "}}}

fun! XPTemplatePriority(...) "{{{
    let x = b:xptemplateData
    let p = get( a:000, 0, '' )
    if p == ''
        let p = 'lang'
    endif

    let x.snipFileScope.priority = xpt#priority#Parse(p)
endfunction "}}}

fun! XPTemplateMark(sl, sr) "{{{
    call s:log.Debug( 'XPTemplateMark called with:' . string( [ a:sl, a:sr ] ) )
    let b:xptemplateData.snipFileScope.ptn = xpt#snipfile#GenPattern({'l':a:sl, 'r':a:sr})
endfunction "}}}

fun! XPTmark() "{{{
    let renderContext = b:xptemplateData.renderContext
    let xp = renderContext.snipObject.ptn
    return [ xp.l, xp.r ]
endfunction "}}}

fun! g:XPTfuncs() "{{{
    return g:GetSnipFileFtScope().funcs
endfunction "}}}

fun! XPTemplateAlias( name, toWhich, setting ) "{{{

    let name = a:name

    let xptObj = b:xptemplateData
    let xt = xptObj.filetypes[ g:GetSnipFileFT() ].allTemplates
    let toSnip = get( xt, a:toWhich )

    if toSnip is 0
        return
    endif

    let setting = deepcopy(toSnip.setting)
    call xpt#util#DeepExtend( setting, a:setting )

    let prio = xptObj.snipFileScope.priority

    let existed = get( xt, a:name, { 'priority': xpt#priority#Get( 'lowest' ) } )
    if existed.priority < prio
        return
    endif

    if has_key( xt, a:toWhich )
        let xt[a:name] = {
                        \ 'name'        : a:name,
                        \ 'parsed'      : 0,
                        \ 'ftScope'     : toSnip.ftScope,
                        \ 'snipText'    : toSnip.snipText,
                        \ 'priority'    : prio,
                        \ 'setting'     : setting,
                        \ 'ptn'         : deepcopy(toSnip.ptn),
                        \}
        call s:UpdateNamePrefixDict( toSnip.ftScope, a:name )

        call s:ParseTemplateSetting( xt[ a:name ] )

        if get( xt[ name ].setting, 'abbr', 0 )
            call s:Abbr( name )
        endif
    endif

endfunction "}}}

fun! g:GetSnipFileFT() "{{{
    let x = b:xptemplateData
    return x.snipFileScope.filetype
endfunction "}}}

fun! g:GetSnipFileFtScope() "{{{
    let x = b:xptemplateData
    return x.filetypes[ x.snipFileScope.filetype ]
endfunction "}}}

fun! s:GetTempSnipScope( x, ft ) "{{{
    if !has_key( a:x, '__tmp_snip_scope' )
        let sc = xpt#snipfile#New('')
        let b:xptemplateData.snipFileScope = sc
        let sc.priority = 0

        let a:x.__tmp_snip_scope = sc
    endif

    let a:x.__tmp_snip_scope.filetype = '' == a:ft ? 'unknown' : a:ft

    return a:x.__tmp_snip_scope
endfunction "}}}

" ********* XXX *********
fun! XPTemplate(name, str_or_ctx, ...) " {{{

    " @param String name			tempalte name
    " @param String context			[optional] context syntax name
    " @param String|List|FunCRef str		template string

    " using dictionary member instead of direct variable for type limit

    let x = b:xptemplateData

    " called from outside snippet file
    if a:0 == 0
        let snip = a:str_or_ctx
        let setting = {}
    else
        let snip = a:1
        let setting = a:str_or_ctx
    endif
    let ft = get( setting, 'filetype', &filetype )
    let ft = '' == ft ? 'unknown' : ft

    " special filetype may has not yet initialized by .xpt.vim
    call xpt#parser#loadSpecialFiletype(ft)

    call xpt#snipfile#Push()

    let x.snipFileScope = s:GetTempSnipScope(x, ft )

    call XPTdefineSnippet( a:name, setting, snip )

    call xpt#snipfile#Pop()

endfunction " }}}

fun! XPTdefineSnippet( name, setting, snip ) "{{{

    " TODO global shortcuts
    let name = a:name

    let x         = b:xptemplateData
    let ftScope   = x.filetypes[ x.snipFileScope.filetype ]
    let templates = ftScope.allTemplates
    let xp        = x.snipFileScope.ptn


    let templateSetting = deepcopy(g:XPTemplateSettingPrototype)
    call extend( templateSetting, a:setting, 'force' )
    call g:XPTapplyTemplateSettingDefaultValue( templateSetting )

    let prio = x.snipFileScope.priority


    " Existed template has the same priority is overrided.
    if has_key(templates, a:name)
          \ && templates[a:name].priority < prio
        return
    endif

    call s:UpdateNamePrefixDict( ftScope, a:name )

    if type(a:snip) == type([])
        let snip = join(a:snip, "\n")
    else
        let snip = a:snip
    endif

    call s:log.Log("tmpl :name=".a:name." priority=".prio)
    let templates[ a:name ] = {
                \ 'name'        : a:name,
                \ 'parsed'      : 0,
                \ 'ftScope'     : ftScope,
                \ 'snipText'    : snip,
                \ 'priority'    : prio,
                \ 'setting'     : templateSetting,
                \ 'ptn'         : deepcopy(b:xptemplateData.snipFileScope.ptn),
                \}


    call s:InitTemplateObject( x, templates[ a:name ] )

    if get( templates[ name ].setting, 'abbr', 0 )
        call s:Abbr( name )
    endif

endfunction "}}}

fun! s:UpdateNamePrefixDict( ftScope, name ) "{{{
    if !has_key( a:ftScope, 'namePrefix' )
        let a:ftScope.namePrefix = {}
    endif

    let [ n, pre ] = [ a:name, a:ftScope.namePrefix ]
    while n != '' && !has_key( pre, n )
        let pre[ n ] = 1
        let n = n[ : -2 ]
    endwhile
endfunction "}}}

" TODO parse snippets first
fun! s:Abbr( name ) "{{{
    let name = a:name
    try
        exe 'inoreabbr <silent> <buffer> ' name '<C-v><C-v>' . "<BS>\<C-r>=XPTtgr(" . string( name ) . ",{'k':''})\<CR>"
    catch /.*/
        let n = matchstr( name, '\v\w+$' )
        let pre = name[ : -len( n ) - 1 ]
        let x.abbrPrefix[ n ] = get( x.abbrPrefix, n, {} )
        let x.abbrPrefix[ n ][ pre ] = 1
        exe 'inoreabbr <silent> <buffer> ' n printf( "\<C-r>=XPTabbr(%s)\<CR>", string( n ) )
    endtry
endfunction "}}}

fun! s:InitTemplateObject( xptObj, tmplObj ) "{{{

    " TODO error occured once: no key :"setting )"

    call s:ParseTemplateSetting( a:tmplObj )


    call s:log.Debug( 'create template name=' . a:tmplObj.name . ' snipText=' . a:tmplObj.snipText )

    call s:AddCursorToComeLast(a:tmplObj.setting)
    call s:InitItemOrderList( a:tmplObj.setting )


    if !has_key( a:tmplObj.setting.defaultValues, 'cursor' )
                " \ || a:tmplObj.setting.defaultValues.cursor !~ 'Finish'
        let a:tmplObj.setting.defaultValues.cursor = xpt#flt#New( 0, 'Finish("")' )
    endif

    call s:log.Debug( 'a:tmplObj.setting.defaultValues.cursor=' . string( a:tmplObj.setting.defaultValues.cursor ) )

    if len( a:tmplObj.name ) == 1
          \ && 0 " diabled

    else
        let nonWordChar = substitute( a:tmplObj.name, '\w', '', 'g' )
        if nonWordChar != ''
            if !( a:tmplObj.setting.wraponly || a:tmplObj.setting.hidden )
                call XPTemplateKeyword( nonWordChar )
            endif
        endif
    endif

endfunction "}}}

fun! s:ParseInclusion( tmplDict, tmplObject ) "{{{
    if type( a:tmplObject.snipText ) == type( function( 'tr' ) )
        return
    endif

    let xp = a:tmplObject.ptn

    let phPattern = '\V' . xp.lft . 'Include:\(\.\{-}\)' . xp.rt
    let linePattern = '\V' . '\n\(\s\*\)\.\{-}' . phPattern

    call s:DoInclude( a:tmplDict, a:tmplObject, { 'ph' : phPattern, 'line' : linePattern }, 1 )


    let phPattern = '\V' . xp.lft . ':\(\.\{-}\):' . xp.rt
    let linePattern = '\V' . '\n\(\s\*\)\.\{-}' . phPattern

    call s:DoInclude( a:tmplDict, a:tmplObject, { 'ph' : phPattern, 'line' : linePattern }, 0 )

    call s:log.Debug( a:tmplObject.snipText )

endfunction "}}}

fun! s:DoInclude( tmplDict, tmplObject, pattern, keepCursor ) "{{{

    " make every line started with \n
    let snip = "\n" . a:tmplObject.snipText

    let xp = a:tmplObject.ptn



    let included = { a:tmplObject.name : 1 }
    let pos = 0
    while 1
        let pos = match( snip, a:pattern.line, pos )
        if -1 == pos
            break
        endif

        let [ matching, indent, incName ] = matchlist( snip, a:pattern.line, pos )[ : 2 ]
        let indent = matchstr( split( matching, '\n' )[ -1 ], '^\s*' )

        call s:log.Debug( 'match list result:' . string( matchlist( snip, a:pattern.line, pos ) ) )
        call s:log.Debug( 'inclusion line:' . matching )
        call s:log.Debug( 'indent=' . string( indent ) )

        let [ incName, params ] = s:ParseInclusionStatement( a:tmplObject, incName )

        if has_key( a:tmplDict, incName )
            if has_key( included, incName ) && included[ incName ] > 20
                throw "XPT : include too many snippet:" . incName . ' in ' . a:tmplObject.name
            endif

            let included[ incName ] = get( included, incName, 0 ) + 1


            let ph = matchstr( matching, a:pattern.ph )

            let incTmplObject = a:tmplDict[ incName ]
            call s:ParseSnippet( incTmplObject, incTmplObject.ftScope )
            call s:MergeSetting( a:tmplObject.setting, incTmplObject.setting )

            let incSnip = s:ReplacePHInSubSnip( a:tmplObject, incTmplObject, params )
            let incSnip = substitute( incSnip, '\n', '&' . indent, 'g' )


            " TODO replace this with parameter
            if !a:keepCursor
                " Dumb `cursor^ of included snippet
                let incSnip = substitute( incSnip, xp.lft . 'cursor' . xp.rt, xp.l . xp.r, 'g' )
            endif

            let leftEnd    = pos + len( matching ) - len( ph )
            let rightStart = pos + len( matching )

            let left  = snip[ : leftEnd - 1 ]
            let right = snip[ rightStart : ]

            let snip = left . incSnip . right

            call s:log.Log( 'include ' . incTmplObject.name . ' : ' . snip )


        else
            throw "XPT : include inexistent snippet:" . incName . ' in ' . a:tmplObject.name
        endif

    endwhile

    " remove "\n"
    let a:tmplObject.snipText = snip[1:]

endfunction "}}}

fun! s:ReplacePHInSubSnip( snipObject, subSnipObject, params ) "{{{
    let xp = a:snipObject.ptn
    let incSnip = a:subSnipObject.snipText

    let incSnipPieces = split( incSnip, '\V' . xp.rt, 1 )

    " NOTE: not very strict matching
    for [ k, v ] in items( a:params )

        let [ i, len ] = [ 0 - 1, len( incSnipPieces ) - 1 ]
        while i < len | let i += 1
            let piece = incSnipPieces[ i ]


            if piece =~# '\V' . k
                let parts = split( piece, '\V' . xp.lft, 1 )

                " len of parts : 2 3 4
                " index of name: 1 2 2

                let iName = len( parts ) == 4 ? 2 : len( parts ) - 1


                if parts[ iName ] ==# k
                    let parts[ iName ] = v
                endif

                let incSnipPieces[ i ] = join( parts, xp.l )
            endif

        endwhile

    endfor

    let incSnip = join( incSnipPieces, xp.r )

    return incSnip
endfunction "}}}

fun! s:ParseInclusionStatement( snipObject, st ) "{{{

    let xp = a:snipObject.ptn


    let ptn = '\V\^\[^(]\{-}('
    let st = a:st

    if st =~ ptn && st[ -1 : -1 ] == ')'

        let name = matchstr( st, ptn )[ : -2 ]
        let paramStr = st[ len( name ) + 1 : -2 ]

        call s:log.Debug( 'name=' . string( name ) )
        call s:log.Debug( 'paramStr' . string( paramStr ) )

        let paramStr = xpt#util#UnescapeChar( paramStr, xp.l . xp.r )
        let params = {}
        try
            let params = eval( paramStr )
        catch /.*/
            XPT#warn( 'XPT: Invalid parameter: ' . string( paramStr ) . ' Error=' . v:exception )
        endtry

        call s:log.Debug( 'params=' . string( params ) )

        return [ name, params ]

    else
        return [ st, {} ]
    endif

endfunction "}}}

fun! s:MergeSetting( toSettings, fromSettings ) "{{{
    let a:toSettings.comeFirst += a:fromSettings.comeFirst
    let a:toSettings.comeLast = a:fromSettings.comeLast + a:toSettings.comeLast
    call s:InitItemOrderList( a:toSettings )

    call extend( a:toSettings.preValues, a:fromSettings.preValues, 'keep' )
    call extend( a:toSettings.defaultValues, a:fromSettings.defaultValues, 'keep' )
    call extend( a:toSettings.postFilters, a:fromSettings.postFilters, 'keep' )
    call extend( a:toSettings.variables, a:fromSettings.variables, 'keep' )

    for key in keys( a:fromSettings.mappings )
        if !has_key( a:toSettings.mappings, key )
            let a:toSettings.mappings[ key ] =
                  \ { 'saver' : xpt#msvr#New(1), 'keys' : {} }
        endif
        for keystroke in keys( a:fromSettings.mappings[ key ].keys )
            let a:toSettings.mappings[ key ].keys[ keystroke ] = a:fromSettings.mappings[ key ].keys[ keystroke ]
            call xpt#msvr#Add( a:toSettings.mappings[ key ].saver, 'i', keystroke )
        endfor
    endfor

endfunction "}}}

fun! s:ParseTemplateSetting( tmpl ) "{{{
    let x = b:xptemplateData

    let setting = a:tmpl.setting

    if type( get( setting, 'wraponly', 0 ) ) == type( '' )
        let setting.wrap = setting.wraponly
        let setting.wraponly = 1
    endif

    let setting.iswrap = has_key( setting, 'wrap' )
    let setting.wraponly = get( setting, 'wraponly', 0 )

    if has_key( setting, 'wrap' ) && setting.wrap is 1
        let setting.wrap = 'cursor'
    endif


    " TODO bad code
    let x.renderContext.snipObject = a:tmpl

    " Note: empty means nothing, "" means something that can override others
    if has_key(setting, 'rawHint')

        let hint = xpt#eval#Eval( setting.rawHint,
              \ [ x.filetypes[ x.snipFileScope.filetype ].funcs,
              \   setting.variables,
              \ ] )

        if type(hint) == type({})
            if get(hint, 'action', '') == 'pum'
                let pum = get(hint, 'pum', [])
                let setting.hint =  join( pum[ : 3 ], ' ' ) . ' ..'
            else
                let setting.hint = get(hint, 'text', '')
            endif
        elseif type(hint) == type([])
            let setting.hint =  join( hint[ : 3 ], ' ' ) . ' ..'
        elseif type(hint) == type(1)
            let setting.hint = string(hint)
        elseif type(hint) == 2
            " function
            let setting.hint = string(hint)
        else
            let setting.hint = hint
        endif

    endif

    call s:ParsePostQuoter( setting )

endfunction "}}}

fun! s:ParsePostQuoter( setting ) "{{{
    if !has_key( a:setting, 'postQuoter' )
                \ || type( a:setting.postQuoter ) == type( {} )
        return
    endif


    let quoters = split( a:setting.postQuoter, ',' )
    if len( quoters ) < 2
        throw 'postQuoter must be separated with ","! :' . a:setting.postQuoter
    endif

    let a:setting.postQuoter = { 'start' : quoters[0], 'end' : quoters[1] }
endfunction "}}}

fun! s:AddCursorToComeLast(setting) "{{{

    if match( a:setting.comeLast, 'cursor' ) < 0
        call add( a:setting.comeLast, 'cursor' )
    endif

    call s:log.Debug( 'has cursor item?:' . string( a:setting.comeLast ) )

endfunction "}}}

fun! s:InitItemOrderList( setting ) "{{{
    " TODO move me to template creation phase

    let a:setting.comeFirst = xpt#util#RemoveDuplicate( a:setting.comeFirst )
    let a:setting.comeLast  = xpt#util#RemoveDuplicate( a:setting.comeLast )

endfunction "}}}

fun! XPTreload() "{{{
    try
        call s:Crash()
    catch /.*/
    endtry

  try
    " unlet b:__xpt_loaded
    unlet b:xptemplateData
  catch /.*/
  endtry

  e

endfunction "}}}

fun! XPTgetAllTemplates() "{{{
    call s:GetContextFTObj() " force initializing

    return copy( b:xptemplateData.filetypes[ &filetype ].allTemplates )
endfunction "}}}


fun! XPTemplatePreWrap( wrap ) "{{{

    " NOTE: start with "s" command, which produce pseudo indent space.

    let x = b:xptemplateData
    let x.wrap = a:wrap

    " TODO is that ok?
    let x.wrap = substitute( x.wrap, '\V\n\$', '', '' )
    let x.wrap = xpt#indent#ToSpace( x.wrap )

    if ( g:xptemplate_strip_left || x.wrap =~ '\n' )
          \ && visualmode() ==# 'V'
        let x.wrapStartPos = virtcol(".")

        let indent = matchstr( x.wrap, '^\s*' )
        let indentNr = len( indent )
        let x.wrap = x.wrap[ indentNr : ]

    else
        let x.wrapStartPos = col(".")

        " NOTE: indent before 'S' command or current indent
        let indentNr = min( [ indent( line( "." ) ), virtcol('.') - 1 ] )


    endif

    let maxIndent = indentNr
    let x.wrap = substitute( x.wrap, '\V\n \{0,' . maxIndent . '\}', "\n", 'g' )
    let lines = split( x.wrap, '\V\\r\n\|\r\|\n', 1 )


    let maxlen = 0
    for l in lines
        let maxlen = maxlen < len(l) ? len(l) : maxlen
    endfor

    let indentNr -= maxIndent

    let x.wrap =  { 'indent' : -indentNr,
          \         'text'   : x.wrap,
          \         'lines'  : lines,
          \         'max'    : maxlen,
          \         'curline' : lines[ 0 ], }

    call s:log.Log( 'x.wrap=' . string( x.wrap ) )


    let leftSpaces = s:ConcreteSpace()
    if leftSpaces != ''
        let x.wrapStartPos = len( leftSpaces ) + 1
    endif

    let leftSpaces = substitute( leftSpaces, '	', '	', 'g' )

    return leftSpaces . "\<C-r>=XPTemplateDoWrap()\<CR>"

endfunction "}}}

fun! s:ConcreteSpace() "{{{

    if getline( line( '.' ) ) =~ '^\s*$'

        let pos = virtcol( '.' )
        normal! d0

        let leftSpaces = XPT#convertSpaceToTab( repeat( ' ', pos - 1 ) )

    else
        let leftSpaces = ''
    endif


    return leftSpaces

endfunction "}}}

fun! XPTemplateDoWrap() "{{{

    call XPTparseSnippets()

    let x = b:xptemplateData
    let ppr = s:Popup("", x.wrapStartPos, {})

    call s:log.Log("popup result:".string(ppr))

    return ppr

endfunction "}}}

fun! XPTabbr( name ) "{{{
    let x = b:xptemplateData

    let line = getline( "." )

    let pre = matchstr( line, '\v\S+$' )
    if pre == ''
        return printf( "\<C-r>=XPTtgr(%s, {'k':''})\<CR>", string( a:name ) )
        " return a:name
    else
        if has_key( x.abbrPrefix, a:name )

            if has_key( x.abbrPrefix[ a:name ], pre )
                return repeat( "\<BS>", len( pre ) ) . printf( "\<C-r>=XPTtgr(%s, {'k':''})\<CR>", string( pre . a:name ) )
            else
                return printf( "\<C-r>=XPTtgr(%s, {'k':''})\<CR>", string( a:name ) )
            endif

        else
            return printf( "\<C-r>=XPTtgr(%s, {'k':''})\<CR>", string( a:name ) )
        endif
    endif

endfunction "}}}

fun! XPTtgr( snippetName, ... ) "{{{
    let opt = a:0 == 1 ? a:1 : {}

    " clear last session
    if pumvisible() || XPPhasSession()
        return XPPend() . "\<C-r>=XPTtgr(" . string( a:snippetName ) . ', ' . string(opt) . ")\<CR>"
    endif

    if opt != {}

        if get( opt, 'noliteral', 0 )
            let opt.nosyn = '\V\cstring\|comment'
        elseif get( opt, 'literal', 0 )
            let opt.syn = '\V\cstring\|comment'
        endif

        if has_key( opt, 'nopum' )
            let opt.pum = !opt.nopum
        endif


        let syn = synIDattr( synID( line("."), col("."), 0 ), "name" )

        if has_key( opt, 'nosyn' ) && syn =~ opt.nosyn
              \ || has_key( opt, 'syn' ) && syn !~ opt.syn
            return opt.k
        endif

        if has_key( opt, 'pum' )
            if opt.pum && !pumvisible()
                  \ || !opt.pum && pumvisible()
                return opt.k
            endif
        endif

    endif

    let action = XPTemplateStart( 0, { 'startPos' : [ line( "." ), col( "." ) ], 'tmplName' : a:snippetName } )

    call s:log.Debug( "action=" . string( action ) )
    return action

endfunction "}}}

fun! XPTemplateTrigger( snippetName, ... ) "{{{
    let opt = a:0 == 1 ? a:1 : {}
    return XPTtgr(a:snippetName, opt)
endfunction "}}}

fun! XPTparseSnippets() "{{{
    let x = b:xptemplateData
    for p in x.snippetToParse
        call xpt#parser#ParseSnippet(p)
    endfor

    let x.snippetToParse = []
endfunction "}}}


" ********* XXX *********
" TODO remove the first argument
" TODO xpt seize pum if something matches snippet name in normal pum.
fun! XPTemplateStart(pos_unused_any_more, ...) " {{{

    let action = ''
    " let action = "\<BS>"

    call XPTparseSnippets()

    let x = b:xptemplateData

    call s:log.Log("a:000".string(a:000))

    let opt = a:0 == 1 ? a:1 : {}

    if has_key( opt, 'tmplName' )
        " exact template trigger, without depending on any input

        let startColumn = opt.startPos[1]
        let templateName = opt.tmplName

        call cursor(opt.startPos)

        return  action . s:DoStart( {
                    \ 'line'    : opt.startPos[0],
                    \ 'col'     : startColumn,
                    \ 'matched' : templateName,
                    \ 'data'    : { 'ftScope' : s:GetContextFTObj() } } )
    endif


    " input mode

    if get( opt, 'concrete', 0 ) == 0

        let opt.concrete = 1

        let leftSpaces = s:ConcreteSpace()

        if leftSpaces != ''
            let leftSpaces = substitute( leftSpaces, '	', '	', 'g' )
            return leftSpaces . "\<C-r>=XPTemplateStart(0," . string( opt ) . ")\<CR>"
        endif
    endif



    let keypressed = get( opt, 'k', g:xptemplate_key )
    let keypressed = substitute( keypressed, '\V++', '>', 'g' )


    if pumvisible()

        call s:log.Debug( "has pum" )

        if XPPhasSession()

            call s:log.Debug( "has session" )

            return XPPend() . "\<C-r>=XPTemplateStart(0," . string( opt ) . ")\<CR>"
        else

            call s:log.Debug( "has no session" )

            if x.fallbacks == []
                " no more tries can be done

                call s:log.Debug( "has no fallbacks" )

                if keypressed =~ g:xptemplate_fallback_condition

                    call s:log.Debug( "it is fallback condition" )

                    let x.fallbacks = [ [ "\<Plug>XPTfallback", 'feed' ] ] + x.fallbacks
                    return XPT#fallback( x.fallbacks )
                else

                    call s:log.Debug( "nothing to do" )

                    " nothing to do, normal procedure.
                endif

            else

                call s:log.Debug( "has fallbacks" )

                if g:xptemplate_fallback =~? '\V<Plug>XPTrawKey\|<NOP>'
                      \ || g:xptemplate_fallback ==? keypressed

                    return XPT#fallback( x.fallbacks )

                else

                    call s:log.Debug( "set up fall back" )

                    let x.fallbacks = [ [ "\<Plug>XPTfallback", 'feed' ] ] + x.fallbacks
                    return XPT#fallback( x.fallbacks )
                endif
            endif

        endif

    else

        call s:log.Debug( "no pum" )

        if XPPhasSession()
            call XPPend()
        endif

    endif


    let forcePum = get( opt, 'forcePum', g:xptemplate_always_show_pum )

    if x.renderContext.processing
        let miniPrefix = g:xptemplate_minimal_prefix_nested
    else
        let miniPrefix = g:xptemplate_minimal_prefix
    endif

    let isFullMaatching = miniPrefix is 'full'
    " if pumvisible()
    "     let isFullMaatching = 1
    " endif


    let cursorColumn = col(".")
    let startLineNr = line(".")
    let accEmp = 0

    if g:xptemplate_key ==? '<Tab>'
        " TODO other plugin like supertab?
        " TODO this is not needed any more.
        let accEmp = 1
    endif

    if has_key( opt, 'popupOnly' )
        let startColumn = cursorColumn

    elseif x.wrapStartPos
        " TODO store wrapping and normal tempalte separately

        let startColumn = x.wrapStartPos

    else

        " TODO codes below are dirty. clean it up lazy bone!!

        let ftScope = s:GetContextFTObj()
        let ftkeyword = ftScope.ftkeyword

        call s:log.Log("ftkeyword.regexp=" . string(ftkeyword.regexp))

        " NOTE: The following statement hangs VIM if x.keyword == '\w'
        " let [startLineNr, startColumn] = searchpos('\V\%(\w\|'. x.keyword .'\)\+\%#', "bn", startLineNr )

        let columnBeforeCursor = col( "." ) - 2
        if columnBeforeCursor >= 0
            let lineToCursor = getline( startLineNr )[ 0 : columnBeforeCursor ]
        else
            let lineToCursor = ''
        endif

        let pre = ftScope.namePrefix
        let n = split( lineToCursor, '\s', 1 )[ -1 ]

        " <non-keyword><keyword> is not breakable: $var in php
        " <keyword><non-keyword> is breakable: func( in c

        " search for valid snippet name or single non-keyword name
        let snpt_name_ptn = '\V\^\(' . ftkeyword.regexp . '\|\k\)\k\*'
        while n != '' && !has_key( pre, n )
            let shorter = substitute( n, snpt_name_ptn, '', '' )

            " no keyword or xpt-keyword stripted, strip one non-keyword
            if shorter == n
                let n = n[ 1 : ]
            else
                let n = shorter
            endif
        endwhile
        let matched = n


        if !has_key( opt, 'popupOnly' )
            if !isFullMaatching
                  \ && len( matched ) < miniPrefix
                  " \ && !forcePum

                  let x.fallbacks = [ [ "\<Plug>XPTfallback", 'feed' ] ] + x.fallbacks
                  return XPT#fallback( x.fallbacks )
            endif
        endif


        let startColumn = col( "." ) - len( matched )

        if matched == ''
            let [startLineNr, startColumn] = [line("."), col(".")]
        endif

    endif

    let templateName = strpart( getline(startLineNr), startColumn - 1, cursorColumn - startColumn )


    call s:log.Log( 'to popup, templateName='.templateName )

    let action = action . s:Popup( templateName, startColumn,
          \ { 'acceptEmpty'    : accEmp,
          \   'forcePum'       : forcePum,
          \   'matchWholeName' : get( opt, 'popupOnly', 0 ) ? 0 : isFullMaatching } )

    return action
endfunction " }}}

fun! s:NewRenderContext( ftScope, tmplName ) "{{{

    let x = b:xptemplateData

    if x.renderContext.processing
        call xpt#buf#Pushrctx()
    endif

    let renderContext = xpt#rctx#New( x )
    let x.renderContext = renderContext

    let renderContext.phase = 'inited'
    let renderContext.snipObject  = s:GetContextFTObj().allTemplates[ a:tmplName ]
    let renderContext.ftScope = a:ftScope

    call s:ParseSnippet( renderContext.snipObject, renderContext.ftScope )

    let renderContext.snipSetting = copy( renderContext.snipObject.setting )

    let setting = renderContext.snipSetting

    for k in [ 'variables', 'preValues', 'defaultValues'
          \  , 'ontypeFilters', 'postFilters', 'comeFirst', 'comeLast' ]
        let setting[ k ] = copy( setting[ k ] )
    endfor

    return renderContext
endfunction "}}}

fun! s:ParseSnippet( snippet, ftScope ) "{{{

    if !a:snippet.parsed

        let a:snippet.snipText = xpt#indent#IndentToTabStr( a:snippet.snipText )

        call s:ParseInclusion( a:ftScope.allTemplates, a:snippet )

        let a:snippet.snipText = s:ParseQuotedPostFilter( a:snippet )
        let a:snippet.snipText = s:ParseRepetition( a:snippet )

        let a:snippet.parsed = 1
    endif
endfunction "}}}

fun! s:DoStart( sess ) " {{{
    " @param sess       xpopup call back argument

    let x = b:xptemplateData

    if !has_key( s:GetContextFTObj().allTemplates, a:sess.matched )
        return ''
    endif

    let b:__xpt_snip_sess__ = a:sess

    " before start, force pum to close
    return "\<BS>" . s:RenderSnippet()

endfunction " }}}

fun! s:RenderSnippet() "{{{

    let x = b:xptemplateData
    let sess = b:__xpt_snip_sess__

    let x.savedReg = @"

    let [lineNr, column] = [ sess.line, sess.col ]
    let cursorColumn = col(".")
    let tmplname = sess.matched

    let ctx = s:NewRenderContext( sess.data.ftScope, tmplname )


    call s:BuildSnippet([ lineNr, column ], [ lineNr, cursorColumn ])


    let ctx.phase = 'rendered'
    let ctx.processing = 1

    call s:CallPlugin( 'render', 'after' )


    if empty(x.stack)
        call s:SaveNavKey()

        call s:ApplyMap()
    endif

    let x.wrap = ''
    let x.wrapStartPos = 0


    let action =  s:GotoNextItem()

    call s:log.Debug("post action =".action)
    call s:log.Debug("mode:".mode())

    call s:log.Debug( "tmpl:", xpt#util#TextBetween( XPMposStartEnd( ctx.marks.tmpl ) ) )

    call s:CallPlugin( 'start', 'after' )


    return action

endfunction "}}}

fun! s:SaveNavKey() "{{{
    let x = b:xptemplateData

    let navKey = g:xptemplate_nav_next

    let mapInfo = xpt#msvr#MapInfo( navKey, 'i' )

    if mapInfo.cont == ''
        let x.canNavFallback = 0
        exe 'inoremap <buffer> <Plug>XPTnavFallback ' navKey
    else
        let x.canNavFallback = 1
        let mapInfo.key = '<Plug>XPTnavFallback'

        exe xpt#msvr#MapCommand( mapInfo )

    endif

    " No need to restore.

endfunction "}}}


" TODO deal with it in any condition
fun! s:FinishRendering(...) "{{{

    let x = b:xptemplateData
    let renderContext = x.renderContext
    let xp = renderContext.snipObject.ptn

    let isCursor = get( renderContext.item, 'name', 0 ) is 'cursor'


    call XPMremoveMarkStartWith( renderContext.markNamePre )


    if empty(x.stack)
        let x.fallbacks = []

        let renderContext.processing = 0
        let renderContext.phase = 'finished'

        call s:ClearMap()



        call XPMflushWithHistory()

        let @" = x.savedReg

        call s:CallPlugin( 'finishAll', 'after' )

    else

        call xpt#buf#Poprctx()
        call s:CallPlugin( 'finishSnippet', 'after' )
        let renderContext = x.renderContext
    endif

    return ''

endfunction "}}}

" TODO cache it and clear it when new snippets parsed
fun! s:Popup(pref, coln, opt) "{{{

    let x = b:xptemplateData
    let renderContext = x.renderContext


    if renderContext.phase == 'finished'
        let renderContext.phase = 'popup'
    endif

    let cmpl=[]
    let cmpl2 = []

    let ftScope = s:GetContextFTObj()
    if ftScope == {}
        " unsupported ft
        return ''
    endif


    let forcePum = get( a:opt, 'forcePum', g:xptemplate_always_show_pum )

    let snipDict = ftScope.allTemplates

    let synNames = s:SynNameStack(line("."), a:coln)

    call s:log.Log("Popup, pref and coln=".a:pref." ".a:coln)

    if has_key( snipDict, a:pref ) && !forcePum
        let snipObj = snipDict[ a:pref ]
        if s:IfSnippetShow( snipObj, synNames )
            return  s:DoStart( {
                  \ 'line'    : line( "." ),
                  \ 'col'     : a:coln,
                  \ 'matched' : a:pref,
                  \ 'data'    : { 'ftScope' : s:GetContextFTObj() } } )
        endif
    endif


    for [ key, snipObj ] in items(snipDict)

        if !s:IfSnippetShow( snipObj, synNames )
            continue
        endif

        let hint = get( snipObj.setting, 'hint', '' )
        if hint == ''
            " the first line of snip body
            let hint = matchstr(snipObj.snipText, '\V\s\*\zs\.\*\ze\n')
        endif

        " buildins come last
        if key =~# '\V\^\[A-Z]'
            call add( cmpl2, {'word' : key, 'menu' : hint } )
        else
            call add( cmpl, {'word' : key, 'menu' : hint } )
        endif

    endfor

    call sort(cmpl)
    call sort(cmpl2)
    let cmpl = cmpl + cmpl2



    let pumsess = XPPopupNew(s:pumCB, { 'ftScope' : ftScope }, cmpl)
    call pumsess.SetAcceptEmpty( get( a:opt, 'acceptEmpty', 0 ) )
    call pumsess.SetMatchWholeName( get( a:opt, 'matchWholeName', 0 ) )
    call pumsess.SetOption( {
          \ 'matchPrefix' : ! forcePum,
          \ 'tabNav'      : g:xptemplate_pum_tab_nav } )
    return pumsess.popup(a:coln, {})

endfunction "}}}

fun! s:IfSnippetShow( snipObj, synNames ) "{{{

    let x = b:xptemplateData

    let snipObj = a:snipObj
    let synNames = a:synNames

    if snipObj.setting.wraponly && x.wrap is ''
          \ || !snipObj.setting.iswrap && x.wrap isnot ''
        return 0
    endif

    if has_key(snipObj.setting, "syn")
          \ && snipObj.setting.syn != ''
          \ && match(synNames, '\c' . snipObj.setting.syn) == -1
        return 0
    endif

    if get( snipObj.setting, 'hidden', 0 )  == 1
        return 0
    endif

    return 1

endfunction "}}}

fun! s:AddIndent( text, nIndent ) "{{{

    let baseIndent = repeat( " ", a:nIndent )
    return substitute(a:text, '\n', '&' . baseIndent, 'g')

endfunction "}}}

fun! s:ParseRepetition( snipObject ) "{{{
    let tmplObj = a:snipObject
    let xp = a:snipObject.ptn

    let tmpl = a:snipObject.snipText


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

        if matchpos == 0
            let bef = ''
        else
            let bef = tmpl[ : matchpos-1 ]
        endif
        let rest = tmpl[ matchpos : ]


        let indentNr = s:GetIndentBeforeEdge( tmplObj, bef )

        call s:log.Log( 'bef=' . bef )
        call s:log.Log( 'indentNr=' . indentNr )
        let repeatPart = matchstr(rest, repContPtn)
        call s:log.Log( 'raw repeatPart=' . repeatPart )
        let repeatPart = 'BuildIfNoChange(' . string( repeatPart ) . ')'


        let symbol = matchstr(rest, rp)
        let name = substitute( symbol, '\V' . xp.lft . '\|' . xp.rt, '', 'g' )

        let tmplObj.setting.postFilters[ name ] = xpt#flt#New( -indentNr, repeatPart )



        let bef .= symbol
        let rest = substitute(rest, repPtn, '', '')
        let tmpl = bef . rest

    endwhile

    call s:log.Log( 'template after parse repetition:', tmpl )

    return tmpl


endfunction "}}}

fun! s:GetIndentBeforeEdge( tmplObj, textBeforeLeftMark ) "{{{
    let xp = a:tmplObj.ptn

    if a:textBeforeLeftMark =~ '\V' . xp.lft . '\_[^' . xp.r . ']\*\%$'
        call s:log.Debug( 'has edge' )
        let tmpBef = substitute( a:textBeforeLeftMark, '\V' . xp.lft . '\_[^' . xp.r . ']\*\%$', '', '' )
        call s:log.Debug( 'tmpBef=' . tmpBef )
        let indentOfFirstLine = matchstr( tmpBef, '.*\n\zs\s*' )

    else
        let indentOfFirstLine = matchstr( a:textBeforeLeftMark, '.*\n\zs\s*' )
    endif

    return len( indentOfFirstLine )
endfunction "}}}

fun! s:ParseQuotedPostFilter( tmplObj ) "{{{
    let xp = a:tmplObj.ptn
    let postFilters = a:tmplObj.setting.postFilters
    let quoter = a:tmplObj.setting.postQuoter

    let flagPattern = '\V\[!]\$'

    let startPattern = '\V\_.\{-}\zs' . xp.lft . '\_[^' . xp.r . ']\*' . quoter.start . xp.rt
    let endPattern = '\V' . xp.lft . quoter.end . xp.rt

    call s:log.Log( 'parse Quoted Post Filter for ' . a:tmplObj.name )

    call s:log.Log( 'startPattern=' . startPattern )
    call s:log.Log( 'endPattern=' . endPattern )

    let snip = a:tmplObj.snipText


    " Note: pattern can not satisfy that most prefix and most xp.lft can be
    " found. Thus stack must be used
    let stack = []

    let startPos = 0
    while startPos != -1
      let startPos = match(snip, startPattern, startPos)
      call s:log.Log( "found:" . startPos )

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


        " without left mark, right mark, start quoter
        let name = startText[ 1 : -1 - len( quoter.start ) - 1 ]
        let flag = matchstr( name, flagPattern )
        if flag != ''
            let name = name[ : -1 - len( flag ) ]
        endif

        " deal with edge
        if name =~ xp.lft
            let name = matchstr( name, '\V' . xp.lft . '\zs\_.\*' )

            " has right edge ?
            if name =~ xp.lft
                let name = matchstr( name, '\V\_.\*\ze' . xp.lft )
            endif
        endif


        call s:log.Log( 'startText=' . startText )
        call s:log.Log( 'endText=' . endText )
        call s:log.Log( 'name=' . name )


        let plainPostFilter = snip[ startPos + len( startText ) : endPos - 1 ]

        let firstLineIndentNr = s:GetIndentBeforeEdge( a:tmplObj, snip[ : startPos - 1 ] )

        if flag == '!'
            let plainPostFilter = 'BuildIfChanged(' . string( plainPostFilter ) . ')'
        else
            " default
            let plainPostFilter = 'BuildIfNoChange(' . string( plainPostFilter ) . ')'
        endif

        let postFilters[ name ] = xpt#flt#New( -firstLineIndentNr, plainPostFilter )

        call s:log.Debug( 'name=' . name )
        call s:log.Debug( 'quoted post filter=' . string( postFilters[ name ] ) )
        " right mark, start quoter
        let snip = snip[ : startPos + len( startText ) - 1 - 1 - len( quoter.start ) - len( flag ) ]
                    \ . snip[ endPos + len( endText ) - 1 : ]

    endwhile

    return snip

endfunction "}}}

fun! s:BuildSnippet(nameStartPosition, nameEndPosition) " {{{

    call s:log.Debug( 'BuildSnippet : start, end=' . string( [ a:nameStartPosition, a:nameEndPosition ] ) )

    " eat up <space> in abbr mode
    call getchar( 0 )

    let x = b:xptemplateData
    let ctx = b:xptemplateData.renderContext
    let xp = ctx.snipObject.ptn



    let curline = getline( a:nameStartPosition[ 0 ] )

    let nIndent = -1
    if len( matchstr( curline, '\V\^\s\*' ) ) == a:nameStartPosition[ 1 ] - 1
        " snippet name starts as the first non-space char

        if has_key( ctx.oriIndentkeys, ctx.snipObject.name )
              \ || has_key( ctx.leadingCharToReindent, ctx.snipObject.name )

            " TODO
            "       For correct indentexpr, we have to place snippet name first on
            "       screen and then clear it.
            "
            "       This is a dirty fix. Better way is to place the snippet name out
            "       of this function.

            if a:nameStartPosition == a:nameEndPosition
                call XPreplace( a:nameStartPosition, a:nameEndPosition,
                      \ ctx.snipObject.name, { 'doJobs' : 0 } )
            endif

            let nIndent = XPT#getPreferedIndentNr( a:nameStartPosition[ 0 ] )

            if a:nameStartPosition == a:nameEndPosition
                call XPreplace( a:nameStartPosition, [ a:nameEndPosition[ 0 ],
                      \     a:nameEndPosition[ 1 ] + len( ctx.snipObject.name ) ],
                      \ '', { 'doJobs' : 0 } )
            endif

        endif

    endif


    let ctx.phase = 'rendering'


    if ctx.snipSetting.iswrap && x.wrap isnot ''
        let setting = ctx.snipSetting

        let setting.preValues[ setting.wrap ] = xpt#flt#New( 0, 'GetWrappedText()' )
        let setting.defaultValues[ setting.wrap ] = xpt#flt#New( 0, "Next()", 1 )

        call insert( setting.comeFirst, setting.wrap, 0 )
    endif

    if x.wrap isnot ''
        let ctx.wrap = copy( x.wrap )
    endif

    let snippetText = ctx.snipObject.snipText



    let currentNIndent = XPT#getIndentNr( a:nameStartPosition[ 0 ], a:nameStartPosition[ 1 ] )
    let nIndentToAdd = currentNIndent
    if nIndent >= 0

        if nIndent > currentNIndent

            let snippetText = repeat( ' ', nIndent - currentNIndent ) . snippetText
            let nIndentToAdd = nIndent

        elseif nIndent < currentNIndent

            let snippetText = repeat( ' ', nIndent ) . snippetText
            let nIndentToAdd = nIndent
            let a:nameStartPosition[ 1 ] = 1

        endif

    endif

    let snippetText = xpt#indent#ToActualIndentStr(snippetText, nIndentToAdd)

    " Note: simple implementation of wrapping, the better way is by default value
    " TODO use default value!




    " update xpm status
    call XPMupdate()
    call s:log.Debug( 'before insert new template mark' )
    call s:log.Debug( XPMallMark() )


    call XPMadd( ctx.marks.tmpl.start, a:nameStartPosition, g:XPMpreferLeft, '\Ve\$' )
    call XPMadd( ctx.marks.tmpl.end, a:nameEndPosition, g:XPMpreferRight, '\Ve\$' )


    call xpt#settingswitch#Switch(b:xptemplateData.settingWrap)
    call XPMsetLikelyBetween( ctx.marks.tmpl.start, ctx.marks.tmpl.end )
    call XPreplace( a:nameStartPosition, a:nameEndPosition, snippetText )

    call s:log.Debug( 'after insert new template' )
    call s:log.Debug( XPMallMark() )

    call s:log.Log( "template start and end=" . string( [ XPMpos( ctx.marks.tmpl.start ), XPMpos( ctx.marks.tmpl.end )] ) )


    " initialize lists
    let ctx.firstList = []
    let ctx.itemList = []
    let ctx.lastList = []

    if 0 > s:BuildPlaceHolders( ctx.marks.tmpl )
        return s:Crash()
    endif



    let ctx = empty( x.stack ) ? x.renderContext : x.stack[0]

    let rg = XPMposList( ctx.marks.tmpl.start, ctx.marks.tmpl.end )

    exe 'silent! ' . rg[0][0] . ',' . rg[1][0] . 'foldopen!'
    " exe 'silent! ' . rg[0][0] . ',' . rg[1][0] . 'retab!'

endfunction " }}}

" [ first, second, third, right-mark ]
" [ first, first, right-mark, right-mark ]
fun! s:GetNameInfo(end) "{{{
    let x = b:xptemplateData
    let xp = x.renderContext.snipObject.ptn

    if getline(".")[col(".") - 1] != xp.l
        throw "cursor is not at item start position:".string(getpos(".")[1:2])
    endif

    call s:log.Log("GetNameInfo from".string(getpos(".")[1:2]))
    call s:log.Log("to:".string(a:end))
    call s:log.Debug( 'pattner:' . string( [ xp.lft, xp.rt ] ) )

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
    endif

endfunction "}}}

fun! s:GetValueInfo( end ) "{{{
    let x = b:xptemplateData
    let xp = x.renderContext.snipObject.ptn

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
    if r1 == [0, 0] || r1[0] * 10000 + r1[1] >= l0n
        return [r0, copy(r0), copy(r0)]
    endif

    let r2 = searchpos(xp.rt, 'W', a:end[0])
    if r2 == [0, 0] || r2[0] * 10000 + r2[1] >= l0n
        return [r0, r1, copy(r1)]
    endif

    return [r0, r1, r2]
endfunction "}}}

fun! s:TextWithoutIndent(posRange) "{{{

    let [ s, e ] = a:posRange

    let text = xpt#util#TextBetween([s, e])
    let text = xpt#indent#ToSpace(text)
    let nIndent = xpt#indent#IndentBefore(s)
    let text = xpt#indent#RemoveIndentStr(text, nIndent)

    " text with first line removed but it is still on-screen indent
    return text
endfunction "}}}

" XSET name|def=
" XSET name|post=
"
" `name^ per-item post-filter ^^


fun! s:CreatePlaceHolder( ctx, nameInfo, valueInfo ) "{{{

    let xp = a:ctx.snipObject.ptn
    let toescape = xp.l . xp.r

    " 1 is length of left mark
    let leftEdge  = s:TextWithoutIndent( a:nameInfo[ 0 : 1 ] )
    let name      = s:TextWithoutIndent( a:nameInfo[ 1 : 2 ] )
    let rightEdge = s:TextWithoutIndent( a:nameInfo[ 2 : 3 ] )

    let [ leftEdge, name, rightEdge ] = [ leftEdge[1 : ], name[1 : ], rightEdge[1 : ] ]

    let leftEdge = xpt#util#UnescapeChar(leftEdge, toescape)
    let name = xpt#util#UnescapeChar(name, toescape)
    let rightEdge = xpt#util#UnescapeChar(rightEdge, toescape)

    let fullname  = leftEdge . name . rightEdge

    call s:log.Log( "item is :" . string( [ leftEdge, name, rightEdge ] ) )


    " NOTE: inclusion comes first
    let incPattern = '\V\^:\zs\.\*\ze:\$\|\^Include:\zs\.\*\$'
    if name =~ incPattern
        " build-time inclusion for XSET
        return { 'include' : matchstr( name, incPattern ) }
    endif

    " TODO quoted pattern
    " if a place holder need to be evalueated, the evaluate part must be all
    " in name but not edge.
    if name =~ '\V' . xp.item_var . '\|' . xp.item_func
        " that is only a instant place holder
        return { 'value' : fullname,
              \     'leftEdge'  : leftEdge,
              \     'name'  : name,
              \     'rightEdge' : rightEdge,
              \ }
    endif




    " PlaceHolder.item is set by caller.
    " After this step, to which item this placeHolder belongs has not been set.
    let placeHolder = {
                \ 'name'        : name,
                \ 'isKey'       : (a:nameInfo[0] != a:nameInfo[1]),
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
        let isPostFilter = a:valueInfo[1][0] == a:valueInfo[2][0]
                    \&& a:valueInfo[1][1] + 1 == a:valueInfo[2][1]

        let val = xpt#util#TextBetween( a:valueInfo[ 0 : 1 ] )
        let val = val[1:]
        let val = xpt#util#UnescapeChar( val, xp.l . xp.r )

        " NOTE: problem indent() returns indent without no mark consideration
        let nIndent = indent( a:valueInfo[0][0] )


        if isPostFilter
            " NOTE: not a good solution.
            " TODO make the "..." ended ph standard.
            if name =~ s:expandablePattern

                " it is converted to string, thus escaped chars are safe now
                let val = xpt#util#UnescapeChar( val, '{$( ' )
                let val = 'BuildIfNoChange(' . string( val ) . ')'
            endif
            let placeHolder.postFilter = xpt#flt#New( -nIndent, val )
        else
            let placeHolder.ontimeFilter = xpt#flt#New( -nIndent, val )
        endif

        call s:log.Debug("placeHolder post filter:key=val : " . name . "=" . val)
    endif

    return placeHolder

endfunction "}}}


" TODO move me to where I should be
" mark naming principle:
"   X{ nested_level }_{ name }
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


fun! s:BuildMarksOfPlaceHolder( item, placeHolder, nameInfo, valueInfo ) "{{{
    " TODO do not create edge mark if not necessary

    let renderContext = b:xptemplateData.renderContext

    let [ item, placeHolder, nameInfo, valueInfo ] =
                \ [a:item, a:placeHolder, a:nameInfo, a:valueInfo]

    if item.name == ''
        let markName =  '``' . s:anonymouseIndex
        let s:anonymouseIndex += 1

    else
        let markName =  item.name . s:buildingSeqNr . '`' . ( placeHolder.isKey ? 'k' : (len(item.placeHolders)-1) )

    endif

    " TODO maybe using the mark-symbol variable is better?
    let markPre = renderContext.markNamePre . markName . '`'

    " NOTE:use 's' 'e' and 'S' 'E' is better, but xpmark compare names with case ignored!
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



    " move to after the last right mark
    let valueInfo[2][1] += 1

    " Adjust position of nameInfo and valueInfo.
    " If 2 positions are at the same line, increase shifting width by 1.
    if placeHolder.isKey
        let shift = ( nameInfo[0] != nameInfo[1] && nameInfo[0][0] == nameInfo[1][0])
        let nameInfo[1][1] -= shift
        call s:log.Debug( 'nameInfo.1 decr=' . shift )

        let shift = (nameInfo[1][0] == nameInfo[2][0]) * (shift + 1)
        let nameInfo[2][1] -= shift
        call s:log.Debug( 'nameInfo.2 decr=' . shift )

        if nameInfo[2] != nameInfo[3]
            let shift = (nameInfo[2][0] == nameInfo[3][0]) * (shift + 1)
            let nameInfo[3][1] -= shift
            call s:log.Debug( 'nameInfo.3 decr=' . shift )
        endif

        call XPreplaceInternal(nameInfo[0], valueInfo[2], placeHolder.fullname)

    else
        if nameInfo[0][0] == nameInfo[3][0]
            let nameInfo[3][1] -= 1
        endif
        call XPreplaceInternal(nameInfo[0], valueInfo[2], placeHolder.name)
    endif




    " must add marks in fixed order

    call XPMadd( placeHolder.mark.start, nameInfo[0], 'l' )

    " TODO remember to remove editMark
    if placeHolder.isKey
        call XPMadd( placeHolder.editMark.start, nameInfo[1], 'l' )
        call XPMadd( placeHolder.editMark.end,   nameInfo[2], 'r' )
    endif

    call XPMadd( placeHolder.mark.end,   nameInfo[3], 'r' )

endfunction "}}}

fun! s:AddItemToRenderContext( ctx, item ) "{{{

    let [ctx, item] = [ a:ctx, a:item ]

    let exist = has_key( ctx.itemDict, item.name )

    if item.name != ''
        let ctx.itemDict[ item.name ] = item
    endif

    if exist
        return
    endif

    " TODO to be precise phase, do not use false condition
    if ctx.phase != 'rendering'

        if ! s:AddToOrderList( ctx.firstList, item )
            call add( ctx.firstList, item )
        endif

        call filter( ctx.itemList, 'v:val isnot item' )

        call s:log.Log( 'item insert to the head of itemList:' . string( item ) )
        return

    endif

    " rendering phase

    if item.name == ''

        call add( ctx.itemList, item )

    elseif s:AddToOrderList( ctx.firstList, item )
          \ || s:AddToOrderList( ctx.lastList, item )

        return

    else

        call add( ctx.itemList, item )
        call s:log.Log( item.name . ' added to itemList' )

    endif

endfunction "}}}

fun! s:AddToOrderList( list, item ) "{{{
    let i = index( a:list, a:item.name )

    if i != -1
        let a:list[ i ] = a:item
        call s:log.Log( a:item.name . ' added to ' . string( a:list ) )
        call s:log.Debug( 'index:' . i )

        return 1
    else
        return 0
    endif

endfunction "}}}

fun! s:BuildPlaceHolders( markRange ) "{{{

    let s:buildingSeqNr += 1
    let rc = 0

    let x = b:xptemplateData
    let renderContext = b:xptemplateData.renderContext
    let snipObj = renderContext.snipObject
    let setting = snipObj.setting
    let xp = renderContext.snipObject.ptn

    " NOTE: every time building PHs, empty itemDict, thus PHs with the same
    " name of another PH from a previous Building are dealt with as a new PH.
    "
    " This avoids problem with expandable nested in expandable with a same
    " trigger PH like "else...".
    let renderContext.itemDict = {}

    " to apply preset value or else, item and leadingPlaceHolder can change
    " through building process
    let current = [ renderContext.item, renderContext.leadingPlaceHolder ]


    let renderContext.action = 'build'

    if renderContext.firstList == []
        let renderContext.firstList = copy( renderContext.snipSetting.comeFirst )
    endif
    if renderContext.lastList == []
        let renderContext.lastList = copy( renderContext.snipSetting.comeLast )
    endif


    let renderContext.buildingMarkRange = copy( a:markRange )

    call XPRstartSession()


    call XPMgoto( a:markRange.start )


    let i = 0
    while i < 10000
        let i += 1

        call s:log.Log( "build from here" )

        let markPos = s:NextLeftMark( a:markRange )

        let end = XPMpos( a:markRange.end )
        let nEnd = end[0] * 10000 + end[1]

        if markPos == [0, 0] || markPos[0] * 10000 + markPos[1] >= nEnd
            break
        endif

        call s:log.Log( "building now" )
        call s:log.Log(" : end=".string(end))

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

        let placeHolder = s:CreatePlaceHolder(renderContext, nameInfo, valueInfo)
        let rc = 1

        call s:log.Log( 'built placeHolder=' . string( placeHolder ) )

        if renderContext.wrap != {}
              \ && setting.iswrap
              \ && get( placeHolder, 'name', 0 ) is setting.wrap
              \ && get( placeHolder, 'isKey', 0 )

            " linewise propagation

            let n = len( renderContext.wrap.lines ) - 1

            let indent = repeat( ' ', virtcol( nameInfo[ 0 ] ) - 1 )

            let line = "\n" . indent . xp.l . placeHolder.leftEdge . xp.l . 'GetWrappedText()' . xp.l . placeHolder.rightEdge . xp.r
            let lines = repeat( line, n )

            let pos = copy( valueInfo[ -1 ] )
            let pos[ 1 ] += 1
            call XPreplaceInternal( pos, pos, lines )

        endif


        if has_key( placeHolder, 'include' )
            call s:ApplyBuildTimeInclusion( placeHolder, nameInfo, valueInfo )

            " leave cursor at the beginning of place holder for further building
            call cursor( nameInfo[0] )

        elseif has_key( placeHolder, 'value' )
            " render it instantly
            " Cursor left just after replacement, and it is where next search
            " start

            let to_build = s:ApplyInstantValue( placeHolder, nameInfo, valueInfo )
            if to_build
                call cursor( nameInfo[ 0 ] )
            endif

        else
            " build item and marks, as a fill in place holder

            let item = s:BuildItemForPlaceHolder( placeHolder )

            call s:BuildMarksOfPlaceHolder( item, placeHolder, nameInfo, valueInfo )

            " set for eval preset value, edge, etc.
            let renderContext.item = item
            let renderContext.leadingPlaceHolder = item.keyPH == s:nullDict ? placeHolder : item.keyPH

            " nameInfo and valueInfo is updated according to new position
            " call cursor(nameInfo[3])

            call s:log.Debug( 'built ph=' . string( placeHolder ) )

            call s:EvaluateEdge( xp, item, placeHolder )
            call s:ApplyPreValues( placeHolder )

            " TODO set it when item created.
            call xpt#rctx#AddDefaultPHFilters(renderContext, placeHolder)

            call cursor( XPMpos( placeHolder.mark.end ) )

        endif


    endwhile


    let renderContext.itemList = renderContext.firstList + renderContext.itemList + renderContext.lastList

    " filter string elements which are not any of item names
    call filter( renderContext.itemList, 'type(v:val) != 1' )

    let renderContext.firstList = []
    let renderContext.lastList = []

    call s:log.Log( "itemList:" . string( renderContext.itemList ) )


    let end = XPMpos( a:markRange.end )

    call cursor( end )

    let [ renderContext.item, renderContext.leadingPlaceHolder ] = current

    let renderContext.action = ''

    call XPRendSession()

    return rc

endfunction "}}}


fun! s:NextLeftMark( markRange ) "{{{
    let x = b:xptemplateData
    let renderContext = x.renderContext
    let xp = renderContext.snipObject.ptn

    " NOTE: search the first mark which might be following a '\'
    "       searchpos() can not find mark in the following case:
    "       \`
    "        cursor stays here( 2nd char "`" )
    let curline = getline( line(".") )
    let c = col(".")
    if len( curline ) > 1 && curline[ c - 1 ] == xp.l
        return [ line("."), c ]
    endif


    while 1

        let end = XPMpos( a:markRange.end )
        let nEnd = end[0] * 10000 + end[1]

        call s:log.Log("search for NextLeftMark : end=".string(end))


        let ptn = xpt#util#CharsPattern(xp.l . xp.r)
        " TODO '^' need to be escaped
        let markPos = searchpos( '\V\\\*' . ptn, 'cW' )
        call s:log.Log('found: ' . string(markPos))

        if markPos == [0, 0] || markPos[0] * 10000 + markPos[1] >= nEnd
            break
        endif

        let content = getline( markPos[0] )[ markPos[1] - 1 : ]
        let char = matchstr( content, '\V' . ptn )
        let content = matchstr( content, '^\\*' )

        call s:log.Log( 'content=' . content, 'char=' . char )

        let newEsc = repeat( '\', len( content ) / 2 )
        call XPreplaceInternal( markPos, [ markPos[0], markPos[1] + len( content ) ], newEsc, { 'doPostJob' : 1 } )
        " call XPreplace( markPos, [ markPos[0], markPos[1] + len( content ) ], newEsc )

        if len( content ) % 2 == 0 && char == xp.l
            call cursor( [ markPos[0], markPos[1] + len( newEsc ) ] )
            break
        endif

        call cursor( [ markPos[0], markPos[1] + len( newEsc ) + 1 ] )


    endwhile

    return markPos

endfunction "}}}


fun! s:EvaluateEdge( xp, item, ph ) "{{{
    call s:log.Debug( 'EvaluateEdge' )
    if !a:ph.isKey
        return
    endif

    let eval_ptn = '\V' . a:xp.item_var . '\|' . a:xp.item_func

    if a:ph.leftEdge =~ eval_ptn
        let a:ph.leftEdge = s:EvalAsFilter(a:ph.leftEdge,
              \                            XPMpos(a:ph.mark.start))
        call XPreplaceByMarkInternal( a:ph.mark.start, a:ph.editMark.start,
              \                       a:ph.leftEdge )
    endif

    if a:ph.rightEdge =~ eval_ptn
        let a:ph.rightEdge = s:EvalAsFilter(a:ph.rightEdge,
              \                             XPMpos(a:ph.editMark.end))
        call XPreplaceByMarkInternal( a:ph.editMark.end, a:ph.mark.end,
              \                       a:ph.rightEdge )
    endif

    let a:ph.fullname   = a:ph.leftEdge . a:item.name . a:ph.rightEdge
    let a:item.fullname = a:ph.fullname

endfunction "}}}

fun! s:EvalAsFilter( raw, start_pos ) "{{{
    let x = b:xptemplateData
    let rctx = x.renderContext

    let flt = xpt#flt#New(0, a:raw)
    let flt_rst = s:EvalFilter(flt, [
          \     rctx.ftScope.funcs,
          \     rctx.snipSetting.variables,
          \ ])
    return s:IndentFilterText(flt_rst, a:start_pos)
endfunction "}}}

fun! s:IndentFilterText( flt_rst, start ) "{{{

    " By default all text passed in is snippet text which takes 4 space as one
    " indent.
    " Unless user specifies text is copied from screen, thus it does not need
    " to parse indent.

    let lines = split( a:flt_rst.text, '\n', 1 )

    if get(a:flt_rst, 'parseIndent', 1)
        call xpt#indent#IndentToTab( lines )
    endif

    let indent = s:IndentAt(a:start, a:flt_rst)
    call xpt#indent#ToActualIndent( lines, indent )
    return join(lines, "\n")
endfunction "}}}

fun! s:ApplyBuildTimeInclusion( placeHolder, nameInfo, valueInfo ) "{{{

    let renderContext = b:xptemplateData.renderContext
    let tmplDict = renderContext.ftScope.allTemplates

    let placeHolder = a:placeHolder
    let nameInfo    = a:nameInfo
    let valueInfo   = a:valueInfo

    call s:log.Debug( 'buildtime inclusion' )

    let [ incName, params ] = s:ParseInclusionStatement( renderContext.snipObject, placeHolder.include )

    if !has_key( tmplDict, incName )
        call XPT#warn( "unknown inclusion :" . incName )
        return
    endif

    let incTmplObject = tmplDict[ incName ]

    call s:ParseSnippet( incTmplObject, renderContext.ftScope )

    call s:MergeSetting( renderContext.snipSetting, incTmplObject.setting )

    let incSnip = s:ReplacePHInSubSnip( renderContext.snipObject, incTmplObject, params )
    let incSnip = s:AddIndent( incSnip, nameInfo[0][1]-1 )

    let valueInfo[-1][1] += 1
    call XPreplaceInternal( nameInfo[0], valueInfo[-1], incSnip )

endfunction "}}}

fun! s:ApplyInstantValue( placeHolder, nameInfo, valueInfo ) "{{{
    " TODO eval edge and name separately?

    let rctx = b:xptemplateData.renderContext

    let ph = a:placeHolder
    let nameInfo    = a:nameInfo
    let valueInfo   = a:valueInfo
    let start = a:nameInfo[0]

    call s:log.Debug( 'instant placeHolder' )

    let combined_flt_rst = {}
    let text = ''
    let to_build = 0
    for k in [ 'leftEdge', 'name', 'rightEdge' ]
        if ph[k] != ''
            let flt = xpt#flt#New( 0, ph[k] )
            let flt_rst = s:EvalFilter( flt, [
                  \     rctx.ftScope.funcs,
                  \     rctx.snipSetting.variables,
                  \ ] )

            if flt_rst.rc == 0
                continue
            endif

            let text .= get( flt_rst, 'text', '' )
            if get(flt_rst, 'nIndent', 0) != 0
                let combined_flt_rst.nIndent = flt_rst.nIndent
            endif
            if flt_rst.action == 'build'
                let to_build = 1
            endif
        endif
    endfor

    call s:log.Log( "instant value filter value:" . string( flt_rst ) )

    let valueInfo[-1][1] += 1

    let combined_flt_rst.text = text
    let text = s:IndentFilterText(combined_flt_rst, start)

    call XPreplaceInternal( nameInfo[0], valueInfo[-1], text, { 'doJobs' : 1 } )

    return to_build

endfunction "}}}

fun! s:IndentAt( start, flt_rst ) "{{{
    " instant filter does not support well yet
    let filter_indent_offset = get(a:flt_rst, 'nIndent', 0)

    let indent = xpt#indent#IndentBefore( a:start )
    let indent += filter_indent_offset
    let indent = max([0, indent])

    return indent
endfunction "}}}

" TODO simplify : if PH has preValue, replace it at once, without replacing with the name
" TODO delay this to after template rendering
fun! s:ApplyPreValues( placeHolder ) "{{{
    let rctx = b:xptemplateData.renderContext
    let setting = rctx.snipSetting
    let name = a:placeHolder.name

    let preValue = name == ''
          \ ? g:EmptyFilter
          \ : get( setting.preValues, name, g:EmptyFilter )

    if preValue is g:EmptyFilter

        let preValue = get( a:placeHolder, 'ontimeFilter',
              \ get( setting.defaultValues, name, g:EmptyFilter ) )

    endif

    if preValue is g:EmptyFilter
        return
    endif

    let flt_rst = s:EvalFilter( preValue, [
          \     rctx.ftScope.funcs,
          \     rctx.snipSetting.variables,
          \ ] )

    if flt_rst.rc is 0 || ! has_key(flt_rst, 'text')
        return
    endif

    let mark_name = s:GetPHReplacingMarkName(flt_rst)
    let marks = a:placeHolder[mark_name]

    let s = XPMpos(marks.start)
    let text = s:IndentFilterText(flt_rst, s)

    call s:log.Log( 'preValue=' . text )
    try
        call XPreplaceByMarkInternal( marks.start, marks.end, text )
    catch /.*/
        call s:Crash( v:exception . " while update preset text" )
    endtry

endfunction "}}}

fun! s:BuildItemForPlaceHolder( placeHolder ) "{{{

    " anonymous item with name set to '' will never been added to a:renderContext.itemDict

    let renderContext = b:xptemplateData.renderContext

    if has_key(renderContext.itemDict, a:placeHolder.name)
        let item = renderContext.itemDict[ a:placeHolder.name ]

    else
        let item = { 'name'         : a:placeHolder.name,
                    \'fullname'     : a:placeHolder.name,
                    \'initValue'    : a:placeHolder.name,
                    \'processed'    : 0,
                    \'placeHolders' : [],
                    \'keyPH'        : s:nullDict,
                    \'behavior'     : {},
                    \}


    endif


    let inPrevBuild = ( index( renderContext.itemList, item ) >= 0 )

    " NOTE: No matter new or old, always try to add. during render-time,
    " dynamically generated PH need to be resorted
    call s:AddItemToRenderContext( renderContext, item )

    if a:placeHolder.isKey
        let item.keyPH = a:placeHolder
        let item.fullname = a:placeHolder.fullname
    else
        if renderContext.phase != 'rendering' && inPrevBuild
            call insert( item.placeHolders, a:placeHolder )
        else
            call add( item.placeHolders, a:placeHolder )
        endif
    endif

    call s:log.Log( 'item built=' . string( item ) )

    return item
endfunction "}}}

fun! s:XPTvisual() "{{{
    if &selectmode =~ 'cmd'
        normal! v\<C-g>
    else
        normal! v
    endif
endfunction "}}}

fun! s:CleanupCurrentItem() "{{{
    let renderContext = b:xptemplateData.renderContext
    call s:ClearItemMapping( renderContext )
endfunction "}}}

fun! s:ShiftBackward() "{{{
    let renderContext = b:xptemplateData.renderContext

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

    return s:SelectCurrent()

endfunction "}}}

fun! s:PushBackItem() "{{{
    let renderContext = b:xptemplateData.renderContext

    let item = renderContext.item
    if !renderContext.leadingPlaceHolder.isKey
        call insert( item.placeHolders, renderContext.leadingPlaceHolder, 0 )
    endif

    call insert( renderContext.itemList, item, 0 )

    let item.processed = 1

endfunction "}}}


fun! s:ShiftForward( action ) " {{{

    let x = b:xptemplateData
    let renderContext = x.renderContext

    if pumvisible()

        if XPPhasSession()
            return XPPend() . "\<C-r>=<SNR>" . s:sid . 'ShiftForward(' . string( a:action ) . ")\<CR>"
        else

            if g:xptemplate_move_even_with_pum
                return s:close_pum . "\<C-r>" . '=XPTforceForward(' . string( a:action ) . ")\<CR>"
            else
                if x.canNavFallback
                    let x.fallbacks = [ [ "\<Plug>XPTnavFallback", 'feed' ],
                          \             [ "\<C-r>=XPTforceForward(" . string( a:action ) . ")\<CR>", 'expr' ], ]
                    return  XPT#fallback( x.fallbacks )
                else
                    return XPPend() . "\<C-r>=<SNR>" . s:sid . 'ShiftForward(' . string( a:action ) . ")\<CR>"
                endif
            endif
        endif

    else

        if XPPhasSession()
            call XPPend()
        endif

        " Pum may be not visible but pum does exist. This cause problem
        " further <tab> swallow chars between pum-text and cursor position.
        "
        " In this case we have to force pum to close.

        return s:close_pum . "\<C-r>" . '=XPTforceForward(' . string( a:action ) . ")\<CR>"

    endif

endfunction " }}}

fun! XPTforceForward( action ) "{{{

    " There is chance when forward is triggered, something is typed by user
    " but CurosrMoved[I] does not triggered.
    "
    " So before moving to next place holder this is the last chance to update
    " following place holders.
    "
    " To produce an issue like this:
    " :inoreabbrev yy yy<C-o>echo 123<CR>
    " When applying snippet:
    " -     type "yy<Space>"
    " -     VIM first insert "yy" and leaves insert mode and do the echo things.
    " -     And then it go back to insert mode(cursor is placed after "yy").
    " -     And then VIM fills in a space after "yy".
    "       When the last space is inserted, NO event is triggered!!
    call XPMupdate('force')
    if s:XPTupdate() < 0
        return ''
    endif

    if s:FinishCurrent( a:action ) < 0
        return ''
    endif

    let postaction =  s:GotoNextItem()

    call s:log.Debug( XPMallMark() )
    call s:log.Debug( "postaction=" . string( postaction ) )

    return postaction

endfunction "}}}

" TODO this function should reset item and leadingPlaceHolder to null
fun! s:FinishCurrent( action ) "{{{
    let renderContext = b:xptemplateData.renderContext
    let marks = renderContext.leadingPlaceHolder.mark

    call s:CleanupCurrentItem()

    call s:log.Debug( "before update=" . XPMallMark() )

    " if typing and <tab> pressed together, no update called
    " TODO do not call this if no need to update
    "       updating followers can be done in postfilter.
    "       here the only thing maybe need to be done is updating marks
    let rc = s:XPTupdate()
    if rc == -1
        " crashed
        return -1
    endif

    call s:log.Debug( "after update=" . XPMallMark() )


    let name = renderContext.item.name


    call s:log.Log("FinishCurrent action:" . a:action)

    if a:action ==# 'clear'
        call s:log.Log( 'to clear:' . string( [ XPMpos( marks.start ),XPMpos( marks.end ) ] ) )
        call XPreplace(XPMpos( marks.start ),XPMpos( marks.end ), '')
    endif

    call s:log.Debug( "before post filter=" . XPMallMark() )

    let [ post, built ] = s:ApplyPostFilter()

    call s:log.Debug( "after post filter=" . XPMallMark() )



    if name != ''
        let renderContext.namedStep[ name ] = post
    endif



    if built || a:action ==# 'clear'
        call s:RemoveCurrentMarks()

    else
        let renderContext.history += [ {
                    \'item' : renderContext.item,
                    \'leadingPlaceHolder' : renderContext.leadingPlaceHolder } ]
    endif


    return 0
endfunction "}}}

fun! s:RemoveCurrentMarks() "{{{
    let renderContext = b:xptemplateData.renderContext
    let item = renderContext.item
    let leader = renderContext.leadingPlaceHolder


    " TODO using XPMremoveMarkStartWith
    call XPMremoveStartEnd( leader.mark )
    if has_key( leader, 'editMark' )
        call XPMremoveStartEnd( leader.editMark )
    endif

    for ph in item.placeHolders
        call XPMremoveStartEnd( ph.mark )
    endfor
endfunction "}}}

fun! s:ApplyPostFilter() "{{{

    " *) Apply Group-scope post filter to leading place holder.
    " *) Following place holders are updated by trying filter on the following
    " order: ph.postFilter, or ontime filter, of the group-scope post filter.
    "
    " Thus, some place holder may be filtered twice.
    "

    let rctx = b:xptemplateData.renderContext


    let rctx.activeLeaderMarks = 'mark'

    let posts  = rctx.snipSetting.postFilters
    let name   = rctx.item.name
    let leader = rctx.leadingPlaceHolder
    let marks  = rctx.leadingPlaceHolder[ rctx.activeLeaderMarks ]

    let rctx.phase = 'post'

    let typed = xpt#util#TextBetween( XPMposStartEnd( marks ) )

    " NOTE: some post filter need the typed value
    if rctx.item.name != ''
        let rctx.namedStep[rctx.item.name] = typed
    endif

    call s:log.Log("before post filtering, tmpl:\n" . xpt#util#TextBetween( XPMposStartEnd( rctx.marks.tmpl ) ) )

    let groupPostFilter  = get( posts, name, g:EmptyFilter )
    let leaderPostFilter = get( leader, 'postFilter', g:EmptyFilter )

    let filter = groupPostFilter is g:EmptyFilter
          \ ? leaderPostFilter
          \ : groupPostFilter

    call s:log.Log("name:".name)
    call s:log.Log("typed:".typed)
    call s:log.Log('group post filter :' . string(groupPostFilter))
    call s:log.Log('leader post filter :' . string(leaderPostFilter))

    let hadBuilt = 0
    " TODO per-place-holder filter
    " check by 'groupPostFilter' is ok
    if filter isnot g:EmptyFilter

        let flt_rst = s:EvalPostFilter( filter, typed, leader )

        " name of marks between which content should be replaced
        let mark_name = s:GetPHReplacingMarkName(flt_rst)
        let marks = rctx.leadingPlaceHolder[mark_name]

        let ori_flt_rst = copy( flt_rst )
        call s:log.Log( 'text=' . get(flt_rst, 'text') )

        " TODO do not replace if no change made
        call XPMsetLikelyBetween( marks.start, marks.end )
        if flt_rst.rc != 0
            if has_key( flt_rst, 'text' )

                if flt_rst.text !=# typed

                    let [ start, end ] = XPMposStartEnd( marks )
                    call s:log.Debug( 'before replace, marks=' . XPMallMark() )

                    " if not innerMarks, repalcement covering marks would
                    " destroy marks.
                    if mark_name == 'mark'
                        call s:RemoveEditMark( leader )
                    endif
                    call xpt#settingswitch#Switch(b:xptemplateData.settingWrap)

                    let text = s:IndentFilterText(flt_rst, start)
                    call XPreplace( start, end, text )
                    call s:log.Debug( 'after replace, marks=' . XPMallMark() )
                endif
            endif

            if flt_rst.action == 'build'
                " TODO extract to function

                let rctx.firstList = []
                let buildrc = s:BuildPlaceHolders( marks )

                if 0 > buildrc
                    return [ s:Crash(), 1 ]
                endif

                " bad name , 'alreadyBuilt' ?
                let hadBuilt = 0 < buildrc

                " change back the phase
                let rctx.phase = 'post'
            endif
        endif
    endif

    " after indent segment, there is something
    if groupPostFilter is g:EmptyFilter
        call s:UpdateFollowingPlaceHoldersWith( typed, {} )
        return [ typed, hadBuilt ]

    else
        call s:UpdateFollowingPlaceHoldersWith( typed, { 'post' : ori_flt_rst } )
        if hadBuilt
            return [ typed, hadBuilt ]
        else
            return [ get(flt_rst, 'text', typed), hadBuilt ]
        endif
    endif
endfunction "}}}

fun! s:RemoveEditMark( ph ) "{{{
    if has_key( a:ph, 'editMark' )
        call XPMremoveStartEnd( a:ph.editMark )
        let a:ph.innerMarks = a:ph.mark
        unlet a:ph.editMark
    endif
endfunction "}}}

fun! s:EvalPostFilter( filter, typed, leader ) "{{{
    let renderContext = b:xptemplateData.renderContext

    let pos = XPMpos( a:leader.mark.start )
    let pos[ 1 ] = 1
    let startMark = XPMmarkAfter( pos )
    let flt_rst = s:EvalFilter( a:filter, [
          \     renderContext.ftScope.funcs,
          \     renderContext.snipSetting.variables,
          \     { '$UserInput' : a:typed } ] )

    call s:log.Log("post_value:\n", string(a:filter))

    return flt_rst
endfunction "}}}


fun! s:GotoNextItem() "{{{
    let action = s:DoGotoNextItem()

    " restore 'wrap'
    call xpt#settingswitch#Restore(b:xptemplateData.settingWrap)

    call s:log.Log("action=" . action)
    return action
endfunction "}}}

" TODO rename me
fun! s:DoGotoNextItem() "{{{
    " @return   insert mode typing action

    let renderContext = b:xptemplateData.renderContext

    let placeHolder = s:ExtractOneItem()
    call s:log.Log( "next placeHolder=" . string( placeHolder ) )

    call s:log.Debug( XPMallMark() )


    if placeHolder == s:nullDict
        call cursor( XPMpos( renderContext.marks.tmpl.end ) )
        " NOTE: FinishRendering does not return any action
        return s:FinishRendering(1)
    endif

    call s:log.Log("ExtractOneItem:".string(placeHolder))
    call s:log.Log("leadingPlaceHolder pos:".string(XPMpos( placeHolder.mark.start )))

    let phPos = XPMpos( placeHolder.mark.start )
    if phPos == [0, 0]
        " error found no position of mark
        " call s:log.Error( 'failed to find position of mark:' . placeHolder.mark.start )
        return s:Crash('failed to find position of mark:' . placeHolder.mark.start)
    endif

    call s:log.Log( "all marks:" . XPMallMark() )




    let leader =  renderContext.leadingPlaceHolder
    let leaderMark = leader.innerMarks

    call XPMsetLikelyBetween( leaderMark.start, leaderMark.end )

    if renderContext.item.processed
        " shift back and then shift forward
        let renderContext.phase = 'fillin'
        " TODO re-popup if needed

        return s:SelectCurrent()
    endif


    let oldRenderContext = renderContext


    let postaction = s:InitItem()

    " InitItem may change template stack
    let renderContext = b:xptemplateData.renderContext
    let leader = renderContext.leadingPlaceHolder

    " TODO extract following part to function

    if renderContext.processing
          \ && empty( renderContext.itemList )
          \ && !has_key( renderContext.snipSetting.postFilters, renderContext.item.name )
          \ && !has_key( leader, 'postFilter' )
          \ && empty( renderContext.item.placeHolders )
          \ && XPMpos( leader.mark.end ) == XPMpos( renderContext.marks.tmpl.end )
          \ && postaction !~ ''

        " NOTE: FinishRendering does not return any action
        let pp = s:FinishRendering()
        return postaction

    endif

    call s:log.Log( 'after InitItem, postaction='.postaction )

    if !renderContext.processing
        return postaction
    endif

    try
        call XPMsetLikelyBetween( leader.mark.start, leader.mark.end )
    catch /.*/
        " Maybe crashed
        return s:Crash()
    endtry

    call s:log.Log( 'current PH is key?=' . renderContext.leadingPlaceHolder.isKey )


    if postaction == ''

        if oldRenderContext == renderContext || oldRenderContext.level < renderContext.level
            call cursor( XPMpos( renderContext.leadingPlaceHolder.innerMarks.end ) )
        endif

        return ''

    else
        return postaction
    endif

endfunction "}}}

fun! s:ExtractOneItem() "{{{

    let renderContext = b:xptemplateData.renderContext
    let itemList = renderContext.itemList


    let [ renderContext.item, renderContext.leadingPlaceHolder ] = [ {}, {} ]

    if empty( itemList )
        return s:nullDict
    endif

    let item = itemList[ 0 ]

    let renderContext.itemList = renderContext.itemList[ 1 : ]

    let renderContext.item = item

    if empty( item.placeHolders ) && item.keyPH == s:nullDict
        call XPT#warn( "item without placeholders!" )
        return s:nullDict
    endif


    " TODO when update, avoid updating leadingPlaceHolder
    if item.keyPH == s:nullDict
        let renderContext.leadingPlaceHolder = item.placeHolders[0]
        let item.placeHolders = item.placeHolders[1:]
    else
        let renderContext.leadingPlaceHolder = item.keyPH

    endif

    return renderContext.leadingPlaceHolder

endfunction "}}}

fun! s:HandleDefaultValueAction( flt_rst ) "{{{

    let x = b:xptemplateData
    let rctx = x.renderContext
    let leader = rctx.leadingPlaceHolder

    call s:log.Log( "type is " . type( a:flt_rst ). ' {} type is ' . type( {} ) )

    if a:flt_rst.action ==# 'expandTmpl'
        " let rctx.item.behavior.gotoNextAtOnce = 1


        " do NOT need to update position
        " TODO innerMarks ?
        let marks = leader.mark
        call XPreplace(XPMpos( marks.start ), XPMpos( marks.end ), '')
        call XPMsetLikelyBetween( marks.start, marks.end )
        return XPTemplateStart(0, {'startPos' : getpos(".")[1:2], 'tmplName' : a:flt_rst.tmplName})

    elseif a:flt_rst.action ==# 'pum'
        return s:DefaultValuePumHandler( rctx, a:flt_rst )

    elseif a:flt_rst.action ==# 'finishTemplate'

        return s:ActionFinish( rctx, a:flt_rst )

    elseif a:flt_rst.action ==# 'build'

        if s:FillinLeader(a:flt_rst) is s:BROKEN
              \ || s:BuildLeaderText(a:flt_rst) is s:BROKEN
            return s:BROKEN
        endif

        return s:GotoNextItem()

    elseif a:flt_rst.action ==# 'text'

        if s:FillinLeader(a:flt_rst) is s:BROKEN
            return s:BROKEN
        endif

    else
        if s:FillinLeader(a:flt_rst) is s:BROKEN
            return s:BROKEN
        endif
    endif


    if a:flt_rst.nav == 'next'
        if x.renderContext.processing
            let postaction =  s:ShiftForward( '' )
            return postaction
        else
            return ''
        endif
    endif

    return s:SelectCurrent()

endfunction "}}}

fun! s:GetLeaderOpPos(flt_rst) "{{{
    let marks = s:GetLeaderOpMarks(a:flt_rst)
    let [ s, e ] = XPMposStartEnd( marks )
    return [ s, e ]
endfunction "}}}

fun! s:GetLeaderOpMarks(flt_rst) "{{{
    " returns ph.innerMarks or marks
    let rctx = b:xptemplateData.renderContext
    let mark_name = s:GetPHReplacingMarkName(a:flt_rst)

    return rctx.leadingPlaceHolder[ mark_name ]
endfunction "}}}

fun! s:GetPHReplacingMarkName(flt_rst) "{{{
    let rctx = b:xptemplateData.renderContext

    let mark_name = get(a:flt_rst, 'marks')
    if mark_name is 0
        let mark_name = xpt#rctx#DefaultMarks(rctx)
    endif
    return mark_name
endfunction "}}}

fun! s:ActionFinish( renderContext, flt_rst ) "{{{

    let rctx = b:xptemplateData.renderContext

    let [ start, end ] = s:GetLeaderOpPos(a:flt_rst)

    call s:log.Debug( "start, end=" . string( [ start, end ] ) )
    call s:log.Debug( "start line=" . string( getline( start[0] ) ) )

    if start[ 0 ] != 0 && end[ 0 ] != 0
        call s:log.Debug( "flt_rst.rc= ".string( a:flt_rst.rc ) )
        call s:log.Debug( "flt_rst= ".string( a:flt_rst ) )
        " marks are not deleted during user edit
        if a:flt_rst.rc isnot 0

            " do NOT need to update position

            if has_key( a:flt_rst, 'text' )
                let text = s:IndentFilterText( a:flt_rst, start )
                call s:log.Debug( "text=" . string( text ) . len( text ) )
                call XPreplace( start, end, text )
            endif
        endif
    endif

    if s:FinishCurrent( '' ) < 0
        return ''
    endif


    " TODO bad
    call cursor( XPMpos( rctx.leadingPlaceHolder.mark.end ) )

    let xptObj = b:xptemplateData

    " TODO controled by behavior is better?
    " NOTE: XXX TODO!!!
    if empty( xptObj.stack )
          \ || 1
        return s:FinishRendering()
    else
        " TODO for cursor item in nested template, this is ok. what if
        " need to select something or doing something else?
        return ''
    endif

endfunction "}}}

fun! s:FillinLeader(flt_rst) "{{{
    let x = b:xptemplateData
    let rctx = x.renderContext

    let mark_name = s:GetPHReplacingMarkName(a:flt_rst)
    let marks = rctx.leadingPlaceHolder[ mark_name ]
    let [ s, e ] = XPMposStartEnd( marks )

    if s[0] == 0 || e[0] == 0
        call s:Crash('leader marks not found:' . string(mark_name))
        return s:BROKEN
    endif

    if a:flt_rst.rc is 0
        return s:NONE
    endif

    if has_key( a:flt_rst, 'text' )

        call xpt#settingswitch#Switch(b:xptemplateData.settingWrap)

        let text = s:IndentFilterText( a:flt_rst, s )
        call s:log.Debug( "text to fillin leader=" . string( text ) . len( text ) )
        call XPreplace( s, e, text )
    endif

    call s:XPTupdate()

    return s:DONE
endfunction "}}}

fun! s:BuildLeaderText(flt_rst) "{{{

    let rctx = b:xptemplateData.renderContext
    let mark_name = s:GetPHReplacingMarkName(a:flt_rst)
    let marks = rctx.leadingPlaceHolder[mark_name]

    if a:flt_rst.action == 'build'

        let build_rc = s:BuildPlaceHolders( marks )
        call s:log.Log( "build_rc=" . string( build_rc ) )

        if build_rc is s:BROKEN
            call s:Crash('building place holder failed')

        elseif build_rc is s:BUILT
            call s:RemoveCurrentMarks()
        end

        return build_rc
    end
    return s:NONE
endfunction "}}}

fun! s:DefaultValuePumHandler( renderContext, flt_rst ) "{{{

    let pumlen = len( a:flt_rst.pum )

    if pumlen > 1
        return s:DefaultValueShowPum( a:renderContext, a:flt_rst )
    endif

    if pumlen == 0
        let a:flt_rst.text = ''
    elseif pumlen == 1
        let a:flt_rst.text = a:flt_rst.pum[0]
    endif

    if s:FillinLeader(a:flt_rst) is s:BROKEN
        return s:BROKEN
    endif

    return s:SelectCurrent()

endfunction "}}}

fun! s:DefaultValueShowPum( renderContext, flt_rst ) "{{{

    let leader = a:renderContext.leadingPlaceHolder
    let [ start, end ] = XPMposStartEnd( leader.innerMarks )

    call XPreplace( start, end, '')
    call cursor(start)

    call s:CallPlugin( 'ph_pum', 'before' )

    " to pop up, but do not enlarge matching, thus empty string is selected at first
    " if only word listed,  do callback at once.
    let pumsess = XPPopupNew( s:ItemPumCB, {}, a:flt_rst.pum )
    call pumsess.SetAcceptEmpty( get( a:flt_rst, 'acceptEmpty',  g:xptemplate_ph_pum_accept_empty ) )
    call pumsess.SetOption( {
          \ 'tabNav'      : g:xptemplate_pum_tab_nav } )

    return pumsess.popup( col("."), { 'doCallback' : 1, 'enlarge' : 0 } )

endfunction "}}}

" return type action
fun! s:InitItem() " {{{

    let renderContext = b:xptemplateData.renderContext
    let currentItem = renderContext.item
    let leaderMark = renderContext.leadingPlaceHolder.innerMarks

    let currentItem.initValue = xpt#util#TextBetween( XPMposStartEnd( leaderMark ) )

    call xpt#rctx#SwitchPhase( renderContext, s:renderPhase.iteminit )


    let postaction = s:ApplyDefaultValue()


    " maybe changed
    let renderContext = b:xptemplateData.renderContext

    " NOTE: InitItem() may change current item to next one
    if renderContext.processing && currentItem == renderContext.item
        let renderContext.item.initValue = xpt#util#TextBetween( XPMposStartEnd( leaderMark ) )
    endif

    if renderContext.phase == s:renderPhase.iteminit
        " not finished by default value
        call s:InitItemMapping()
        call s:InitItemTempMapping()
        call xpt#rctx#SwitchPhase( renderContext, s:renderPhase.fillin )
    endif

    return postaction

endfunction " }}}

fun! s:ApplyDefaultValue() "{{{

    " TODO place holder default value with higher priority!
    let rctx = b:xptemplateData.renderContext
    let leader = rctx.leadingPlaceHolder
    let defs = rctx.snipSetting.defaultValues

    if has_key( defs, leader.name ) && defs[ leader.name ].force
        let filter = defs[ leader.name ]
    else
        let filter =
              \ get( leader, 'ontimeFilter',
              \     get( defs, leader.name,
              \         g:EmptyFilter ) )
    endif

    if filter is g:EmptyFilter
        " to update the edge to following place holder
        call s:XPTupdate()
        return s:SelectCurrent()
    endif

    let rctx.activeLeaderMarks = 'innerMarks'

    call s:log.Debug( 'filter=' . string( filter ) )

    let typed = xpt#util#TextBetween( XPMposStartEnd( leader.innerMarks ) )
    let flt_rst = s:EvalFilter( filter, [
          \     rctx.ftScope.funcs,
          \     rctx.snipSetting.variables,
          \     { '$UserInput': typed } ] )


    if flt_rst.rc is 0
        return s:SelectCurrent()
    endif

    return s:HandleDefaultValueAction( flt_rst )

endfunction "}}}

fun! XPTmappingEval( str ) "{{{
    if pumvisible()
        if XPPhasSession()
            return XPPend() . "\<C-r>=XPTmappingEval(" . string(a:str) . ")\<CR>"
        else
            return "\<C-v>\<C-v>\<BS>\<C-r>=XPTmappingEval(" . string(a:str) . ")\<CR>"
        endif
    endif

    " If pum is visible when something typed, updating must be made because
    " update is not triggered when pum is visible
    let rc = s:XPTupdate()

    if rc != 0
        return ''
    endif


    " TODO startPos is current pos or start of mark?

    let x = b:xptemplateData

    let typed = xpt#util#TextBetween(
          \ XPMposStartEnd(
          \     x.renderContext.leadingPlaceHolder.mark ) )


    let filter = xpt#flt#New( 0, a:str )
    let flt_rst = s:EvalFilter( filter, [
          \     x.renderContext.ftScope.funcs,
          \     x.renderContext.snipSetting.variables,
          \  { '$UserInput' : typed } ] )

    if flt_rst.rc is 0
        return ''
    endif

    let postAction = s:HandleMapAction( flt_rst )
    call s:log.Log( 'postAction=' . postAction )

    return postAction

endfunction "}}}

fun! s:InitItemMapping() "{{{
    let renderContext = b:xptemplateData.renderContext
    " TODO use renderContext.setting
    let mappings = renderContext.snipObject.setting.mappings
    let item = renderContext.item

    if has_key( mappings, item.name )

        call xpt#msvr#Save( mappings[ item.name ].saver )

        for [ key, mapping ] in items( mappings[ item.name ].keys )
            " TODO not good
            exe 'inoremap <silent> <buffer>' key '<C-r>=XPTmappingEval(' string( mapping.text ) ')<CR>'
        endfor
    endif

endfunction "}}}

fun! s:InitItemTempMapping() "{{{

    let renderContext = b:xptemplateData.renderContext
    let mappings = renderContext.tmpmappings

    if !has_key( mappings, 'saver' )
        return
    endif


    for keys in mappings.keys
        call xpt#msvr#Add( mappings.saver, 'i', keys[0] )
    endfor

    call xpt#msvr#Save( mappings.saver )

    for keys in mappings.keys
        exe 'inoremap <silent> <buffer>' keys[0] '<C-r>=XPTmappingEval(' string( keys[1] ) ')<CR>'
    endfor

endfunction "}}}

fun! XPTmapKey( left, right ) "{{{


    let renderContext = b:xptemplateData.renderContext
    let mappings = renderContext.tmpmappings

    if renderContext.phase != s:renderPhase.iteminit
        call s:log.Warn( "Not in [iteminit] phase, mapping ingored" )
        return
    endif

    if !has_key( mappings, 'saver' )
        let mappings.saver = xpt#msvr#New(1)
        let mappings.keys = []
    endif

    call add( mappings.keys, [ a:left, a:right ] )

endfunction "}}}

fun! s:ClearItemMapping( rctx ) "{{{

    let renderContext = a:rctx

    let mappings = renderContext.tmpmappings
    if has_key( mappings, 'saver' )
        call xpt#msvr#Restore( mappings.saver )
    endif


    let mappings = renderContext.snipObject.setting.mappings
    let item = renderContext.item

    if has_key( mappings, item.name )
        call xpt#msvr#Restore( mappings[ item.name ].saver )
    endif

endfunction "}}}

fun! s:SelectCurrent() "{{{
    let ph = b:xptemplateData.renderContext.leadingPlaceHolder
    let marks = ph.innerMarks

    let [ ctl, cbr ] = XPMposStartEnd( marks )


    if ctl == cbr
        call cursor( ctl )
        call XPMupdateStat()
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

        " Because it feed keys. make sure it is the last step of rendering
        " thus no more key sequences generated
        "
        " CursorMoved called before feedkeys. thus test script can not be
        " aware of mode switched to select mode thus it does not go.
        if &selectmode =~ 'cmd'
            call feedkeys( "\<esc>gv", 'nt' )
        else
            call feedkeys( "\<esc>gv\<C-g>", 'nt' )
        endif

        call XPMupdateStat()
        return ''

        " NOTE: Using <C-R>= output special chars like \<esc> \<C-v> cause
        " gvim7.3 on ubuntu 10.10 amd64 become lagger each time expanding a
        " snippet.
        " Now use feedkeys instead.

        " " Weird, but that's only way to select content
        " return "\<esc>gv\<C-g>"
    endif

endfunction "}}}

fun! s:EvalFilter( filter, closures ) "{{{

    " TODO EvalFilter might be called from non-rendering phase, is there a snipObject?
    let rctx = b:xptemplateData.renderContext
    let snip = rctx.snipObject

    let r = xpt#flt#Eval( snip, a:filter, a:closures )
    call s:LoadFilterActionSnippet( r )
    call s:log.Debug("evaled filter rst: " . string(r))
    return r

endfunction "}}}

fun! s:LoadFilterActionSnippet( flt_rst ) "{{{

    let renderContext = b:xptemplateData.renderContext

    if has_key( a:flt_rst, 'snippet' )

        let allsnip = renderContext.ftScope.allTemplates
        let snipname = a:flt_rst.snippet

        if has_key( allsnip, snipname )
            let snip = allsnip[ snipname ]
            call s:ParseSnippet( snip, renderContext.ftScope )
            call s:MergeSetting( renderContext.snipSetting,
                  \ snip.setting )
            let a:flt_rst.text = snip.snipText
        else
            call XPT#warn( 'snippet "' . snipname . '" not found' )
        end
    end
endfunction "}}}

fun! s:Goback() "{{{
    let renderContext = b:xptemplateData.renderContext
    " call cursor( XPMpos( renderContext.leadingPlaceHolder.mark.end ) )
    " return ''

    return s:SelectCurrent()
endfunction "}}}

fun! s:XPTinitMapping() "{{{

    " Note: <bs> works the same with <C-h>, but only masking <bs> in buffer
    " level does mask <c-h>. So that <bs> still works with old mapping
    let literal_chars = ''
          \ . 'abcdefghijklmnopqrstuvwxyz'
          \ . 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
          \ . '1234567890'
          \ . '!@#$%^&*()'
          \ . '`~-_=+[{]}\;:"'',<.>/?'
    let literalKeys = split( literal_chars, '\V\s\*' )
    let literalKeys = map( literalKeys, '"s_".v:val' )
          \ + [
          \     's_<SPACE>',
          \     's_\|',
          \   ]

    let b:mapSaver = xpt#msvr#New(1)
    call xpt#msvr#AddList( b:mapSaver,
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
          \ 'i_<CR>',
          \
          \ 's_<DEL>',
          \ 's_<BS>',
          \)

    if g:xptemplate_nav_next_2 != g:xptemplate_nav_next
        call xpt#msvr#AddList( b:mapSaver,
              \ 'i_' . g:xptemplate_nav_next_2,
              \ 's_' . g:xptemplate_nav_next_2,
              \ )

    endif

    let b:mapLiteral = xpt#msvr#New(1)
    call xpt#msvr#AddList( b:mapLiteral, literalKeys )


    " 'indentkeys' causes problem that it changes indent or converts tabs/spaces
    " that xpmark can not track
    "
    " *<Return> reindent current line
    let b:xptemplateData.settingSwitch = xpt#settingswitch#New()
    call xpt#settingswitch#AddList(b:xptemplateData.settingSwitch,
          \[ '&l:textwidth', '0' ],
          \[ '&l:lazyredraw', '1' ],
          \[ '&l:indentkeys', { 'exe' : 'setl indentkeys-=*<Return>' } ],
          \[ '&l:cinkeys', { 'exe' : 'setl cinkeys-=*<Return>' } ],
          \)
    " \[ '&l:indentkeys', { 'exe' : 'setl indentkeys-=*<Return> | setl indentkeys-=o' } ],
    " \[ '&l:cinkeys', { 'exe' : 'setl cinkeys-=*<Return> | setl cinkeys-=o' } ],

    " provent horizontal scroll when putting raw snippet onto screen before building
    let b:xptemplateData.settingWrap = xpt#settingswitch#New()
    call xpt#settingswitch#Add(b:xptemplateData.settingWrap, '&l:wrap', '1')

endfunction "}}}


fun! s:XPTCR() "{{{
    let [ l, c ] = [ line( "." ), col( "." ) ]

    let textFollowing = getline( l )[ c - 1 : ]

    if textFollowing !~ '\V\^\s' || !&autoindent
        return "\<CR>"
    else
        let spaces = matchstr( textFollowing, '\V\^\s\+' )
        return "\<CR>" . spaces . repeat( "\<Left>", len( spaces ) )
    endif
endfunction "}}}

fun! s:ApplyMap() " {{{

    let x = b:xptemplateData
    let renderContext = x.renderContext

    " if exists( ':AcpLock' )
    "     AcpLock
    " endif


    call xpt#settingswitch#Switch(b:xptemplateData.settingSwitch)


    call xpt#msvr#Save( b:mapSaver )
    call xpt#msvr#Save( b:mapLiteral )

    call xpt#msvr#UnmapAll( b:mapSaver )
    call xpt#msvr#Literalize( b:mapLiteral, { 'insertAsSelect' : 1 } )

    exe 'imap <silent> <buffer> <CR>' g:xptemplate_hook_before_cr . '<Plug>XPT_map_CR'

    " TODO map should distinguish between 'selection'
    " <C-v><C-v><BS> force pum to close
    exe 'inoremap <silent> <buffer>' g:xptemplate_nav_prev   '<C-v><C-v><BS><C-r>=<SID>ShiftBackward()<CR>'

    " exe 'inoremap <silent> <buffer>' g:xptemplate_nav_next   '<C-v><C-v><BS><C-r>=<SID>ShiftForward("")<CR>'
    exe 'inoremap <silent> <buffer>' g:xptemplate_nav_next   '<C-r>=<SID>ShiftForward("")<CR>'
    exe 'snoremap <silent> <buffer>' g:xptemplate_nav_cancel '<Esc>i<C-r>=<SID>ShiftForward("clear")<CR>'

    exe 'nnoremap <silent> <buffer>' g:xptemplate_goback     'i<C-r>=<SID>Goback()<CR>'
    exe 'inoremap <silent> <buffer>' g:xptemplate_goback     ' <C-v><C-v><BS><C-r>=<SID>Goback()<CR>'

    snoremap <silent> <buffer> <Del> <Del>i
    snoremap <silent> <buffer> <BS> d<BS>

    if g:xptemplate_nav_next_2 != g:xptemplate_nav_next
        exe 'inoremap <silent> <buffer>' g:xptemplate_nav_next_2   '<C-v><C-v><BS><C-r>=<SID>ShiftForward("")<CR>'
        exe 'snoremap <silent> <buffer>' g:xptemplate_nav_next_2   '<Esc>`>a<C-r>=<SID>ShiftForward("")<CR>'
    endif

    if &selection == 'inclusive'
        " snoremap <silent> <buffer> <BS> <esc>`>a<BS>
        exe 'snoremap <silent> <buffer>' g:xptemplate_nav_prev   '<Esc>`>a<C-r>=<SID>ShiftBackward()<CR>'
	exe 'snoremap <silent> <buffer>' g:xptemplate_nav_next   '<Esc>`>a<C-r>=<SID>ShiftForward("")<CR>'
        exe "snoremap <silent> <buffer> ".g:xptemplate_to_right." <esc>`>a"
    else
        " snoremap <silent> <buffer> <BS> <esc>`>i<BS>
        exe 'snoremap <silent> <buffer>' g:xptemplate_nav_prev   '<Esc>`>i<C-r>=<SID>ShiftBackward()<CR>'
	exe 'snoremap <silent> <buffer>' g:xptemplate_nav_next   '<Esc>`>i<C-r>=<SID>ShiftForward("")<CR>'
        exe "snoremap <silent> <buffer> ".g:xptemplate_to_right." <esc>`>i"
    endif

endfunction " }}}

fun! s:ClearMap() " {{{

    call xpt#settingswitch#Restore(b:xptemplateData.settingSwitch)

    call xpt#msvr#Restore( b:mapLiteral )
    call xpt#msvr#Restore( b:mapSaver )

    " if exists( ':AcpUnlock' )
    "     try
    "         AcpUnlock
    "     catch /.*/
    "     endtry
    " endif

endfunction " }}}

fun! XPTbufData() "{{{
    if !exists( 'b:xptemplateData' )
        call XPTemplateInit()
    endif
    return b:xptemplateData
endfunction "}}}

fun! XPTnewSnipScope( filename )
    let sf = xpt#snipfile#New(a:filename)
    let b:xptemplateData.snipFileScope = sf
    return sf
endfunction

fun! XPTsnipScope()
  return b:xptemplateData.snipFileScope
endfunction

fun! XPTemplateInit() "{{{

    if exists( 'b:xptemplateData' )
        return
    endif

    call xpt#buf#New()

    " TODO is this the right place to do that?
    call XPMsetBufSortFunction( function( 'XPTmarkCompare' ) )

    call s:XPTinitMapping()
endfunction "}}}

fun! s:SynNameStack(l, c) "{{{
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
endfunction "}}}


fun! s:UpdateFollowingPlaceHoldersWith( contentTyped, option ) "{{{

    let renderContext = b:xptemplateData.renderContext
    call s:log.Debug( 'option=' . string( a:option ) )
    call s:log.Debug( 'phase=' . renderContext.phase )

    let useGroupPost = renderContext.phase == 'post' && has_key( a:option, 'post' )
    if useGroupPost
        let group_flt_rst = a:option.post
    endif

    call XPRstartSession()

    let phList = renderContext.item.placeHolders
    try
        for ph in phList
            call s:log.Log( 'name=' . ph.name )
            let flt = renderContext.phase == 'post'
                  \ ? get( ph, 'postFilter',
                  \     get( ph, 'ontimeFilter',  g:EmptyFilter ) )
                  \ : get( ph, 'ontimeFilter', g:EmptyFilter )


            call s:log.Log( 'UpdateFollowingPlaceHoldersWith : filter=' . string( flt ) )

            let phStartPos = XPMpos( ph.mark.start )
            let [ phln, phcol ] = phStartPos

            if flt isnot g:EmptyFilter

                let flt_rst = s:EvalFilter( flt, [
                      \     renderContext.ftScope.funcs,
                      \     renderContext.snipSetting.variables,
                      \     { '$UserInput' : a:contentTyped } ] )


                " TODO ontime flt action support?

            elseif useGroupPost
                let flt_rst = copy( group_flt_rst )
            else
                let flt_rst = { 'nIndent': -XPT#getIndentNr( phln, phcol ),
                      \         'text': a:contentTyped }
            endif
            let flttext = s:IndentFilterText(flt_rst, phStartPos)


            " TODO replace only when filter applied or filter.text has line break
            let text = xpt#util#TextBetween( XPMposStartEnd( ph.mark ) )
            if text !=# flttext
                call XPreplaceByMarkInternal( ph.mark.start, ph.mark.end, flttext )
            endif

            call s:log.Debug( 'after update 1 place holder:', xpt#util#TextBetween( XPMposStartEnd( renderContext.marks.tmpl ) ) )
        endfor
    catch /.*/
        call XPT#error( v:exception )
    finally
        call XPRendSession()
    endtry

endfunction "}}}

fun! s:Crash(...) "{{{

    let msg = "XPTemplate session ends: " . join( a:000, "\n" )

    call XPPend()

    let x = b:xptemplateData

    call s:ClearItemMapping( x.renderContext )

    while !empty( x.stack )
        let rctx = remove( x.stack, -1 )
        call s:ClearItemMapping( rctx )
    endwhile

    call s:ClearMap()

    let x.stack = []
    let x.renderContext = xpt#rctx#New( x )
    call XPMflushWithHistory()

    call XPT#warn( msg )

    call s:CallPlugin( 'finishAll', 'after' )

    " no post typing action
    return ''
endfunction "}}}

" fun! s:SkipSpecialBuf() "{{{
"     if bufname( '%' ) == "[Command Line]"
"         return 1
"     endif

"     if &buftype == 'quickfix'
"         return 1
"     endif

"     return 0
" endfunction "}}}

fun! s:XPTupdateTyping() "{{{

    " if s:SkipSpecialBuf()
        " return 0
    " endif

    call s:log.Debug("start XPTupdateTyping")
    let rc = s:XPTupdate()

    if rc != 0
        return rc
    endif


    let renderContext = b:xptemplateData.renderContext

    if 'fillin' != renderContext.phase
        return rc
    endif

    call s:log.Debug( 'render phase=' . renderContext.phase )


    let leader = renderContext.leadingPlaceHolder
    let ontypeFilters = renderContext.snipSetting.ontypeFilters

    let flt = get( ontypeFilters, leader.name, g:EmptyFilter )

    if flt isnot g:EmptyFilter
        call s:HandleOntypeFilter( flt )
    endif

    return rc
endfunction "}}}

fun! s:HandleOntypeFilter( filter ) "{{{

    call s:log.Debug( 'handle filter=' . string( a:filter ) )

    let renderContext = b:xptemplateData.renderContext
    let leader = renderContext.leadingPlaceHolder
    let [ start, end ] = XPMposStartEnd( leader.mark )
    let contentTyped = xpt#util#TextBetween( [ start, end ] )

    let flt_rst = s:EvalFilter( a:filter, [
          \     renderContext.ftScope.funcs,
          \     renderContext.snipSetting.variables,
          \     { '$UserInput' : contentTyped } ] )


    if 0 is flt_rst.rc
        return
    endif

    if has_key( flt_rst, 'action' )
        call s:HandleOntypeAction( renderContext, flt_rst )
    endif

endfunction "}}}

fun! s:HandleOntypeAction( renderContext, flt_rst ) "{{{

    let postaction = s:HandleAction( a:flt_rst )

    if '' != postaction
        call feedkeys( postaction, 'n' )
    endif

endfunction "}}}

fun! s:HandleMapAction( flt_rst ) "{{{

    let rctx = b:xptemplateData.renderContext

    if a:flt_rst.action == 'finishTemplate'
        let postaction = s:ActionFinish( rctx, a:flt_rst )
        return postaction

    elseif a:flt_rst.action == ''
    endif

    let postaction = get(a:flt_rst, 'text', '')

    if a:flt_rst.nav == 'next'
        if rctx.processing
            let postaction .=  s:ShiftForward( '' )
            return postaction
        else
            return ''
        endif
    endif

    return postaction

endfunction "}}}
fun! s:HandleAction( flt_rst ) "{{{
    " NOTE: handle only leader's action

    let rctx = b:xptemplateData.renderContext
    let [ s, e ] = s:GetLeaderOpPos(a:flt_rst)

    let postaction = ''
    if a:flt_rst.action == 'text'

        if has_key( a:flt_rst, 'text' )

            call XPreplace( s, e, a:flt_rst.text )

        endif

    elseif a:flt_rst.action == 'finishTemplate'
        let postaction = s:ActionFinish( rctx, a:flt_rst )
        return postaction

    elseif a:flt_rst.action == ''
        " TODO other actions

    endif

    if a:flt_rst.nav == 'next'
        if rctx.processing
            let postaction =  s:ShiftForward( '' )
            return postaction
        else
            return ''
        endif
    endif

    return postaction

endfunction "}}}

fun! s:IsUpdateCondition( renderContext ) "{{{

    if a:renderContext.phase == 'uninit'
        call XPMflushWithHistory()
        return 0
    endif


    if !a:renderContext.processing
        " update XPM is necessary
        call XPMupdate()
        return 0
    endif

    return 1

endfunction "}}}

fun! s:UpdateMarksAccordingToLeaderChanges( renderContext ) "{{{

    let leaderMark = a:renderContext.leadingPlaceHolder.mark
    let innerMarks = a:renderContext.leadingPlaceHolder.innerMarks

    let [ start, end ] = XPMposList( leaderMark.start, leaderMark.end )

    if start[0] == 0 || end[0] == 0
        throw 'XPM:mark_lost:' . string( start[0] == 0 ? leaderMark.start : leaderMark.end )
    endif

    " call XPMsetLikelyBetween( leaderMark.start, leaderMark.end )
    if XPMhas( innerMarks.start, innerMarks.end )
        call XPMsetLikelyBetween( innerMarks.start, innerMarks.end )
    else
        call XPMsetLikelyBetween( leaderMark.start, leaderMark.end )
    endif

    let rc = XPMupdate()
    call s:log.Log( 'rc=' . string(rc) . ' phase=' . string(a:renderContext.phase) . ' strict=' . g:xptemplate_strict )

    if a:renderContext.phase == 'fillin'

        if rc is g:XPM_RET.updated
              \ || ( type( rc ) == type( [] )
              \      && ( rc[ 0 ] != leaderMark.start && rc[ 0 ] != innerMarks.start
              \        || rc[ 1 ] != leaderMark.end && rc[ 1 ] != innerMarks.end ) )

            if g:xptemplate_strict == 2

                throw 'XPT:changes outside of place holder'

            elseif g:xptemplate_strict == 1

                undo
                call XPMupdate()

                " TODO better hint
                " TODO allow user to move?

                call XPT#warn( "editing OUTSIDE place holder is not allowed whne g:xptemplate_strict=1, use " . g:xptemplate_goback . " to go back" )

                return g:XPT_RC.canceled
            else
                 " == 0
            endif
        endif
    endif

    return rc

endfunction "}}}

fun! s:XPTupdate() "{{{

    " NOTE: ctrlp plugin opens a window and XPTupdate will be triggered in new
    " window and just before BufEnter event triggered.
    call XPTemplateInit()

    let renderContext = b:xptemplateData.renderContext

    if !s:IsUpdateCondition( renderContext )
        return 0
    endif


    call s:log.Log( "current line=" . string( getline( "." ) ) )
    call s:log.Log( "XPTupdate called, mode:" . mode() )
    call s:log.Log( "marks before XPTupdate:\n" . XPMallMark() )


    try
        let rc = s:UpdateMarksAccordingToLeaderChanges( renderContext )
        if g:XPT_RC.canceled is rc
            return 0
        endif

        call s:DoUpdate( renderContext, rc )

        call s:log.Log( "marks after XPTupdate:\n" . XPMallMark() )
        return 0

    catch /^XP.*/
        call s:Crash( v:exception )
        return -1

    finally
        call XPMupdateStat()

    endtry

endfunction "}}}

fun! s:DoUpdate( renderContext, changeType ) "{{{

    let renderContext = a:renderContext

    let contentTyped = xpt#util#TextBetween( XPMposStartEnd( renderContext.leadingPlaceHolder.mark ) )

    " if contentTyped ==# renderContext.lastContent
    "     call s:log.Log( "nothing different typed" )
    "     return
    " endif

    call s:log.Log( "typed:" . contentTyped )

    call s:CallPlugin("update", 'before')

    " update items

    call s:log.Log( "-----------------------")
    call s:log.Log( 'current line=' . string( getline( "." ) ) )
    call s:log.Log( "tmpl:", xpt#util#TextBetween( XPMposStartEnd( renderContext.marks.tmpl ) ) )
    call s:log.Log( "lastContent=".renderContext.lastContent )
    call s:log.Log( "contentTyped=".contentTyped )

    " NOTE: sometimes, update is made before key mapping finished. Thus XPTupdate can not catch likely_matched result
    if type( a:changeType ) == type( [] )
          \ || a:changeType is g:XPM_RET.likely_matched
          \ || a:changeType is g:XPM_RET.no_updated_made

        call s:log.Log( "marks before updating following:\n" . XPMallMark() )

        " TODO optimize?
        " change taken in current focused place holder
        let relPos = s:RecordRelativePosToMark( [ line( '.' ), col( '.' ) ], renderContext.leadingPlaceHolder.mark.start )
        call s:UpdateFollowingPlaceHoldersWith( contentTyped, {} )
        call s:GotoRelativePosToMark( relPos, renderContext.leadingPlaceHolder.mark.start )

    else
        " TODO undo-redo handling
    endif

    call s:CallPlugin('update', 'after')

    let renderContext.lastContent = contentTyped

endfunction "}}}

fun! s:DoBreakUndo() "{{{
    if pumvisible()
        " force pum to show. to fix autocomplpop problem:div<C-\><space>
        return "\<UP>\<DOWN>"
    endif
    return "\<C-g>u"
endfunction "}}}

inoremap <silent> <Plug>XPTdoBreakUndo <C-r>=<SID>DoBreakUndo()<CR>
inoremap <silent> <Plug>XPT_map_CR <C-r>=<SID>XPTCR()<CR>

fun! s:BreakUndo() "{{{
    if mode() != 'i' || pumvisible()
        return
    endif
    call s:log.Debug( "BreakUndo" )
    let x = b:xptemplateData
    if x.renderContext.processing
        call feedkeys( "\<Plug>XPTdoBreakUndo", 'm' )
    endif
endfunction "}}}


" TODO using mark
fun! s:RecordRelativePosToMark( pos, mark ) "{{{
    let p = XPMpos( a:mark )
    if a:pos[0] == p[0]
        return [0, a:pos[1] - p[1]]
    else
        return [ a:pos[0] - p[0], a:pos[1] ]
    endif
endfunction "}}}

fun! s:GotoRelativePosToMark( rPos, mark ) "{{{
    let p = XPMpos( a:mark )
    if a:rPos[0] == 0
        call cursor( p[0], a:rPos[1] + p[1] )
    else
        call cursor( p[0] + a:rPos[0], a:rPos[1] )
    endif
endfunction "}}}

fun! s:XPTcheck() "{{{

    if !exists( 'b:xptemplateData' )
        call XPTemplateInit()
    endif

    let x = b:xptemplateData

    if x.wrap isnot ''
        let x.wrapStartPos = 0
        let x.wrap = ''
    endif

    call s:CallPlugin( 'insertenter', 'after' )

endfunction "}}}

fun! s:GetContextFT() "{{{
    if exists( 'b:XPTfiletypeDetect' )
        return b:XPTfiletypeDetect()
    elseif &filetype == ''
        return 'unknown'
    else
        return &filetype
    endif
endfunction "}}}

" TODO not good here to call XPTparseSnippets()
fun! s:GetContextFTObj() "{{{

    let x = b:xptemplateData
    let ft = s:GetContextFT()

    call xpt#parser#loadSpecialFiletype(ft)
    let ftScope = get( x.filetypes, ft, {} )

    return ftScope

endfunction "}}}

augroup XPT "{{{

    au!

    au BufEnter * call XPTemplateInit()

    au InsertEnter * call <SID>XPTcheck()

    au InsertEnter * call s:log.Debug('InsertEnter: ' . string(getline(".")))
    au InsertLeave * call s:log.Debug('InsertLeave: ' . string(getline(".")))

    au CursorMoved,CursorMovedI * call <SID>XPTupdateTyping()

    if g:xptemplate_strict == 1
        au CursorMovedI * call <SID>BreakUndo()
    endif

augroup END "}}}

fun! g:XPTaddPlugin(event, when, func) "{{{
    if has_key(s:plugins, a:event)
        call add(s:plugins[a:event][a:when], a:func)
    else
        throw "XPT does NOT support event:".a:event
    endif
endfunction "}}}

let s:plugins = {}
fun! s:CreatePluginContainer( ... ) "{{{
    for evt in a:000
        let s:plugins[evt] = { 'before' : [], 'after' : []}
    endfor
endfunction "}}}

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
            \'insertenter',
            \)
delfunc s:CreatePluginContainer

fun! s:CallPlugin(ev, when) "{{{
    let cnt = get(s:plugins, a:ev, {})
    let evs = get(cnt, a:when, [])
    if evs == []
        return
    endif

    let x = b:xptemplateData

    for XPTplug in evs
        call XPTplug(x, x.renderContext)
    endfor

endfunction "}}}

com! XPTreload call XPTreload()
com! XPTcrash call <SID>Crash()

let &cpo = s:oldcpo
