XPTemplate priority=spec keyword=<

let [s:f, s:v] = XPTcontainer() 
 
XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $INDENT_HELPER /* void */;

XPTinclude 
      \ _common/common
      \ _common/personal
      \ _comment/xml


" ========================= Function and Variables =============================


" ================================= Snippets ===================================
XPTemplateDef


XPT < hint=<Tag>..</Tag>
<`tag^` `...{{^ `name^="`val^"` `...^`}}^>
    `cursor^
</`tag^>


XPT ver hint=<?xml\ version=...
<?xml version="`ver^1.0^" encoding="`enc^utf-8^" ?>


XPT style hint=<?xml-stylesheet...
<?xml-stylesheet type="`style^text/css^" href="`from^">


XPT CDATA_ hint=<![CDATA[...
<![CDATA[
`cursor^
]]>


