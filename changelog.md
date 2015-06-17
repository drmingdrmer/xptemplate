2015-06-17
==========

Fixed
-----

*   engine: fix #69 mapping saver should not reinitiate when switching buffer

2015-06-02
==========

Fixed
-----

*   engine: support hint of pum in dictionary type
*   engine: post-filter uses outer-marks

*   eval: concat text and Echo(). fix #68

2015-04-20
==========

Fixed
-----

*   util: xpt#once#init path parsing in windows

2015-04-17
==========

Added
-----

*   util: load .xpt.vim from working dir

Fixed
-----

*   engine: quick-add snippet to buffer without filetype

2015-04-16
==========

Added
-----

*   integration-test: of g:xptemplate_lib_filter

*   option: g:xptemplate_lib_filter

2015-04-14
==========

Added
-----

*   integration-test: 01-g-xptemplate_key_force_pum
*   integration-test: 01-g-xptemplate_key
*   integration-test: escaping in g:xptemplate_vars
*   integration-test: 00-verboselog
*   integration-test: snippet hint

Fixed
-----

*   eval: \\$a should unescape one back slash
*   eval: error message should not interrupt working flow

*   hint: beside string, also accept number, dict and list value type

*   util: xpt#once#init resolve symbolic link

2015-03-05
==========

Fixed
-----

*   oop: skip verbose message when looking for class member

2015-03-03
==========

Added
-----

*   integration-test: basic rendering.
*   integration-test: indenting.
*   integration-test: command 'XSET'.
*   integration-test: pop up menu.
*   integration-test: wrapper.
*   integration-test: function:
    `Build()` `BuildIfNoChange()` `BuildSnippet()` `Choose()` `Echo()` `Trigger()`.
*   snippet: golang.
*   doc: `Build()` `Echo()` `BuildIfNoChange()`.
*   doc: gif screencast.
*   doc: `g:xptemplate_break_undo`.

Changed
-------

*   snippet: simplify markdown.
*   engine: use closure for variable looking up.
*   engine: filter action 'embed' is same with 'build'.
*   engine: support to change only the visual mapping.
*   engine: add conf `g:xptemplate_close_pum`.

Deprecated
----------

*   action: 'embed'.

Removed
-------

*   engine: several old fashion classes.

Fixed
-----

*   engine: fix script-local mapping restore.
*   readme: integration with latest supertab.
*   engine: non-built default value should not move cursor to next.
*   engine: correct several indent handling.
*   engien: option 'preview' with completeopt.
*   mapping: fix lost setting during applying BuildSnippet.
