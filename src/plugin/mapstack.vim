" File Description {{{
" =============================================================================
" Store key mapping in local buffer.
"                                                  by drdr.xp
"                                                     drdr.xp@gmail.com
"
" Usage :
"   call g:MapPush("key sequence", 'mode:[invsxc]', 0/1)
"
"   call g:MapPop()
"
" TODO InsertEnter to clear?
" =============================================================================
" }}}

if exists("g:__MAPSTACK_VIM__")
  finish
endif
let g:__MAPSTACK_VIM__ = 1

runtime plugin/debug.vim

let s:log = CreateLogger( 'debug' )

fun! s:InitStacks() "{{{
    let b:__setting_stack__ = []
    let b:__map_stack__ = []

endfunction "}}}

" pre alloc setting stack to speed up
augroup SettingStack
  au!
  au BufRead,BufNewFile,BufNew,BufAdd,BufCreate,FileType * call <SID>InitStacks()
augroup END



fun! s:GetCmdOutput(cmd) "{{{
  let l:a = ""

  redir => l:a
  exe a:cmd
  redir END

  return l:a

endfunction "}}}


" Critical implementation!!
" Not sure whether it works well on any platform
"
" TODO Maybe use <script> mapping is better
fun! s:GetAlighWidth() "{{{
  nmap <buffer> 1 2
  let line = s:GetCmdOutput("silent nmap <buffer> 1")
  nunmap <buffer> 1

  let line = split(line, "\n")[0]

  return len(matchstr(line, '^n.*\ze2$'))
endfunction "}}}

let s:alignWidth = s:GetAlighWidth()

delfunction s:GetAlighWidth



fun! s:GetMapLine(key, mode, isbuffer) "{{{
  let mcmd = "silent ".a:mode."map ".(a:isbuffer ? "<buffer> " : "").a:key

  " get fixed mapping
  let str = s:GetCmdOutput(mcmd)

  let lines = split(str, "\n")


  " Find out the line representing the expect mapping. Because mappings with
  " the same prefix may all returned.
  "
  " *  norepeat
  " &@ script or buffer local
  "
  " The :map command format: if a mapped key length is less than s:alignWidth,
  " the right hand part is aligned. Or 1 space separates the left part and the
  " right part
  let localmark = a:isbuffer ? '@' : ' '
  let ptn = '\V\c' . a:mode . '  ' . escape(a:key, '\') . '\s\{-}' . '\zs\[* ]' 
        \. localmark.'\%>' . s:alignWidth . 'c\S\.\{-}\$'


  for line in lines
    if line =~? ptn
      return matchstr(line, ptn)
    endif
  endfor


  return ""

endfunction "}}}

fun! s:GetMapInfo(key, mode, isbuffer) "{{{
  let line = s:GetMapLine(a:key, a:mode, a:isbuffer)
  if line == ''
    " unmap info
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

endfunction "}}}

fun! g:MapPush(key, mode, isbuffer) "{{{
  if !exists( 'b:__map_stack__' )
    call s:InitStacks()
  endif

  let info = s:GetMapInfo(a:key, a:mode, a:isbuffer)

  let st = b:__map_stack__
  call add(st, info)

  return info
endfunction "}}}

fun! g:MapPop(expected) "{{{
  if !exists( 'b:__map_stack__' )
    call s:InitStacks()
  endif
  let st = b:__map_stack__

  let info = st[-1]

  unlet st[-1]

  if a:expected isnot info
    throw "Err_XPT:try to restore unexpected mapping expected :" . string(a:expected) . " but :" . string(info)
  endif

  call s:log.Debug("map info:".string(info))

  if empty(info)
    return
  endif



  if info.cont == ''
    let cmd = "silent ".info.mode.'unmap '. info.isbuf . info.key
  else
    let cmd = "silent " . info.mode . info.nore .'map '. info.isbuf . info.key . ' ' . info.cont
  endif


  " mapping may already be cleared
  try
    exe cmd
  catch /.*/
  endtry


endfunction "}}}










fun! SettingPush(key, value) "{{{
  if !exists( 'b:__setting_stack__' )
    call s:InitStacks()
  endif

    let b:__setting_stack__ += [{'key' : a:key, 'val' : eval(a:key)}]

    exe 'let ' . a:key . '=' . string(a:value)
    
endfunction "}}}

fun! SettingPop() "{{{
  if !exists( 'b:__setting_stack__' )
    call s:InitStacks()
  endif

    let d = b:__setting_stack__[-1]
    exe 'let '.d.key.'='.string(d.val)

    call remove(b:__setting_stack__, -1)
endfunction "}}}
