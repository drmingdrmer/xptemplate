" --------------------------------------------
" using reltime()
" --------------------------------------------

fun! Hun()
  return Gun()
endfunction
fun! Gun()
  return Fun()
endfunction
fun! Fun() "{{{
  return 1
endfunction "}}}

let key = 've'
let value = 'block,onemore,insert'


unlet a
unlet b
unlet c


" let a = [ [1, 2] ]
let a = 1
let b = [ [1, 2] ]
let c = 1

fun! Test()
  let a = 2

  let i = 0
  while i < 10000
    call cursor( [31, 4] )
    call cursor( [40, 3] )
    let i += 1
  endwhile
endfunction

let start = reltime()
call Test()
let str = reltimestr( reltime( start ) )
let integs = split( str, '\.' )

" the first 6 digits
let integ = integs[1][ :5 ]
if len( integ ) < 6 
  let integ .= repeat( ' ', 6 - len( integ ) )
endif
echom integ/10000


" times = 500000 
" let &l:ve = 'block,onemore,insert'
" 5
"
" exe 'let ' . key . '=' . string(value)
" 12
"
" exe 'setlocal ' . key . '=' . value
" 9
"
" setlocal ve=block,onemore,insert
" 5
"
" call Fun()
" 5
"
" let m = Fun()
" 7
"
" <empty>
" 3
"
" " {{{
" " {{{
" " {{{
" " }}}
" " }}}
" " }}}
" 4
"
" silent! normal! zO
" 6
"
" if foldlevel(".") >= 0
"   silent! normal! zO
" endif
" 7
"
" if foldlevel(".") >= 20
"   silent! normal! zO
" endif
" 6
"
" let q = [line("."), col(".")]
" 4 
" 17 / 2
"
" let q = getpos(".")[1:2]
" 5
" 17 / 2
"
" try
"   throw "a"
" catch /.*/
" endtry
" 9
"
" let a = 1
" if a == 1 
" endif
" 4
"
" let a = 1
" if a == 1 
" else
" endif
" 5
"
"
" let a = 1
" if a == 1 
" else
" " 123
" " 123
" " 123
" " 123
" " 123
" " 123
" " 123
" " 123
" " 123
" " 123
" " 123
" " 123
" " 123
" " 123
" " 123
" endif
" 8
"
" let a = 1
" if a == 1 
" else
" call Fun() " with the comment statements above
" endif
" 6
"
" let a = 1
" if a == 1 
" else
" " 123 " 123 " 123 " 123 " 123 " 123 " 123 " 123 " 123 " 123 " 123 " 123 " 123 " 123 " 123
" endif
" 5
" 
" let [ a, b, c, d, e ] = [ 1, 2, 3, 4, 5 ]
" 5
"
" let [ a, b, c, d, e ] = [ 1,
"       \2, 
"       \3, 
"       \4, 
"       \5 ]
" 5
"
" call len( getline( 26 ) )
" 5
"
" call col( [26, '$'] )
" 4.0
"
" following tests are done without the real 'let i += 1'
" let i += 1
" 4
"
" let i += 1
" let i += 1
" let i += 1
" 5
"
" another 0
" 5
"
" another 4
" 7 
"
" another 7
" 7 
"
"
" let mm =  col( [26, '$'] ) - 1
" 4.5
"
" let j = i
" 3.5
"
" let j = !i
" 3.5
"
" let j = i * 1
" 3.5
"
"
" if a == b
"   let c += 1
" else
"   let c = 1
" endif
" 7.5
"
"
" let c = ( a==b ) * c + 1
" 6.0
"
" let c = ( a[0]==b[0] ) * c + 1
" 6.5
"
" let c = (                                                              a[0]==b[0] ) * c + 1
" 7.5
"
"
" fun! Hun()
  " return Gun()
" endfunction
" fun! Gun()
  " return Fun()
" endfunction
" fun! Fun() "{{{
  " return 1
" endfunction "}}}
" 9.5
"
"
" fun! Gun()
  " return Fun()
" endfunction
" fun! Fun() "{{{
  " return 1
" endfunction "}}}
" 7.5
"
" let a = changenr()
" 5.0
"
" call cursor( [31, 4] )
" call cursor( [40, 3] )
" 6.50
"
"
"
"
"
"
"
"
"
"
"
"
"
"
"
"
