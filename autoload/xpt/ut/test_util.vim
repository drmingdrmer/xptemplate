let s:oldcpo = &cpo
set cpo-=< cpo+=B

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

