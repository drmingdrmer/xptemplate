XPTemplate priority=lang-


XPTinclude
      \ _common/common
      \ html/html


XPT _simpletag hidden " {% $_xSnipName %}
{% `$_xSnipName^ %}
..XPT


XPT _tag hidden " {% $_xSnipName params %}
{% `$_xSnipName^ `params^ %}
..XPT


XPT _qtag hidden " {% $_xSnipName "params" %}
{% `$_xSnipName^ "`params^" %}
..XPT


XPT _simpleblock hidden " {% $_xSnipName %}..{% end$_xSnipName %}
{% `$_xSnipName^ %}`content^{% end`$_xSnipName^ %}
..XPT


XPT _block wrap=content hidden " {% $_xSnipName  params %}..{% end$_xSnipName %} 
{% `$_xSnipName^ `params^ %}
    `content^
{% end`$_xSnipName^ %}
..XPT


XPT _qblock wrap=content hidden " {% $_xSnipName "params" %}..{% end$_xSnipName %} 
{% `$_xSnipName^ "`params^" %}
    `content^
{% end`$_xSnipName^ %}
..XPT


XPT _if wrap=content " $_xSnipName .. else .. end$_xSnipName
{% `$_xSnipName^ `param^ %}
    `content^
`else...{{^{% else %}
    `content^`}}^
{% end`$_xSnipName^ %}
..XPT


XPT var " {{ var }}
{{ `var^ }}
..XPT


XPT autoescape  alias=_block
XPT block       alias=_block
XPT comment     alias=_simpleblock
XPT csrf_token  alias=_simpletag
XPT cycle       alias=_tag
XPT debug       alias=_simpletag
XPT extends     alias=_qtag
XPT filter      alias=_block
XPT firstof     alias=_tag
XPT for         alias=_block
XPT empty       alias=_simpletag
XPT else        alias=_simpletag
XPT if          alias=_if
XPT ifchanged   alias=_if
XPT ifequal     alias=_if
XPT ifnotequal  alias=_if
XPT include     alias=_qtag
XPT load        alias=_tag
XPT now         alias=_tag
XPT regroup     alias=_tag
XPT url         alias=_tag
XPT spaceless   alias=_simpleblock
XPT ssi         alias=_tag
XPT with        alias=_block
