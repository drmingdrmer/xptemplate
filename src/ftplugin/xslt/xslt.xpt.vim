XPTemplate priority=lang- keyword=<

let s:f = g:XPTfuncs()

XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL

XPTvar $VOID_LINE  /* void */;
XPTvar $CURSOR_PH      cursor

XPTvar $BRif          ' '
XPTvar $BRel          \n
XPTvar $BRloop        ' '
XPTvar $BRstc         ' '
XPTvar $BRfun         ' '

XPTinclude
      \ _common/common
      \ html/html
      \ xml/xml

XPTvar $CL    <!--
XPTvar $CM
XPTvar $CR    -->
XPTinclude
      \ _comment/doubleSign

" ========================= Function and Variables =============================

" ================================= Snippets ===================================
XPTemplateDef




XPT sort hint=<xsl:sort\ ...
<xsl:sort select="`what^" />


XPT valueof hint=<xsl:value-of\ ...
<xsl:value-of select="`what^" />


XPT apply hint=<xsl:apply-templates\ ...
<xsl:apply-templates select="`what^" />


XPT param hint=<xsl:param\ ...
<xsl:param name="`name^" `select...{{^select="`expr^"`}}^ />


XPT import hint=<xsl:import\ ...
<xsl:import href="`URI^" />


XPT include hint=<xsl:include\ ...
<xsl:include href="`URI^" />


XPT stylesheet hint=<xsl:stylesheet\ ...
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform" >

    <xsl:output method="xml" indent="yes"/>

    <xsl:template match="/`cursor^">
    </xsl:template>
</xsl:stylesheet>


XPT template hint=<xsl:template\ match=\ ...
<xsl:template match="`match^">
    `cursor^
</xsl:template>


XPT foreach hint=<xsl:for-each\ select=\ ...
<xsl:for-each select="`match^">
    `cursor^
</xsl:for-each>


XPT if hint=<xsl:if\ test=\ ...
<xsl:if test="`test^">
    `cursor^
</xsl:if>


XPT choose hint=<xsl:choose\ ...
XSET job=$CL void $CR
<xsl:choose>
    <xsl:when test="`expr^">
        `job^
    </xsl:when>`...^
    <xsl:when test="`ex^">
        `job^
    </xsl:when>`...^
    `otherwise...{{^<xsl:otherwise>
        `cursor^
    </xsl:otherwise>`}}^
</xsl:choose>


XPT when hint=<xsl:when\ test=\ ...
<xsl:when test="`ex^">
    `what^
</xsl:when>


