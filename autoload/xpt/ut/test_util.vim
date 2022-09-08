let s:oldcpo = &cpo
set cpo-=< cpo+=B

fun! s:TestFlatten(t) "{{{
    let cases = [
          \ [ [], [] ],
          \ [ [1, 2, 3], [1, 2, 3] ],
          \ [ [[1, 2], 3], [1, 2, 3] ],
          \ [ [[[1, 2], 3], 4], [1, 2, 3, 4] ],
          \ ]
    for [inp, outp] in cases
        call a:t.Eq(outp, xpt#util#Flatten(inp), string([inp, outp]))
    endfor
endfunction "}}}

fun! s:TestCharsePattern(t) "{{{
    " all visible ascii char
    let [i, len] = [0x21 - 1, 0x7e - 1]
    while i < len | let i += 1
        let c = nr2char(i)

        " by default it is non-magic
        let ptn = xpt#util#CharsPattern(c)
        call a:t.Eq(c, matchstr(c, '\V' . ptn), 'no magic \V' . string(ptn))
        call a:t.Eq(c, matchstr(c, '\M' . ptn), 'no magic \M' . string(ptn))

        " explicit non-magic
        let ptn = xpt#util#CharsPattern(c, 0)
        call a:t.Eq(c, matchstr(c, '\V' . ptn), 'no magic \V' . string(ptn))
        call a:t.Eq(c, matchstr(c, '\M' . ptn), 'no magic \M' . string(ptn))

        " explicit magic
        let ptn = xpt#util#CharsPattern(c, 1)
        call a:t.Eq(c, matchstr(c, '\v' . ptn), 'magic \v' . string(ptn))
        call a:t.Eq(c, matchstr(c, '\m' . ptn), 'magic \m' . string(ptn))
    endwhile
endfunction "}}}

fun! s:TestUnescapeChar( t ) "{{{
    let cases = [
          \ [ [ '', '' ], '' ],
          \ [ [ '\1', '1' ], '1' ],
          \ [ [ '\\1', '1' ], '\1' ],
          \ [ [ '\\\1', '1' ], '\1' ],
          \ [ [ '\\\11', '1' ], '\11' ],
          \ [ [ '\\\12', '1' ], '\12' ],
          \ [ [ '2\\\1', '1' ], '2\1' ],
          \ [ [ '2\\\1\\1', '1' ], '2\1\1' ],
          \ [ [ '\\\12', '2' ], '\\\12' ],
          \ ]

    " add all ascii char to test
    let [ i, len ] = [ 11 - 1, 127 - 1 ]
    while i < len | let i += 1

        let c = nr2char(i)

        " skip '\'
        if c == '\'
            continue
        endif
        call add( cases, [ [ '\\\' . c, c ], '\' . c ] )
    endwhile


    for [inp,outp] in cases
        let rst = xpt#util#UnescapeChar( inp[0], inp[1] )
        call a:t.Eq( outp, rst, string([ inp,  outp ] ) )
    endfor

endfunction "}}}

fun! s:TestSplitWith( t ) "{{{
    let cases = [
          \ [ [ '',          '`' ], [ '' ] ],
          \ [ [ '1',         '`' ], [ '1' ] ],
          \ [ [ '\1',        '`' ], [ '\1' ] ],
          \ [ [ '\\1',       '`' ], [ '\\1' ] ],
          \ [ [ '\\\1',      '`' ], [ '\\\1' ] ],
          \
          \ [ [ '1',         '`' ], [ '1' ] ],
          \ [ [ '1\',        '`' ], [ '1\' ] ],
          \ [ [ '1\\',       '`' ], [ '1\\' ] ],
          \ [ [ '1\\\',      '`' ], [ '1\\\' ] ],
          \
          \ [ [ '1`',        '`' ], [ '1', '' ] ],
          \ [ [ '1\`',       '`' ], [ '1\`' ] ],
          \ [ [ '1\\`',      '`' ], [ '1\\', '' ] ],
          \ [ [ '1\\\`',     '`' ], [ '1\\\`' ] ],
          \
          \ [ [ '`1',        '`' ], [ '', '1' ] ],
          \ [ [ '\`1',       '`' ], [ '\`1' ] ],
          \ [ [ '\\`1',      '`' ], [ '\\', '1' ] ],
          \ [ [ '\\\`1',     '`' ], [ '\\\`1' ] ],
          \
          \ [ [ '\\`\\^\\`', '^' ], [ '\\`\\', '\\`' ] ],
          \ ]

    for [inp,outp] in cases
        let rst = xpt#util#SplitWith( inp[0], inp[1] )
        call a:t.Eq( outp, rst, string([ inp,  outp ] ) )
    endfor

endfunction "}}}

exec xpt#unittest#run

let &cpo = s:oldcpo

