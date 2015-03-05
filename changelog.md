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
