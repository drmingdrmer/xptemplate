if exists("g:__AL_XPT_UNITTEST_2h3j4k89__") && g:__AL_XPT_UNITTEST_2h3j4k89__ >= XPT#ver
    finish
endif
let g:__AL_XPT_UNITTEST_2h3j4k89__ = XPT#ver


let s:oldcpo = &cpo
set cpo-=< cpo+=B

let s:log = xpt#debug#Logger( 'warn' )
let s:ctx = {'n_assert': 0}

fun! s:ctx.True( val, mes ) "{{{
    let self.n_assert += 1
    if a:val
        " ok
    else
        throw a:mes
    endif
endfunction "}}}
fun! s:ctx.Eq( a, b, mes ) "{{{
    call self.True( type(a:a) == type(a:b) && a:a == a:b,
          \ "Expect " . string(a:a) . " But " . string(a:b) . " " .a:mes )
endfunction "}}}
fun! s:ctx.Ne( a, b, mes ) "{{{
    call self.True( a:a != a:b,
          \ "Expect not to be " . string(a:a) . " But " . string(a:b) . " " .a:mes )
endfunction "}}}
fun! s:ctx.Is( a, b, mes ) "{{{
    call self.True( a:a is a:b,
          \ "Expect is " . string(a:a) . " But " . string(a:b) . " " .a:mes )
endfunction "}}}

let s:bench = 0
fun! xpt#unittest#Runall(ptn) "{{{
    echom 'Unittest: autoload/xpt/ut/' . a:ptn . '.vim'
    try
        let s:bench = 0
        let s:ctx.n_assert = 0
        exe 'runtime!' 'autoload/xpt/ut/' . a:ptn . '.vim'
        echom "All tests passed. nr of assert=" . s:ctx.n_assert

        let s:bench = $XPT_BENCH
        if ! s:bench
            return
        endif

        echom 'Benchmark: autoload/xpt/ut/' . a:ptn . '.vim'
        exe 'runtime!' 'autoload/xpt/ut/' . a:ptn . '.vim'
        echom "All benchmark done"

    catch /.*/
        " bla
        echom "    " v:throwpoint
        echom "Failure" v:exception
    endtry

endfunction "}}}

let xpt#unittest#run = 'exe XPT#let_sid | call xpt#unittest#Run(s:sid, expand("<sfile>"))'
fun! xpt#unittest#Run( sid, fn ) "{{{

    echom "Test: " . string(a:fn)

    let ff = s:GetTestFuncs( a:sid )
    let funcnames = keys( ff )
    let funcnames = sort( funcnames )

    if s:bench == 0
        for funcname in funcnames
            if funcname !~ '\V\<Test'
                continue
            endif

            echom 'Case: ' . funcname
            let Func = ff[ funcname ]

            try
                call Func( s:ctx )
            catch /.*/
                echom "    " a:fn
                echom "    " funcname
                echom "    " v:throwpoint
                echom "Failure" v:exception
                throw "F"
            endtry
        endfor
    else
        for funcname in funcnames
            if funcname !~ '\V\<Bench'
                continue
            endif

            echom 'Bench: ' . funcname
            let Func = ff[ funcname ]

            let at_least = 2
            let t = 0
            let n = 100
            while t < at_least

                let ctx = {'n' : n}
                let t_0 = reltime()

                try
                    call Func(ctx)
                catch /.*/
                    echom "    " a:fn
                    echom "    " funcname
                    echom "    " v:throwpoint
                    echom "Failure" v:exception
                    throw "F"
                endtry

                let t_1 = reltime( t_0 )
                let us = t_1[0] * 1000 * 1000 + t_1[1]

                echom funcname . ' spent: ' . string(reltimestr(t_1)) . ' on ' . n . ' calls'
                echom funcname . ' per-call(us):' . string(us/n)

                if us > at_least * 1000 * 1000
                    break
                endif
                if us < 0.1 * 1000 * 1000
                    let n = n * 2
                else
                    let n = n * at_least * 1000 * 1000 / us * 3 / 2
                endif

            endwhile

        endfor
    endif

endfunction "}}}
fun! s:GetTestFuncs( sid ) "{{{

    let clz = {}

    let funcs = split( XPT#getCmdOutput( 'silent function /' . a:sid ), "\n" )
    call map( funcs, 'matchstr( v:val, "' . a:sid . '\\zs.*\\ze(" )' )

    for name in funcs
        if name !~ '\V\^_'
            let clz[ name ] = function( '<SNR>' . a:sid . name )
        endif
    endfor

    return clz

endfunction "}}}

let &cpo = s:oldcpo
