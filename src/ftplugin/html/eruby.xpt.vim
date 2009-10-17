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
<%# `cursor %>
