let s:oldcpo = &cpo
set cpo-=< cpo+=B

exec XPT#importConst

fun! s:TestTokenize(t) "{{{

    let ptn = {
          \   'lft' : s:nonEscaped . '`',
          \   'rt'  : s:nonEscaped . '^',
          \ }

    let cases = [
          \ ['', ['']],
          \ ['1', ['1']],
          \ ["\n", ["\n"]],
          \ ["a\nb", ["a\nb"]],
          \ ["a`", ['a', '`']],
          \ ["`", ['`']],
          \ ["`a", ['`a']],
          \ ["a`", ['a', '`']],
          \ ['a`b`c`', ['a', '`b', '`c', '`']],
          \ ['`a`b', ['`a', '`b']],
          \ ['^a`b^^`', ['^a', '`b', '^', '^', '`']],
          \ ["^a`x\nb^^`", ['^a', "`x\nb", '^', '^', '`']],
          \ ]

    for [inp, outp] in cases
        let act = xpt#snip#Tokenize(inp, ptn)
        call a:t.Eq(outp, act, string([inp, outp]))
    endfor

endfunction "}}}

exec xpt#unittest#run

let &cpo = s:oldcpo
