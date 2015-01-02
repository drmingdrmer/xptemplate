if exists( "g:__XPT_UT_TEST_EVAL_f78d9s6fds__" )
    finish
endif
let g:__XPT_UT_TEST_EVAL_f78d9s6fds__ = 1

let s:oldcpo = &cpo
set cpo-=< cpo+=B

let s:funcs = xpt#snipfunction#funcs

fun! s:TestEval( t ) "{{{
    let cases = [
          \ [ [ '', {}, {} ], '' ],
          \ [ [ 'a', {}, {} ], 'a' ],
          \ [ [ 'a bc', {}, {} ], 'a bc' ],
          \ [ [ 'a "bc"', {}, {} ], 'a "bc"' ],
          \ [ [ 'a ''bc''', {}, {} ], 'a ''bc''' ],
          \
          \ [ [ '"$a"', {}, {} ], '"$a"' ],
          \ [ [ '"$abc"', {}, {} ], '"$abc"' ],
          \
          \ [ [ 'tr("abc", "a", "X")', {}, {} ], 'Xbc' ],
          \ [ [ 'tr("abc", "a", "X")', {"tr":"tr"}, {} ], 'fake tr' ],
          \
          \ [ [ '$', {}, {} ], '$' ],
          \ [ [ '$$', {}, {} ], '$$' ],
          \ [ [ 'aa$', {}, {} ], 'aa$' ],
          \ [ [ '$a', {}, {} ], '$a' ],
          \ [ [ '$abcd', {}, {} ], '$abcd' ],
          \ [ [ 'xx$abcd', {}, {} ], 'xx$abcd' ],
          \
          \ [ [ '$a', {"$a" : "var-a"}, {} ], 'var-a' ],
          \ [ [ '$ a', {"$a" : "var-a"}, {} ], '$ a' ],
          \ [ [ '$\a', {"$a" : "var-a"}, {} ], '$\a' ],
          \ [ [ '\$a', {"$a" : "var-a"}, {} ], '$a' ],
          \ [ [ 'cc$a', {"$a" : "var-a"}, {} ], 'ccvar-a' ],
          \ [ [ '{$a}b', {"$a" : "var-a"}, {} ], 'var-ab' ],
          \
          \ [ [ 'a()', {}, {} ], '' ],
          \ [ [ 'a()', {'a' : 'a'}, {} ], 'a-' ],
          \ [ [ '()', {}, {} ], '()' ],
          \ [ [ '()a()', {}, {} ], '' ],
          \ [ [ '()a("xx")', {'a' : 'a'}, {} ], '()a-xx' ],
          \ [ [ '()a("xx")()', {'a' : 'a'}, {} ], '()a-xx()' ],
          \
          \ [ [ 'a()a\()', {'a' : 'a'}, {} ], 'a-a()' ],
          \ [ [ 'a\\()', {'a' : 'a'}, {} ], 'a\()' ],
          \ [ [ 'a\\\()', {'a' : 'a'}, {} ], 'a\()' ],
          \ [ [ 'a ()', {'a' : 'a'}, {} ], 'a ()' ],
          \ [ [ 'a (', {'a' : 'a'}, {} ], 'a (' ],
          \ [ [ '"a()"', {'a' : 'a'}, {} ], '"a()"' ],
          \ [ [ 'a("b")', {'a' : 'a'}, {} ], 'a-b' ],
          \ [ [ 'a(b("c"))', {'a' : 'a', 'b' : 'b'}, {} ], 'a-b-c' ],
          \
          \ [ [ 'd($x)', {"d" : "dictfunc", "$x": 123}, {} ], 'dictfunc-123' ],
          \ [ [ '', {}, {} ], '' ],
          \ [ [ '', {}, {} ], '' ],
          \ [ [ '', {}, {} ], '' ],
          \ [ [ '', {}, {} ], '' ],
          \ [ [ '', {}, {} ], '' ],
          \ ]

    for [inp,outp] in cases
        let [ str, scope, ctx ] = inp
        let inp = deepcopy(inp)

        for k in keys(scope)
            if k !~# '\V\^$'
                let scope[k] = function( 'xpt#ut#test_eval#' . scope[k] )
            endif
        endfor
        call extend(scope, s:funcs, 'keep')

        let rst = xpt#eval#Eval( str, scope, ctx )
        call a:t.Eq( outp, rst, string([ inp,  outp ] ) )
    endfor

endfunction "}}}

fun! xpt#ut#test_eval#a( ... ) "{{{
    return 'a-' . join(a:000, '')
endfunction "}}}
fun! xpt#ut#test_eval#b( ... ) "{{{
    return 'b-' . join(a:000, '')
endfunction "}}}

fun! xpt#ut#test_eval#dictfunc( ... ) dict "{{{
    return 'dictfunc-' . join(a:000, '')
endfunction "}}}

fun! xpt#ut#test_eval#tr(...) "{{{
    return 'fake tr'
endfunction "}}}

exec xpt#unittest#run

let &cpo = s:oldcpo

