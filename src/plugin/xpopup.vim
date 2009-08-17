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


" TODO popup fix:select it if strictly matched
runtime plugin/debug.vim
runtime plugin/xpreplace.vim
runtime plugin/mapstack.vim

let s:log = CreateLogger( 'debug' )


" Script scope variables {{{
let s:sessionPrototype = {
            \ 'callback'    : {},
            \ 'list'        : [],
            \ 'prefixIndex' : {},
            \
            \ 'line'        : 0,
            \ 'col'         : 0,
            \ 'prefix'      : '',
            \ 'ignoreCase'  : 0,
            \ 'longest'     : '',
            \ 'matched'     : '',
            \ 'matchedCallback' : '', 
            \ 'currentList' : [],
            \ }
            " \ 'postAction'  : '',
" }}}

" API {{{

" Additional argument can be a list
fun! XPPopupNew(callback, data, ...) "{{{
    let list = ( a:0 == 0 ) ? [] : a:1

    let sess = deepcopy(s:sessionPrototype)
    let sess.callback = a:callback
    let sess.data = a:data

    call sess.createPrefixIndex([])
    call sess.addList(list)
    return sess
endfunction "}}}

fun! s:sessionPrototype.popup(start_col, ...) "{{{
    " Show the popup
    " callback keys:
    "   onEmpty(sess)
    "   onOneMatch(sess)


    " if multi items matched, whether to invoke call back or just show popup
    let doCallback = a:0 == 0 || a:1

    call s:log.Debug("doCallback=".doCallback)

    let sess = self

    let sess.line        = line(".")
    let sess.col         = a:start_col
    let sess.prefix      = getline( sess.line )[ sess.col - 1 : col(".") - 2 ]
    let sess.ignoreCase  = sess.prefix !~# '\u'
    let sess.currentList = s:filterCompleteList(sess)
    let sess.longest     = s:LongestPrefix(sess)

    call s:log.Debug("sess=".string(sess))

    let actionList = []


    " 1) ignoreCase may cause prefix doesn't equal to longest.
    " 2) LongestPrefix may enlarge to longer string
    if sess.longest !=# sess.prefix
        "   *) clear prefix
        "   *) check and clear pum. Because pum may not always show if
        "   user-typed does not match any on list elements.
        "   *) type longest prefix.

        let actionList += [ 'clearPrefix', 'clearPum', 'typeLongest' ]

    endif


    if len(sess.currentList) == 0
        call s:log.Debug("no matching")

        let sess.matched = ''
        let sess.matchedCallback = 'onEmpty'
        let actionList += ['callback']

    elseif len(sess.currentList) == 1
        call s:log.Debug("only 1 item matched")

        let sess.matched = type(sess.currentList[0]) == type({}) ? sess.currentList[0].word : sess.currentList[0]
        let sess.matchedCallback = 'onOneMatch'
        let actionList += ['callback']

    elseif sess.prefix != "" && sess.longest ==? sess.prefix && doCallback
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
                let actionList += ['callback']
                " let action = 'end'
                break
            endif
        endfor

        if sess.matched == ''
            let actionList += [ 'popup', 'fixPopup' ]
        endif

    else

        call s:log.Debug("no match and list is not empty")
        let actionList += [ 'popup', 'fixPopup' ]

    endif



    " Both popup and callback need this session
    let b:__xpp_current_session = sess

    call s:log.Debug("actionList=".string(actionList))

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

" }}}

" Operations of <C-R> {{{

fun! XPPprocess(list) "{{{
    " Deal with action chains 

    " no more actions pending
    if len(a:list) == 0
        return ""
    endif

    if !exists("b:__xpp_current_session")
        call s:log.Error("session does not exist!")
        return ""
    endif



    let sess = b:__xpp_current_session
    let actionName = a:list[ 0 ]
    let nextList = a:list[ 1 : ]
    let postAction = ""

    call s:log.Debug("actionName=".actionName)
    call s:log.Debug("postAction=".postAction)

    

    if actionName == 'clearPrefix'
        let n = col(".") - sess.col
        let postAction = repeat( "\<bs>", n )

    elseif actionName == 'clearPum'
        if pumvisible()
            let postAction = "\<C-e>"
        endif

    elseif actionName == 'typeLongest'
        let postAction = sess.longest

    elseif actionName == 'popup'
        call s:ApplyMap()
        call complete( sess.col, sess.currentList )

    elseif actionName == 'fixPopup'
        let current = getline(".")[ sess.col - 1 : col(".") - 2 ]

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

        if has_key(sess.callback, sess.matchedCallback)
            let postAction = sess.callback[ sess.matchedCallback ](sess)
        else 
            let postAction = ""
        endif

    else
        " nothing to do 
    endif


    if !empty(nextList)
        let  postAction .= "\<C-r>=XPPprocess(" . string( nextList ) . ")\<cr>"
    endif

    call s:log.Log("postAction=" . postAction)

    return postAction
    
endfunction "}}}

fun! XPPfixPopupOption() "{{{
    " Fix the problem that initially popup selection highlight stays on the
    " first item, second item or the last item. And that depends!
    "
    " XPPfixPopupOption() moves the selection highlight to before the first item,
    " that makes nothing selected. Just like the 'longest' option of
    " 'completeoption'
    " 
    " Selection is only made by user's pressing <C-p> or <C-n>


    call s:log.Log("start")

    if !s:PopupCheck()
        return ""
    endif

    call s:log.Log("check is ok")

    let sess = b:__xpp_current_session

    let current = getline(".")[ sess.col - 1 : col(".") - 2 ]

    call s:log.Log("current typed:".current)

    if current != sess.longest
        return "\<C-p>\<C-r>=XPPfixPopupOption()\<cr>"
    endif


    " Refresh : or popup may be partially shown. Display problem.
    return "\<C-p>\<C-r>=XPPfixFinalize()\<cr>"
endfunction "}}}

fun! XPPfixFinalize() "{{{
    call s:log.Log("start")

    let sess = b:__xpp_current_session

    let current = getline(".")[ sess.col - 1 : col(".") - 2 ]

    call s:log.Log("current typed:".current)

    if current == sess.longest
        return "\<C-p>\<C-r>=XPPfixFinalize()\<cr>"
    endif


    " scroll to first.
    return "\<C-n>\<C-n>\<C-p>"

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


    let action = actions . repeat( "\<bs>", len(current) - len(shorterKey) ) . "\<C-r>=XPPrepopup(0)\<cr>"
    " let action = actions . repeat( "\<bs>", len(current) - len(shorterKey) )

    call s:log.Log("action=".action)

    return action

endfunction "}}}

fun! XPPenlarge() "{{{
    if !s:PopupCheck()
        " use feedkeys, instead of <C-r>= for <C-r>= does not remap keys.
        call feedkeys("\<tab>", 'mt')
        return ""
        " return "\<tab>"
    endif

    " TODO here check pum
    " if pum is visible, <C-y> removes all typed
    "
    " if pumvisible

    return "\<C-r>=XPPrepopup(1)\<cr>"
    return "\<space>\<bs>\<C-r>=XPPrepopup()\<cr>"
    " return "\<space>\<bs>\<C-y>\<C-r>=XPPrepopup()\<cr>"
endfunction "}}}

fun! XPPrepopup(doCallback) "{{{
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
    return sess.popup(sess.col, a:doCallback)
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
" }}}

" Internal {{{
fun! s:ApplyMap() "{{{
    if exists("b:__xpp_mapped")
        return
    endif
    let b:__xpp_mapped = {}

    let b:__xpp_mapped.i_bs     =  g:MapPush('<bs>', 'i', 1)
    let b:__xpp_mapped.i_tab    =  g:MapPush('<tab>', 'i', 1)

    exe 'inoremap <buffer> <bs>' '<C-r>=XPPshorten()<cr>'
    exe 'inoremap <buffer> <tab>' '<C-r>=XPPenlarge()<cr>'

endfunction "}}}

fun! s:ClearMap() "{{{
    if !exists("b:__xpp_mapped")
        return
    endif

    call g:MapPop(b:__xpp_mapped.i_tab)
    call g:MapPop(b:__xpp_mapped.i_bs)

    unlet b:__xpp_mapped
endfunction "}}}

fun! s:End() "{{{
    call s:ClearMap()
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

" }}}

" Utils {{{
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

    for item in a:sess.list
        let key = ( type(item) == type({}) ) ? item.word : item

        if key =~ pattern
            let list += [ item ]
        endif
    endfor

    call s:log.Log("filtered list:".string(list))

    return list
endfunction "}}}

fun! s:FindShorter(map, key) "{{{
    let key = a:key

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

" }}}

" vim: set sw=4 sts=4 :
