" File Description {{{
" =============================================================================
" Popup wrapper for better popup behaviors
"                                                         by drdr.xp
"                                                            drdr.xp@gmail.com
"
" Usage :
"   XPPopupNew(callbacks, {}, ['a', 'b', 'c']).popup(fromColumn)
"
" TODO trigger, XPTupdate, <bs> : makes pum shown but no session bind
" =============================================================================
" }}}

if exists("g:__XPOPUP_VIM__")
    finish
endif
let g:__XPOPUP_VIM__ = 1


let s:oldcpo = &cpo
set cpo-=< cpo+=B
" TODO popup fix:select it if strictly matched
runtime plugin/debug.vim
runtime plugin/SettingSwitch.class.vim
runtime plugin/MapSaver.class.vim


exe XPT#let_sid


let s:log = CreateLogger( 'warn' )
" let s:log = CreateLogger( 'debug' )

fun! s:SetIfNotExist(k, v) "{{{
  if !exists(a:k)
    exe "let ".a:k."=".string(a:v)
  endif
endfunction "}}}

let s:opt = {
            \'doCallback'   : 'doCallback', 
            \'enlarge'      : 'enlarge', 
            \'acceptEmpty'  : 'acceptEmpty', 
            \}



" Script scope variables {{{
let s:sessionPrototype = {
            \ 'callback'    : {},
            \ 'list'        : [],
            \ 'prefixIndex' : {},
            \ 'popupCount'  : 0,
            \
            \ 'line'        : 0,
            \ 'col'         : 0,
            \ 'prefix'      : '',
            \ 'ignoreCase'  : 0,
            \ 'acceptEmpty' : 0,
            \ 'last'        : '',
            \ 'longest'     : '',
            \ 'matched'     : '',
            \ 'matchedCallback' : '', 
            \ 'currentList' : [],
            \ }
            " \ 'postAction'  : '',
" }}}


" Additional argument can be a list
fun! XPPopupNew(callback, data, ...) "{{{

    let sess = deepcopy(s:sessionPrototype)
    let sess.callback = a:callback
    let sess.data = a:data

    call sess.createPrefixIndex([])

    if a:0 > 0
        let data = a:1
        if type( data ) == type( '' )
            " XXX
            " call sess.setTriggerKey( data )
        elseif type( data ) == type( [] )
            call sess.addList( data )
        endif
    endif

    return sess
endfunction "}}}

fun! s:SetAcceptEmpty( acc ) dict "{{{
    let self.acceptEmpty = !!a:acc
    return self
endfunction "}}}

" TODO on first time popup do not accept empty
fun! s:popup(start_col, opt) dict "{{{
    " Show the popup
    " callback keys:
    "   onEmpty(sess)
    "   onOneMatch(sess)

    " if multi items matched, whether to invoke call back or just show popup
    let doCallback  = get( a:opt, s:opt.doCallback, 1 )
    let ifEnlarge   = get( a:opt, s:opt.enlarge, 1 )



    call s:log.Debug("doCallback=".doCallback)

    let sess = self

    let sess.popupCount += 1

    " index of cursor position in line string
    " start from 1, without current character
    let cursorIndex = col(".") - 1 - 1

    let sess.line        = line(".")
    let sess.col         = a:start_col
    let sess.prefix      = cursorIndex >= 0 ? getline( sess.line )[ sess.col - 1 : cursorIndex ] : ''
    let sess.ignoreCase  = sess.prefix !~# '\u'
    let sess.currentList = s:filterCompleteList(sess)
    if ifEnlarge
        let sess.longest     = s:LongestPrefix(sess)
    else
        let sess.longest     = sess.prefix
    endif


    " call s:log.Debug("sess=".string(sess))

    let actionList = []




    " TODO simplify the procedure of clearing PUM. 
    " Note: clearPum only once may still cause vim fall back to line-wise completion

    " 1) ignoreCase may cause prefix doesn't equal to longest.
    " 2) LongestPrefix may enlarge to longer string
    if sess.longest !=# sess.prefix
        "   *) clear prefix
        "   *) check and clear pum. Because pum may not always show if
        "   user-typed does not match any on list elements.
        "   *) type longest prefix.

        let actionList += ['clearPum',  'clearPrefix', 'clearPum', 'typeLongest' ]

    endif


    " TODO double <tab>
    if sess.popupCount > 1 && ifEnlarge && sess.acceptEmpty && sess.prefix == ''
        let sess.matched = ''
        let sess.matchedCallback = 'onOneMatch'
        let actionList = []
        let actionList += [ 'clearPum',  'clearPrefix', 'clearPum', 'callback' ]

    elseif len(sess.currentList) == 0
        call s:log.Debug("no matching")

        let sess.matched = ''
        let sess.matchedCallback = 'onEmpty'
        let actionList += ['callback']

    elseif len(sess.currentList) == 1
          \&& doCallback
        call s:log.Debug("only 1 item matched")

        let sess.matched = type(sess.currentList[0]) == type({}) ? sess.currentList[0].word : sess.currentList[0]
        let sess.matchedCallback = 'onOneMatch'
        let actionList += ['clearPum', 'clearPrefix', 'clearPum', 'typeLongest', 'callback']

    elseif sess.prefix != "" 
          \&& sess.longest ==? sess.prefix 
          \&& doCallback
        " If the typed text matches all items with case ignored, Try to find
        " the first matched item.

        call s:log.Debug("try to call callback")

        let sess.matched = ''
        for item in sess.currentList
            let key = type(item) == type({}) ? item.word : item

            " the first match
            if key ==? sess.prefix
                let sess.matched = key
                let sess.matchedCallback = 'onOneMatch'
                let actionList += ['clearPum', 'clearPrefix', 'clearPum', 'typeLongest', 'callback']
                " let action = 'end'
                break
            endif
        endfor

        if sess.matched == ''
            let actionList += [ 'popup', 'fixPopup' ]
            " let actionList += [ 'popup' ]
        endif

    else

        call s:log.Debug("no match and list is not empty")
        let actionList += [ 'popup', 'fixPopup' ]
        " let actionList += [ 'popup' ]

    endif



    " Both popup and callback need this session
    let b:__xpp_current_session = sess

    call s:log.Debug("actionList=".string(actionList))

    call s:ApplyMapAndSetting()

    return "\<C-r>=XPPprocess(" . string(actionList) . ")\<cr>"

endfunction "}}}

fun! s:sessionPrototype.addList(list) "{{{
    let self.list += a:list
    call self.updatePrefixIndex(a:list)
endfunction "}}}

" the number of items with a certain prefix
fun! s:sessionPrototype.createPrefixIndex(list) "{{{
    let self.prefixIndex = { 'keys' : {}, 'lowerkeys' : {}, 'ori' : {}, 'lower' : {} }
    call self.updatePrefixIndex(a:list)
endfunction "}}}

fun! s:sessionPrototype.updatePrefixIndex(list) "{{{
    for item in a:list
        let key = ( type(item) == type({}) ) ?item.word : item

        if !has_key(self.prefixIndex.keys, key)
            let self.prefixIndex.keys[ key ] = 1
            call s:UpdateIndex(self.prefixIndex.ori, key)
        endif

        let lowerKey = substitute(key, '.', '\l&', 'g')

        if !has_key(self.prefixIndex.lowerkeys, lowerKey)
            let self.prefixIndex.lowerkeys[ lowerKey ] = 1
            call s:UpdateIndex(self.prefixIndex.lower, lowerKey)
        endif
    endfor
endfunction "}}}



fun! s:_InitBuffer() "{{{
    if exists( 'b:__xpp_buffer_init' )
        return
    endif

    let b:_xpp_map_saver = g:MapSaver.New( 1 )
    call b:_xpp_map_saver.AddList( 
          \ 'i_<UP>', 
          \ 'i_<DOWN>', 
          \
          \ 'i_<BS>', 
          \ 'i_<TAB>', 
          \ 'i_<CR>', 
          \
          \ 'i_<C-e>', 
          \ 'i_<C-y>', 
          \)

    " Disable indent keys or cinkeys, or for c language, <C-\>,
    " then selecting snippet start with '#' causes a choas.
    " NOTE:  user-defined pum does not accept non-keywords char. pressing
    "       non-keywords char make pum disappear.
    "
    " 33 is the min visual char "!".
    " 127 is last ascii char.
    " and other multi bytes letters.
    let b:_xpp_setting_switch = g:SettingSwitch.New()
    call b:_xpp_setting_switch.AddList( 
          \ [ '&l:cinkeys', '' ], 
          \ [ '&l:indentkeys', '' ], 
          \ [ '&completeopt', 'menu,longest' ], 
          \)
          " \ [ '&iskeyword', '33-127,128-255' ], 
    " TODO  '&l:ignorecase', '1'???

    let b:__xpp_buffer_init = 1
endfunction "}}}

" Operations of <C-R>

fun! XPPprocess(list) "{{{
    " Deal with action chains 

    " no more actions pending

    if !exists("b:__xpp_current_session")
        call s:log.Error("session does not exist!")
        return ""
    endif

    let sess = b:__xpp_current_session

    if len(a:list) == 0
        return "\<C-n>\<C-p>"
    endif




    let actionName = a:list[ 0 ]
    let nextList = a:list[ 1 : ]
    let postAction = ""

    call s:log.Debug("actionName=".actionName)
    call s:log.Debug("postAction=".postAction)
    call s:log.Debug('current line=' . getline(line("."))  )

    

    if actionName == 'clearPrefix'
        let n = col(".") - sess.col
        let postAction = repeat( "\<bs>", n )

    elseif actionName == 'clearPum'
        if pumvisible()
            let postAction = "\<C-e>"
        endif

    elseif actionName == 'typeLongest'
        let postAction = sess.longest

    elseif actionName == 'type'
        let postAction = remove( nextList, 0 )

    elseif actionName == 'popup'
        " call s:ApplyMapAndSetting()
        call complete( sess.col, sess.currentList )
        " let postAction =  XPpum#complete( sess.col, sess.currentList
              " \ , function( '<SNR>' . s:sid . 'ApplyMapAndSetting' ) )

    elseif actionName == 'fixPopup'


        let beforeCursor = col( "." ) - 2
        let beforeCursor = beforeCursor == -1 ? 0 : beforeCursor
        let current = getline(".")[ sess.col - 1 : beforeCursor ]

        " find out where we are in the popup list
        let i = 0
        let j = -1
        for v in sess.currentList
            let key = type(v) == type({}) ? v.word : v

            if key ==# current
                let j = i
                break
            endif

            let i += 1
        endfor

        call s:log.Debug("j=".j)


        if j != -1
            let postAction .= repeat( "\<C-p>", j + 1 )
        endif

    elseif actionName == 'callback'

        call s:log.Debug("callback is:".sess.matchedCallback)
        call s:End()

        " Note: after s:End(), b:__xpp_current_session is not valid any more

        let postAction = ""
        if has_key(sess.callback, sess.matchedCallback)
            let postAction = sess.callback[ sess.matchedCallback ](sess)
            return postAction
        endif

    elseif actionName == 'end'
        call s:End()
        let postAction = ''

    else
        " nothing to do 
    endif


    if !empty(nextList)
        let  postAction .= "\<C-r>=XPPprocess(" . string( nextList ) . ")\<cr>"

    else
        " test concern

        " let postAction .= "\<C-n>\<C-p>"
        let postAction .= g:xpt_post_action

    endif

    call s:log.Log("postAction=" . postAction)



    return postAction
    
endfunction "}}}


" Behaviors of Popup {{{
"                                  |
" pre-type   post-type             |  <c-e>        <c-y>          pumvisible()
" ---------------------------------+------------------------------------------
" nothing    nothing               |  nothing      nothing        1
"            select                |  nothing      selection      1
"            sth        match      |  post         nothing        1
"                       unmatch    |  post         <c-y>          0
"                                  |
" sth        nothing               |  nothing      pre            1
"            select                |  pre          selection      1
"            sth        match      |  post         pre            1
"                       unmatch    |  post         pre+<c-y>      0
"                                  |
"                                  |
" }}}


" NOTE: complete() has the problem that it select a random element when pum shown
fun! XPPcomplete(col, list) "{{{
    let oldcfu = &completefunc
    set completefunc=XPPcompleteFunc
    return "\<C-x>\<C-u>"
endfunction "}}}


fun! XPPcr() "{{{
    if !s:PopupCheck(1)
        call feedkeys("\<CR>", 'mt')
        return ""
    endif

    return "\<C-r>=XPPaccept()\<CR>"
endfunction "}}}

fun! XPPup() "{{{
    if !s:PopupCheck(1)
        call feedkeys("\<UP>", 'mt')
        return ""
    endif

    return "\<C-p>"
endfunction "}}}

fun! XPPdown() "{{{
    if !s:PopupCheck(1)
        call feedkeys("\<DOWN>", 'mt')
        return ""
    endif

    return "\<C-n>"
endfunction "}}}

fun! XPPcallback() "{{{
    if !exists("b:__xpp_current_session")
        return ""
    endif

    let sess = b:__xpp_current_session
    call s:End()

    call s:log.Debug("callback is:".sess.matchedCallback)

    if has_key(sess.callback, sess.matchedCallback)
        let post = sess.callback[ sess.matchedCallback ](sess)
    else 
        let post = ""
    endif

    return post
endfunction "}}}

fun! XPPshorten() "{{{
    if !s:PopupCheck()
        " 1) pum hidden by unmatch typing, but <bs> times restores pum. need
        " <c-e>
        " 2) pum hidden by quit insert mode or other causes
        " needn't <c-e>
        let s:pos = getpos(".")[ 1 : 2 ]
        return "\<C-e>\<C-r>=XPPcorrectPos()\<cr>\<bs>"
    endif

    let sess = b:__xpp_current_session


    let current = getline(".")[ sess.col - 1 : col(".") - 2 ]

    call s:log.Log("current typed=".current)

    " <bs> pressed when no content can be removed any more.
    if current == ''
        call s:End()
        return "\<bs>"
    endif


    " TODO simplify this
    let actions = "\<C-y>"
    let actions = ""


    let prefixMap = ( sess.ignoreCase ) ? sess.prefixIndex.lower : sess.prefixIndex.ori
    call s:log.Log("prefix map:".string(prefixMap))

    let shorterKey = s:FindShorter(prefixMap, ( sess.ignoreCase ? substitute(current, '.', '\l&', 'g') : current ))
    call s:log.Log("shorterKey=".shorterKey)


    let action = actions . repeat( "\<bs>", len(current) - len(shorterKey) ) . "\<C-r>=XPPrepopup(0, 'noenlarge')\<cr>"
    " let action = actions . repeat( "\<bs>", len(current) - len(shorterKey) )

    call s:log.Log("action=".action)

    return action

endfunction "}}}

fun! XPPenlarge() "{{{
    if !s:PopupCheck()
        " use feedkeys, instead of <C-r>= for <C-r>= does not remap keys.
        call feedkeys("\<tab>", 'mt')
        return ""
    endif

    " TODO here check pum
    " if pum is visible, <C-y> removes all typed
    "
    " if pumvisible

    return "\<C-r>=XPPrepopup(1, 'enlarge')\<cr>"
endfunction "}}}

fun! XPPcancel() "{{{
    if !s:PopupCheck()
        " use feedkeys, instead of <C-r>= for <C-r>= does not remap keys.
        call feedkeys("\<C-e>", 'mt')
        return ""
    endif

    return "\<C-r>=XPPprocess(" . string( [ 'clearPum', 'clearPrefix', 'typeLongest', 'end' ] ) . ")\<cr>"

endfunction "}}}

fun! XPPaccept() "{{{
    if !s:PopupCheck()
        " use feedkeys, instead of <C-r>= for <C-r>= does not remap keys.
        call feedkeys("\<C-y>", 'mt')
        return ""
    endif

    let sess = b:__xpp_current_session
    let beforeCursor = col( "." ) - 2
    let beforeCursor = beforeCursor == -1 ? 0 : beforeCursor

    let toType = getline( sess.line )[ sess.col - 1 : beforeCursor ]

    return "\<C-r>=XPPprocess(" . string( [ 'clearPum', 'clearPrefix', 'type', toType, 'end' ] ) . ")\<cr>"

endfunction "}}}

fun! XPPrepopup(doCallback, ifEnlarge) "{{{
    " If re-popup is called by XPPshorten, matched item should not trigger callback,
    " to let user see what matches. 
    "
    " If it is call by XPPenlarge, callback should be called as soon as possible.
    " But normally, XPPenlarge does NOT call callbacks if the longest  exceeds
    " user typed text.

    if !exists("b:__xpp_current_session")
        " no post action
        return ""
    endif
    let sess = b:__xpp_current_session
    return sess.popup(sess.col, { 'doCallback' : a:doCallback, 'enlarge' : a:ifEnlarge == 'enlarge' } )
endfunction "}}}

fun! XPPcorrectPos() "{{{
    let p = getpos(".")[1:2]
    call s:log.Debug("before correct pos, line=".getline("."))
    if p != s:pos
        unlet s:pos
        return "\<bs>"
    else
        unlet s:pos
        return ""
    endif
endfunction "}}}

" Internal --------------------------------------------------------

" TODO using g:xptemplate_nav_next for enlarge ?
fun! s:ApplyMapAndSetting() "{{{
    call s:_InitBuffer()

    if exists( 'b:__xpp_pushed' )
        return
    endif

    let b:__xpp_pushed = 1

    call s:log.Debug( 'ApplyMapAndSetting' )

    call b:_xpp_map_saver.Save()

    exe 'inoremap <silent> <buffer> <UP>'   '<C-r>=XPPup()<CR>'
    exe 'inoremap <silent> <buffer> <DOWN>' '<C-r>=XPPdown()<CR>'

    exe 'inoremap <silent> <buffer> <bs>'  '<C-r>=XPPshorten()<cr>'
    exe 'inoremap <silent> <buffer> <tab>' '<C-r>=XPPenlarge()<cr>'
    exe 'inoremap <silent> <buffer> <cr>'  '<C-r>=XPPcr()<cr>'
    exe 'inoremap <silent> <buffer> <C-e>' '<C-r>=XPPcancel()<cr>'
    exe 'inoremap <silent> <buffer> <C-y>' '<C-r>=XPPaccept()<cr>'

    " augroup XPP
        " au!
        " au CursorMovedI * call s:CheckAndRepop()
    " augroup END

    call b:_xpp_setting_switch.Switch()

    if exists( ':AcpLock' )
        AcpLock
    endif

endfunction "}}}


fun! s:CheckAndRepop() "{{{
    if !exists( 'b:__xpp_buffer_init' )
        return
    endif

    if !pumvisible()
          \ && len(b:__xpp_current_session.currentList) > 1
        call feedkeys( "\<C-r>=XPPrepopup(0, 'noenlarge')\<cr>" )
    endif
endfunction "}}}

fun! s:ClearMapAndSetting() "{{{
    call s:_InitBuffer()
    if !exists( 'b:__xpp_pushed' )
        return
    endif

    unlet b:__xpp_pushed

    call s:log.Debug( 'ClearMapAndSetting' )

    " augroup XPP
        " au!
    " augroup END

    " if &completefunc == 'XPPcompleteFunc'
        " let 


    call b:_xpp_map_saver.Restore()
    call b:_xpp_setting_switch.Restore()
    if exists( ':AcpUnlock' )
        try
            AcpUnlock
        catch /.*/
            
        endtry
    endif

endfunction "}}}


fun! XPPend() "{{{
    call s:End()
endfunction "}}}

fun! s:End() "{{{
    call s:ClearMapAndSetting()
    if exists("b:__xpp_current_session")
        unlet b:__xpp_current_session
    endif
endfunction "}}}

fun! s:PopupCheck(...) "{{{
    " Check if popup is shown, and if cursor is in a valid position
    " Return 0 if check failed that popup can not continue.
    " @param : a:1      to check popup menu or not. default : check popup menu

    call s:log.Log("start")

    let checkPum = ( a:0 == 0 || a:1 )

    if !exists("b:__xpp_current_session")
        call s:log.Log("buffer session does not exist, to end popup")
        call s:End()
        return 0
    endif

    let sess = b:__xpp_current_session

    if sess.line != line(".") || col(".") < sess.col || (checkPum && !pumvisible())
        call s:log.Log("invalid position: line=".line("."), 'col='.col("."), 'sess.col='.sess.col, 'pum visibile='.pumvisible())
        call s:End()
        return 0
    endif

    call s:log.Log("popup check is ok")
    return 1
endfunction "}}}


" Utils -------------------------------------------------------- 

fun! s:UpdateIndex(map, key) "{{{
    let  [ i, len ] = [ 0, len(a:key) ]

    while i < len
        let prefix = a:key[ 0 : i - 1 ]
        if !has_key( a:map, prefix )
            let a:map[ prefix ] = 1
        else
            let a:map[ prefix ] += 1
        endif

        let i += 1
    endwhile

endfunction "}}}

fun! s:LongestPrefix(sess) "{{{
    let longest = ".*"

    for e in a:sess.currentList
        let key = ( type(e) == type({}) ) ? e.word : e

        if longest == ".*"
            let longest  = a:sess.ignoreCase ? substitute(key, '.', '\l&', 'g') : key
        else
            while key !~ '^\V' . ( a:sess.ignoreCase ? '\c' : '\C' ) . escape(longest, '\') && len(longest) > 0
                let longest = longest[ : -2 ] " remove one char
            endwhile
        endif
    endfor

    let longest = ( longest == '.*' ) ? '' : longest

    " case issue
    if a:sess.prefix !=# longest[ : len(a:sess.prefix) - 1 ]
        let longest = a:sess.prefix . longest[ len(a:sess.prefix) : ]
    endif

    call s:log.Log("longest=".longest)

    return longest
endfunction "}}}

fun! s:filterCompleteList(sess) "{{{
    let list = []
    let pattern = '^\V' . ( a:sess.ignoreCase ? '\c' : '\C' ) . a:sess.prefix

    call s:log.Log("sess.list=".string(a:sess.list))
    call s:log.Log( "popup filter pattern=" . string( pattern ) )

    for item in a:sess.list
        let key = ( type(item) == type({}) ) ? item.word : item

        " call s:log.Debug( 'key=' . key )
        if key =~ pattern
            let list += [ item ]
        endif
    endfor

    call s:log.Log("filtered list:".string(list))

    return list
endfunction "}}}

fun! s:FindShorter(map, key) "{{{
    let key = a:key

    if len( key ) == 1
      return ''
    endif

    let nmatch = has_key(a:map, key) ? a:map[key] : 1

    if !has_key( a:map, key[ : -2 ] )
        call s:log.Log("no match")
        return key[ : -2 ]
    endif

    let key = key[ : -2 ]
    while key != '' && a:map[key] == nmatch
        let key = key[ : -2 ]
    endwhile

    return key
endfunction "}}}



fun! s:ClassPrototype(...) "{{{
    let p = {}
    for name in a:000
        let p[ name ] = function( '<SNR>' . s:sid . name )
    endfor

    return p
endfunction "}}}


let s:sessionPrototype2 =  s:ClassPrototype(
            \    'popup',
            \   'SetAcceptEmpty', 
            \)

call extend( s:sessionPrototype, s:sessionPrototype2, 'force' )

let &cpo = s:oldcpo

