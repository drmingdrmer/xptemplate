if exists("g:__MAPSTACK_VIM__")
  finish
endif
let g:__MAPSTACK_VIM__ = 1
runtime plugin/debug.vim
let s:log = CreateLogger( 'warn' )
fun! s:InitStacks() 
    let b:__setting_stack__ = []
    let b:__map_stack__ = []
endfunction 
fun! s:GetCmdOutput(cmd) 
  let l:a = ""
  redir => l:a
  exe a:cmd
  redir END
  return l:a
endfunction 
fun! s:GetAlighWidth() 
  nmap <buffer> 1 2
  let line = s:GetCmdOutput("silent nmap <buffer> 1")
  nunmap <buffer> 1
  let line = split(line, "\n")[0]
  return len(matchstr(line, '^n.*\ze2$'))
endfunction 
let s:alignWidth = s:GetAlighWidth()
delfunction s:GetAlighWidth
fun! s:GetMapLine(key, mode, isbuffer) 
  let mcmd = "silent ".a:mode."map ".(a:isbuffer ? "<buffer> " : "").a:key
  let str = s:GetCmdOutput(mcmd)
  let lines = split(str, "\n")
  let localmark = a:isbuffer ? '@' : ' '
  let ptn = '\V\c' . a:mode . '  ' . escape(a:key, '\') . '\s\{-}' . '\zs\[* ]' 
        \. localmark.'\%>' . s:alignWidth . 'c\S\.\{-}\$'
  for line in lines
    if line =~? ptn
      return matchstr(line, ptn)
    endif
  endfor
  return ""
endfunction 
fun! s:GetMapInfo(key, mode, isbuffer) 
  let line = s:GetMapLine(a:key, a:mode, a:isbuffer)
  if line == ''
    return {'mode' : a:mode,
          \'key'   : a:key,
          \'nore'  : '',
          \'isbuf' : a:isbuffer ? ' <buffer> ' : ' ',
          \'cont'  : ''}
  endif
  let item = line[0:1] " the first 2 characters
  return {'mode' : a:mode,
        \'key'   : a:key,
        \'nore'  : item =~ '*' ? 'nore' : '',
        \'isbuf' : a:isbuffer ? ' <buffer> ' : ' ',
        \'cont'  : line[2:]}
endfunction 
fun! g:MapPush(key, mode, isbuffer) 
  if !exists( 'b:__map_stack__' )
    call s:InitStacks()
  endif
  let info = s:GetMapInfo(a:key, a:mode, a:isbuffer)
  let st = b:__map_stack__
  call add(st, info)
  return info
endfunction 
fun! g:MapPop(expected) 
  if !exists( 'b:__map_stack__' )
    call s:InitStacks()
  endif
  let st = b:__map_stack__
  let info = st[-1]
  unlet st[-1]
  if a:expected isnot info
    throw "Err_XPT:try to restore unexpected mapping expected :" . string(a:expected) . " but :" . string(info)
  endif
  if empty(info)
    return
  endif
  let exprMap = ''
  if info.mode == 'i' && info.cont =~ '\V\w(\.\*)' && info.cont !~? '\V<c-r>'
              \ || info.mode != 'i' && info.cont =~ '\V\w(\.\*)' 
      let exprMap = '<expr> '
  endif
  if info.cont == ''
    let cmd = "silent! ".info.mode.'unmap '. info.isbuf . info.key 
  else
    let cmd = "silent! " . info.mode . info.nore .'map '. exprMap . info.isbuf . info.key . ' ' . info.cont
  endif
  try
    exe cmd
  catch /.*/
  endtry
endfunction 
fun! SettingPush(key, value) 
  if !exists( 'b:__setting_stack__' )
    call s:InitStacks()
  endif
    let b:__setting_stack__ += [{'key' : a:key, 'val' : eval(a:key)}]
    exe 'let ' . a:key . '=' . string(a:value)
endfunction 
fun! SettingPop( ... ) 
  if !exists( 'b:__setting_stack__' )
    call s:InitStacks()
  endif
    let d = b:__setting_stack__[-1]
    call remove(b:__setting_stack__, -1)
    if a:0 != 0 && d.key != a:1
        throw "unexpected setting popped up, expected:" . a:1 . ' but popped up is ' . d.key
    endif
    exe 'let '.d.key.'='.string(d.val)
endfunction 
