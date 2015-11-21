let s:oldcpo = &cpo
set cpo-=< cpo+=B

let s:cases = []
let s:cases += [
      \[ [],
      \  [],
      \  [],
      \  [],
      \],
      \[ [],
      \  [],
      \  [[0, 0]],
      \  [],
      \],
      \[ [''],
      \  [''],
      \  [[0, 0]],
      \  [[0, 0]],
      \],
      \[ [''],
      \  [''],
      \  [[1, 0]],
      \  [],
      \],
      \[ ['x'],
      \  ['x'],
      \  [[0, 0], [0, 1]],
      \  [[0, 0], [0, 1]],
      \],
      \[ ['x'],
      \  ['xy'],
      \  [[0, 0], [0, 1]],
      \  [[0, 0], [0, 1]],
      \],
      \[ ['x'],
      \  ['xy'],
      \  [[0, 2], [0, 4]],
      \  [],
      \],
      \[ ['xy'],
      \  ['qxy'],
      \  [[0, 0], [0, 1]],
      \  [[0, 0], [0, 2]],
      \],
      \[ ['l1', 'l2'],
      \  ['l12'],
      \  [[0, 1], [0, 2], [1, 0], [1, 1], [1, 2]],
      \  [[0, 1], [0, 2], [0, 2], [0, 2], [0, 3]],
      \],
      \[ ['l123', 'l456'],
      \  ['l156'],
      \  [[0, 3], [1, 1], [1, 3]],
      \  [[0, 2], [0, 2], [0, 3]],
      \],
      \[ ['111', 'l123', 'l456'],
      \  ['000', '111', 'l156'],
      \  [[1, 3], [2, 1], [2, 3]],
      \  [[2, 2], [2, 2], [2, 3]],
      \],
      \[ ['hello', 'world', 'abc'],
      \  ['hello', 'wor', 'ld', 'abc'],
      \  [[0, 5], [1, 2], [1, 3], [1, 4], [2, 0]],
      \  [[0, 5], [1, 2], [1, 3], [2, 1], [3, 0]],
      \],
      \[ ['hello', 'world', 'abc', 'def'],
      \  ['hello', 'wor', 'ld', 'abc', 'def'],
      \  [[0, 5], [1, 2], [1, 3], [1, 4], [2, 0]],
      \  [[0, 5], [1, 2], [1, 3], [2, 1], [3, 0]],
      \],
      \]

fun! s:Test_00_UpdateLineChange(t) "{{{
    let cases = s:cases[:]
    let cases += [
          \[ ['l1', 'l2'],
          \  ['l0', 'l1', 'l', '2'],
          \  [[0, 1], [0, 2], [1, 0], [1, 1], [1, 2]],
          \  [[0, 1], [1, 2], [2, 0], [2, 1], [3, 1]],
          \],
          \[ ['l1', 'l2'],
          \  ['l1', 'l', '2'],
          \  [[0, 1], [0, 2], [1, 0], [1, 1], [1, 2]],
          \  [[0, 1], [0, 2], [1, 0], [1, 1], [2, 1]],
          \],
          \[ ['l1', 'l2'],
          \  ['l1', 'l', '2', 'l3', 'l4'],
          \  [[0, 1], [0, 2], [1, 0], [1, 1], [1, 2]],
          \  [[0, 1], [0, 2], [1, 0], [1, 1], [2, 1]],
          \],
          \]

    for [lines_a, lines_b, marks, expected] in cases

        let mes  = 'lines_a: ' . string(lines_a) . ";"
        let mes .= 'lines_b: ' . string(lines_b) . ";"
        let mes .= 'marks: ' . string(marks) . ";"
        let mes .= 'expected: ' . string(expected) . ";"

        let m0 = marks[:]
        call map(m0, 'v:val[:]')
        let r = xpt#mark#UpdateLineChange(lines_a, lines_b, marks)
        call a:t.Eq(expected, r, mes)

        call a:t.Eq(m0, marks, 'does not change input: ' . mes)

        unlet lines_a
        unlet lines_b
        unlet marks
        unlet expected
    endfor

endfunction "}}}

fun! s:Test_01_UpdateMarks(t) "{{{
    let cases = s:cases[:]
    let cases += [
          \[ ['l1', 'l2'],
          \  ['l0', 'l1', 'l', '2'],
          \  [[0, 1], [0, 2], [1, 0], [1, 1], [1, 2]],
          \  [[1, 1], [1, 2], [2, 0], [2, 1], [3, 1]],
          \],
          \[ ['l1', 'l2'],
          \  ['l1', 'l', '2'],
          \  [[0, 1], [0, 2], [1, 0], [1, 1], [1, 2]],
          \  [[0, 1], [0, 2], [1, 0], [1, 1], [2, 1]],
          \],
          \[ ['l1', 'l2'],
          \  ['l1', 'l', '2', 'l3', 'l4'],
          \  [[0, 1], [0, 2], [1, 0], [1, 1], [1, 2]],
          \  [[0, 1], [0, 2], [1, 0], [1, 1], [2, 1]],
          \],
          \]

    for [lines_a, lines_b, marks, expected] in cases

        let mes  = 'lines_a: ' . string(lines_a) . ";"
        let mes .= 'lines_b: ' . string(lines_b) . ";"
        let mes .= 'marks: ' . string(marks) . ";"
        let mes .= 'expected: ' . string(expected) . ";"

        let m0 = marks[:]
        call map(m0, 'v:val[:]')
        let r = xpt#mark#UpdateMarks(lines_a, lines_b, marks)
        call a:t.Eq(expected, r, mes)

        call a:t.Eq(m0, marks, 'does not change input: ' . mes)

        unlet lines_a
        unlet lines_b
        unlet marks
        unlet expected
    endfor

endfunction "}}}

fun! s:Bench_00_UpdateLineChange(b) "{{{
    let [lines_a, lines_b, marks] = [
          \  ['l1', 'l2'],
          \  ['l1', 'l', '2', 'l3', 'l4'],
          \  [[0, 1], [0, 2], [1, 0], [1, 1], [1, 2]],
          \]

    let i = 0
    while i < a:b.n | let i += 1
        let r = xpt#mark#UpdateLineChange(lines_a, lines_b, marks)
    endwhile
endfunction "}}}

fun! s:Bench_01_UpdateMarks(b) "{{{

    let [lines_a, lines_b, marks, expected] = [
          \  ['l1', 'l2'],
          \  ['l0', 'l1', 'l', '2'],
          \  [[0, 1], [0, 2], [1, 0], [1, 1], [1, 2]],
          \  [[1, 1], [1, 2], [2, 0], [2, 1], [3, 1]],
          \]

    let i = 0
    while i < a:b.n | let i += 1
        let r = xpt#mark#UpdateMarks(lines_a, lines_b, marks[ : ])
    endwhile

endfunction "}}}

let s:mypath = expand('<sfile>:p:h')

fun! s:Bench_02_UpdateMarks_200lines(b) "{{{

    let lines_a = readfile(s:mypath . '/helper/changes/text-vimhelp-200-1')
    let lines_b = readfile(s:mypath . '/helper/changes/text-vimhelp-200-2')

    let marks = [
          \[97, 11],
          \[99, 18],
          \[99, 19],
          \[99, 20],
          \[100, 0],
          \]

    let i = 0
    while i < a:b.n | let i += 1
        let r = xpt#mark#UpdateMarks(lines_a, lines_b, marks)
    endwhile

endfunction "}}}

exec xpt#unittest#run
let &cpo = s:oldcpo
