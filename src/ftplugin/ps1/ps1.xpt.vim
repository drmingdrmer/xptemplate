XPTemplate priority=lang


XPTinclude
      \ _common/common

" ========================= Function and Variables =============================

" ================================= Snippets ===================================
XPTemplateDef
XPT cmdlet hint=cmdlet\ ..-..\ {}
Cmdlet `verb^-`noun^
{
    `Param...{{^Param(
       `^
    )`}}^
    `Begin...{{^Begin
    {
    }`}}^
    Process
    {
    }
    `End...{{^End
    {
    }`}}^
}


XPT if hint=if\ (\ ..\ )\ {\ ..\ }\ ...
if ( `cond^ )
{
    `code^
}`
`...^
elseif ( `cond2^ )
{
    `body^
}`
`...^`
`else...{{^
else
{
    `body^
}`}}^


XPT fun hint=function\ ..(..)\ {\ ..\ }
function `funName^( `params^ )
{
   `cursor^
}


XPT function hint=function\ {\ BEGIN\ PROCESS\ END\ }
function `funName^( `params^ )
{
    `Begin...{{^Begin
    {
        `^
    }`}}^
    `Process...{{^Process
    {
        `^
    }`}}^
    `End...{{^End
    {
        `^
    }`}}^
}


XPT foreach hint=foreach\ (..\ in\ ..)
foreach ($`var^ in `other^)
    { `cursor^ }


XPT switch hint=switch\ (){\ ..\ {..}\ }
switch `option^^ (`what^)
{
 `pattern^ { `action^ }`...^
 `pattern^ { `action^ }`...^
 `Default...{{^Default { `action^ }`}}^
}


XPT trap hint=trap\ [..]\ {\ ..\ }
trap [`Exception^]
{
    `body^
}


XPT for hint=for\ (..;..;++)
for ($`var^ = `init^; $`var^ -ge `val^; $`var^--)
{
    `cursor^
}


XPT forr hint=for\ (..;..;--)
for ($`var^ = `init^; $`var^ -ge `val^; $`var^--)
{
    `cursor^
}


" ================================= Wrapper ===================================

XPT if_ hint=if\ (..)\ {\ SEL\ }\ ...
if ( `cond^ )
{
    `wrapped^
}`...^
elseif ( `cond2^ )
{
    `body^
}`...^`else...{{^
else
{
    `body^
}`}}^
