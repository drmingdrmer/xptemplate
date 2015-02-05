let s:oldcpo = &cpo
set cpo-=< cpo+=B

exec XPT#importConst

let s:ptn = {
      \   'lft' : s:nonEscaped . '`',
      \   'rt'  : s:nonEscaped . '^',
      \   'l': '`',
      \   'r': '^',
      \ }

fun! s:TestTokenize(t) "{{{

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
          \ ['`a`b^', ['`a', '`b', '^']],
          \ ['`a`b^^^', ['`a', '`b', '^', '^', '^']],
          \ ['`a`b^xx^', ['`a', '`b', '^', 'xx', '^']],
          \ ['`a`b^xx^^', ['`a', '`b', '^', 'xx', '^', '^']],
          \ ['^a`b^^`', ['^', 'a', '`b', '^', '^', '`']],
          \ ["^a`x\nb^^`", ['^', 'a', "`x\nb", '^', '^', '`']],
          \ ]

    for [inp, outp] in cases
        let act = xpt#snip#Tokenize(inp, s:ptn)
        call a:t.Eq(outp, act, string([inp, outp]))
    endfor

endfunction "}}}

fun! s:TestTextToPlaceholders(t) "{{{
    let cases = [
          \ ['', []],
          \ ['a', [{'text': 'a'}]],
          \ [' a', [{'text': ' a'}]],
          \ [' a ', [{'text': ' a '}]],
          \ ['a b', [{'text': 'a b'}]],
          \
          \ ['\', [{'text': '\'}]],
          \ ['\\', [{'text': '\\'}]],
          \
          \ ['\`', [{'text': '`'}]],
          \ ['\\\`', [{'text': '\`'}]],
          \ ['\\\\\`', [{'text': '\\`'}]],
          \
          \ ['\^', [{'text': '^'}]],
          \ ['\\\^', [{'text': '\^'}]],
          \ ['\\\\\^', [{'text': '\\^'}]],
          \
          \ ['	a	b', [{'text': '	a	b'}]],
          \ ['	a	b	', [{'text': '	a	b	'}]],
          \
          \ ["\na	b	", [{"text": "\na	b	"}]],
          \ ["\na\nb	", [{"text": "\na\nb	"}]],
          \ ["\na\nb\n", [{"text": "\na\nb\n"}]],
          \
          \ ["a`b^c", [ {"text": "a"}, {"name": { "text": "b" }}, {"text": "c"} ]],
          \ ["a``b^c", [ { "text": "a" },
          \              { "leftEdge": {"text":""},
          \                "name": {"text": "b"} },
          \              { "text": "c" }]],
          \ ["a```b^c", [ { "text": "a"},
          \               { "leftEdge": {"text":""},
          \                 "name": {"text": ""},
          \                 "rightEdge": {"text": "b"}},
          \               { "text": "c" }]],
          \ ["a``b`^c", [ { "text": "a"},
          \               { "leftEdge": {"text":""},
          \                 "name": {"text": "b"},
          \                 "rightEdge": {"text": ""}},
          \               { "text": "c" }]],
          \ ["a`b``^c", [ { "text": "a"},
          \               { "leftEdge": {"text":"b"},
          \                 "name": {"text": ""},
          \                 "rightEdge": {"text": ""}},
          \               { "text": "c" }]],
          \
          \ ["a``b`^^^c", [ { "text": "a"},
          \                 { "leftEdge": {"text":""},
          \                   "name": {"text": "b"},
          \                   "rightEdge": {"text": ""},
          \                   "postFilter": {"text": ""},
          \                 },
          \                 { "text": "c" }]],
          \ ["a``b`^c^^", [ { "text": "a"},
          \                 { "leftEdge": {"text":""},
          \                   "name": {"text": "b"},
          \                   "rightEdge": {"text": ""},
          \                   "postFilter": {"text": "c"},
          \                 }]],
          \ ["a``b`^^c", [ { "text": "a"},
          \                { "leftEdge": {"text":""},
          \                  "name": {"text": "b"},
          \                  "rightEdge": {"text": ""},
          \                  "liveFilter": {"text": ""},
          \                },
          \                { "text": "c" }]],
          \ ["a``b`^w^c", [ { "text": "a"},
          \                 { "leftEdge": {"text":""},
          \                   "name": {"text": "b"},
          \                   "rightEdge": {"text": ""},
          \                   "liveFilter": {"text": "w"},
          \                 },
          \                 { "text": "c" }]],
          \
          \ ["a\n`\n	`tr($A, 'a', 'b')`    ^\nEcho(0)^\n`Inc('t')^",
          \               [ { "text": "a\n"},
          \                 { "leftEdge": {"text": "\n	"},
          \                   "name": {"text": "tr($A, 'a', 'b')"},
          \                   "rightEdge": {"text": "    "},
          \                   "liveFilter": {"text": "\nEcho(0)"},
          \                 },
          \                 { "text": "\n" },
          \                 { "name": { "text": "Inc('t')" } }]],
          \
          \ ["a\n`\\\n\\`	\\\\`tr($A, 'a', 'b')`    \\^^\nEcho(0)^\n`Inc('t')^",
          \               [ { "text": "a\n"},
          \                 { "leftEdge": {"text": "\\\n`	\\\\"},
          \                   "name": {"text": "tr($A, 'a', 'b')"},
          \                   "rightEdge": {"text": "    ^"},
          \                   "liveFilter": {"text": "\nEcho(0)"},
          \                 },
          \                 { "text": "\n" },
          \                 { "name": { "text": "Inc('t')" } }]],
          \ ]

    for [inp, outp] in cases
        let act = xpt#snip#TextToPlaceholders(inp, s:ptn)
        call a:t.Eq(outp, act, string([inp, outp]))
    endfor
endfunction "}}}

exec xpt#unittest#run

let &cpo = s:oldcpo
