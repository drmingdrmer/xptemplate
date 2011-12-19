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
" KNOWING BUG: "{{{
"   sh: "else" snippet does not support 'indentkeys' setting.
"
" "}}}
"
" TODOLIST: "{{{
" in 0.4.8:
" TODO ( and type and press ")"  inside typed text cause it complete the whole snippet.
" TODO clear empty indent of wrapper
" TODO use \k instead of \w
" TODO move out all functions out of common.xpt.vim
" TODO in php, starting with empty file, { <CR> does not create indent.
" TODO finish ActionFinish
" TODO check super tab or other pum plugin before jump to next.
" TODO quote complete should break at once if user move cursor to other place.
" TODO multiple expandible or reference to expanded parts.
" TODO add version info to dist/
" TODO move all xpt files into one sub folder.
" TODO bug: in *.css: type: "* {<CR>" prodcues another "* }" at the next line.
" TODO duplicate snippet name check
" TODO remove log printed to ~/vim.log
" in future
" TODO when tracking snippet rendering, ignore leading spaces.
" TODO efficiently loading long snippet file
" TODO test vim 7.3
" TODO lazy load of scripts
" TODO add: be able to load textmate snippet or snipmate snippet.
" TODO add: <BS> at ph start to shift backward.
" TODO add: php snippet <% for .. %> in html
" TODO improve: 3 quotes in python
" TODO fix: register handling when snippet expand
" TODO goto next or trigger?
" TODO add: visual mode trigger.
" TODO fix: after undo, highlight is not cleared.
" TODO with strict = 0/1 XPT does not work well
" TODO add: XSET to set edge.
" TODO add: short snippet syntax
" TODO add: global shortcuts
" TODO add: context detect
" TODO fix: versionlize scripts
" TODO doc of ontype filters, XSET what|map
" TODO cross file support, .h and .cpp skeletion generator.
" TODO bug in 114.74, ' and then <C-n> complete, and then <C-y> accept, now ' is between complete start and complete end
" TODO xpreplace use SettingSwitch,
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
"
" Log of this version:
"
"
"   removed: hint format "hint=**" is no longer supported. Instead use quote. See more in doc
"   fix: slowly loading *.xpt.vim
"   fix: mistakely using $SPop in brackets snippet. It should be $SParg
"   fix: bug pre-parsing spaces
"   fix: bug that non-key place holder does not clear  '`' and '^'
"   fix: bug snippet starts with "..." repetition can not be rendered correctly.
"   fix: parse abbr setting at once as snippet loaded. parse inclusion at the first time snippet rendering.
"
"   add: g:xptemplate_highlight_nested
"   add: g:xptemplate_minimal_prefix_nested
"   TODO doc it
"   add: zen-code style snippet: supported with snippet-extention.
"   change: symbolic priority value changed. See more info in doc
"   change: Inclusion of snippet has been converted to function-call
"   change: Functions defined in common.xpt.vim now are moved to autoload/xpt/ftsc.vim.
"
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

com! -nargs=+ Assert call xpt#debug#Assert( <args>, <q-args> )

exe XPT#let_sid

let g:XPTact = {
      \ 'embed'         : 'embed',
      \ 'next'          : 'next',
      \ 'finishPH'      : 'finishTemplate',
      \ 'removePH'      : 'remove',
      \ 'trigger'       : 'expandTmpl',
      \ }


runtime plugin/xptemplate.conf.vim
runtime plugin/xptemplate.util.vim
runtime plugin/xpreplace.vim
runtime plugin/xpmark.vim
runtime plugin/xpopup.vim

exec XPT#importConst

let s:log = xpt#debug#Logger( 'warn' )
let s:log = xpt#debug#Logger( 'debug' )

call XPRaddPreJob( 'XPMupdateCursorStat' )
call XPRaddPostJob( 'XPMupdateSpecificChangedRange' )
call XPMsetUpdateStrategy( 'normalMode' )


" XXX Compatibility Maintaining "{{{
let g:FilterValue = {}
let g:FilterValue.New = function( 'xpt#flt#New' )
"}}}

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
let s:priorities = XPT#priorities
let s:expandablePattern     = '\V\S\+...\$'

exe XPT#importConst

fun! g:XPTapplyTemplateSettingDefaultValue( setting ) "{{{
    let s = a:setting
    let s.postQuoter        = get( s,           'postQuoter',   { 'start' : '{{', 'end' : '}}' } )
    let s.preValues.cursor  = get( s.preValues, 'cursor',       '$CURSOR_PH' )
endfunction "}}}


fun! s:SetDefaultFilters( ph ) "{{{
    let setting = b:xptemplateData.renderContext.snipSetting

    " post filters
    if !has_key( setting.postFilters, a:ph.name )
        let pfs = setting.postFilters

        if a:ph.name =~ '\V\w\+?'
            let pfs[ a:ph.name ] = g:FilterValue.New( 0, "EchoIfNoChange( '' )" )
        endif
    endif
endfunction "}}}


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

fun! s:pumCB.onEmpty(sess) "{{{
    if g:xptemplate_fallback ==? '<NOP>'
        call XPT#info( "XPT: No snippet matches" )
        return ''
    else
        let x = b:xptemplateData
        let x.fallbacks = [ [ "\<Plug>XPTfallback", 'feed' ] ] + x.fallbacks
        return xpt#util#Fallback( x.fallbacks )
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
" TODO filetype scope
fun! XPTemplateKeyword( val ) "{{{

    let x = b:xptemplateData

    " word characters are already valid.
    let val = substitute(a:val, '\w', '', 'g')
    let val = string( val )[ 1 : -2 ]
    let needEscape = '^\]-'


    let x.keywordList += split( val, '\v\s*' )
    call sort( x.keywordList )
    let x.keywordList = split( substitute( join( x.keywordList, '' ), '\v(.)\1+', '\1', 'g' ), '\v\s*' )


    let x.keyword = '\[0-9A-Za-z_' . escape( join( x.keywordList, '' ), needEscape ) . ']'

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
    let xp = b:xptemplateData.snipFileScope.ptn
    let xp.l = a:sl
    let xp.r = a:sr

    let b:xptemplateData.snipFileScope.ptn = xpt#snipf#GenPattern( b:xptemplateData.snipFileScope.ptn )
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

    let x = b:xptemplateData

    " TODO simplify it
    call xpt#st#Extend( a:setting )

    let name = a:name

    let xt = x.filetypes[ g:GetSnipFileFT() ].allTemplates
    let toSnip = get( xt, a:toWhich )

    if toSnip is 0
        return
    endif

    let setting = deepcopy(toSnip.setting)
    call xpt#util#DeepExtend( setting, a:setting )

    let prio = x.snipFileScope.priority

    let existed = get( xt, a:name, { 'priority': xpt#priority#Get( 'lowest' ) } )
    if existed.priority < prio
        return
    endif

    if has_key( xt, a:toWhich )

        let xt[ a:name ] = xpt#snip#New(
              \ a:name, toSnip.ftScope, toSnip.snipText, prio,
              \ setting, deepcopy(toSnip.ptn) )
        call s:UpdateNamePrefixDict( toSnip.ftScope, a:name )

        call xpt#st#Parse( xt[ a:name ].setting, xt[ a:name ] )

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
        let sc          = xpt#snipf#New( '' )
        let sc.priority = 0

        let a:x.__tmp_snip_scope = sc
    endif

    let a:x.__tmp_snip_scope.filetype = '' == a:ft ? 'unknown' : a:ft

    return a:x.__tmp_snip_scope
endfunction "}}}

" ********* XXX *********
fun! XPTemplate(name, str_or_ctx, ...) " {{{

    call xpt#snipf#Push()
    " @param String name			tempalte name
    " @param String context			[optional] context syntax name
    " @param String|List|FunCRef str		template string

    " using dictionary member instead of direct variable for type limit

    let x = b:xptemplateData

    " called from outside snippet file
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
          \ && !has_key(x.filetypes, 'unknown')

        call s:LoadSnippetFile( 'unknown/unknown' )

    endif

    if !has_key( x.filetypes, x.snipFileScope.filetype )
        " TODO create the ft
        return
    endif

    call XPTdefineSnippet( a:name, setting, snip )


    call xpt#snipf#Pop()

endfunction " }}}

fun! XPTdefineSnippet( name, setting, snip ) "{{{

    " TODO global shortcuts
    let name = a:name

    let x         = b:xptemplateData
    let ftScope   = x.filetypes[ x.snipFileScope.filetype ]
    let templates = ftScope.allTemplates
    let xp        = x.snipFileScope.ptn


    " TODO this is unnecessary if XPTdefineSnippet is always called from
    " snippet file.
    call xpt#st#Extend( a:setting )
    let templateSetting = a:setting

    if has_key( templateSetting, 'priority' )
        " TODO debug
        echom a:name
    endif

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

    " Compiler convert 4 spaces to 1 tab. And each tab should be converted to
    " 1 indent.
    let snip = xpt#util#ExpandTab( snip, &shiftwidth )

    call s:log.Log( "tmpl :name=" . a:name . " priority=" . prio )
    let templates[ a:name ] = xpt#snip#New( a:name, ftScope, snip, prio,
          \ templateSetting, deepcopy(x.snipFileScope.ptn) )


    call s:InitSnipObject( x, templates[ a:name ] )

    if get( templates[ name ].setting, 'abbr', 0 )
        call s:Abbr( name )
    endif

endfunction "}}}

fun! XPTdefineSnippetInternal( name, setting, snip ) "{{{

    " TODO global shortcuts
    let name = a:name

    let x         = b:xptemplateData
    let ftScope   = x.filetypes[ x.snipFileScope.filetype ]
    let templates = ftScope.allTemplates


    let prio = x.snipFileScope.priority


    " Existed template has the same priority is overrided.
    if has_key(templates, a:name)
          \ && templates[a:name].priority < prio
        return
    endif


    " TODO
    " snippet is splitted by units of indent
    let snip = join( a:snip, repeat( ' ', &shiftwidth ) )

    call s:log.Log( "tmpl :name=" . a:name . " priority=" . prio )


    let templates[ a:name ] = xpt#snip#New( a:name, ftScope, snip, prio,
          \ a:setting, deepcopy(x.snipFileScope.ptn) )


    call s:InitSnipObject( x, templates[ a:name ] )

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
        " key sequence is not allowed as abbr name
        let x = b:xptemplateData
        let n = matchstr( name, '\v\w+$' )
        let pre = name[ : -len( n ) - 1 ]
        let x.abbrPrefix[ n ] = get( x.abbrPrefix, n, {} )
        let x.abbrPrefix[ n ][ pre ] = 1
        exe 'inoreabbr <silent> <buffer> ' n printf( "\<C-r>=XPTabbr(%s)\<CR>", string( n ) )
    endtry
endfunction "}}}

fun! s:InitSnipObject( xptObj, tmplObj ) "{{{

    " TODO error occured once: no key :"setting )"

    call xpt#st#Parse( a:tmplObj.setting, a:tmplObj )


    call s:log.Debug( 'create template name=' . a:tmplObj.name . ' snipText=' . a:tmplObj.snipText )

    call xpt#st#InitItemOrderList( a:tmplObj.setting )


    let nonWordChar = substitute( a:tmplObj.name, '\w', '', 'g' )
    if nonWordChar != ''
        if !( a:tmplObj.setting.iswraponly || a:tmplObj.setting.hidden )
            call XPTemplateKeyword( nonWordChar )
        endif
    endif

endfunction "}}}



fun! XPTreload() "{{{
    try
        call s:Crash()
    catch /.*/
    endtry

  try
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
    let x.userWrapped = a:wrap

    " TODO simplify me
    let ts  = &tabstop


    let tabspaces = repeat( ' ', ts )

    " TODO is that ok?
    let x.userWrapped = substitute( x.userWrapped, '\V\n\$', '', '' )


    let x.userWrapped = xpt#util#ExpandTab( x.userWrapped, &tabstop )


    if ( g:xptemplate_strip_left || x.userWrapped =~ '\n' )
          \ && visualmode() ==# 'V'
        let x.wrapStartPos = virtcol(".")

        let indent = matchstr( x.userWrapped, '^\s*' )
        let indentNr = len( indent )
        let x.userWrapped = x.userWrapped[ indentNr : ]

    else
        let x.wrapStartPos = col(".")

        " NOTE: indent before 'S' command or current indent
        let indentNr = min( [ indent( line( "." ) ), virtcol('.') - 1 ] )


    endif

    let maxIndent = indentNr
    let x.userWrapped = substitute( x.userWrapped, '\V\n \{0,' . maxIndent . '\}', "\n", 'g' )
    let lines = split( x.userWrapped, '\V\\r\n\|\r\|\n', 1 )


    let maxlen = 0
    for l in lines
        let maxlen = maxlen < len(l) ? len(l) : maxlen
    endfor

    let indentNr -= maxIndent

    let x.userWrapped =  { 'indent' : -indentNr,
          \         'text'   : x.userWrapped,
          \         'lines'  : lines,
          \         'max'    : maxlen,
          \         'curline' : lines[ 0 ], }

    call s:log.Log( 'x.userWrapped=' . string( x.userWrapped ) )


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

        let leftSpaces = xpt#util#convertSpaceToTab( repeat( ' ', pos - 1 ) )

    else
        let leftSpaces = ''
    endif


    return leftSpaces

endfunction "}}}

fun! XPTemplateDoWrap() "{{{

    " " TODO is needed?
    " call XPTparseSnippets()
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



" ********* XXX *********
" TODO remove the first argument
" TODO xpt seize pum if something matches snippet name in normal pum.
fun! XPTemplateStart(pos_unused_any_more, ...) " {{{

    " (\W)
    " (\W)(\w)(\W)
    " (\names)(\ext)
    " dynamic: ( \names )( \ext )$
    " static: search backward by dictionary defined


    let action = ''
    " " TODO is it needed?
    " call XPTparseSnippets()

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

    " Fix fake indent space generated by "n_S" command

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


    " Handle with popup menu. Deside what to do about pum: trigger XPT,
    " navigate to next PH, or fallback to normal pum function.
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
                    return xpt#util#Fallback( x.fallbacks )
                else

                    call s:log.Debug( "nothing to do" )

                    " nothing to do, normal procedure.
                endif

            else

                call s:log.Debug( "has fallbacks" )

                if g:xptemplate_fallback =~? '\V<Plug>XPTrawKey\|<NOP>'
                      \ || g:xptemplate_fallback ==? keypressed

                    return xpt#util#Fallback( x.fallbacks )

                else

                    call s:log.Debug( "set up fall back" )

                    let x.fallbacks = [ [ "\<Plug>XPTfallback", 'feed' ] ] + x.fallbacks
                    return xpt#util#Fallback( x.fallbacks )
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

        call s:log.Log("x.keyword=" . x.keyword)

        " TODO test escaping
        "
        " NOTE: The following statement hangs VIM if x.keyword == '\w'
        " let [startLineNr, startColumn] = searchpos('\V\%(\w\|'. x.keyword .'\)\+\%#', "bn", startLineNr )

        let columnBeforeCursor = col( "." ) - 2
        if columnBeforeCursor >= 0
            let lineToCursor = getline( startLineNr )[ 0 : columnBeforeCursor ]
        else
            let lineToCursor = ''
        endif


        let ext = s:GetSnippetExtension( lineToCursor )

        if ext != {}

            " return  action . repeat( "\<BS>", len( ext.ext ) ) . s:DoStart( {
            return  action . s:DoStart( {
                        \ 'line'    : startLineNr,
                        \ 'col'     : col( "." ) - len( ext.name ) - len( ext.ext ),
                        \ 'matched' : ext.name,
                        \ 'data'    : { 'ftScope' : s:GetContextFTObj() } } )

        endif

        let ftScope = s:GetContextFTObj()
        let pre = ftScope.namePrefix
        let n = split( lineToCursor, '\s', 1 )[ -1 ]

        " TODO use filetype.keyword
        " TODO in php $se should not trigger snippet 'se'

        " <non-keyword><keyword> is not breakable: $var in php
        " <keyword><non-keyword> is breakable: func( in c

        " search for valid snippet name or single non-keyword name
        let snpt_name_ptn = '\V\^' . x.keyword . '\w\*\|\^\W'
        while n != '' && !has_key( pre, n )
            let n = substitute( n, snpt_name_ptn, '', '' )
        endwhile
        let matched = n

        if !has_key( opt, 'popupOnly' )
            if !isFullMaatching
                  \ && len( matched ) < miniPrefix
                  " \ && !forcePum

                  let x.fallbacks = [ [ "\<Plug>XPTfallback", 'feed' ] ] + x.fallbacks
                  return xpt#util#Fallback( x.fallbacks )
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

fun! s:GetSnippetExtension( line ) "{{{

    " TODO option specifying to prefer simple snippet or extended snippet.

    let x = b:xptemplateData
    let ftScope = s:GetContextFTObj()

    let ext = {}

    for [ extPtn, snipNames ] in items( ftScope.extensionTable )

        " TODO non-ascii char in snipNames?
        let namePattern = '\V\(' . join( snipNames, '\|' ) . '\)'
        let ptn = namePattern . '\v' . extPtn . '\V\$'


        let matched = matchstr( a:line, ptn )
        if matched != ''
            let name = matchstr( matched, '\V\^' . namePattern )
            let ext = { 'ptn' : ptn,
                  \     'snipNames' : snipNames,
                  \     'name' : name,
                  \     'ext' : matched[ len( name ) : ] }
            break
        endif

    endfor

    let x.currentExt = ext

    return ext

endfunction "}}}

fun! s:InitRenderContext( ftScope, tmplName ) "{{{

    let x = b:xptemplateData

    if x.renderContext.processing
        call xpt#rctx#Push()
    endif

    let renderContext = xpt#rctx#New( x )
    let x.renderContext = renderContext

    let renderContext.phase = 'inited'
    let renderContext.snipObject  = s:GetContextFTObj().allTemplates[ a:tmplName ]
    let renderContext.ftScope = a:ftScope

    let so = renderContext.snipObject
    call xpt#snip#CompileAndParse( so )


    let renderContext.snipSetting = xpt#st#RenderPhaseCopy( so.setting )


    return renderContext
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

    let ctx = s:InitRenderContext( sess.data.ftScope, tmplname )


    call s:BuildSnippet([ lineNr, column ], [ lineNr, cursorColumn ])


    let ctx.phase = 'rendered'
    let ctx.processing = 1

    call s:CallPlugin( 'render', 'after' )


    if empty(x.stack)
        call s:SaveNavKey()
        call s:ApplyMap()
    endif

    let x.userWrapped = ''
    let x.wrapStartPos = 0


    let action =  s:GotoNextItem()

    call s:log.Log( 'just after GotoNextItem' . string( [ line( "'<" ), col( "'<" ) ] ) )
    call s:log.Debug("post action =".action)
    call s:log.Debug("mode:".mode())
    call s:log.Debug( "tmpl:", xpt#util#TextBetween( XPMposStartEnd( ctx.marks.tmpl ) ) )

    call s:log.Debug( "tmpl:", s:TextBetween( XPMposStartEnd( ctx.marks.tmpl ) ) )

    call s:CallPlugin( 'start', 'after' )


    call s:log.Log( string( [ line( "'<" ), col( "'<" ) ] ) )


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

    call XPMremoveMarkStartWith( renderContext.markNamePre )


    if empty(x.stack)
        let x.fallbacks = []

        let renderContext.processing = 0
        let renderContext.phase = 'finished'

        " TODO clear according to group status
        call s:ClearMap()


        call XPMflushWithHistory()

        let @" = x.savedReg

        call s:CallPlugin( 'finishAll', 'after' )

    else

        call xpt#rctx#Pop()
        call s:CallPlugin( 'finishSnippet', 'after' )
    endif


    " renderContext may be changed
    let x.renderContext.userPostAction = ''
    return s:DONE

endfunction "}}}

" TODO cache it and clear it when new snippets compiled
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

    let synNames = xpt#util#SynNameStack(line("."), a:coln)

    call s:log.Log("Popup, pref and coln=".a:pref." ".a:coln)

    if has_key( snipDict, a:pref ) && !forcePum

        let snipObject = snipDict[ a:pref ]

        if s:IfSnippetShow( snipObject, synNames )
            return  s:DoStart( {
                  \ 'line'    : line( "." ),
                  \ 'col'     : a:coln,
                  \ 'matched' : a:pref,
                  \ 'data'    : { 'ftScope' : ftScope } } )
        endif
    endif


    for [ key, snipObject ] in items(snipDict)

        if !s:IfSnippetShow( snipObject, synNames )
            continue
        endif

        let hint = get( snipObject.setting, 'hint', '' )

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

fun! s:IfSnippetShow( snipObject, synNames ) "{{{

    let x = b:xptemplateData

    let snipObject = a:snipObject
    let synNames = a:synNames

    if snipObject.setting.iswraponly && x.userWrapped is ''
          \ || !snipObject.setting.iswrap && x.userWrapped isnot ''
        return 0
    endif

    if has_key(snipObject.setting, "syn")
          \ && snipObject.setting.syn != ''
          \ && match(synNames, '\c' . snipObject.setting.syn) == -1
        return 0
    endif

    if get( snipObject.setting, 'hidden', 0 )  == 1
        return 0
    endif

    return 1

endfunction "}}}

fun! s:AdjustIndentAt( text, startPos ) "{{{

    let nIndent = xpt#util#getIndentNr( a:startPos )

    return s:AddIndent( a:text, nIndent )

endfunction "}}}

fun! s:AddIndent( text, nIndent ) "{{{
    return xpt#util#AddIndent( a:text, a:nIndent )
endfunction "}}}

fun! s:BuildSnippet(nameStartPosition, nameEndPosition) " {{{

    call s:log.Debug( 'BuildSnippet : start, end=' . string( [ a:nameStartPosition, a:nameEndPosition ] ) )

    " eat up <space> in abbr mode
    call getchar( 0 )

    let x = b:xptemplateData
    let rctx = b:xptemplateData.renderContext
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


    let rctx.phase = 'rendering'


    if rctx.snipSetting.iswrap && x.userWrapped isnot ''
        let setting = rctx.snipSetting

        let setting.preValues[ setting.wrapPH ] = xpt#flt#New( 0, 'EmbedWrappedText()', 1 )
        let setting.onfocusFilters[ setting.wrapPH ] = xpt#flt#New( 0, "Next()", 1 )

        call insert( setting.comeFirst, setting.wrapPH, 0 )
    endif

    if x.userWrapped isnot ''
        let rctx.userWrapped = copy( x.userWrapped )
    endif

    let nSpaceToAdd = s:NPreferedIndent( a:nameStartPosition )


    " update xpm status
    call XPMupdate()

    let render = xpt#render#New( rctx, a:nameStartPosition, nSpaceToAdd )
    let [ lines, markArgs ] = xpt#render#GenScreenData( render )

    call s:log.Debug( 'markArgs to add:' . string( markArgs ) )


    call XPreplace( a:nameStartPosition, a:nameEndPosition, join( lines, "\n" ) )


    call XPMaddSeq( markArgs )
    " for mk in markArgs
    "     " 3-arguments or 4-arguments format
    "     call call( 'XPMadd', mk )
    " endfor


    " call cursor( a:nameStartPosition )
    call XPMupdateStat()

    call s:log.Debug( XPMallMark() )

    let rctx = empty( x.stack ) ? x.renderContext : x.stack[0]

    let rg = XPMposList( rctx.marks.tmpl.start, rctx.marks.tmpl.end )

    exe 'silent! ' . rg[0][0] . ',' . rg[1][0] . 'foldopen!'

    return

endfunction " }}}

" TODO seems non-keyword trigger does not work?

fun! s:NPreferedIndent( startPos ) "{{{

    let ctx = b:xptemplateData.renderContext
    let curline = getline( a:startPos[ 0 ] )
    let nSpaceToAdd = 0


    let prefered = -1
    if len( matchstr( curline, '\V\^\s\*' ) ) == a:startPos[ 1 ] - 1
        " snippet name starts as the first non-space char

        let firstWord = ctx.snipObject.parsedSnip[ 0 ]

        if type( firstWord ) == type( '' )
            let firstWord = matchstr( firstWord, '\V\^\w\+' )

            " NOTE: Only keys appears in &indentkeys trigger re-indent
            if firstWord != '' && has_key( ctx.oriIndentkeys, firstWord )
                let prefered = xpt#util#GetPreferedIndentNr( a:startPos[ 0 ] )
            endif

        endif

    endif



    if prefered >= 0

        let currentNIndent = xpt#util#getIndentNr( a:startPos )

        if prefered > currentNIndent

            let nSpaceToAdd = prefered - currentNIndent

        elseif prefered < currentNIndent

            let nSpaceToAdd = prefered
            let a:startPos[ 1 ] = 1

        endif

    endif

    return nSpaceToAdd

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
        let markName =  item.name . s:buildingSeqNr . '`' . ( has_key( placeHolder, 'isKey' ) ? 'k' : (len(item.placeHolders)-1) )

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

    if has_key( placeHolder, 'isKey' )
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
    if has_key( placeHolder, 'isKey' )
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
    if has_key( placeHolder, 'isKey' )
        call XPMadd( placeHolder.editMark.start, nameInfo[1], 'l' )
        call XPMadd( placeHolder.editMark.end,   nameInfo[2], 'r' )
    endif

    call XPMadd( placeHolder.mark.end,   nameInfo[3], 'r' )

endfunction "}}}

fun! s:BuildPlaceHolders( markRange ) "{{{

    let s:buildingSeqNr += 1
    let rc = 0

    let x = b:xptemplateData
    let renderContext = b:xptemplateData.renderContext
    let snipObject = renderContext.snipObject
    let setting = snipObject.setting
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



        let nn = [ line( "." ), col( "." ) ]


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


        let placeHolder = xpt#ph#CreateFromScreen( snipObject, nameInfo, valueInfo )
        let rc = 1

        call s:log.Log( 'built placeHolder=' . string( placeHolder ) )

        if renderContext.userWrapped != {}
              \ && setting.iswrap
              \ && get( placeHolder, 'name', 0 ) is setting.wrapPH
              \ && get( placeHolder, 'isKey', 0 )

            " linewise propagation

            let n = len( renderContext.userWrapped.lines ) - 1

            let indent = repeat( ' ', virtcol( nameInfo[ 0 ] ) - 1 )


            let line = "\n" . indent . xp.l . placeHolder.leftEdge . xp.l . 'GetWrappedText()' . xp.l . placeHolder.rightEdge . xp.r

            let lines = repeat( line, n )

            let pos = copy( valueInfo[ -1 ] )
            let pos[ 1 ] += 1
            call XPreplaceInternal( pos, pos, lines )
            " call XPreplace( pos, pos, lines )

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

            let item = xpt#rctx#AddPHToGroup( renderContext, placeHolder )

            call s:BuildMarksOfPlaceHolder( item, placeHolder, nameInfo, valueInfo )

            " set for eval preset value, edge, etc.
            let renderContext.item = item
            let renderContext.leadingPlaceHolder = item.keyPH == s:nullDict ? placeHolder : item.keyPH

            " nameInfo and valueInfo is updated according to new position
            " call cursor(nameInfo[3])

            call s:log.Debug( 'built ph=' . string( placeHolder ) )

            call s:EvaluateEdge( xp, item, placeHolder )
            call s:ApplyPreValues( placeHolder )

            " " TODO set it when item created.
            " call s:SetDefaultFilters( placeHolder )


            call cursor( XPMpos( placeHolder.mark.end ) )

        endif


    endwhile


    let renderContext.groupList = renderContext.firstList + renderContext.groupList + renderContext.lastList

    " filter string elements which are not any of item names
    call filter( renderContext.groupList, 'type(v:val) != 1' )

    let renderContext.firstList = []
    let renderContext.lastList = []

    call s:log.Log( "groupList:" . string( renderContext.groupList ) )


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


        " TODO '^' need to be escaped
        let markPos = searchpos( '\V\\\*\[' . xp.l . xp.r . ']', 'cW' )


        if markPos == [0, 0] || markPos[0] * 10000 + markPos[1] >= nEnd
            break
        endif



        let content = getline( markPos[0] )[ markPos[1] - 1 : ]
        let char = matchstr( content, '[' . xp.l . xp.r . ']' )
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
    let x = b:xptemplateData
    if !has_key( a:ph, 'isKey' )
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

    let flt = g:FilterValue.New(0, a:raw)
    let flt_rst = s:EvalFilter(flt, x.renderContext.ftScope.funcs,
          \                {'startPos': a:start_pos})
    return s:IndentFilterText(flt_rst, a:start_pos)
endfunction "}}}

fun! s:IndentFilterText( flt_rst, start ) "{{{
    let indent = s:IndentAt(a:start, a:flt_rst)
    return xpt#indent#ParseStr(a:flt_rst.text, indent)
endfunction "}}}

fun! s:ApplyBuildTimeInclusion( placeHolder, nameInfo, valueInfo ) "{{{

    let renderContext = b:xptemplateData.renderContext
    let tmplDict = renderContext.ftScope.allTemplates

    let placeHolder = a:placeHolder
    let nameInfo    = a:nameInfo
    let valueInfo   = a:valueInfo

    call s:log.Debug( 'buildtime inclusion' )

    let [ incName, params ] = xpt#snip#ParseInclusionStatement( renderContext.snipObject, placeHolder.include )

    if !has_key( tmplDict, incName )
        call XPT#info( "unknown inclusion :" . incName )
        return
    endif

    let incTmplObject = tmplDict[ incName ]
    if !incTmplObject.parsed

        " TODO These functions are never been used

        call s:ParseInclusion( renderContext.ftScope.allTemplates, incTmplObject )
        let incTmplObject.snipText = s:ParseSpaces( incTmplObject )
        let incTmplObject.snipText = s:ParseQuotedPostFilter( incTmplObject )
        let incTmplObject.snipText = s:ParseRepetition( incTmplObject )

        let incTmplObject.parsed = 1

    endif

    call xpt#st#Merge( renderContext.snipSetting, incTmplObject.setting )

    let incSnip.parsedSnip = xpt#phfilter#Filter( incTmplObject, 'xpt#phfilter#ReplacePH',
          \ { 'replParams' : params } )

    let incSnip = s:AdjustIndentAt( incSnip, nameInfo[0][1] - 1 )

    let valueInfo[-1][1] += 1
    call XPreplaceInternal( nameInfo[0], valueInfo[-1], incSnip )

endfunction "}}}

fun! s:ApplyInstantValue( placeHolder, nameInfo, valueInfo ) "{{{
    " TODO eval edge and name separately?

    let x = b:xptemplateData

    let ph = a:placeHolder
    let nameInfo    = a:nameInfo
    let valueInfo   = a:valueInfo
    let start = a:nameInfo[0]
    let evalctx = {'startPos': start}
    let funcs = x.renderContext.ftScope.funcs

    call s:log.Debug( 'instant placeHolder' )

    let flt_indent = {}
    let text = ''
    let to_build = 0
    for k in [ 'leftEdge', 'name', 'rightEdge' ]
        if ph[k] != ''
            let flt = g:FilterValue.New( 0, ph[k] )
            let flt_rst = s:EvalFilter( flt, funcs, evalctx )
            let text .= get( flt_rst, 'text', '' )
            if get(flt_rst, 'nIndent', 0) != 0
                let flt_indent.nIndent = flt_rst.nIndent
            endif
            if get( flt_rst, 'action', 0 ) == 'build'
                let to_build = 1
            endif
        endif
    endfor

    call s:log.Log( "instant value filter value:" . string( flt_rst ) )

    let valueInfo[-1][1] += 1

    let flt_indent.text = text
    let text = s:IndentFilterText(flt_indent, start)

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
    let renderContext = b:xptemplateData.renderContext
    let setting = renderContext.snipSetting

    let name = a:placeHolder.name

    let preValue = a:placeHolder.name == ''
          \ ? g:EmptyFilter
          \ : get( setting.preValues, name, g:EmptyFilter )



    if preValue is g:EmptyFilter

        let preValue = get( a:placeHolder, 'ontimeFilter',
              \ get( setting.defaultValues, name, g:EmptyFilter ) )

    endif

    if preValue is g:EmptyFilter
        return
    endif

    let flt_rst = s:EvalFilter( preValue, renderContext.ftScope.funcs,
          \                     { 'startPos' : XPMpos( a:placeHolder.innerMarks.start ) } )


    " TODO isnot 0? or is 0?
    if flt_rst.rc isnot 0 && has_key( flt_rst, 'text' )
        call s:SetPreValue( a:placeHolder, flt_rst )
    endif

endfunction "}}}

fun! s:SetPreValue( placeHolder, flt_rst ) "{{{

    let marks = a:placeHolder.innerMarks


    call s:log.Log( 'preValue=' . a:flt_rst.text )
    " call XPRstartSession()
    try
        call XPreplaceByMarkInternal( marks.start, marks.end, a:flt_rst.text )
    catch /.*/
    finally
        " call XPRendSession()
    endtry
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

    call s:SelectCurrent()


    call XPMupdateStat()
    return renderContext.userPostAction

endfunction "}}}

fun! s:PushBackItem() "{{{
    let renderContext = b:xptemplateData.renderContext

    let item = renderContext.item
    if !has_key( renderContext.leadingPlaceHolder, 'isKey' )
        call insert( item.placeHolders, renderContext.leadingPlaceHolder, 0 )
    endif

    call insert( renderContext.groupList, item, 0 )

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
                return "\<C-v>\<C-v>\<BS>\<C-r>" . '=XPTforceForward(' . string( a:action ) . ")\<CR>"
            else
                if x.canNavFallback
                    let x.fallbacks = [ [ "\<Plug>XPTnavFallback", 'feed' ],
                          \             [ "\<C-r>=XPTforceForward(" . string( a:action ) . ")\<CR>", 'expr' ], ]
                    return  xpt#util#Fallback( x.fallbacks )
                else
                    return XPPend() . "\<C-r>=<SNR>" . s:sid . 'ShiftForward(' . string( a:action ) . ")\<CR>"
                endif
            endif
        endif

        return XPTforceForward( a:action )

    else

        if XPPhasSession()
            call XPPend()
        endif

        " Pum may be not visible but pum does exist. This cause problem
        " further <tab> swallow chars between pum-text and cursor position.
        "
        " In this case we have to force pum to close.

        return "\<C-v>\<C-v>\<BS>\<C-r>" . '=XPTforceForward(' . string( a:action ) . ")\<CR>"

    endif

endfunction " }}}

fun! XPTforceForward( action ) "{{{

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

    " TODO clean up according to group status
    call s:CleanupCurrentItem()

    call s:log.Debug( "before update=" . XPMallMark() )

    " if typing and <tab> pressed together, no update called
    " TODO do not call this if no need to update
    "       updating followers can be done in postfilter.
    "       here the only thing maybe need to be done is updating marks
    let rc = s:XPTupdate()
    if rc == s:BROKEN
        " crashed
        return s:BROKEN
    endif

    call s:log.Debug( "after update=" . XPMallMark() )


    let name = renderContext.item.name


    call s:log.Log("FinishCurrent action:" . a:action)

    if a:action ==# 'clear'
        call s:log.Log( 'to clear:' . string( [ XPMpos( marks.start ),XPMpos( marks.end ) ] ) )
        call XPreplace(XPMpos( marks.start ),XPMpos( marks.end ), '')
    endif

    call s:log.Debug( "before post filter=" . XPMallMark() )

    let [ resultText, built ] = s:ApplyPostFilter()

    call s:log.Debug( "after post filter=" . XPMallMark() )


    if name != ''
        let renderContext.namedStep[ name ] = resultText
    endif


    if built is s:BUILT || a:action ==# 'clear'
        call s:RemoveCurrentMarks()
    else
        let renderContext.history += [ {
                    \'item' : renderContext.item,
                    \'leadingPlaceHolder' : renderContext.leadingPlaceHolder } ]
    endif


    " TODO use elaborate return code
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

    let renderContext = b:xptemplateData.renderContext

    let renderContext.activeLeaderMarks = 'mark'


    let posts  = renderContext.snipSetting.postFilters
    let name   = renderContext.item.name
    let leader = renderContext.leadingPlaceHolder
    let marks  = renderContext.leadingPlaceHolder[ renderContext.activeLeaderMarks ]

    let [ start, end ] = XPMposStartEnd( marks )

    let renderContext.phase = 'post'

    let typed = xpt#util#TextBetween( XPMposStartEnd( marks ) )

    " NOTE: some post filter need the typed value
    if renderContext.item.name != ''
        let renderContext.namedStep[renderContext.item.name] = typed
    endif

    call s:log.Log("before post filtering, tmpl:\n" . xpt#util#TextBetween( XPMposStartEnd( renderContext.marks.tmpl ) ) )



    " TODO forced groupPostFilter
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
    let rc = 0
    " TODO per-place-holder filter
    " check by 'groupPostFilter' is ok
    if filter isnot g:EmptyFilter
        let filter = copy( filter )

        let flt_rst = s:EvalPostFilter( filter, typed, leader )

        call s:log.Log( 'text=' . flt_rst.text )

        let ori_flt_rst = copy( flt_rst )

        if rc is s:DONE
            " nothing to do
        else
            call s:log.Log( 'text=' . filter.rst.text )


            let [ start, end ] = XPMposStartEnd( marks )

            " TODO do not replace if no change made
            call XPMsetLikelyBetween( marks.start, marks.end )
            if filter.rst.text !=# typed
                call s:log.Debug( 'before replace, marks=' . XPMallMark() )

                call s:RemoveEditMark( leader )

                call b:xptemplateData.settingWrap.Switch()

                call XPreplace( start, end, filter.rst.text )
                call s:log.Debug( 'after replace, marks=' . XPMallMark() )
            endif

        if flt_rst.action == 'build'
            " TODO extract to function

                call cursor( start )

                let renderContext.firstList = []
                let buildrc = s:BuildPlaceHolders( marks )

            if 0 > buildrc
                return [ s:Crash(), 1 ]
            endif

                " bad name , 'alreadyBuilt' ?
                let hadBuilt = 0 < buildrc

                " change back the phase
                let renderContext.phase = 'post'

        endif

    endif

    " after indent segment, there is something
    if groupPostFilter is g:EmptyFilter
        call s:UpdateFollowingPlaceHoldersWith( typed, { 'leaderPosStart' : start } )
        return [ typed, hadBuilt ]

    else
        call s:UpdateFollowingPlaceHoldersWith( typed, { 'leaderPosStart' : start,  'post' : oriFilter } )
        if hadBuilt
            return [ typed, hadBuilt ]
        else
            return [ flt_rst.text, hadBuilt ]
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

    call xpt#flt#Eval( a:filter, renderContext.ftScope.funcs, {
          \ 'typed' : a:typed,
          \ 'startPos' : startMark.pos[ 0 : 1 ] } )

    if a:filter.rst.rc is 0
        return [ s:DONE, 0 ]
    endif

    call s:log.Log("post_value:\n", string(a:filter))

    if flt_rst.rc == 0
        return
    endif

    let act = flt_rst.action

    if act == 'build'
        if ! has_key( flt_rst, 'text' )
            let flt_rst.text = a:typed
        end

    elseif act == 'keepIndent'
        " TODO check if this is neccesary
        let flt_rst.nIndent = 0

    elseif flt_rst.action =~# '\vembed'
        " TODO check if embeding is inside editable marksf

        " Prevent mark overlaps which crash xpt rendering
        call s:RemoveEditMark( a:leader )
        " TODO simplify action call
        call xpt#act#fillin#{a:filter.rst.action}( renderContext, a:filter )
        return [ s:DONE, s:BUILT ]

        " TODO
    " elseif act.name == 'expandTmpl'
        " let leader = renderContext.leadingPlaceHolder
        " let marks = leader.marks
        " let [ start, end ] = XPMposList( marks.start, marks.end )

        " call XPreplace( start, end, '')
        " return XPTemplateStart(0, {'startPos' : start, 'tmplName' : post.tmplName})

        " let res = [ post. ]
    else
        " unknown action
        " let flt_rst.text = get( post, 'text', '' )
    endif

    " TODO elaborate return value
    return [ 0, 0 ]

endfunction "}}}


fun! s:GotoNextItem() "{{{
    let rc = s:DoGotoNextItem()

    " restore 'wrap'
    call xpt#stsw#Restore( b:xptemplateData.settingWrap )

    return b:xptemplateData.renderContext.userPostAction
endfunction "}}}

" TODO rename me
fun! s:DoGotoNextItem() "{{{
    " @return   insert mode typing action

    let rctx = b:xptemplateData.renderContext
    let ph = s:ExtractOneItem()

    call s:log.Log( "next ph=" . string( ph ) )

    call s:log.Debug( XPMallMark() )


    if ph == s:nullDict
        call cursor( XPMpos( rctx.marks.tmpl.end ) )
        " NOTE: FinishRendering does not return any action
        return s:FinishRendering(1)
    endif

    call s:log.Log("ExtractOneItem:".string(ph))
    call s:log.Log("leadingPlaceHolder pos:".string(XPMpos( ph.mark.start )))

    let phPos = XPMpos( ph.mark.start )
    if phPos == [0, 0]
        " error found no position of mark
        " call s:log.Error( 'failed to find position of mark:' . ph.mark.start )
        return s:Crash('failed to find position of mark:' . ph.mark.start)
    endif

    call s:log.Log( "all marks:" . XPMallMark() )



    let leader =  rctx.leadingPlaceHolder
    let leaderMark = leader.innerMarks

    call XPMsetLikelyBetween( leaderMark.start, leaderMark.end )

    if rctx.item.processed
        " shift back and then shift forward
        let rctx.phase = 'fillin'
        " TODO re-popup if needed

        call s:SelectCurrent()

        call XPMupdateStat()
        return rctx.userPostAction
    endif


    let oldRenderContext = rctx


    let postaction = s:InitItem()


    call s:log.Log( 'after InitItem:' . string( [ line( "'<" ), col( "'<" ) ] ) )

    " InitItem may change template stack
    let rctx = b:xptemplateData.renderContext
    let leader = rctx.leadingPlaceHolder

    " TODO extract following part to function

    if rctx.processing
          \ && empty( rctx.groupList )
          \ && !has_key( rctx.snipSetting.postFilters, rctx.item.name )
          \ && !has_key( leader, 'postFilter' )
          \ && empty( rctx.item.placeHolders )
          \ && XPMpos( leader.mark.end ) == XPMpos( rctx.marks.tmpl.end )
          \ && postaction !~ ''

        " NOTE: FinishRendering does not return any action
        let pp = s:FinishRendering()
        return postaction

    endif

    call s:log.Log( 'after InitItem, postaction='.postaction )

    if !rctx.processing
        return postaction
    endif

    try
        call XPMsetLikelyBetween( leader.mark.start, leader.mark.end )
    catch /.*/
        " Maybe crashed
        return s:Crash()
    endtry

    call s:log.Log( 'current PH is key?=' . has_key( rctx.leadingPlaceHolder, 'isKey' ) )


    if postaction == ''

        if oldRenderContext == rctx
              \ || oldRenderContext.level < rctx.level
            call cursor( XPMpos( rctx.leadingPlaceHolder.innerMarks.end ) )
        endif

        return ''

    else
        return postaction
    endif

endfunction "}}}

fun! s:ExtractOneItem() "{{{

    let renderContext = b:xptemplateData.renderContext
    let groupList = renderContext.groupList


    let [ renderContext.item, renderContext.leadingPlaceHolder ] = [ {}, {} ]

    if empty( groupList )
        return s:nullDict
    endif

    let item = groupList[ 0 ]

    let renderContext.groupList = renderContext.groupList[ 1 : ]

    let renderContext.item = item

    if empty( item.placeHolders ) && item.keyPH == s:nullDict
        call XPT#info( "item without placeholders!" )
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

fun! s:HandleDefaultValueAction( filter ) "{{{
    " @return   string  typing
    "           -1      if this action can not be handled

    let x = b:xptemplateData
    let rctx = x.renderContext
    let leader = rctx.leadingPlaceHolder

    let frst = a:filter.rst


    call s:log.Log( "type is " . type( frst ). ' {} type is ' . type( {} ) )

    if frst.action ==# g:XPTact.trigger
        " let rctx.item.behavior.gotoNextAtOnce = 1


        " do NOT need to update position
        " TODO innerMarks ?
        let marks = leader.mark
        call XPreplace(XPMpos( marks.start ), XPMpos( marks.end ), '')
        call XPMsetLikelyBetween( marks.start, marks.end )
        let userPostAction = XPTemplateStart(0, {'startPos' : getpos(".")[1:2], 'tmplName' : frst.tmplName})

    elseif a:flt_rst.action ==# 'pum'
        return s:DefaultValuePumHandler( ctx, a:flt_rst )

    elseif a:flt_rst.action ==# 'finishTemplate'
        " TODO remove it and apply userPostAction in XPTemplateStart
        let x.renderContext.userPostAction = userPostAction
        return s:AGAIN

    elseif frst.action ==# g:XPTact.embed
        " embed a piece of snippet

        let rc = xpt#act#fillin#{a:filter.rst.action}( rctx, a:filter )
        call s:RemoveCurrentMarks()

        " TODO ShiftForward or GotoNextItem
        return s:GotoNextItem()

    elseif frst.name ==# g:XPTact.build
        " same as 'embed'

        " building destory current item
        let [ built ] =  s:EmbedSnippetInLeadingPlaceHolder( ctx, a:flt_rst.text, a:flt_rst )
        return s:GotoNextItem()

    elseif frst.action ==# g:XPTact.finishPH

        return s:ActionFinish( a:filter )

    elseif frst.action ==# g:XPTact.next

        " TODO update following?

        if has_key( a:filter.rst, 'phs' )

            let rc = xpt#act#fillin#embed( rctx, a:filter )

        elseif has_key( a:filter.rst, 'text' )

            let rc = xpt#act#fillin#embed( rctx, a:filter )

            if rc is s:BUILT
                call s:RemoveCurrentMarks()
            endif

        let postaction = ''
        " Note: update following?
        if has_key( a:flt_rst, 'text' )
            let postaction = s:FillinLeadingPlaceHolderAndSelect( ctx, a:flt_rst )
        endif
        if x.renderContext.processing
            " TODO is it better calling a deeper func?
            return s:ShiftForward( '' )
        else
            call s:SelectCurrent()
            call XPMupdateStat()
            return rctx.userPostAction
        endif

    elseif frst.action ==# g:XPTact.removePH

        let postaction = ''
        if has_key( a:flt_rst, 'text' )
            let postaction = s:FillinLeadingPlaceHolderAndSelect( ctx, a:flt_rst )
        endif
        if x.renderContext.processing
            return s:ShiftForward( 'clear' )
        else
            return postaction
        endif

    elseif a:flt_rst.action ==# 'text'
        return s:FillinLeadingPlaceHolderAndSelect( ctx, a:flt_rst )
    else
        " other action

    endif

    return -1

endfunction "}}}

fun! s:ActionFinish( filter ) "{{{

    let x = b:xptemplateData
    let renderContext = x.renderContext
    let marksToUse = get( a:filter.rst, 'marks', 'innerMarks' )
    let marks = renderContext.leadingPlaceHolder[ marksToUse ]
    let [ start, end ] = XPMposStartEnd( marks )
    let isMarkBroken = start[ 0 ] * end[ 0 ] == 0

    call s:log.Debug( "start, end=" . string( [ start, end ] ) )
    call s:log.Debug( "start line=" . string( getline( start[0] ) ) )

    call s:SaveCursorBeforeAction( a:filter )


    if !isMarkBroken
          \ && a:filter.rst.rc isnot 0
          \ && has_key( a:filter.rst, 'text' )

        " marks are not deleted during user edit

            if has_key( a:flt_rst, 'text' )
                let text = s:IndentFilterText( a:flt_rst, start )
            else
                let text = ''
            endif

        " do NOT need to update position

        call s:log.Debug( "text=" . string( text ) . len( text ) )
        call XPreplace( start, end, text )
    endif

    let rc = s:FinishCurrent( '' )

    if rc is s:BROKEN
        let x.renderContext.userPostAction = ''
        return s:DONE
    endif

    if exists( 'b:__xpt_saved_cursor__' )
        call s:RestoreCursorAfterAction( a:filter )
    else
        " TODO bad
        call cursor( XPMpos( renderContext.leadingPlaceHolder.mark.end ) )
    endif


    let x = b:xptemplateData

    let postponed = get( a:filter.rst, 'postponed', '' )


    " TODO controled by behavior is better?
    " NOTE: XXX TODO!!!
    if empty( x.stack )
          \ || 1
        let rc = s:FinishRendering()
        let x.renderContext.userPostAction = postponed
        return s:DONE
    else
        " TODO for cursor item in nested template, this is ok. what if
        " need to select something or doing something else?
        return ''
    endif

endfunction "}}}

fun! s:SaveCursorBeforeAction( filter ) "{{{
    let x = b:xptemplateData
    let renderContext = x.renderContext

    if has_key( a:filter.rst, 'cursor' )

        if a:filter.rst.isCursorRel

            let relMark = eval( 'renderContext.leadingPlaceHolder.' . a:filter.rst.cursor.where )

            if XPMhas( relMark )
                let relPos = s:RecordRelativePosToMark( [ line( "." ), col( "." ) ],
                      \ relMark )

                let b:__xpt_saved_cursor__ = [ relMark, relPos ]
            endif

        elseif a:filter.rst.cursor is 'current'

            let b:__xpt_saved_cursor__ = [ line( "." ), col( "." ) ]

        else " absolute position

            let b:__xpt_saved_cursor__ = copy( a:filter.rst.cursor )

    if a:flt_rst.action == 'build'
        let build_rc = s:BuildPlaceHolders( marks )
        call s:log.Log( "build_rc=" . string( build_rc ) )
        if build_rc < 0
            call s:Crash('building place holder failed')
            return [ s:NOTBUILT ]
        else
            if build_rc == s:BUILT
                call s:RemoveCurrentMarks()
            end
            return [ build_rc ]
        endif

    endif

endfunction "}}}

fun! s:RestoreCursorAfterAction( filter ) "{{{
    let x = b:xptemplateData
    let renderContext = x.renderContext

    if exists( 'b:__xpt_saved_cursor__' )

        let saved = b:__xpt_saved_cursor__

        if has_key( a:filter.rst, 'cursor' )

            if a:filter.rst.isCursorRel

                call s:GotoRelativePosToMark( saved[ 1 ], saved[ 0 ] )

            elseif a:filter.rst.cursor is 'current'

                call cussor( saved[ 0 ], saved[ 1 ] )

            else " absolute position

                call cussor( saved[ 0 ], saved[ 1 ] )

            endif

        endif

        unlet b:__xpt_saved_cursor__
    endif

endfunction "}}}


" TODO bad implementation. If further build or shifforward needed, return back a
" flag to inform caller to do this.  Do not do it silently itself
fun! s:FillinLeadingPlaceHolderAndSelect( ctx, flt_rst ) "{{{
    " TODO remove needless marks

    let [ ctx, str ] = [ a:ctx, a:flt_rst.text ]
    let [ item, ph ] = [ ctx.item, ctx.leadingPlaceHolder ]

    let marks = ph.innerMarks
    let [ start, end ] = [ XPMpos( marks.start ), XPMpos( marks.end ) ]


    if start == [0, 0] || end == [0, 0]
        return s:Crash()
    endif

    let flt_rst = copy( a:flt_rst )
    let flt_rst.text = str
    let str = s:IndentFilterText(flt_rst, start)

    call xpt#stsw#Switch( b:xptemplateData.settingWrap )
    " set str to key place holder or the first normal place holder
    call XPreplace( start, end, str )


    let xp = ctx.snipObject.ptn

    if flt_rst.action == 'build'
        if 0 > s:BuildPlaceHolders( marks )
            return s:Crash()
        endif

        call s:log.Log( 'rebuild default values' )
        " TODO behaviors changed here. check it
        " return s:GotoNextItem()
        return s:AGAIN
    endif


    call s:XPTupdate()
    call s:SelectCurrent()
    call XPMupdateStat()
    return s:DONE

endfunction "}}}

fun! s:ApplyDefaultValueToPH( filter ) "{{{

    let rctx = b:xptemplateData.renderContext
    let leader = rctx.leadingPlaceHolder
    let rctx.activeLeaderMarks = 'innerMarks'

    let start = XPMpos( leader.mark.start )

    call s:log.Debug( 'filter=' . string( a:filter ) )

    let ph = renderContext.leadingPlaceHolder
    let typed = s:TextBetween( XPMposStartEnd( ph.innerMarks ) )
    let flt_rst = s:EvalFilter( a:filter, renderContext.ftScope.funcs,
          \                     { 'typed': typed, 'startPos' : start } )


    if a:filter.rst.rc is 0
        call s:SelectCurrent()
        call XPMupdateStat()
        return s:DONE
    endif

    let flt_rst.text = get( flt_rst, 'text', typed )

    let rc = s:HandleDefaultValueAction( renderContext, flt_rst )
    if rc is -1
        return s:FillinLeadingPlaceHolderAndSelect( renderContext, flt_rst )
    else
        return rc
    endif

endfunction "}}}

fun! s:DefaultValuePumHandler( renderContext, flt_rst ) "{{{

    let pumlen = len( a:filter.rst.pum )

    if pumlen == 0
        let a:flt_rst.text = ''
        return s:FillinLeadingPlaceHolderAndSelect( a:renderContext, a:flt_rst )

    elseif pumlen == 1
        let a:flt_rst.text = a:flt_rst.pum[0]
        return s:FillinLeadingPlaceHolderAndSelect( a:renderContext, a:flt_rst )

    else
        return s:DefaultValueShowPum( a:renderContext, a:flt_rst )

    endif

endfunction "}}}

fun! s:DefaultValueShowPum( renderContext, flt_rst ) "{{{

    let leader = a:renderContext.leadingPlaceHolder
    let [ start, end ] = XPMposStartEnd( leader.innerMarks )

    call XPreplace( start, end, '')
    call cursor(start)

    call s:CallPlugin( 'ph_pum', 'before' )

    " to pop up, but do not enlarge matching, thus empty string is selected at first
    " if only word listed,  do callback at once.
    let pumsess = XPPopupNew( s:ItemPumCB, {}, a:filter.rst.pum )
    call pumsess.SetAcceptEmpty( get( a:filter.rst, 'acceptEmpty',  g:xptemplate_ph_pum_accept_empty ) )
    call pumsess.SetOption( {
          \ 'tabNav'      : g:xptemplate_pum_tab_nav } )

    let a:renderContext.userPostAction = pumsess.popup( col("."), { 'doCallback' : 1, 'enlarge' : 0 } )
    return s:DONE

endfunction "}}}

" return type action
fun! s:InitItem() " {{{

    let rctx        = b:xptemplateData.renderContext
    let currentItem = rctx.item
    let leaderMark  = rctx.leadingPlaceHolder.innerMarks

    let currentItem.initValue = xpt#util#TextBetween( XPMposStartEnd( leaderMark ) )

    call xpt#rctx#SwitchPhase( rctx, g:xptRenderPhase.iteminit )


    let rc = s:ApplyDefaultValue()


    " maybe changed
    let rctx = b:xptemplateData.renderContext

    " NOTE: InitItem() may change current item to next one
    if rctx.processing && currentItem == rctx.item
        let rctx.item.initValue = xpt#util#TextBetween( XPMposStartEnd( leaderMark ) )
    endif

    if rctx.phase == g:xptRenderPhase.iteminit
        " not finished by default value
        call s:ActivateItemMapping()
        call s:ActivateItemTempMapping()
        call xpt#rctx#SwitchPhase( rctx, g:xptRenderPhase.fillin )
    endif

    return rctx.userPostAction

endfunction " }}}

fun! s:ApplyDefaultValue() "{{{

    " TODO place holder default value with higher priority!
    let rctx = b:xptemplateData.renderContext
    let leader = renderContext.leadingPlaceHolder
    let defs = renderContext.snipSetting.defaultValues

    let onfocus = s:GetOnfocus()

    if onfocus is g:EmptyFilter

        " TODO to update the edge to following place holder
        call s:XPTupdate()
        let rctx.userPostAction = s:SelectCurrent()
        call XPMupdateStat()

        return s:DONE

    else
        " TODO change to return code
        let rc = s:ApplyDefaultValueToPH( onfocus )
        return rctx.userPostAction
    endif

endfunction "}}}

fun! s:GetOnfocus() "{{{

    let rctx = b:xptemplateData.renderContext
    let leader = rctx.leadingPlaceHolder
    let onfocuses = rctx.snipSetting.onfocusFilters

    let groupOnfocus = leader.name == ''
          \ ? g:EmptyFilter
          \ : get( onfocuses, leader.name, g:EmptyFilter )

    if get( groupOnfocus, 'force', 0 )

        let onfocus = groupOnfocus
        call s:log.Debug('setting.onfocusFilters.' . leader.name . '=' . string( onfocus ) )

    else

        call s:log.Debug('leader.liveFilter' . '=' . string(leader))

        let onfocus = get( leader, 'liveFilter', groupOnfocus )

    endif

    call s:log.Debug( 'leader default value is: ' . string( onfocus ) )

    return onfocus

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

    if rc isnot 0
        return ''
    endif

    " TODO startPos is current pos or start of mark?

    let x = b:xptemplateData

    let typed = xpt#util#TextBetween(
          \ XPMposStartEnd(
          \     x.renderContext.leadingPlaceHolder.mark ) )


    let filter = xpt#flt#New( 0, a:str )
    let filter = xpt#flt#Eval( filter, x.renderContext.ftScope.funcs,
          \ { 'typed'    : typed,
          \   'startPos' : [ line( "." ), col( "." ) ] } )

    if has_key( filter.rst, 'action' )
        let postAction = s:HandleAction( x.renderContext, filter )

    elseif has_key( filter.rst, 'text' )
        let postAction = filter.rst.text

    endif

    call s:log.Log( 'postAction=' . postAction )

    return postAction

endfunction "}}}

fun! s:ActivateItemMapping() "{{{

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

fun! s:ActivateItemTempMapping() "{{{

    let renderContext = b:xptemplateData.renderContext
    let mappings = renderContext.tmpmappings

    if empty( mappings.keys )
        return
    endif

    call xpt#msvr#Save( mappings.saver )

    for [ left, right ] in items( mappings.keys )
        exe 'inoremap <silent> <buffer>' left '<C-r>=XPTmappingEval(' string( right ) ')<CR>'
    endfor

endfunction "}}}

fun! XPTmapKey( left, right ) "{{{


    let renderContext = b:xptemplateData.renderContext
    let mappings = renderContext.tmpmappings

    if renderContext.phase != g:xptRenderPhase.iteminit
        call s:log.Warn( "Not in [iteminit] phase, mapping ingored" )
        return
    endif


    let mappings.keys[ a:left ] = a:right
    call xpt#msvr#Add( mappings.saver, 'i', a:left )

endfunction "}}}

fun! s:ClearItemMapping( rctx ) "{{{

    let renderContext = a:rctx

    let mappings = renderContext.tmpmappings
    if !empty( mappings.keys )
        call xpt#msvr#Restore( mappings.saver )
    endif
    " TODO what?
    let renderContext.tmpmappings = { 'saver' : xpt#msvr#New( 1 ), 'keys' : {} }


    let mappings = renderContext.snipObject.setting.mappings
    let item = renderContext.item

    if has_key( mappings, item.name )
        call xpt#msvr#Restore( mappings[ item.name ].saver )
    endif

endfunction "}}}

fun! s:SelectCurrent() "{{{

    let rctx = b:xptemplateData.renderContext
    let ph = rctx.leadingPlaceHolder
    let marks = ph.innerMarks

    let [ ctl, cbr ] = XPMposStartEnd( marks )


    if ctl == cbr
        call cursor( ctl )
        let rctx.userPostAction = ''
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
            let rctx.userPostAction = "\<esc>gv"
        else
            let rctx.userPostAction = "\<esc>gv\<C-g>"
        endif
        return ''

        " NOTE: Using <C-R>= output special chars like \<esc> \<C-v> cause
        " gvim7.3 on ubuntu 10.10 amd64 become lagger each time expanding a
        " snippet.
        " Now use feedkeys instead.

        " " Weird, but that's only way to select content
        " return "\<esc>gv\<C-g>"
    endif

endfunction "}}}

fun! s:EvalFilter( filter, global, context ) "{{{

    " TODO EvalFilter might be called from non-rendering phase, is there a snipObject?
    let rctx = b:xptemplateData.renderContext
    let snipptn = rctx.snipObject.ptn

    let a:filter.rc = 1
    let r = { 'rc': 1, 'filter': a:filter }

    let rst = xpt#eval#Eval( a:filter.text, a:global, a:context )

    if type( rst ) == type( 0 )
        let r.rc = 0
        return r
    endif

    if type( rst ) == type( '' )

        " indent adjusting should be done just before put onto screen.
        " call a:filter.AdjustIndent( a:context.startPos )

        " plain text is interpreted as plain text or snippet segment, depends
        " on if there is mark in it.
        "
        " To explicitly use plain text or snippet segment, use Echo() and
        " Build() respectively.
        if rst =~ snipptn.lft
            let r.action = 'build'
        else
            let r.action = 'text'
        endif
        let r.text = rst
        return r
    endif

    if type( rst ) == type( [] )
        let r.action = 'pum'
        let r.pum = rst
        return r

    else
        " rst is dictionary
        if has_key( rst, 'action' )
            call extend( r, rst, 'error' )
        else
            let text = get( r, 'text', '' )

            " effective action is determined by if there is item pattern in text
            if text =~ snipptn.lft
                let r.action = 'build'
            else
                let r.action = 'text'
            endif
        endif

        if ! has_key( r, 'marks' )
            let r.marks = a:filter.marks
        endif

        call s:LoadFilterActionSnippet( r )
    endif

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

fun! s:TextBetween( posList ) "{{{

    let [ s, e ] = a:posList

    if s[0] > e[0]
        return ""
    endif

    if s[0] == e[0]
        if s[1] == e[1]
            return ""
        else
            call s:log.Log( "content between " . string( [s, e] ) . ' is :' . getline(s[0])[ s[1] - 1 : e[1] - 2] )
            return getline(s[0])[ s[1] - 1 : e[1] - 2 ]
        endif
    endif


    let r = [ getline(s[0])[s[1] - 1:] ] + getline(s[0]+1, e[0]-1)

    if e[1] > 1
        let r += [ getline(e[0])[:e[1] - 2] ]
    else
        let r += ['']
    endif

    call s:log.Log( "content between " . string( [s, e] ) . ' is :'.join( r, "\n" ) )
    return join(r, "\n")

endfunction "}}}

fun! s:Goback() "{{{
    let renderContext = b:xptemplateData.renderContext
    " call cursor( XPMpos( renderContext.leadingPlaceHolder.mark.end ) )
    " return ''

    call s:SelectCurrent()
    return renderContext.userPostAction
endfunction "}}}

" TODO move away
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
    let b:xptemplateData.settingSwitch = xpt#stsw#New()
    call xpt#stsw#AddList( b:xptemplateData.settingSwitch,
          \[ '&l:textwidth', '0' ],
          \[ '&l:lazyredraw', '1' ],
          \[ '&l:indentkeys', { 'exe' : 'setl indentkeys-=*<Return>' } ],
          \[ '&l:cinkeys', { 'exe' : 'setl cinkeys-=*<Return>' } ],
          \)
    " \[ '&l:indentkeys', { 'exe' : 'setl indentkeys-=*<Return> | setl indentkeys-=o' } ],
    " \[ '&l:cinkeys', { 'exe' : 'setl cinkeys-=*<Return> | setl cinkeys-=o' } ],

    " provent horizontal scroll when putting raw snippet onto screen before building
    let b:xptemplateData.settingWrap = xpt#stsw#New()
    call xpt#stsw#Add( b:xptemplateData.settingWrap, '&l:wrap', '1' )

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


    call xpt#stsw#Switch( b:xptemplateData.settingSwitch )


    call xpt#msvr#Save( b:mapSaver )
    call xpt#msvr#Save( b:mapLiteral )

    call xpt#msvr#UnmapAll( b:mapSaver )
    call xpt#msvr#Literalize( b:mapLiteral, { 'insertAsSelect' : 1 } )



    " TODO map should distinguish between 'selection'
    " <C-v><C-v><BS> force pum to close
    exe 'inoremap <silent> <buffer>' g:xptemplate_nav_prev   '<C-v><C-v><BS><C-r>=<SID>ShiftBackward()<CR>'

    " exe 'inoremap <silent> <buffer>' g:xptemplate_nav_next   '<C-v><C-v><BS><C-r>=<SID>ShiftForward("")<CR>'
    exe 'inoremap <silent> <buffer>' g:xptemplate_nav_next   '<C-r>=<SID>ShiftForward("")<CR>'
    exe 'snoremap <silent> <buffer>' g:xptemplate_nav_cancel '<Esc>i<C-r>=<SID>ShiftForward("clear")<CR>'

    exe 'nnoremap <silent> <buffer>' g:xptemplate_goback     'i<C-r>=<SID>Goback()<CR>'
    exe 'inoremap <silent> <buffer>' g:xptemplate_goback     ' <C-v><C-v><BS><C-r>=<SID>Goback()<CR>'

    exe 'imap <silent> <buffer> <CR>' g:xptemplate_hook_before_cr . '<Plug>XPT_map_CR'
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

    call xpt#stsw#Restore( b:xptemplateData.settingSwitch )

    call xpt#msvr#Restore( b:mapLiteral )
    call xpt#msvr#Restore( b:mapSaver )

endfunction " }}}

" TODO move away
fun! XPTbufData() "{{{
    if !exists( 'b:xptemplateData' )
        call XPTemplateInit()
    endif
    return b:xptemplateData
endfunction "}}}

fun! XPTdefaultFtDetector() "{{{
    return &filetype
endfunction "}}}

fun! XPTemplateInit() "{{{

    if exists( 'b:xptemplateData' )
        return
    endif

    let b:xptemplateData = {
          \     'filetypes'         : {},
          \     'wrapStartPos'      : 0,
          \     'userWrapped'              : '',
          \     'savedReg'          : '',
          \     'snippetToParse'    : [],
          \     'abbrPrefix'        : {},
          \     'fallbacks'         : [],
          \     'phFilterContexts'   : [],
          \     'ftdetector'        : { 'priority' : s:priorities.lang,
          \                             'func' : function( 'XPTdefaultFtDetector' ) },
          \ }

    let b:xptemplateData.posStack = []
    let b:xptemplateData.stack = []

    let b:xptemplateData.currentExt = {}

    " which letter can be used in template name
    let b:xptemplateData.keyword = '\w'
    let b:xptemplateData.keywordList = []

    let b:xptemplateData.snipFileScope = {}
    let b:xptemplateData.snipFileScopeStack = []


    let b:xptemplateData.renderContext = xpt#rctx#New( b:xptemplateData )

    " TODO is this the right place to do that?
    call XPMsetBufSortFunction( function( 'XPTmarkCompare' ) )

    call s:XPTinitMapping()

    let b:_xpeval = { 'strMaskCache' : {}, 'evalCache' : {} }

    let b:_xptSnipCache = {
          \ 'conditions' : [],
          \ 'pumCache' : {
          \ }
          \ }

endfunction "}}}

fun! s:RedefinePattern() "{{{
    let xp = b:xptemplateData.snipFileScope.ptn

    let xp.lft = s:nonEscaped . xp.l
    let xp.rt  = s:nonEscaped . xp.r

    " for search
    let xp.lft_e = s:nonEscaped . '\\'.xp.l
    let xp.rt_e  = s:nonEscaped . '\\'.xp.r

    let xp.item_var          = '$\w\+'
    let xp.item_qvar         = '{$\w\+}'
    let xp.item_func         = '\w\+(\.\*)'
    let xp.item_qfunc        = '{\w\+(\.\*)}'
    let xp.itemContent       = '\_.\{-}'
    let xp.item              = xp.lft . '\%(' . xp.itemContent . '\)' . xp.rt


    " let xp.cursorPattern     = xp.lft . '\%('.s:cursorName.'\)' . xp.rt

    for [k, v] in items(xp)
        if k != "l" && k != "r"
            let xp[k] = '\V' . v
        endif
    endfor

endfunction "}}}

fun! s:UpdateFollowingPlaceHoldersWith( contentTyped, option ) "{{{

    let renderContext = b:xptemplateData.renderContext
    call s:log.Debug( 'option=' . string( a:option ) )
    call s:log.Debug( 'phase=' . renderContext.phase )

    let useGroupPost = renderContext.phase == 'post' && has_key( a:option, 'post' )
    if useGroupPost
        let group_flt_rst = a:option.post
    endif

    let [ s, e ] = a:option.leaderPosStart
    let leaderIndent = xpt#util#getIndentNr( [ s, e ] )

    call XPRstartSession()

    let phList = renderContext.item.placeHolders
    try
        for ph in phList
            call s:log.Log( 'name=' . ph.name )
            let flt = renderContext.phase == 'post'
                  \ ? get( ph, 'postFilter',
                  \     get( ph, 'liveFilter',  g:EmptyFilter ) )
                  \ : get( ph, 'liveFilter', g:EmptyFilter )


            call s:log.Log( 'UpdateFollowingPlaceHoldersWith : filter=' . string( flt ) )

            let phStartPos = XPMpos( ph.mark.start )
            let [ phln, phcol ] = phStartPos

            if flt isnot g:EmptyFilter

                let flt = copy( flt )

                call xpt#flt#Eval( flt, renderContext.ftScope.funcs,
                      \ { 'typed'    : a:contentTyped,
                      \   'startPos' : phStartPos } )


                " TODO ontime flt action support?

                " TODO re-adjust flt indent cause problems

            elseif useGroupPost
                let flt = copy( groupFilter )
                " TODO xpt#flt#AddIndentAccordingToPos now would has been done
                " in Eval().Duplicate call to it causing error
                call xpt#flt#AddIndentAccordingToPos( flt, phStartPos )

            else


                if a:contentTyped =~ '\V\n'
                    let followerIndent = xpt#util#getIndentNr( [ phln, phcol ] )

                    " Relatvie indent
                    let nIndent = max( [ 0, followerIndent - leaderIndent ] )

                    let textIndented = xpt#util#AddIndent( a:contentTyped, nIndent )

                    let flt = { 'rst' : { 'text' : textIndented } }
                else
                    let flt = { 'rst' : { 'text' : a:contentTyped } }
                endif


                " let flt = xpt#flt#New( -xpt#util#getIndentNr( phln, phcol ), a:contentTyped )

                " " TODO xpt#flt#AddIndentAccordingToPos now would has been done
                " " in Eval().Duplicate call to it causing error
                " call xpt#flt#AddIndentAccordingToPos( flt, phStartPos )

            endif
            let flttext = s:IndentFilterText(flt_rst, phStartPos)


            " TODO replace only when filter applied or filter.text has line break
            let text = xpt#util#TextBetween( XPMposStartEnd( ph.mark ) )
            if text !=# flt.rst.text
                call XPreplaceByMarkInternal( ph.mark.start, ph.mark.end, flt.rst.text )
            endif

            call s:log.Debug( 'after update 1 place holder:', xpt#util#TextBetween( XPMposStartEnd( renderContext.marks.tmpl ) ) )
        endfor
    catch /.*/
        call XPT#error( v:throwpoint )
        call XPT#error( v:exception )
    finally
        call XPRendSession()
    endtry

endfunction "}}}

fun! s:Crash(...) "{{{

    let msg = "XPTemplate session ends: " . join( a:000, "\n" )

    call XPPend()

    let x = b:xptemplateData

    " TODO clear depends on group status
    call s:ClearItemMapping( x.renderContext )

    while !empty( x.stack )
        let rctx = remove( x.stack, -1 )
        " TODO clear depends on group status
        call s:ClearItemMapping( rctx )
    endwhile

    call s:ClearMap()

    let x.stack = []
    let x.renderContext = xpt#rctx#New( x )
    call XPMflushWithHistory()

    call XPT#info( msg )

    call s:CallPlugin( 'finishAll', 'after' )

    " no post typing action
    return s:DONE
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
    let liveFilters = renderContext.snipSetting.liveFilters

    let flt = get( liveFilters, leader.name, g:EmptyFilter )

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

    call xpt#flt#Eval( a:filter, renderContext.ftScope.funcs, {
          \ 'typed' : contentTyped, 'startPos' : start } )


    if 0 is a:filter.rst.rc
        return

    elseif has_key( a:filter.rst, 'action' )
        call s:HandleOntypeAction( renderContext, a:filter )

    elseif has_key( a:filter.rst, 'text' )

        if a:filter.rst.text != contentTyped
            let [ start, end ] = XPMposStartEnd( leader.mark )
            call XPreplace( start, end, a:filter.rst.text )
            call s:XPTupdate()
        endif

    endif

endfunction "}}}

fun! s:HandleOntypeAction( renderContext, flt_rst ) "{{{

    let postaction = s:HandleAction( a:renderContext, a:flt_rst )

    if '' != postaction
        call feedkeys( postaction, 'n' )
    endif

endfunction "}}}

fun! s:HandleAction( renderContext, flt_rst ) "{{{
    " NOTE: handle only leader's action

    if a:renderContext.phase == 'post'
        let marks = a:renderContext.leadingPlaceHolder.mark
    else
        let marks = a:renderContext.leadingPlaceHolder.innerMarks
    endif


    let postaction = ''
    if a:filter.rst.action == 'next'

        if has_key( a:filter.rst, 'text' )

            " TODO replace by mark
            let [ start, end ] = XPMposList( marks.start, marks.end )
            call XPreplace( start, end, a:filter.rst.text )

        endif

        let postaction = s:ShiftForward( '' )

    elseif a:filter.rst.action == 'finishTemplate'
        let postaction = s:ActionFinish( a:filter )

    elseif a:filter.rst.action == ''
        " TODO other actions

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

    if g:xptemplate_strict == 2
                \&& a:renderContext.phase == 'fillin'

        if rc is g:XPM_RET.updated
              \ || ( type( rc ) == type( [] )
              \      && ( rc[ 0 ] != leaderMark.start && rc[ 0 ] != innerMarks.start
              \        || rc[ 1 ] != leaderMark.end && rc[ 1 ] != innerMarks.end ) )

            throw 'XPT:changes outside of place holder'

        endif

    endif

    if g:xptemplate_strict == 1
                \&& a:renderContext.phase == 'fillin'
                \&& rc is g:XPM_RET.updated
        " g:XPM_RET.updated means update made but not in likely range

        if rc is g:XPM_RET.updated
              \ || ( type( rc ) == type( [] )
              \      && ( rc[ 0 ] != leaderMark.start && rc[ 0 ] != innerMarks.start
              \        || rc[ 1 ] != leaderMark.end && rc[ 1 ] != innerMarks.end ) )

            undo
            call XPMupdate()

            " TODO better hint
            " TODO allow user to move?

            call XPT#info( "editing OUTSIDE place holder is not allowed whne g:xptemplate_strict=1, use " . g:xptemplate_goback . " to go back" )

            return g:XPT_RC.canceled

        endif
    endif

    return rc

endfunction "}}}

fun! s:XPTupdate() "{{{

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

    let leaderPos = XPMposStartEnd( renderContext.leadingPlaceHolder.mark )
    let contentTyped = xpt#util#TextBetween( leaderPos )

    if contentTyped ==# renderContext.lastContent
        call s:log.Log( "nothing different typed" )
        return
    endif

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
        call s:UpdateFollowingPlaceHoldersWith( contentTyped, { 'leaderPosStart' : leaderPos[ 0 ] } )
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


" TODO using mark may be better? Or not..
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

    if x.userWrapped isnot ''
        let x.wrapStartPos = 0
        let x.userWrapped = ''
    endif

    call s:CallPlugin( 'insertenter', 'after' )

endfunction "}}}

" TODO move away
fun! s:GetContextFT() "{{{

    let ft = b:xptemplateData.ftdetector.func()

    if ft == ''
        return 'unknown'
    else
        return ft
    endif

endfunction "}}}

" TODO move away
" TODO not good here to call XPTparseSnippets()
fun! s:GetContextFTObj() "{{{

    let x = b:xptemplateData
    let ft = s:GetContextFT()

    if has_key( x.filetypes, ft )
        " nothing to do

    else

        if ft == 'unknown'
            call s:LoadSnippetFile( 'unknown/unknown' )

        else
            " Some filetype is not supported yet by XPT, but "common" snippets
            " still should be loaded.
            "
            " We load "common" snippets by creating a fake snippet file.

            call xpt#parser#SnippetFileInit( '~~/xpt/pseudo/ftplugin/' . ft . '/' . ft . '.xpt.vim' )
            call xpt#parser#Include( '_common/common' )
            call XPTfiletypeInit()

        endif
    endif

    let ftScope = get( x.filetypes, ft, {} )

    return ftScope

endfunction "}}}

fun! s:LoadSnippetFile( snipname ) "{{{

    exe 'runtime! ftplugin/' . a:snipname . '.xpt.vim'
    call xpt#parser#LoadFTSnippets( a:snipname )
    call XPTfiletypeInit()

endfunction "}}}


" TODO When to init?
fun! s:XPTbufferInit() "{{{

    call XPTemplateInit()

endfunction "}}}

augroup XPT "{{{

    au!

    au BufEnter * call <SID>XPTbufferInit()

    au InsertEnter * call <SID>XPTcheck()

    au CursorMovedI * call <SID>XPTupdateTyping()

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


" " acp hack to detect if acp is showing
" let scriptnames = XPT#getCmdOutput( 'silent scriptnames' )
" let scrs = split( scriptnames, "\n" )
" for s in scrs
"     if s =~ '\V/autoload/acp.vim\$'
"         let acpline = s
"         break
"     endif
" endfor

" let acpsid = matchstr( acpline, '\V\s\*\zs\d\+' )

" let SS = function( '<SNR>' . acpsid . '_setTempOption' )


" fun! XPTwhat(x)
"     let s:acp_tempOptionSet = a:x
"     let a:x[ 0 ] = {}
"     return ''
" endfunction


" try
"     call SS( 0, 'readonly.XPTwhat(s:tempOptionSet)', &readonly )
" catch /.*/
" endtry

" echom string( s:acp_tempOptionSet )

let &cpo = s:oldcpo


