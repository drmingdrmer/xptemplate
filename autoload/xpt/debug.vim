if exists( "g:__XPT_DEBUG_VIM__" ) && g:__XPT_DEBUG_VIM__ >= XPT#ver
    finish
endif
let g:__XPT_DEBUG_VIM__ = XPT#ver

let s:oldcpo = &cpo
set cpo-=<
set cpo+=B


exe XPT#let_sid

let s:globalLogLevel = 'debug'

let s:logLevels = {
      \ 'fatal' : 1,
      \ 'error' : 2,
      \ 'warn'  : 3,
      \ 'info'  : 4,
      \ 'log'   : 5,
      \ 'debug' : 6,
      \ }

fun! xpt#debug#Logger( level ) "{{{

  let level = s:logLevels[ a:level ]
  let level = min( [ level, s:logLevels[ s:globalLogLevel ] ] )

  let logger = copy( s:loggerPrototype )

  if level < s:logLevels.fatal | let logger.Fatal = s:loggerPrototype.LogNothing | endif
  if level < s:logLevels.error | let logger.Error = s:loggerPrototype.LogNothing | endif
  if level < s:logLevels.warn  | let logger.Warn  = s:loggerPrototype.LogNothing | endif
  if level < s:logLevels.info  | let logger.Info  = s:loggerPrototype.LogNothing | endif
  if level < s:logLevels.log   | let logger.Log   = s:loggerPrototype.LogNothing | endif
  if level < s:logLevels.debug | let logger.Debug = s:loggerPrototype.LogNothing | endif

  return logger
endfunction "}}}

fun! xpt#debug#Assert( shouldBeTrue, msg ) "{{{
    if !a:shouldBeTrue
        throw a:msg
    end
endfunction "}}}

fun! xpt#debug#List( l ) "{{{
    let rst = '[' . "\n"
    for e in a:l
        let rst .= '--- ' . string( e ) . "\n"
        unlet e
    endfor

    return rst . "\n" . ']'
endfunction "}}}

fun! xpt#debug#EchoList( l ) "{{{

    echom '['
    for e in a:l
        echom '--- ' . string( e ) . "\n"
        unlet e
    endfor

    echom  ']'

endfunction "}}}


fun! s:Fatal(...) dict "{{{
    return call('Log_core', ['Fatal'] + a:000)
endfunction "}}}

fun! s:Error(...) dict "{{{
    return call('Log_core', ['Error'] + a:000)
endfunction "}}}

fun! s:Warn(...) dict "{{{
    return call('Log_core', ['Warn'] + a:000)
endfunction "}}}

fun! s:Info(...) dict "{{{
    return call('Log_core', ['Info'] + a:000)
endfunction "}}}

fun! s:Log(...) dict "{{{
    return call('Log_core', ['Log'] + a:000)
endfunction "}}}

fun! s:Debug(...) dict "{{{
    return call('Log_core', ['Debug'] + a:000)
endfunction "}}}

fun! s:LogNothing(...) "{{{
endfunction "}}}


fun! Log_core(level, ...) "{{{

    if s:logLocation == ''
        return
    end

    " call stack printing
    try
        throw ''
    catch /.*/
        let stack = matchstr( v:throwpoint, 'function\s\+\zs.\{-}\ze\.\.\%(Fatal\|Error\|Warn\|Info\|Log\|Debug\).*' )
        let stack = substitute( stack, '<SNR>\d\+_', '', 'g' )
    endtry


    exe 'redir! >> '.s:logLocation


    silent echom a:level . ':::' . stack . ' cursor at=' . string( [ line("."), col(".") ] )

    for msg in a:000
        let l = split(';' . msg . ';', "\n")
        let l[0] = l[0][1:]
        let l[ -1 ] = l[ -1 ][ :-2 ]
        for v in l
            silent! echom v
        endfor
    endfor
    redir END


    if a:level =~ 'Fatal\|Error\|Warn'
        echoerr string( a:000 )
    endif

endfunction "}}}


" define script-private functions first and then make reference to them. Thus
" in traceback function name can be shown.
let s:loggerPrototype = {}
let s:loggerPrototype.Fatal       = function( "<SNR>" . s:sid . "Fatal"      )
let s:loggerPrototype.Error       = function( "<SNR>" . s:sid . "Error"      )
let s:loggerPrototype.Warn        = function( "<SNR>" . s:sid . "Warn"       )
let s:loggerPrototype.Info        = function( "<SNR>" . s:sid . "Info"       )
let s:loggerPrototype.Log         = function( "<SNR>" . s:sid . "Log"        )
let s:loggerPrototype.Debug       = function( "<SNR>" . s:sid . "Debug"      )
let s:loggerPrototype.LogNothing  = function( "<SNR>" . s:sid . "LogNothing" )

fun! s:MakeLogPath() "{{{
    let path = g:xptemplate_debug_log
    if path == ''
        let s:logLocation = ''
    else
        let path = substitute( path, '\V\^~/', $HOME . '/', '' )
        let s:logLocation = path
        call delete(s:logLocation)
    endif
endfunction "}}}
call s:MakeLogPath()

let &cpo = s:oldcpo
