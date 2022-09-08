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
          \ [ [ '\', {}, {} ], '\' ],
          \ [ [ '\\', {}, {} ], '\\' ],
          \ [ [ '\\\', {}, {} ], '\\\' ],
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
          \ [ [ '$a', {}, {} ], '' ],
          \ [ [ '$abcd', {}, {} ], '' ],
          \ [ [ 'xx$abcd', {}, {} ], 'xx' ],
          \
          \ [ [ '{}', {}, {} ], '{}' ],
          \ [ [ '{$}', {}, {} ], '{$}' ],
          \ [ [ '{$_}', {}, {} ], '' ],
          \
          \ [ [ '$a', {"$a" : "var-a"}, {} ], 'var-a' ],
          \ [ [ '$ a', {"$a" : "var-a"}, {} ], '$ a' ],
          \ [ [ '$\a', {"$a" : "var-a"}, {} ], '$\a' ],
          \ [ [ '\$a', {"$a" : "var-a"}, {} ], '$a' ],
          \ [ [ '\\$a', {"$a" : "var-a"}, {} ], '\var-a' ],
          \ [ [ '\\\$a', {"$a" : "var-a"}, {} ], '\$a' ],
          \ [ [ '\\\\$a', {"$a" : "var-a"}, {} ], '\\var-a' ],
          \ [ [ 'cc$a', {"$a" : "var-a"}, {} ], 'ccvar-a' ],
          \ [ [ '{$a}b', {"$a" : "var-a"}, {} ], 'var-ab' ],
          \
          \ [ [ '{$a}b', {"$a" : "var-a"}, {"$a": "var-A2"} ], 'var-A2b' ],
          \
          \ [ [ 'a()', {}, {} ], '' ],
          \ [ [ 'a()', {'a' : 'a'}, {} ], 'a-' ],
          \ [ [ '()', {}, {} ], '()' ],
          \ [ [ '()a()', {}, {} ], '' ],
          \ [ [ '()a("xx")', {'a' : 'a'}, {} ], '()a-xx' ],
          \ [ [ '()a("xx")()', {'a' : 'a'}, {} ], '()a-xx()' ],
          \
          \ [ [ 'a("xx")()-b("yy")', {'a' : 'a', 'b': 'b'}, {} ], 'a-xx()-b-yy' ],
          \ [ [ '()a("xx")()-b("yy")', {'a' : 'a', 'b': 'b'}, {} ], '()a-xx()-b-yy' ],
          \ [ [ '()a("xx")()-b("yy")end', {'a' : 'a', 'b': 'b'}, {} ], '()a-xx()-b-yyend' ],
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
          \
          \ [ [ 'err()', {"err" : "err"}, {} ], '' ],
          \ [ [ 'return_empty_dict()', {"return_empty_dict" : "return_empty_dict"}, {} ], {} ],
          \ [ [ 'abc[return_empty_dict()]', {"return_empty_dict" : "return_empty_dict"}, {} ], "abc[]" ],
          \ [ [ 'return_dict()', {"return_dict" : "return_dict"}, {} ], {"action":"build", "text": "123"} ],
          \ [ [ 'abc[return_dict()]', {"return_dict" : "return_dict"}, {} ], {"action":"build", "text": "abc[123]"} ],
          \ [ [ 'return_0()', {"return_0" : "return_0"}, {} ], 0 ],
          \ [ [ 'abc[return_0()]', {"return_0" : "return_0"}, {} ], 0 ],
          \ [ [ 'strlen("123")', {}, {} ], '3' ],
          \ [ [ 'foo{strlen("123")}', {}, {} ], 'foo3' ],
          \ [ [ '{strlen("123")}bar', {}, {} ], '3bar' ],
          \ [ [ '{$foo}tr("ab", "a", "A")bla{strlen("123")}', {"$foo" : "bar"}, {} ], 'barAbbla3' ],
          \ ]
          " \ [ [ '', {}, {} ], '' ],

    for [inp,outp] in cases
        let [ str, scope, scope2 ] = inp
        let inp = deepcopy(inp)

        for k in keys(scope)
            if k !~# '\V\^$'
                let scope[k] = function( 'xpt#ut#test_eval#' . scope[k] )
            endif
        endfor
        call extend(scope, s:funcs, 'keep')

        let rst = xpt#eval#Eval( str, [scope, scope2] )
        call a:t.Eq( outp, rst, string([ inp,  outp ] ) )
        unlet outp
        unlet rst
    endfor

endfunction "}}}

fun! xpt#ut#test_eval#a( ... ) "{{{
    return 'a-' . join(a:000, '')
endfunction "}}}
fun! xpt#ut#test_eval#b( ... ) "{{{
    return 'b-' . join(a:000, '')
endfunction "}}}

fun! xpt#ut#test_eval#err( ... ) "{{{
    throw 'err'
endfunction "}}}

fun! xpt#ut#test_eval#return_0( ... ) "{{{
    return 0
endfunction "}}}
fun! xpt#ut#test_eval#return_dict( ... ) "{{{
    return {'action' : 'build', 'text' : '123'}
endfunction "}}}
fun! xpt#ut#test_eval#return_empty_dict( ... ) "{{{
    return {}
endfunction "}}}

fun! xpt#ut#test_eval#dictfunc( ... ) dict "{{{
    return 'dictfunc-' . join(a:000, '')
endfunction "}}}

fun! xpt#ut#test_eval#tr(...) "{{{
    return 'fake tr'
endfunction "}}}

exec xpt#unittest#run

let &cpo = s:oldcpo

