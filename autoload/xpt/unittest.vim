if exists("g:__AL_XPT_UNITTEST_2h3j4k89__") && g:__AL_XPT_UNITTEST_2h3j4k89__ >= XPT#ver
    finish
endif
let g:__AL_XPT_UNITTEST_2h3j4k89__ = XPT#ver


let s:oldcpo = &cpo
set cpo-=< cpo+=B

let s:log = xpt#debug#Logger( 'warn' )
let s:ctx = {}

fun! s:ctx.True( val, mes ) "{{{
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

fun! xpt#unittest#Runall(ptn) "{{{
    echom 'Unittest: autoload/xpt/ut/' . a:ptn . '.vim'
    try
        exe 'runtime!' 'autoload/xpt/ut/' . a:ptn . '.vim'
        echom "All tests passed"
    catch /.*/
        " bla
    endtry
endfunction "}}}

let xpt#unittest#run = 'exe XPT#let_sid | call xpt#unittest#Run(s:sid, expand("<sfile>"))'
fun! xpt#unittest#Run( sid, fn ) "{{{

    echom "Test: " . string(a:fn)

    let ff = s:GetTestFuncs( a:sid )
    let funcnames = keys( ff )
    sort( funcnames )

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
