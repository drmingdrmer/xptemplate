
-   4-space indent:
    Used in snippet file.
    Consistent with different 'tabstop', 'shiftwidth' setting.

-   tab indent:
    Used internally in XPTemplate.
    Produced by converting 4 leading space to one tab.

    These two above are VIM setting irrelavent. Snippet file can use either of
    them, but 4-space indent is recommended.

-   space indent:
    Produced by expanding a `tab` char to `&shiftwidth` spaces.
    These spaces occupies the same room as actual indent.
    This is the second last step before putting text onto screen.

    space indent texts are used internally.
    Wrapped text is passing through in this style.

-   actual indent:
    Produced by convert `&tabstop` space to one tab if 'expandtab' not set.
    This is the actual indent

    The last two are VIM setting relavent.
