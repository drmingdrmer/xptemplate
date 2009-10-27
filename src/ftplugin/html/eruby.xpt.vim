" These snippets work only in html context of a eruby file
if &filetype != 'eruby'
    finish
endif

XPTemplate priority=lang-

XPTemplateDef

XPT ruby hint=<%\ ...
<%
    `cursor^
%>


XPT r hint=<%\ ...\ %>
<% `cursor^ %>


XPT re hint=<%=\ ...
<%= `expr^ %>


XPT rc hint=<%#\ ...
<%# `cursor^ %>
