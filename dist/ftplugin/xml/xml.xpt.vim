XPTemplate priority=spec

let s:f = g:XPTfuncs()

XPTvar $CURSOR_PH     <!-- cursor -->

XPTinclude
      \ _common/common

XPTvar $CL    <!--
XPTvar $CM
XPTvar $CR    -->
XPTinclude
      \ _comment/doubleSign


" ========================= Function and Variables =============================

fun! s:f.xml_att_val()
    if self.Phase()=='post'
        return ''
    endif

    let name = self.ItemName()
    return self.Vmatch('\V' . name, '\V\^\s\*\$')
          \ ? ''
          \ : '="val" ' . name
endfunction

" ================================= Snippets ===================================
XPTemplateDef


XPT < hint=<Tag>..</Tag>
XSET att*|post=BuildIfChanged(V().'="`val^"` `att*^`att*^xml_att_val()^')
<`tag^` `att*^`att*^xml_att_val()^>`content^</`tag^>
..XPT


XPT ver hint=<?xml\ version=...
<?xml version="`ver^1.0^" encoding="`enc^utf-8^" ?>


XPT style hint=<?xml-stylesheet...
<?xml-stylesheet type="`style^text/css^" href="`from^">


XPT cdata hint=<![CDATA[...
<![CDATA[`cursor^]]>



" ================================= Wrapper ===================================

XPT <_ hint=<Tag>\ SEL\ </Tag>
<`tag^` `...{{^ `name^="`val^"` `...^`}}^>`wrapped^</`tag^>


XPT cdata_ hint=<![CDATA[\ SEL\ ]]>
<![CDATA[`wrapped^]]>


