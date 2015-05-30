" File Description {{{
" =============================================================================
" Evaluation support for XPTemplate
"                                                  by drdr.xp
"                                                     drdr.xp@gmail.com
" Usage :
"
" =============================================================================
" }}}
if exists( "g:__AL_XPT_EVAL_VIM__" ) && g:__AL_XPT_EVAL_VIM__ >= XPT#ver
    finish
endif
let g:__AL_XPT_EVAL_VIM__ = XPT#ver


let s:oldcpo = &cpo
set cpo-=< cpo+=B


let s:log = xpt#debug#Logger( 'warn' )
let s:log = xpt#debug#Logger( 'debug' )

exe XPT#importConst

" TODO consistent cache
let s:_evalCache = { 'strMask' : {}, 'compiledExpr' : {} }

fun! xpt#eval#Eval( str, closures ) "{{{

    if a:str == ''
        return ''
    endif

    let globals = a:closures[0]
    let x = b:xptemplateData

    let expr = xpt#eval#Compile( a:str )
    call s:log.Debug( 'expression to eval=' . string( expr ) )

    let globals._ctx = {
          \         'closures': a:closures,
          \         'renderContext' : x.renderContext,
          \ }

    let xfunc = globals
    try
        let r = eval(expr)
        return r
    catch /.*/
        call XPT#warn(v:throwpoint)
        call XPT#warn(v:exception)
        call XPT#warn(expr)
        return ''
    endtry

endfunction "}}}

fun! xpt#eval#Compile( s ) "{{{
    " TODO consistent cache: evalTable

    if a:s is ''
        return ''
    endif

    let expr = get( s:_evalCache.compiledExpr, a:s, 0 )

    if expr is 0
        if a:s !~ s:item_var . '\|' . s:item_func
            let expr = string( xpt#util#UnescapeChar(a:s, s:nonsafe) )

        elseif a:s =~ '\V\^$\w\+\$'
            let expr = 'xfunc.GetVar(' . string( a:s ) . ')'

        else
            let expr = s:DoCompile( a:s )
        endif

        let s:_evalCache.compiledExpr[ a:s ] = expr
    endif

    return expr

endfunction "}}}

fun! s:DoCompile(s) "{{{

    " non-escaped prefix
    let fptn = '\V' . '\w\+(\[^($]\{-})' . '\|' . s:nonEscaped . '{\w\+(\[^($]\{-})}'
    let vptn = '\V' . s:nonEscaped . '$\w\+' . '\|' . s:nonEscaped . '{$\w\+}'
    let sptn = '\V' . s:nonEscaped . '(\[^($]\{-})'

    let patternVarOrFunc = fptn . '\|' . vptn . '\|' . sptn

    " simple test
    if a:s !~  s:regEval
        return string(xpt#util#UnescapeChar(a:s, s:nonsafe))
    endif

    let stringMask = s:CreateStringMask( a:s )

    if stringMask !~ patternVarOrFunc
        return string(xpt#util#UnescapeChar(a:s, s:nonsafe))
    endif

    call s:log.Debug( 'string =' . a:s, 'strmask=' . stringMask )

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
            " ignore it
            let contextedMatchedLen = len(matched)
            let spaces = repeat(' ', contextedMatchedLen)
            let stringMask = (matchedIndex == 0 ? "" : stringMask[:matchedIndex-1])
                        \ . spaces
                        \ . stringMask[matchedIndex + matchedLen :]

            continue

        elseif matched[-1:] == ')'

            " Dynamic function look up make it consistent even when function
            " added into function-container.
            "
            " Old way is to compile to xfunc.xx() call if function exist,
            " otherwise xx() for native function. This does not work with
            " caching when function added.

            let funcname = matchstr(matched, '^\w\+')

            " strip braces
            let args = matched[ len(funcname) + 1 : -2 ]
            let matched = "xfunc.Call('" . funcname . "',[" . args . '])'

        elseif matched[0:0] == '$'
            let matched = 'xfunc.GetVar(' . string( matched ) . ')'

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
    let expr = ''
    while 1
        let matches = matchlist( evalMask, '\V\(-\*\)\(+ \*\)\?', idx )
        if '' == matches[0]
            break
        endif

        " string part
        if '' != matches[1]
            let part = str[ idx : idx + len(matches[1]) - 1 ]
            " if the following element is nonliteral, thus trailing back slash
            " should be unescaped
            if matches[2] != ''
                let part = xpt#util#UnescapeChar(part . '$', '{$( ')
                let part = strpart(part, 0, strlen(part) - 1)
            else
                let part = xpt#util#UnescapeChar(part, '{$( ')
            endif
            let expr .= ',' . string(part)
        endif

        " expression part
        if '' != matches[2]
            let expr .= ',' . str[ idx + len(matches[1]) : idx + len(matches[0]) - 1 ]
        endif

        let idx += len(matches[0])
    endwhile

    let expr = "xfunc.Concat(" . expr[ 1: ] . ')'
    call s:log.Log('expression to evaluate=' . string(expr))

    return expr

endfunction "}}}

fun! s:CreateStringMask( str ) "{{{

    if a:str == ''
        return ''
    endif

    if has_key( s:_evalCache.strMask, a:str )
        return s:_evalCache.strMask[ a:str ]
    endif

    " non-escaped prefix

    " non-escaped quotation
    let dqe = '\V\('. s:nonEscaped . '"\)'
    let sqe = '\V\('. s:nonEscaped . "'\\)"

    let dptn = dqe.'\_.\{-}\1'

    " let sptn = sqe.'\_.\{-}\1'
    " Note: only ' is escaped by doubling it: ''
    " let sptn = sqe.'\_.\{-}\%(\^\|\[^'']\)\(''''\)\*'''
    let sptn = sqe.'\%(\_[^'']\)\{-}'''

    " create mask hiding all string literal with space
    let mask = substitute(a:str, '[ *]', '+', 'g')
    while 1 "{{{
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

    endwhile "}}}

    let s:_evalCache.strMask[ a:str ] = mask

    return mask

endfunction "}}}

let &cpo = s:oldcpo
