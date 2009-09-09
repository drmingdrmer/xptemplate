XPTemplate priority=lang

let [s:f, s:v] = XPTcontainer() 
 
XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL
XPTvar $INDENT_HELPER /* void */;
XPTvar $IF_BRACKET_STL \n

XPTinclude 
      \ _common/common
      \ _common/personal


" ========================= Function and Variables =============================


" ================================= Snippets ===================================
XPTemplateDef


XPT invoke_ hint=..(SEL)
XSET name.post=RubySnakeCase()
`name^(`wrapped^)


XPT def_ hint=def\ ..()\ SEL\ end
XSET _.post=RubySnakeCase()
def `_^`(`args`)^
`wrapped^
end


XPT class_ hint=class\ ..\ SEL\ end
XSET _.post=RubyCamelCase()
class `_^
`wrapped^
end


XPT module_ hint=module\ ..\ SEL\ end
XSET _.post=RubyCamelCase()
module `_^
`wrapped^
end


XPT begin_ hint=begin\ SEL\ rescue\ ...
XSET exception=Exception
XSET block=# block
XSET rescue...|post=\nrescue `exception^\n  `block^`\n`rescue...^
XSET else...|post=\nelse\n  `block^
XSET ensure...|post=\nensure\n  `cursor^
begin
`wrapped^`
`rescue...^`
`else...^`
`ensure...^
end
