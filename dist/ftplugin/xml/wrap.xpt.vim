XPTemplate priority=spec keyword=<

let [s:f, s:v] = XPTcontainer() 
 
XPTvar $TRUE          1
XPTvar $FALSE         0


" ========================= Function and Variables =============================


" ================================= Snippets ===================================
XPTemplateDef


XPT <_ hint=<Tag>\ SEL\ </Tag>
<`tag^` `...{{^ `name^="`val^"` `...^`}}^>`wrapped^</`tag^>


XPT CDATA_ hint=<![CDATA[\ SEL\ ]]>
<![CDATA[
`wrapped^
]]>


