let s:oldcpo = &cpo
set cpo-=< cpo+=B

fun! s:TestDiff(t) "{{{

    " string-a, string-b,
    " longest-match, changes-of-a, changes-of-b

    let cases = [
          \
          \ [ '', '',
          \   0, [], [],
          \ ],
          \ [ 'a', '',
          \   0, [0], [],
          \ ],
          \ [ '', 'b',
          \   0, [], [0],
          \ ],
          \ [ 'x', 'x',
          \   1, [], [],
          \ ],
          \
          \ [ 'xa', 'x',
          \   1, [1], [],
          \ ],
          \ [ 'xa', 'xb',
          \   1, [1], [1],
          \ ],
          \
          \ [ 'ax', 'x',
          \   1, [0], [],
          \ ],
          \ [ 'x', 'bx',
          \   1, [], [0],
          \ ],
          \ [ 'ax', 'bx',
          \   1, [0], [0],
          \ ],
          \ [ 'xax', 'bx',
          \   1, [0, 1], [0],
          \ ],
          \ [ 'ax', 'xbx',
          \   1, [0], [0, 1],
          \ ],
          \ [ 'yax', 'bx',
          \   1, [0, 1], [0],
          \ ],
          \ [ 'ax', 'ybx',
          \   1, [0], [0, 1],
          \ ],
          \ [ 'uvax', 'ybx',
          \   1, [0, 1, 2], [0, 1],
          \ ],
          \
          \ [ 'xax', 'xbx',
          \   2, [1], [1],
          \ ],
          \ [ 'yax', 'ybx',
          \   2, [1], [1],
          \ ],
          \ [ 'xay', 'Xa',
          \   1, [0, 2], [0],
          \ ],
          \ [ 'xay', 'XaY',
          \   1, [0, 2], [0, 2],
          \ ],
          \ [ 'xaybz', 'XaYb',
          \   2, [0, 2, 4], [0, 2],
          \ ],
          \ [ 'xayb', 'XaYbZ',
          \   2, [0, 2], [0, 2, 4],
          \ ],
          \ [ 'xaybz', 'XaYbZ',
          \   2, [0, 2, 4], [0, 2, 4],
          \ ],
          \
          \ [ 'xabay', 'xay',
          \   3, [2, 3], [],
          \ ],
          \ [ 'xay', 'xabay',
          \   3, [], [2, 3],
          \ ],
          \ [ 'xaay', 'xaabaay',
          \   4, [], [3, 4, 5],
          \ ],
          \
          \ [ 'hello world', 'hello',
          \   5, [5, 6, 7, 8, 9, 10], [],
          \ ],
          \ [ 'hello', 'hello world',
          \   5, [], [5, 6, 7, 8, 9, 10],
          \ ],
          \ [ "hello\nworld", 'hello',
          \   5, [5, 6, 7, 8, 9, 10], [],
          \ ],
          \ [ 'hello', "hello\nworld",
          \   5, [], [5, 6, 7, 8, 9, 10],
          \ ],
          \ ]

    for [a, b, longest, chg_a, chg_b] in cases
        let mes =  string(a) . ' and ' . string(b)
        let mes .= '; expected: longest=' . longest
        let mes .= '; changes: ' . string(chg_a) . '; ' . string(chg_b)

        let r = xpt#diff#Diff(a, b)

        call a:t.Eq(longest, r.longest, 'longest wrong: ' . mes)
        call a:t.Eq(chg_a, r.changes.a, 'changes of a: ' . mes)
        call a:t.Eq(chg_b, r.changes.b, 'changes of b: ' . mes)
    endfor
endfunction "}}}

exec xpt#unittest#run

let &cpo = s:oldcpo
