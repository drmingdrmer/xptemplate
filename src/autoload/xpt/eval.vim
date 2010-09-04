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

let s:nonEscaped  = XPT#nonEscaped
let s:regEval     = XPT#regEval
let s:nonsafe     = XPT#nonsafe
let s:nonsafeHint = XPT#nonsafeHint


" TODO consistent cache
let s:_xpeval = { 'strMaskCache' : {}, 'evalCache' : {} }

fun! xpt#eval#Eval(str, container, ...) "{{{
    " @param a:1    key         desc
    "               'typed'     what user typed

    " TODO if expression compiled in loading phase, Variable not found can
    "       not be found any more in runtime phase.
    if a:str == ''
        return ''
    endif

    let renderContext = b:xptemplateData.renderContext


    " TODO simplify me
    let a:container.renderContext = renderContext

    let opt = a:0 == 1 ? a:1 : {}
    let typed = get( opt, 'typed', '' )
    let variables = get( opt, 'variables', {} )

    let renderContext.evalCtx = { 'userInput' : renderContext.processing ? typed : '',
          \                       'variables' : variables, }


    let expr = xpt#eval#Compile( a:str, a:container )

    try
        let xfunc = a:container
        return eval(expr)
    catch /.*/
        call s:log.Warn(expr . "\n" . v:exception)
        return ''
    endtry

endfunction "}}}

fun! xpt#eval#Compile( s, xfunc ) "{{{
    " TODO consistent cache: evalTable

    let expr = get( s:_xpeval.evalCache, a:s, 0 )

    if expr is 0
        let expr = s:DoCompile( a:s, a:xfunc )
        if a:s != ''
            echom a:s . ' ' . expr
            let s:_xpeval.evalCache[ a:s ] = expr
        endif
    endif

    return expr

endfunction "}}}

fun! s:DoCompile(s, xfunc) "{{{

    " non-escaped prefix


    " TODO bug:() can not be evaluated
    " TODO how to add '$' ?
    " TODO \$ inside func or ( ) can not be parsed correctly
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

        elseif matched[-1:] == ')' && has_key(a:xfunc, matchstr(matched, '^\w\+'))
            let matched = "xfunc." . matched

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
    let expr = "''"
    while 1
        let matches = matchlist( evalMask, '\V\(-\*\)\(+ \*\)\?', idx )
        if '' == matches[0]
            break
        endif

        if '' != matches[1]
            let part = str[ idx : idx + len(matches[1]) - 1 ]
            let part = xpt#util#UnescapeChar(part, '{$( ')
            let expr .= '.' . string(part)
        endif

        if '' != matches[2]
            let expr .= '.' . str[ idx + len(matches[1]) : idx + len(matches[0]) - 1 ]
        endif

        let idx += len(matches[0])
    endwhile

    let expr = matchstr(expr, "\\V\\^''.\\zs\\.\\*")
    call s:log.Log('expression to evaluate=' . string(expr))

    return expr

endfunction "}}}

fun! s:CreateStringMask( str ) "{{{

    if a:str == ''
        return ''
    endif

    if has_key( s:_xpeval.strMaskCache, a:str )
        return s:_xpeval.strMaskCache[ a:str ]
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

    let s:_xpeval.strMaskCache[ a:str ] = mask

    return mask

endfunction "}}}

let &cpo = s:oldcpo
