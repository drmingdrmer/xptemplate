" Default settings and functions used in every snippet file.
XPTemplate priority=all

" containers
let s:f = g:XPTfuncs()

XPTvar $author $author is not set, you need to set g:xptemplate_vars="$author=your_name" in .vimrc
XPTvar $email  $email is not set, you need to set g:xptemplate_vars="$email=your_email@com" in .vimrc

XPTvar $VOID

" if () ** {
" else ** {
XPTvar $BRif     ' '

" } ** else {
XPTvar $BRel     \n

" for () ** {
" while () ** {
" do ** {
XPTvar $BRloop   ' '

" struct name ** {
XPTvar $BRstc    ' '

" int fun() ** {
" class name ** {
XPTvar $BRfun    ' '


" int fun ** (
" class name ** (
XPTvar $SPfun      ''

" int fun( ** arg ** )
" if ( ** condition ** )
" for ( ** statement ** )
" [ ** a, b ** ]
" { ** 'k' : 'v' ** }
XPTvar $SParg      ' '

" if ** (
" while ** (
" for ** (
XPTvar $SPcmd      ' '

" a ** = ** b
" a = a ** + ** 1
" (a, ** b, ** )
XPTvar $SPop       ' '


XPTvar $DATE_FMT     '%Y %b %d'
XPTvar $TIME_FMT     '%H:%M:%S'
XPTvar $DATETIME_FMT '%c'


XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          0
XPTvar $UNDEFINED     0

XPTvar $VOID_LINE
XPTvar $CURSOR_PH      CURSOR


XPTinclude
      \ _common/personal
      \ _common/inlineComplete
      \ _common/common.*

" XPTinclude
      " \ _common/cmn.counter


call XPTdefineSnippet('Author', {}, '`$author^')
call XPTdefineSnippet('Email', {}, '`$email^')
call XPTdefineSnippet('Date', {}, '`date()^')
call XPTdefineSnippet('File', {}, '`file()^')
call XPTdefineSnippet('Path', {}, '`path()^')
call XPTdefineSnippet('Time', {}, '`time()^')


call XPTdefineSnippet('"_', {'hint' : '" .. "', 'wraponly' : 'w' }, '"`w^"')
call XPTdefineSnippet("'_", {'hint' : "' .. '", 'wraponly' : 'w' }, "'`w^'")
call XPTdefineSnippet("<_", {'hint' : '< .. >', 'wraponly' : 'w' }, '<`w^>')
call XPTdefineSnippet("(_", {'hint' : '( .. )', 'wraponly' : 'w' }, '(`w^)')
call XPTdefineSnippet("[_", {'hint' : '[ .. ]', 'wraponly' : 'w' }, '[`w^]')
call XPTdefineSnippet("{_", {'hint' : '{ .. }', 'wraponly' : 'w' }, '{`w^}')
call XPTdefineSnippet("`_", {'hint' : '` .. `', 'wraponly' : 'w' }, '\``w^\`')

