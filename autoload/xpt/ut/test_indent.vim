let s:oldcpo = &cpo
set cpo-=< cpo+=B

fun! s:TestConvertIndentToTab( t ) "{{{
    let cases = [
          \ [ [ '', '' ],       [ '', '' ] ],
          \ [ [ ' ', '' ],      [ ' ', '' ] ],
          \ [ [ '   ', '' ],    [ '   ', '' ] ],
          \ [ [ '    ', '' ],   [ '	', '' ] ],
          \ [ [ '     ', '' ],  [ '	 ', '' ] ],
          \ [ [ '        ', '' ],  [ '		', '' ] ],
          \ [ [ '         ', '' ],  [ '		 ', '' ] ],
          \ [ [ '	', '' ],  [ '	', '' ] ],
          \ [ [ 'x     ', '' ],  [ 'x     ', '' ] ],
          \ [ [ 'x	', '' ],  [ 'x	', '' ] ],
          \ [ [ ' 	x	', '' ],  [ ' 	x	', '' ] ],
          \ [ [ '    	x	', '' ],  [ '		x	', '' ] ],
          \ ]

    for [inp,outp] in cases
        let lines = deepcopy(inp)
        " 2 same lines should both be converted
        let lines[1] = lines[0]
        let outp[1] = outp[0]
        call xpt#indent#IndentToTab(lines)
        call a:t.Eq( outp, lines, string([ inp,  outp ] ) )

        let lines = deepcopy(inp)
        let lines[1] = lines[0]
        let text = join(lines, "\n")
        let text = xpt#indent#IndentToTabStr(text)
        call a:t.Eq(join(outp, "\n"), text, string([inp, outp]))
    endfor

endfunction "}}}

fun! s:TestToActualIndent( t ) "{{{
    let old = [ &shiftwidth, &tabstop, &expandtab ]

    for sw in [ 2, 4, 8 ]
        for ts in [ 2, 4, 8 ]

            let cases = [
                  \ [ '', '', '' ],
                  \ [ '	', repeat('	',  sw / ts) . repeat(' ', sw % ts),
                  \        repeat(' ', sw) ],
                  \ [ '		', repeat('	',  sw*2 / ts) . repeat(' ', sw*2 % ts),
                  \                repeat(' ', sw*2)],
                  \ [ 'x		', 'x		', 'x		' ],
                  \ ]

            for [input_line,out_0, out_1] in cases
                let out = [out_0, out_1]
                for et in [0, 1]
                    let lines = [input_line, input_line]
                    let &shiftwidth = sw
                    let &tabstop = ts
                    let &expandtab = et

                    let out_lines = [out[et], out[et]]

                    call xpt#indent#ToActualIndent(lines, 0)
                    call a:t.Eq( out_lines, lines,
                          \      'sw=' . sw . ' ts=' . ts . ' et=' . et . ' '
                          \      . string([ input_line,  out[et] ] ) )

                    let lines = [input_line, input_line]
                    let text = xpt#indent#ToActualIndentStr(join(lines, "\n"), 0)
                    call a:t.Eq( join(out_lines, "\n"), text,
                          \      'sw=' . sw . ' ts=' . ts . ' et=' . et . ' '
                          \      . string([ input_line,  out[et] ] ) )
                endfor

            endfor

        endfor
    endfor

    let [ &shiftwidth, &tabstop, &expandtab ] = old

endfunction "}}}

fun! s:TestToActualIndentShift( t ) "{{{
    let old = [ &shiftwidth, &tabstop, &expandtab ]

    let &shiftwidth = 4
    let &tabstop = 4
    let &expandtab = 0

    let cases = [
          \ [ '', "\n ", "\n	" ],
          \ [ 'a', "a\n a", "a\n	a" ],
          \ [ '	a', "	a\n	 a", "	a\n		a" ],
          \ ]

    for [input_line, out1, out4] in cases
        let inp = input_line . "\n" . input_line
        let text = xpt#indent#ToActualIndentStr( inp, 1 )
        call a:t.Eq( out1, text, string([inp, out1]))

        let text = xpt#indent#ToActualIndentStr( inp, 4 )
        call a:t.Eq( out4, text, string([inp, out4]))
    endfor


    let [ &shiftwidth, &tabstop, &expandtab ] = old
endfunction "}}}

fun! s:TestToSpace( t ) "{{{
    let old = [ &shiftwidth, &tabstop, &expandtab ]

    let &shiftwidth = 4
    let &tabstop = 4
    let &expandtab = 0

    let cases = [
          \ [ '', '', ],
          \ [ ' ', ' ', ],
          \ [ '  ', '  ', ],
          \ [ '   ', '   ', ],
          \ [ '    ', '    ', ],
          \ [ ' 	', '    ', ],
          \ [ ' 	a', '    a', ],
          \ [ " 	a\n 	", "    a\n    ", ],
          \ [ "	a\n	b", "    a\n    b", ],
          \ [ " 	a\n 	b", "    a\n    b", ],
          \ [ "  	a\n  	b", "    a\n    b", ],
          \ [ "   	a\n   	b", "    a\n    b", ],
          \ [ "    	a\n    	b", "        a\n        b", ],
          \ [ "	 a\n	 b", "     a\n     b", ],
          \ [ "		 a\n		 	b",
          \   "         a\n            b", ],
          \ ]

    for [inp, out] in cases
        let text = xpt#indent#ToSpace( inp )
        call a:t.Eq( out, text, string([inp, out]))
    endfor

    let [ &shiftwidth, &tabstop, &expandtab ] = old
endfunction "}}}

fun! s:TestSpaceToTab( t ) "{{{
    let old = [ &shiftwidth, &tabstop, &expandtab ]

    let &shiftwidth = 4

    let cases = [
          \ [ '', '', ],
          \ [ ' ', ' ', ],
          \ [ '  ', '  ', ],
          \ [ '   ', '   ', ],
          \ [ '    ', '	', ],
          \ [ '     ', '	 ', ],
          \ [ '      ', '	  ', ],
          \ [ '       ', '	   ', ],
          \ [ '        ', '		', ],
          \
          \ [ ' 	', ' 	', ],
          \ [ ' 	a', ' 	a', ],
          \ [ "     a\n     ", "	 a\n	 ", ],
          \ [ "	a\n	b", "	a\n	b", ],
          \ [ "    a\n    b", "	a\n	b", ],
          \ [ "     a\n     b", "	 a\n	 b", ],
          \ [ "      a\n      b", "	  a\n	  b", ],
          \ [ "       a\n       b", "	   a\n	   b", ],
          \ [ "        a\n        b", "		a\n		b", ],
          \ ]

    for [inp, out] in cases
        let text = xpt#indent#SpaceToTab( inp )
        call a:t.Eq( out, text, string([inp, out]))
    endfor

    let [ &shiftwidth, &tabstop, &expandtab ] = old
endfunction "}}}

fun! s:TestRemoveIndentStr(t) "{{{
    let cases = [
          \  ['', 0, ''],
          \  ['', 1, ''],
          \  ['   ', 1, '   '],
          \  ["   ", 1, "   "],
          \  ["   \n ", 1, "   \n"],
          \  ["   \n ", 2, "   \n"],
          \  ["   \n   a", 2, "   \n a"],
          \
          \  ["   \n	a", 2, "   \n	a"],
          \  ["   \n  a", 2, "   \na"],
          \  ["   \n  a", 3, "   \na"],
          \  ["   \n   \n a", 2, "   \n \na"],
          \ ]

    for [txt, n, outp] in cases
        let act = xpt#indent#RemoveIndentStr(txt, n)
        call a:t.Eq(outp, act, string([txt, n, outp]))
    endfor
endfunction "}}}

exec xpt#unittest#run

let &cpo = s:oldcpo
