XPTemplate priority=spec keyword=<

let s:f = g:XPTfuncs() 
 
XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $VOID_LINE     <!-- void -->;

XPTinclude 
      \ _common/common

XPTvar $CL    <!--
XPTvar $CM    
XPTvar $CR    -->
XPTinclude 
      \ _comment/doubleSign


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


XPT CDATA hint=<![CDATA[...
<![CDATA[
`cursor^
]]>



" ================================= Wrapper ===================================

XPT <_ hint=<Tag>\ SEL\ </Tag>
<`tag^` `...{{^ `name^="`val^"` `...^`}}^>`wrapped^</`tag^>


XPT CDATA_ hint=<![CDATA[\ SEL\ ]]>
<![CDATA[
`wrapped^
]]>


