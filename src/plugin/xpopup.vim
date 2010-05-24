" File Description {{{
" =============================================================================
" Popup wrapper for better popup behaviors
"                                                         by drdr.xp
"                                                            drdr.xp@gmail.com
"
" Usage :
"   XPPopupNew( callbacks,
"   \           {'privateKey':'privateValue'},
"   \           ['foo', 'bar', 'foobar'] ).popup( fromColumn )
"
" TODO sometime key-triggered pum does not clear <tab> map.
" =============================================================================
" }}}


if exists( "g:__XPOPUP_VIM__" ) && g:__XPOPUP_VIM__ >= XPT#ver
    finish
endif
let g:__XPOPUP_VIM__ = XPT#ver

let s:oldcpo = &cpo
set cpo-=< cpo+=B

" TODO popup fix:select it if strictly matched

runtime plugin/debug.vim
runtime plugin/classes/SettingSwitch.vim
runtime plugin/classes/MapSaver.vim


exe XPT#let_sid


let s:log = CreateLogger( 'warn' )
let s:log = CreateLogger( 'debug' )

fun! s:SetIfNotExist(k, v) "{{{
    if !exists(a:k)
        exe "let ".a:k."=".string(a:v)
    endif
endfunction "}}}

let s:opt = {
            \ 'doCallback'   : 'doCallback', 
            \ 'enlarge'      : 'enlarge', 
            \ 'acceptEmpty'  : 'acceptEmpty', 
            \ 'tabNav'       : 'tabNav',
            \}

let s:CHECK_PUM = 1

let s:errorTolerance = 3


" Script scope variables {{{
let s:sessionPrototype = {
            \ 'callback'    : {},
            \ 'list'        : [],
            \ 'key'         : '',
            \ 'prefixIndex' : {},
            \ 'popupCount'  : 0,
            \ 'sessCount'   : 0,
            \ 'errorInputCount' : 0,
            \
            \ 'line'            : 0,
            \ 'col'             : 0,
            \ 'prefix'          : '',
            \
            \ 'ignoreCase'      : 0,
            \ 'acceptEmpty'     : 0,
            \ 'matchWholeName'  : 0,
            \ 'matchPrefix'     : 0,
            \ 'strictInput'     : 0,
            \ 'tabNav'          : 0,
            \
            \ 'last'            : '',
            \ 'currentText'     : '',
            \ 'longest'         : '',
            \ 'matched'         : '',
            \ 'matchedCallback' : '',
            \ 'currentList'     : [],
            \ }
            " \ 'postAction'  : '',
" }}}


" Additional argument can be a list
fun! XPPopupNew( callback, data, ... ) "{{{

    let sess = deepcopy(s:sessionPrototype)
    let sess.callback = a:callback
    let sess.data = a:data

    call sess.createPrefixIndex([])

    if a:0 > 0

        let items = a:1

        if type( items ) == type( '' )
            call sess.SetTriggerKey( items )

        elseif type( items ) == type( [] )
            call sess.addList( items )

        else
            call s:log.Error( 'unsupported items type as pum items:' . str( items ) )

        endif

    endif

    return sess

endfunction "}}}

" TODO on first time popup do not accept empty
fun! s:popup( start_col, opt ) dict "{{{
    " Show the popup
    " callback keys:
    "   onEmpty(self)
    "   onOneMatch(self)

    " if multi items matched, whether to invoke call back or just show popup
    let doCallback  = get( a:opt, s:opt.doCallback, 1 )
    let ifEnlarge   = get( a:opt, s:opt.enlarge, 1 )


    call s:log.Debug("doCallback=".doCallback)

    let self.popupCount += 1

    " index of cursor position in line string
    " start from 1, without current character
    let cursorIndex = col(".") - 1 - 1

    let self.line        = line(".")
    let self.col         = a:start_col
    " let self.prefix      = cursorIndex >= 0 ? getline( self.line )[ self.col - 1 : cursorIndex ] : ''
    let self.prefix      = s:GetTextBeforeCursor( self )
    let self.ignoreCase  = self.prefix !~# '\u'


    if self.key != ''

        " TODO handle ifEnlarge arguments
        let self.longest = self.prefix
        let actions = self.KeyPopup( doCallback, ifEnlarge )

    else
        let self.currentList = s:filterCompleteList(self)

        if ifEnlarge
            let self.longest = s:LongestPrefix(self)
        else
            let self.longest = self.prefix
        endif

        let actions = self.ListPopup( doCallback, ifEnlarge )

    endif
    
    let actions = s:CreateSession( self ) . actions


    call s:ApplyMapAndSetting()

    call s:log.Debug("actions=".string( actions ))

    call s:log.Debug( '  Just after popup current line=' . getline( line("." ) ) )

    return actions

endfunction "}}}

fun PUMclear() "{{{
    return "\<C-v>\<C-v>\<BS>"
endfunction "}}}

fun! s:CreateSession( sess ) "{{{

    if !exists( 'b:__xpp_sess_count' )
        let b:__xpp_sess_count = 0
    endif

    let action = ''

    let b:__xpp_sess_count += 1
    let a:sess.sessCount = b:__xpp_sess_count

    if exists( 'b:__xpp_current_session' )
        call s:End()
        if pumvisible()
            let action .= PUMclear()
        endif
    endif

    
    let b:__xpp_current_session = a:sess

    return action
endfunction "}}}


fun! s:SetAcceptEmpty( acc ) dict "{{{
    let self.acceptEmpty = !!a:acc
    return self
endfunction "}}}

fun! s:SetMatchWholeName( mwn ) dict "{{{
    let self.matchWholeName = !!a:mwn
    return self
endfunction "}}}

fun! s:SetOption( opt ) dict "{{{
    if type( a:opt ) == type( [] )
        for optname in a:opt
            let self[ optname ] = 1
        endfor
    elseif type( a:opt ) == type( {} )
        for [ key, value ] in items( a:opt )
            let self[ key ] = value
        endfor
    endif
endfunction "}}}

fun! s:KeyPopup( doCallback, ifEnlarge ) dict "{{{

    let actionList = []

    " TODO check one match

    if a:ifEnlarge

        let actionList = [ 'clearPum', 'clearPrefix', 'typeLongest', 'triggerKey', 'setLongest' ]

        if a:doCallback
            let actionList += [ 'checkAndCallback' ]
        endif

    else

        let actionList = [ 'clearPum', 'clearPrefix', 'typeLongest', 'triggerKey', 'removeTrailing', 'forcePumShow' ]

    endif


    return "\<C-r>=XPPprocess(" . string( actionList ) . ")\<CR>"

endfunction "}}}

fun! s:ListPopup( doCallback, ifEnlarge ) dict "{{{


    call s:log.Debug( ' ListPopup current line=' . getline( line("." ) ) )

    " if pum need to show, previous pum must close first
    let actionClosePum = ''

    let actionList = []


    " TODO simplify the procedure of clearing PUM. 
    " NOTE: Calling clearPum only once may still cause vim fall back to line-wise completion

    " 1) ignoreCase may cause prefix doesn't equal to longest.
    " 2) LongestPrefix may enlarge to longer string
    if self.longest !=# self.prefix
        "   *) clear prefix
        "   *) check and clear pum. Because pum may not always show if
        "   user-typed does not match any on list elements.
        "   *) type longest prefix.

        let actionList += ['clearPum',  'clearPrefix', 'clearPum', 'typeLongest' ]

    endif

    if 0
        " !self.matchPrefix
        " call s:log.Debug("only 1 matched, but matchPrefix or callback is disabled")
        " let actionClosePum = PUMclear()
        " let actionList += [ 'popup', 'fixPopup' ]

    else

        if self.popupCount > 1
              \ && a:ifEnlarge
              \ && self.acceptEmpty
              \ && self.prefix == ''

            let self.matched = ''
            let self.matchedCallback = 'onOneMatch'
            let actionList = []
            let actionList += [ 'clearPum',  'clearPrefix', 'clearPum', 'callback' ]

        elseif len(self.currentList) == 0
            call s:log.Debug("no matching")

            let self.matched = ''
            let self.matchedCallback = 'onEmpty'
            let actionList += ['callback']

        elseif len(self.currentList) == 1
              \ && a:doCallback

            call s:log.Debug("only 1 item matched")

            if self.matchPrefix

                let self.matched = type(self.currentList[0]) == type({}) ? self.currentList[0].word : self.currentList[0]
                let self.matchedCallback = 'onOneMatch'
                let actionList += ['clearPum', 'clearPrefix', 'clearPum', 'typeMatched', 'callback']
            else
                call s:log.Debug("only 1 matched, but matchPrefix or callback is disabled")
                let actionClosePum = PUMclear()
                let actionList += [ 'popup', 'fixPopup' ]
            endif

        elseif self.prefix != "" 
              \ && self.longest ==? self.prefix 

            if self.matchPrefix && a:doCallback

                " If text typed matches all items with case ignored, Try to find
                " the first matched item.

                call s:log.Debug("try to call callback")

                let self.matched = ''
                for item in self.currentList
                    let key = type(item) == type({}) ? item.word : item

                    " the first match
                    if key ==? self.prefix
                        let self.matched = key
                        let self.matchedCallback = 'onOneMatch'
                        let actionList += ['clearPum', 'clearPrefix', 'clearPum', 'typeLongest', 'callback']
                        " let actionClosePum = 'end'
                        break
                    endif
                endfor

                if self.matched == ''
                    let actionClosePum = PUMclear()
                    let actionList += [ 'popup', 'fixPopup' ]
                endif

            else
                call s:log.Debug("only 1 matched, but matchPrefix or callback is disabled")
                
                let actionClosePum = PUMclear()
                let actionList += [ 'popup', 'fixPopup' ]
            endif

        else

            call s:log.Debug("no match and list is not empty")

            let actionClosePum = PUMclear()
            let actionList += [ 'popup', 'fixPopup' ]

        endif


    endif



    " if pum shows, prefix matching is enabled
    let self.matchPrefix = 1


    call s:log.Debug( ' After ListPopup current line=' . getline( line("." ) ) )

    return actionClosePum . "\<C-r>=XPPprocess(" . string( actionList ) . ")\<CR>"

endfunction "}}}

fun! s:SetTriggerKey( key ) dict "{{{
    let self.key = a:key
endfunction "}}}

fun! s:sessionPrototype.addList( list ) "{{{
    let list = a:list

    if list == []
        return
    endif

    if type( list[0] ) == type( '' )
        call map( list, '{"word" : v:val, "icase" : 1 }' )
    else
        call map( list, '{"word" : v:val["word"], "menu" : get( v:val, "menu", "" ), "icase" : 1 }' )
    endif

    let self.list += list
    call self.updatePrefixIndex( list )
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
          \ 'i_<S-TAB>', 
          \ 'i_<CR>', 
          \
          \ 'i_<C-e>', 
          \ 'i_<C-y>', 
          \)

    " Disable indent keys or cinkeys, or for c language, <C-\>,
    " then selecting snippet start with '#' causes a choas.
    " NOTE:  user-defined pum does not accept non-keywords char. pressing
    "       non-keywords char make pum disappear.

    let b:_xpp_setting_switch = g:SettingSwitch.New()
    call b:_xpp_setting_switch.AddList( 
          \ [ '&l:cinkeys', '' ], 
          \ [ '&l:indentkeys', '' ], 
          \ [ '&completeopt', 'menu,longest,menuone' ], 
          \)
          " \ [ '&iskeyword', '33-127,128-255' ], 
    " TODO  '&l:ignorecase', '1'???

    let b:__xpp_buffer_init = 1
endfunction "}}}

" Operations of <C-R>
fun! XPPprocess( list ) "{{{

    call s:log.Debug( '  Just before XPPprocess current line=' . getline( line("." ) ) )

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

    elseif actionName == 'triggerKey'
        " NOTE: no need to force pum shown. pum shows unless further action
        "       pended.
        " let postAction = sess.key . "\<C-n>\<C-p>"
        let postAction = sess.key

    elseif actionName == 'setLongest'
        let current = s:GetTextBeforeCursor( sess )



        if len( current ) > len( sess.longest )
            let postAction = repeat( "\<BS>", len( current ) - len( sess.longest ) ) 
                  \ . current[ len( sess.longest ) : ]

            let sess.longest = s:GetTextBeforeCursor( sess )
            if pumvisible()
                let nextList = [ 'clearPum', 'clearPrefix', 'typeLongest', 'triggerKey' ] + nextList
            else
                " NOTE: clearPum is necessary
                let nextList = [ 'clearPrefix', 'clearPum', 'typeLongest' ] + nextList
            endif
        endif


    elseif actionName == 'removeTrailing'
        let current = s:GetTextBeforeCursor( sess )

        if len( current ) > len( sess.longest )
            let postAction = repeat( "\<BS>", len( current ) - len( sess.longest ) )
        endif

    elseif actionName == 'forcePumShow'
        let postAction = "\<C-n>\<C-p>"

    elseif actionName == 'checkAndCallback'
        " return ""
        if pumvisible()
            return "\<C-n>\<C-p>"
            " return ""

        else
            let current = s:GetTextBeforeCursor( sess )
            let sess.matched = current
            let sess.matchedCallback = 'onOneMatch'

            " TODO use XPPcallback

            call s:log.Debug( "callback is:" . sess.matchedCallback )
            call s:End()

            " Note: after s:End(), b:__xpp_current_session is not valid any more

            let postAction = ""
            if has_key( sess.callback, sess.matchedCallback )
                let postAction = sess.callback[ sess.matchedCallback ]( sess )
                return postAction
            else
                return ''
            endif

        endif

    elseif actionName == 'keymodeEnlarge'

        let current = s:GetTextBeforeCursor( sess )

        call s:log.Debug( "current=" . string( current ) )
        call s:log.Debug( "last pumtext=" . string( sess.currentText ) )
        call s:log.Debug( "sess.col=" . sess.col )
        call s:log.Debug( "col('.')=" . col(".") )

        if sess.acceptEmpty && current == ''
            " nothing typed and empty input is acceptable

            let sess.longest = ''
            let sess.matched = ''
            let sess.matchedCallback = 'onOneMatch'

            let nextList = [ 'callback' ]

        elseif current !=# sess.currentText
            " something selected before enlarge

            let sess.longest = sess.currentText
            let sess.matched = sess.currentText
            let sess.matchedCallback = 'onOneMatch'

            " TODO simplify me
            let nextList = [ 'clearPrefix', 'typeLongest', 'callback' ]

        else
            " Something typed, and no item selected
            " In this case, re-popup with current prefix
            return sess.popup( sess.col,
                  \ { 'doCallback' : 1,
                  \   'enlarge'    : 1 } )
        endif

    elseif actionName == 'enlarge'

        let current = s:GetTextBeforeCursor( sess )

        if current !=# sess.currentText

            let sess.longest = sess.currentText
            let sess.matched = sess.currentText
            let sess.matchedCallback = 'onOneMatch'

            " TODO simplify me
            let nextList = [ 'clearPrefix', 'typeLongest', 'callback' ]

        else
            return sess.popup( sess.col,
                  \ { 'doCallback' : 1,
                  \   'enlarge'    : 1 } )
        endif



    elseif actionName == 'typeMatched'
        let postAction = sess.matched

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

        let current = s:GetTextBeforeCursor( sess )

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
        let  postAction .= "\<C-r>=XPPprocess(" . string( nextList ) . ")\<CR>"

    else
        " test concern

        " let postAction .= "\<C-n>\<C-p>"
        let postAction .= g:xpt_post_action

    endif

    call s:log.Log("postAction=" . postAction)


    return postAction
    
endfunction "}}}

fun! s:GetTextBeforeCursor( sess ) "{{{
    let c = col( "." )
    if c == 1
        return ''
    endif

    return getline(".")[ a:sess.col - 1 : c - 2 ]
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
    if !s:PopupCheck( s:CHECK_PUM )
        call feedkeys("\<CR>", 'mt')
        return ""
    endif

    return "\<C-r>=XPPaccept()\<CR>"
endfunction "}}}

fun! XPPup( key ) "{{{
    if !s:PopupCheck( s:CHECK_PUM )
        call feedkeys( a:key, 'mt' )
        return ""
    endif

    return "\<C-p>"
endfunction "}}}

fun! XPPdown( key ) "{{{
    if !s:PopupCheck( s:CHECK_PUM )
        call feedkeys( a:key, 'mt' )
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

    if !s:PopupCheck( ! s:CHECK_PUM )
        " 1) pum hidden by unmatch typing, but <bs> times restores pum. need
        " <c-e>
        " 2) pum hidden by quit insert mode or other causes
        " needn't <c-e>
        let s:pos = getpos(".")[ 1 : 2 ]
        return "\<C-e>\<C-r>=XPPcorrectPos()\<cr>\<bs>"
    endif


    if !pumvisible()
        return "\<BS>"
    endif


    let sess = b:__xpp_current_session

    let current = s:GetTextBeforeCursor( sess )


    if sess.key != ''
        return "\<BS>"
    endif


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

" TODO when pum shown, <space> does not close session
" TODO feedkeys <cr> if tabNav
fun! XPPenlarge( key ) "{{{
    call s:log.Log( "XPPenlarge called" )

    if !s:PopupCheck( s:CHECK_PUM )
        call s:log.Debug( "check failed" )
        call feedkeys( a:key, 'm' )
        return ""

    endif

    call s:log.Debug('current line=' . getline(line("."))  )

    return "\<C-r>=XPPrepopup(1, 'enlarge')\<cr>"

endfunction "}}}

fun! XPPcancel( key ) "{{{
    if !s:PopupCheck()
        " use feedkeys, instead of <C-r>= for <C-r>= does not remap keys.
        call feedkeys( a:key, 'mt' )
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

fun! XPPrepopup( doCallback, ifEnlarge ) "{{{

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


    if sess.key != ''
        " NOTE: Check if some element is select in pum

        let sess.currentText = s:GetTextBeforeCursor( sess )
        " TODO <C-e> clears typed!!.
        let action = "\<C-e>" . "\<C-r>=XPPprocess(" . string( [ 'keymodeEnlarge' ] ) . ")\<CR>"
        " let action = "\<C-r>=XPPprocess(" . string( [ 'clearPum', 'keymodeEnlarge' ] ) . ")\<CR>"

        return action

    else

        let action =  sess.popup(sess.col,
              \ { 'doCallback' : a:doCallback,
              \   'enlarge'    : a:ifEnlarge == 'enlarge' } )

        call s:log.Debug( ' After XPPrepopup current line=' . getline( line( "." ) ) )
        call s:log.Debug( '  action=' . action )


        " let action = "\<C-e>"

        return action

    endif
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


    let sess = b:__xpp_current_session

    exe 'inoremap <silent> <buffer> <UP>'   '<C-r>=XPPup("\<lt>UP>")<CR>'
    exe 'inoremap <silent> <buffer> <DOWN>' '<C-r>=XPPdown("\<lt>DOWN>")<CR>'

    exe 'inoremap <silent> <buffer> <bs>'  '<C-r>=XPPshorten()<cr>'


    exe 'inoremap <silent> <buffer> <C-e>' '<C-r>=XPPcancel("\<lt>C-e>")<cr>'

    if sess.tabNav
        " exe 'inoremap <silent> <buffer> <cr>'  '<C-r>=XPPselect("CR")<cr>'

        exe 'inoremap <silent> <buffer> <S-tab>' '<C-r>=XPPup("\<lt>S-Tab>")<cr>'
        exe 'inoremap <silent> <buffer> <tab>' '<C-r>=XPPdown("\<lt>TAB>")<cr>'
        exe 'inoremap <silent> <buffer> <cr>'  '<C-r>=XPPenlarge("\<lt>CR>")<cr>'
        exe 'inoremap <silent> <buffer> <C-y>' '<C-r>=XPPenlarge("\<lt>C-y>")<cr>'
    else
        exe 'inoremap <silent> <buffer> <tab>' '<C-r>=XPPenlarge("\<lt>TAB>")<cr>'
        exe 'inoremap <silent> <buffer> <cr>'  '<C-r>=XPPenlarge("\<lt>CR>")<cr>'
        exe 'inoremap <silent> <buffer> <C-y>' '<C-r>=XPPenlarge("\<lt>C-y>")<cr>'
        " exe 'inoremap <silent> <buffer> <cr>'  '<C-r>=XPPcr("\<lt>CR>")<cr>'
        " exe 'inoremap <silent> <buffer> <C-y>' '<C-r>=XPPaccept("\<lt>C-y>")<cr>'
    endif

    augroup XPpopup
        au!
        au CursorMovedI * call s:CheckAndFinish()
        au InsertEnter * call XPPend()
    augroup END

    call b:_xpp_setting_switch.Switch()

    if exists( ':AcpLock' )
        AcpLock
    endif

endfunction "}}}

fun! s:ClearMapAndSetting() "{{{
    call s:_InitBuffer()
    if !exists( 'b:__xpp_pushed' )
        return
    endif

    unlet b:__xpp_pushed

    call s:log.Debug( 'ClearMapAndSetting' )

    augroup XPpopup
        au!
    augroup END

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

fun! s:CheckAndFinish() "{{{

    if !exists( 'b:__xpp_current_session' )
        call s:End()
        return ''
    endif

    let sess = b:__xpp_current_session

    if !pumvisible()

        if line( "." ) == sess.line

            if sess.strictInput
                if col(".") > sess.col
                    call feedkeys( "\<BS>", 'n' )
                endif

            else
                return s:MistakeTypeEnd()
            endif

        else
            return s:MistakeTypeEnd()
        endif

    endif

    return ''

endfunction "}}}

fun! s:MistakeTypeEnd() "{{{
    call s:End()

    " NOTE: re-pop pum menu to clear last pum session.
    "
    "       <C-e> or <C-y> does not work in identical way in different case(
    "       chosen something in pum or not )
    return PUMclear()

    " return ''
endfunction "}}}

fun! XPPhasSession() "{{{
    return exists("b:__xpp_current_session")
endfunction "}}}

fun! XPPend() "{{{
    call s:End()
    if pumvisible()
        return PUMclear()
    endif

    return ''
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

fun! s:filterCompleteList( sess ) "{{{

    let list = []

    let caseOption = a:sess.ignoreCase ? '\c' : '\C'

    if a:sess.matchWholeName
        let pattern = '\V\^' . caseOption . a:sess.prefix . '\$'
    else
        let pattern = '\V\^' . caseOption . a:sess.prefix
    endif

    call s:log.Log( "sess.list=".string(a:sess.list) )
    call s:log.Log( "popup filter pattern=" . string( pattern ) )

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
            \   'popup',
            \   'SetAcceptEmpty',
            \   'SetMatchWholeName',
            \   'SetTriggerKey',
            \   'SetOption',
            \   'KeyPopup',
            \   'ListPopup',
            \ )

call extend( s:sessionPrototype, s:sessionPrototype2, 'force' )

let &cpo = s:oldcpo

