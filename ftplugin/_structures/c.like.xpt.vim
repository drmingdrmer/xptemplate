if exists("b:__STRUCTURES_C_LIKE_XPT_VIM__") 
    finish 
endif
let b:__STRUCTURES_C_LIKE_XPT_VIM__ = 1 

" containers
let [s:f, s:v] = XPTcontainer() 

" constant definition
call extend(s:v, {'$TRUE': '1', '$FALSE' : '0', '$NULL' : 'NULL', '$INDENT_HELPER' : '/* void */;'}, 'keep')

fun! s:f.c_enum_next(ptn) dict
  let v = self.V()
  " return ",  element.."
  if v == a:ptn
    return ''
  else
    return "-"
  endif
  " return toupper(self.V())
  " return '...'
endfunction

XPTemplateDef

XPT enum hint=enum\ {\ ..\ }
XSET var=
enum `name^
{
    `e^=`e^c_enum_next('e')^
} `var^^;
..XPT
XSETm elm?|post
,
`element^`
`elm?^XSETm END


XPT struct hint=struct\ {\ ..\ }
struct `structName^
{
    `type^ `field^;`
    `...^
    `type^ `field^;`
    `...^
} `var^^;


XPT bitfield hint=struct\ {\ ..\ :\ n\ }
struct `structName^
{
    `type^ `field^ : `bits^;`
    `...^
    `type^ `field^ : `bits^;`
    `...^
} `var^^;


