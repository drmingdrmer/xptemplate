" snippets for reStructuredText (.rst)
XPTemplate priority=lang mark=~^

let s:f = g:XPTfuncs()

XPTinclude
      \ _common/common

fun! s:f.ExpandRstTitle()
    let txt = self.R( 'title' )
    let bar = repeat( '=', len( txt ) )
    return bar . "\n" . txt . "\n" . bar . "\n"
endfunction

fun! s:f.ExpandRstSection( char )
    let txt = self.R( 'sectionName' )
    let bar = repeat( a:char, len( txt ) )
    return txt . "\n" . bar . "\n"
endfunction

XPT index " all stuff to create basic index
XSET sectionName|post=ExpandRstSection('=')
~sectionName^

Contents:

.. toctree::
   :maxdepth: 2
   :numbered:
   ~cursor^

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`


XPT title synonym=h1 " === ... ===
XSET title|post=ExpandRstTitle()
~title^


XPT section synonym=h2 " ... ====
XSET sectionName|post=ExpandRstSection('=')
~sectionName^

XPT subsection synonym=h3 " .... -------
XSET sectionName|post=ExpandRstSection('-')
~sectionName^


XPT code " ```...```
``~cursor^``

XPT italic " *...*
*~cursor^*

XPT bold " **...**
**~cursor^**

XPT link " .. _a link: ...
.. _a link: ~url^

XPT func " .. function:: ...
.. function:: ~funDesc^

    ~cursor^

