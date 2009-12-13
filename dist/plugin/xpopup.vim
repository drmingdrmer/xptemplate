if exists("g:__XPOPUP_VIM__")
    finish
endif
let g:__XPOPUP_VIM__ = 1
let s:oldcpo = &cpo
set cpo-=< cpo+=B
runtime plugin/debug.vim
runtime plugin/SettingSwitch.class.vim
runtime plugin/MapSaver.class.vim
exe XPT#let_sid
let s:log = CreateLogger( 'warn' )
fun! s:SetIfNotExist(k, v) 
  if !exists(a:k)
    exe "let ".a:k."=".string(a:v)
  endif
endfunction 
let s:opt = {
            \'doCallback'   : 'doCallback', 
            \'enlarge'      : 'enlarge', 
            \'acceptEmpty'  : 'acceptEmpty', 
            \}
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
fun! XPPopupNew(callback, data, ...) 
    let list = ( a:0 == 0 ) ? [] : a:1
    let sess = deepcopy(s:sessionPrototype)
    let sess.callback = a:callback
    let sess.data = a:data
    call sess.createPrefixIndex([])
    call sess.addList(list)
    return sess
endfunction 
fun! s:SetAcceptEmpty( acc ) dict 
    let self.acceptEmpty = !!a:acc
    return self
endfunction 
fun! s:popup(start_col, opt) dict 
    let doCallback  = get( a:opt, s:opt.doCallback, 1 )
    let ifEnlarge   = get( a:opt, s:opt.enlarge, 1 )
    let sess = self
    let sess.popupCount += 1
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
    let actionList = []
    if sess.longest !=# sess.prefix
        let actionList += ['clearPum',  'clearPrefix', 'clearPum', 'typeLongest' ]
    endif
    if sess.popupCount > 1 && ifEnlarge && sess.acceptEmpty && sess.prefix == ''
        let sess.matched = ''
        let sess.matchedCallback = 'onOneMatch'
        let actionList = []
        let actionList += [ 'clearPum',  'clearPrefix', 'clearPum', 'callback' ]
    elseif len(sess.currentList) == 0
        let sess.matched = ''
        let sess.matchedCallback = 'onEmpty'
        let actionList += ['callback']
    elseif len(sess.currentList) == 1
          \&& doCallback
        let sess.matched = type(sess.currentList[0]) == type({}) ? sess.currentList[0].word : sess.currentList[0]
        let sess.matchedCallback = 'onOneMatch'
        let actionList += ['clearPum', 'clearPrefix', 'clearPum', 'typeLongest', 'callback']
    elseif sess.prefix != "" 
          \&& sess.longest ==? sess.prefix 
          \&& doCallback
        let sess.matched = ''
        for item in sess.currentList
            let key = type(item) == type({}) ? item.word : item
            if key ==? sess.prefix
                let sess.matched = key
                let sess.matchedCallback = 'onOneMatch'
                let actionList += ['clearPum', 'clearPrefix', 'clearPum', 'typeLongest', 'callback']
                break
            endif
        endfor
        if sess.matched == ''
            let actionList += [ 'popup', 'fixPopup' ]
        endif
    else
        let actionList += [ 'popup', 'fixPopup' ]
    endif
    let b:__xpp_current_session = sess
    call s:ApplyMapAndSetting()
    return "\<C-r>=XPPprocess(" . string(actionList) . ")\<cr>"
endfunction 
fun! s:sessionPrototype.addList(list) 
    let self.list += a:list
    call self.updatePrefixIndex(a:list)
endfunction 
fun! s:sessionPrototype.createPrefixIndex(list) 
    let self.prefixIndex = { 'keys' : {}, 'lowerkeys' : {}, 'ori' : {}, 'lower' : {} }
    call self.updatePrefixIndex(a:list)
endfunction 
fun! s:sessionPrototype.updatePrefixIndex(list) 
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
endfunction 
fun! s:_InitBuffer() 
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
    let b:_xpp_setting_switch = g:SettingSwitch.New()
    call b:_xpp_setting_switch.AddList( 
          \ [ '&l:cinkeys', '' ], 
          \ [ '&l:indentkeys', '' ], 
          \)
    let b:__xpp_buffer_init = 1
endfunction 
fun! XPPprocess(list) 
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
        call complete( sess.col, sess.currentList )
    elseif actionName == 'fixPopup'
        let beforeCursor = col( "." ) - 2
        let beforeCursor = beforeCursor == -1 ? 0 : beforeCursor
        let current = getline(".")[ sess.col - 1 : beforeCursor ]
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
        if j != -1
            let postAction .= repeat( "\<C-p>", j + 1 )
        endif
    elseif actionName == 'callback'
        call s:End()
        let postAction = ""
        if has_key(sess.callback, sess.matchedCallback)
            let postAction = sess.callback[ sess.matchedCallback ](sess)
            return postAction
        endif
    elseif actionName == 'end'
        call s:End()
        let postAction = ''
    else
    endif
    if !empty(nextList)
        let  postAction .= "\<C-r>=XPPprocess(" . string( nextList ) . ")\<cr>"
    else
        let postAction .= g:xpt_post_action
    endif
    return postAction
endfunction 
fun! XPPcomplete(col, list) 
    let oldcfu = &completefunc
    set completefunc=XPPcompleteFunc
    return "\<C-x>\<C-u>"
endfunction 
fun! XPPcr() 
    if !s:PopupCheck(1)
        call feedkeys("\<CR>", 'mt')
        return ""
    endif
    return "\<C-r>=XPPaccept()\<CR>"
endfunction 
fun! XPPup() 
    if !s:PopupCheck(1)
        call feedkeys("\<UP>", 'mt')
        return ""
    endif
    return "\<C-p>"
endfunction 
fun! XPPdown() 
    if !s:PopupCheck(1)
        call feedkeys("\<DOWN>", 'mt')
        return ""
    endif
    return "\<C-n>"
endfunction 
fun! XPPcallback() 
    if !exists("b:__xpp_current_session")
        return ""
    endif
    let sess = b:__xpp_current_session
    call s:End()
    if has_key(sess.callback, sess.matchedCallback)
        let post = sess.callback[ sess.matchedCallback ](sess)
    else 
        let post = ""
    endif
    return post
endfunction 
fun! XPPshorten() 
    if !s:PopupCheck()
        let s:pos = getpos(".")[ 1 : 2 ]
        return "\<C-e>\<C-r>=XPPcorrectPos()\<cr>\<bs>"
    endif
    let sess = b:__xpp_current_session
    let current = getline(".")[ sess.col - 1 : col(".") - 2 ]
    if current == ''
        call s:End()
        return "\<bs>"
    endif
    let actions = "\<C-y>"
    let actions = ""
    let prefixMap = ( sess.ignoreCase ) ? sess.prefixIndex.lower : sess.prefixIndex.ori
    let shorterKey = s:FindShorter(prefixMap, ( sess.ignoreCase ? substitute(current, '.', '\l&', 'g') : current ))
    let action = actions . repeat( "\<bs>", len(current) - len(shorterKey) ) . "\<C-r>=XPPrepopup(0, 'noenlarge')\<cr>"
    return action
endfunction 
fun! XPPenlarge() 
    if !s:PopupCheck()
        call feedkeys("\<tab>", 'mt')
        return ""
    endif
    return "\<C-r>=XPPrepopup(1, 'enlarge')\<cr>"
endfunction 
fun! XPPcancel() 
    if !s:PopupCheck()
        call feedkeys("\<C-e>", 'mt')
        return ""
    endif
    return "\<C-r>=XPPprocess(" . string( [ 'clearPum', 'clearPrefix', 'typeLongest', 'end' ] ) . ")\<cr>"
endfunction 
fun! XPPaccept() 
    if !s:PopupCheck()
        call feedkeys("\<C-y>", 'mt')
        return ""
    endif
    let sess = b:__xpp_current_session
    let beforeCursor = col( "." ) - 2
    let beforeCursor = beforeCursor == -1 ? 0 : beforeCursor
    let toType = getline( sess.line )[ sess.col - 1 : beforeCursor ]
    return "\<C-r>=XPPprocess(" . string( [ 'clearPum', 'clearPrefix', 'type', toType, 'end' ] ) . ")\<cr>"
endfunction 
fun! XPPrepopup(doCallback, ifEnlarge) 
    if !exists("b:__xpp_current_session")
        return ""
    endif
    let sess = b:__xpp_current_session
    return sess.popup(sess.col, { 'doCallback' : a:doCallback, 'enlarge' : a:ifEnlarge == 'enlarge' } )
endfunction 
fun! XPPcorrectPos() 
    let p = getpos(".")[1:2]
    if p != s:pos
        unlet s:pos
        return "\<bs>"
    else
        unlet s:pos
        return ""
    endif
endfunction 
fun! s:ApplyMapAndSetting() 
    call s:_InitBuffer()
    if exists( 'b:__xpp_pushed' )
        return
    endif
    let b:__xpp_pushed = 1
    call b:_xpp_map_saver.Save()
    exe 'inoremap <silent> <buffer> <UP>'   '<C-r>=XPPup()<CR>'
    exe 'inoremap <silent> <buffer> <DOWN>' '<C-r>=XPPdown()<CR>'
    exe 'inoremap <silent> <buffer> <bs>'  '<C-r>=XPPshorten()<cr>'
    exe 'inoremap <silent> <buffer> <tab>' '<C-r>=XPPenlarge()<cr>'
    exe 'inoremap <silent> <buffer> <cr>'  '<C-r>=XPPcr()<cr>'
    exe 'inoremap <silent> <buffer> <C-e>' '<C-r>=XPPcancel()<cr>'
    exe 'inoremap <silent> <buffer> <C-y>' '<C-r>=XPPaccept()<cr>'
    call b:_xpp_setting_switch.Switch()
    if exists( ':AcpLock' )
        AcpLock
    endif
endfunction 
fun! s:CheckAndRepop() 
    if !exists( 'b:__xpp_buffer_init' )
        return
    endif
    if !pumvisible()
          \ && len(b:__xpp_current_session.currentList) > 1
        call feedkeys( "\<C-r>=XPPrepopup(0, 'noenlarge')\<cr>" )
    endif
endfunction 
fun! s:ClearMapAndSetting() 
    call s:_InitBuffer()
    if !exists( 'b:__xpp_pushed' )
        return
    endif
    unlet b:__xpp_pushed
    call b:_xpp_map_saver.Restore()
    call b:_xpp_setting_switch.Restore()
    if exists( ':AcpUnlock' )
        try
            AcpUnlock
        catch /.*/
        endtry
    endif
endfunction 
fun! XPPend() 
    call s:End()
endfunction 
fun! s:End() 
    call s:ClearMapAndSetting()
    if exists("b:__xpp_current_session")
        unlet b:__xpp_current_session
    endif
endfunction 
fun! s:PopupCheck(...) 
    let checkPum = ( a:0 == 0 || a:1 )
    if !exists("b:__xpp_current_session")
        call s:End()
        return 0
    endif
    let sess = b:__xpp_current_session
    if sess.line != line(".") || col(".") < sess.col || (checkPum && !pumvisible())
        call s:End()
        return 0
    endif
    return 1
endfunction 
fun! s:UpdateIndex(map, key) 
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
endfunction 
fun! s:LongestPrefix(sess) 
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
    if a:sess.prefix !=# longest[ : len(a:sess.prefix) - 1 ]
        let longest = a:sess.prefix . longest[ len(a:sess.prefix) : ]
    endif
    return longest
endfunction 
fun! s:filterCompleteList(sess) 
    let list = []
    let pattern = '^\V' . ( a:sess.ignoreCase ? '\c' : '\C' ) . a:sess.prefix
    for item in a:sess.list
        let key = ( type(item) == type({}) ) ? item.word : item
        if key =~ pattern
            let list += [ item ]
        endif
    endfor
    return list
endfunction 
fun! s:FindShorter(map, key) 
    let key = a:key
    if len( key ) == 1
      return ''
    endif
    let nmatch = has_key(a:map, key) ? a:map[key] : 1
    if !has_key( a:map, key[ : -2 ] )
        return key[ : -2 ]
    endif
    let key = key[ : -2 ]
    while key != '' && a:map[key] == nmatch
        let key = key[ : -2 ]
    endwhile
    return key
endfunction 
fun! s:ClassPrototype(...) 
    let p = {}
    for name in a:000
        let p[ name ] = function( '<SNR>' . s:sid . name )
    endfor
    return p
endfunction 
let s:sessionPrototype2 =  s:ClassPrototype(
            \    'popup',
            \   'SetAcceptEmpty', 
            \)
call extend( s:sessionPrototype, s:sessionPrototype2, 'force' )
let &cpo = s:oldcpo
