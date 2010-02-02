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

fun! s:f.xml_tag_ontype()
    let v = self.V()
    if v =~ '\V\s\$'
        let v = substitute( v, '\V\s\*\$', '', 'g' )
        return self.Next( v )
    endif
    return v
endfunction

fun! s:f.xml_attr_ontype()
    let v = self.V()
    if v =~ '\V=\$'
        return self.Next()
    elseif len( v ) > 2 && v =~ '\V""\$'
        return self.Next( v[ 0 : -2 ] )
    else
        return v
    endif

endfunction

fun! s:f.xml_create_attr_ph()
    " let prev = self.PrevItem( -1 )
    if !self.HasStep( 'x' )
        return self.Embed('` `x^' . '`att*^')
    endif

    let prev = self.Reference( 'x' )

    if prev =~ '=$' 
        return self.Embed('`"`x`"^' . '`att*^')
    elseif prev =~ '"$'
        return self.Embed('` `x^' . '`att*^')
    else
        return self.Next( '' )
    endif
endfunction


" ================================= Snippets ===================================
XPTemplateDef


" NOTE: use Embed in default value phase to prevent post filter ruin place
" holder
XPT < hint=<Tag>..</Tag>
XSET tag|ontype=xml_tag_ontype()
XSET att*|pre=Echo('')
XSET att*|def=Embed( '` `^' )
<`tag^`att*^>`content^</`tag^>
..XPT


" " auto attributes completion
" XPT < hint=<Tag>..</Tag>
" XSET tag|ontype=xml_tag_ontype()
" XSET att*|pre=Echo('')
" XSET att*|def=xml_create_attr_ph()
" XSET x|def=Echo( '' )
" XSET x|ontype=xml_attr_ontype()
" XSET x|post=SV( '\v^\s*$', '' )
" <`tag^`att*^>`content^</`tag^>
" ..XPT


XPT ver " <?xml version=...
<?xml version="`ver^1.0^" encoding="`enc^utf-8^" ?>


XPT style " <?xml-stylesheet...
<?xml-stylesheet type="`style^text/css^" href="`from^">


XPT cdata " <![CDATA[...
<![CDATA[`cursor^]]>



" ================================= Wrapper ===================================

XPT <_ " <Tag>\ SEL\ </Tag>
<`tag^` `...{{^ `name^="`val^"` `...^`}}^>`wrapped^</`tag^>


XPT cdata_ " <![CDATA[\ SEL\ ]]>
<![CDATA[`wrapped^]]>


