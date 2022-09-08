let s:oldcpo = &cpo
set cpo-=< cpo+=B

fun! s:TestDiff(t) "{{{

    " string-a, string-b,
    " longest-match, changes-of-a, changes-of-b

    let cases = [
          \
          \ [ '', '',
          \   [],
          \ ],
          \ [ 'a', '',
          \   [[[0, 1], [0, 0]],
          \   ]
          \ ],
          \ [ '', 'b',
          \   [[[0, 0], [0, 1]],
          \   ]
          \ ],
          \ [ 'x', 'x',
          \   [],
          \ ],
          \
          \ [ 'xa', 'x',
          \   [[[1, 2], [1, 1]],
          \   ]
          \ ],
          \ [ 'xa', 'xb',
          \   [[[1, 2], [1, 2]],
          \   ]
          \ ],
          \
          \ [ 'ax', 'x',
          \   [[[0, 1], [0, 0]],
          \   ]
          \ ],
          \ [ 'x', 'bx',
          \   [[[0, 0], [0, 1]],
          \   ]
          \ ],
          \ [ 'ax', 'bx',
          \   [[[0, 1], [0, 1]],
          \   ]
          \ ],
          \ [ 'xax', 'bx',
          \   [[[0, 2], [0, 1]],
          \   ]
          \ ],
          \ [ 'ax', 'xbx',
          \   [[[0, 1], [0, 2]],
          \   ]
          \ ],
          \ [ 'yax', 'bx',
          \   [[[0, 2], [0, 1]],
          \   ]
          \ ],
          \ [ 'ax', 'ybx',
          \   [[[0, 1], [0, 2]],
          \   ]
          \ ],
          \ [ 'uvax', 'ybx',
          \   [[[0, 3], [0, 2]],
          \   ]
          \ ],
          \
          \ [ 'xax', 'xbx',
          \   [[[1, 2], [1, 2]],
          \   ]
          \ ],
          \ [ 'yax', 'ybx',
          \   [[[1, 2], [1, 2]],
          \   ]
          \ ],
          \ [ 'xay', 'Xa',
          \   [[[0, 1], [0, 1]],
          \    [[2, 3], [2, 2]],
          \   ]
          \ ],
          \ [ 'xay', 'XaY',
          \   [[[0, 1], [0, 1]],
          \    [[2, 3], [2, 3]],
          \   ]
          \ ],
          \ [ 'xaybz', 'XaYb',
          \   [[[0, 1], [0, 1]],
          \    [[2, 3], [2, 3]],
          \    [[4, 5], [4, 4]],
          \   ]
          \ ],
          \ [ 'xayb', 'XaYbZ',
          \   [[[0, 1], [0, 1]],
          \    [[2, 3], [2, 3]],
          \    [[4, 4], [4, 5]],
          \   ]
          \ ],
          \ [ 'xaybz', 'XaYbZ',
          \   [[[0, 1], [0, 1]],
          \    [[2, 3], [2, 3]],
          \    [[4, 5], [4, 5]],
          \   ]
          \ ],
          \
          \ [ 'xabay', 'xay',
          \   [[[2, 4], [2, 2]],
          \   ]
          \ ],
          \ [ 'xay', 'xabay',
          \   [[[2, 2], [2, 4]],
          \   ]
          \ ],
          \ [ 'xaay', 'xaabaay',
          \   [[[3, 3], [3, 6]],
          \   ]
          \ ],
          \
          \ [ 'hello world', 'hello',
          \   [[[5, 11], [5, 5]],
          \   ]
          \ ],
          \ [ 'hello', 'hello world',
          \   [[[5, 5], [5, 11]],
          \   ]
          \ ],
          \ [ "hello\nworld", 'hello',
          \   [[[5, 11], [5, 5]],
          \   ]
          \ ],
          \ [ 'hello', "hello\nworld",
          \   [[[5, 5], [5, 11]],
          \   ]
          \ ],
          \ ]

    " prefix and suffix are removed before compare.
    let cases += [
          \ [ 'xa', "xaba",
          \   [[[2, 2], [2, 4]],
          \   ]
          \ ],
          \ [ 'xay', "xcabay",
          \   [[[1, 1], [1, 4]],
          \   ]
          \ ],
          \ ]

    " diff list
    let cases += [
          \ [ [], [],
          \   [],
          \ ],
          \ [ ['a'], [],
          \   [[[0, 1], [0, 0]],
          \   ]
          \ ],
          \ [ [], ['b'],
          \   [[[0, 0], [0, 1]],
          \   ]
          \ ],
          \ [ ['x'], ['x'],
          \   [],
          \ ],
          \ ]

    let cases += [
          \ [ ['x', ''], ['x'],
          \   [[[1, 2], [1, 1]],
          \   ]
          \ ],
          \ [ ['x', ''], ['x', 'b'],
          \   [[[1, 2], [1, 2]],
          \   ]
          \ ],
          \ ]

    let cases += [
          \ [ ['aaa', 'x'], ['x'],
          \   [[[0, 1], [0, 0]],
          \   ]
          \ ],
          \ [ ['x'], ['', 'x'],
          \   [[[0, 0], [0, 1]],
          \   ]
          \ ],
          \ [ ['aaa', 'x'], ['', 'x'],
          \   [[[0, 1], [0, 1]],
          \   ]
          \ ],
          \ [ ['xx', 'aaa', 'xx'], ['', 'xx'],
          \   [[[0, 2], [0, 1]],
          \   ]
          \ ],
          \ [ ['aaa', 'xx'], ['xx', '', 'xx'],
          \   [[[0, 1], [0, 2]],
          \   ]
          \ ],
          \ [ ['yy', 'aaa', 'xx'], ['', 'xx'],
          \   [[[0, 2], [0, 1]],
          \   ]
          \ ],
          \ [ ['aaa', 'xx'], ['yy', '', 'xx'],
          \   [[[0, 1], [0, 2]],
          \   ]
          \ ],
          \ [ ['uu', 'aaa', 'xx'], ['yy', '', 'xx'],
          \   [[[0, 2], [0, 2]],
          \   ]
          \ ],
          \ ]

    let cases += [
          \ [ ['xx', 'aaa', 'xx'], ['xx', '', 'xx'],
          \   [[[1, 2], [1, 2]],
          \   ]
          \ ],
          \ [ ['yy', 'aaa', 'xx'], ['yy', '', 'xx'],
          \   [[[1, 2], [1, 2]],
          \   ]
          \ ],
          \ [ ['xx', 'aaa', 'yy'], ['XX', 'aaa'],
          \   [[[0, 1], [0, 1]],
          \    [[2, 3], [2, 2]],
          \   ]
          \ ],
          \ [ ['xx', 'aaa', 'yy'], ['XX', 'aaa', 'YY'],
          \   [[[0, 1], [0, 1]],
          \    [[2, 3], [2, 3]],
          \   ]
          \ ],
          \ [ ['xx', 'aaa', 'yy', 'bb', 'zz'], ['XX', 'aaa', 'YY', 'bb'],
          \   [[[0, 1], [0, 1]],
          \    [[2, 3], [2, 3]],
          \    [[4, 5], [4, 4]],
          \   ]
          \ ],
          \ [ ['xx', 'aaa', 'yy', 'bb', 'zz'], ['XX', 'aaa', 'YY', 'bb', 'ZZ'],
          \   [[[0, 1], [0, 1]],
          \    [[2, 3], [2, 3]],
          \    [[4, 5], [4, 5]],
          \   ]
          \ ],
          \ ]

    " maximize prefix
    let cases += [
          \ [ ['xx', 'aaa', 'bb', 'aaa', 'yy'], ['xx', 'aaa', 'yy'],
          \   [[[2, 4], [2, 2]],
          \   ]
          \ ],
          \ [ ['xx', 'aaa', 'yy'], ['xx', 'aaa', 'bb', 'aaa', 'yy'],
          \   [[[2, 2], [2, 4]],
          \   ]
          \ ],
          \ [ ['xx', 'aaa', 'aaa', 'yy'], ['xx', 'aaa', 'aaa', 'bb', 'aaa', 'aaa', 'yy'],
          \   [[[3, 3], [3, 6]],
          \   ]
          \ ],
          \ ]

    let cases += [
          \ [ [ "the",
          \     "fox",
          \     "jumps",
          \     "over",
          \     "stupid",
          \     "rabbit",
          \   ],
          \   [ "the",
          \     "fox",
          \     "jumps",
          \   ],
          \   [[[3, 6], [3, 3]],
          \   ]
          \ ],
          \ [ [ "the",
          \     "jumps",
          \     "stupid",
          \     "rabbit",
          \   ],
          \   [ "the",
          \     "fox",
          \     "jumps",
          \     "over",
          \     "stupid",
          \     "rabbit",
          \   ],
          \   [[[1, 1], [1, 2]],
          \    [[2, 2], [3, 4]],
          \   ]
          \ ],
          \ [ [ "the",
          \     "fox",
          \     "jumps",
          \     "over",
          \     "stupid",
          \     "rabbit",
          \   ],
          \   [ "the fox",
          \     "jumps",
          \     "over",
          \     "stu",
          \     "pid",
          \     "rabbit",
          \   ],
          \   [[[0, 2], [0, 1]],
          \    [[4, 5], [3, 5]],
          \   ]
          \ ],
          \ ]

    for [a, b, chg_lst] in cases
        let mes =  string(a) . ' and ' . string(b)
        let mes .= '; changes: ' . string(chg_lst)

        let r = xpt#diff#Diff(a, b)

        call a:t.Eq(chg_lst, r, mes)

        unlet a
        unlet b
        unlet chg_lst
        unlet r

    endfor
endfunction "}}}

fun! s:Bench_00_Diff(b) "{{{

    let [la, lb] =  [
          \ "hello\nworld", 'hello',
          \ ]

    let i = 0
    while i < a:b.n | let i += 1
        let r = xpt#diff#Diff(la, lb)
    endwhile
endfunction "}}}

exec xpt#unittest#run

let &cpo = s:oldcpo
