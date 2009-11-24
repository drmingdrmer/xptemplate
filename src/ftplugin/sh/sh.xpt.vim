XPTemplate priority=lang mark=~^ keyword=$([{

let s:f = g:XPTfuncs()

XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL

XPTvar $VOID_LINE     # void
XPTvar $CURSOR_PH     # cursor


XPTvar $BRif          ' '
XPTvar $BRel          \n
XPTvar $BRloop        ' '
XPTvar $BRstc         ' '
XPTvar $BRfun         ' '

XPTinclude
      \ _common/common

XPTvar $CS    #
XPTinclude
      \ _comment/singleSign


" ========================= Function and Variables =============================

let s:braceMap = {
            \   '`' : '`',
            \   '{' : '}',
            \   '[' : ']',
            \   '(' : ')',
            \  '{{' : '}}',
            \  '[[' : ']]',
            \  '((' : '))',
            \  '{ ' : ' }',
            \  '[ ' : ' ]',
            \  '( ' : ' )',
            \ '{{ ' : ' }}',
            \ '[[ ' : ' ]]',
            \ '(( ' : ' ))',
            \}

fun! s:f.sh_complete_brace()
    if !g:xptemplate_brace_complete
        return ''
    endif
    let v = self.V()
    let br = matchstr( v, '\V\^\[\[({`]\{1,2} \?' )
    if br == ''
        return ''
    elseif br == '`'
        return s:braceMap[ br ]
    else
        try
            let cmpl = s:braceMap[ br ]
            let cmplEsc = substitute( cmpl, ']', '\\[]]', 'g' )
            let tail = matchstr( v, '\V\%[' . cmplEsc . ']\$' )
            if tail == ' ' && br =~ ' '
                let tail = ''
            endif
            return cmpl[ len( tail ) : ]
        catch /.*/
            echom v:exception
        endtry
    endif
endfunction

" ================================= Snippets ===================================


XPTemplateDef


XPT shebang hint=#!/bin/[ba|z]sh
XSET sh=ChooseStr( 'sh', 'bash', 'zsh' )
#!/bin/~sh^

..XPT

XPT sb alias=shebang

XPT sh alias=shebang hint=#!/bin/sh
XSET sh=Next( 'sh' )

XPT bash alias=shebang hint=#!/bin/bash
XSET sh=Next( 'bash' )

XPT zsh alias=shebang hint=#!/bin/zsh
XSET sh=Next( 'zsh' )

XPT echodate hint=echo\ `date\ +%...`
echo `date +~fmt^`



XPT forin
for ~i^ in ~list^;~$BRloop^do
    ~cursor^
done


XPT foreach alias=forin


XPT for
for ((~i^ = ~0^; ~i^ < ~len^; ~i^++));~$BRloop^do
    ~cursor^
done

XPT forr
for ((~i^ = ~n^; ~i^ >~=^ ~start^; ~i^--));~$BRloop^do
    ~cursor^
done


XPT while
while ~condition^;~$BRloop^do
    ~cursor^
done


XPT while1 alias=while
XSET condition=Next( '[ 1 ]' )


XPT case
case $~var^ in
    ~pattern^)
    ~cursor^
    ;;

    *)
    ;;
esac


XPT if
if ~condition^~condition^sh_complete_brace()^;~$BRif^then
    ~cursor^
fi

XPT el hint=else\ ...
else
    ~cursor^



XPT ife
if ~condition^~condition^sh_complete_brace()^;~$BRif^then
    ~job^
else
    ~cursor^
fi


XPT elif
elif ~condition^~condition^sh_complete_brace()^;~$BRif^then
    ~cursor^


XPT (
( ~cursor^ )


XPT {
{ ~cursor^ }


XPT [
[ ~test^ ]

XPT [[
[[ ~test^ ]]


XPT fun
~name^ ()~$BRfun^{
    ~cursor^
}
