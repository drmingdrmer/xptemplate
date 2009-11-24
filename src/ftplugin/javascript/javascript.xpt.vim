XPTemplate priority=lang

let s:f = g:XPTfuncs()

XPTvar $TRUE          true
XPTvar $FALSE         false
XPTvar $NULL          null
XPTvar $UNDEFINED     undefined

XPTvar $BRif     ' '
XPTvar $BRel   \n
XPTvar $BRloop    ' '
XPTvar $BRstc ' '
XPTvar $BRfun   ' '

XPTvar $VOID_LINE  /* void */;
XPTvar $CURSOR_PH      /* cursor */

XPTvar $CL  /*
XPTvar $CM   *
XPTvar $CR   */


XPTinclude
      \ _common/common
      \ _comment/doubleSign
      \ _condition/c.like

XPTvar $VAR_PRE
XPTvar $FOR_SCOPE 'var '
XPTinclude
      \ _loops/for

XPTinclude
      \ javascript/jquery

" ========================= Function and Variables =============================


" ================================= Snippets ===================================
XPTemplateDef



XPT bench hint=Benchmark
XSET log=console.log
XSET job=$VOID_LINE
XSET jobn=$VOID_LINE
var t0 = new Date().getTime();
for (var i = 0; i < `times^; ++i){
    `job^
}
var t1 = new Date().getTime();
for (var i = 0; i < `times^; ++i){
    `jobn^
}
var t2 = new Date().getTime();
`log^(t1-t0, t2-t1);

..XPT

XPT asoe hint=assertObjectEquals
assertObjectEquals(`mess^
                  , `arr^
                  , `expr^)


XPT cmt hint=/**\ @auth...\ */
XSET author=$author
XSET email=$email
/**
* @author : `author^ | `email^
* @description
*     `cursor^
* @return {`Object^} `desc^
*/


XPT cpr hint=@param
@param {`Object^} `name^ `desc^


" file comment
" 4 back slash represent 1 after rendering.
XPT fcmt hint=full\ doxygen\ comment
/**-------------------------/// `sum^ \\\---------------------------
 *
 * <b>`function^</b>
 * @version : `1.0^
 * @since : `date^
 *
 * @description :
 *   `cursor^
 * @usage :
 *
 * @author : `$author^ | `$email^
 * @copyright :
 * @TODO :
 *
 *--------------------------\\\ `sum^ ///---------------------------*/


XPT fun hint=function\ ..(\ ..\ )\ {..}
XSET arg*|post=ExpandIfNotEmpty(', ', 'arg*')
function` `name^ (`arg*^) {
    `cursor^
}


XPT forin hint=for\ (var\ ..\ in\ ..)\ {..}
for ( var `i^ in `array^ )`$BRloop^{
    var `e^ = `array^[`i^];
    `cursor^
}


XPT new hint=var\ ..\ =\ new\ ..\(..)
XSET arg*|post=ExpandIfNotEmpty(', ', 'arg*')
var `instant^ = new `Constructor^(`arg*^)


XPT proto hint=...prototype...\ =\ function\(..)\ {\ ..\ }
XSET arg*|post=ExpandIfNotEmpty(', ', 'arg*')
`Class^.prototype.`method^ = function(`arg*^)`$BRfun^{
`cursor^
}


XPT setTimeout hint=setTimeout\(function\()\ {\ ..\ },\ ..)
XSET job=$VOID_LINE
setTimeout(function() { `job^ }, `milliseconds^)


XPT try hint=try\ {..}\ catch\ {..}\ finally
XSET dealError=/* error handling */
XSET job=$VOID_LINE
try`$BRif^{
    `job^
}
catch (`err^)`$BRif^{
    `dealError^
}`...^
catch (`err^)`$BRif^{
    `dealError^
}`...^`
`finally...{{^
finally`$BRif^{
    `cursor^
}`}}^

" ================================= Wrapper ===================================

XPT bench_ hint=Benchmark
XSET log=console.log
var t0 = new Date().getTime();
for (var i = 0; i < `times^; ++i){
    `wrapped^
}
var t1 = new Date().getTime();
`log^(t1-t0);


XPT fun_ hint=function\ ..(\ ..\ )\ {..}
function` `name^ (`param^) {
    `wrapped^
    return;
}


XPT try_ hint=try\ {..}\ catch\ {..}\ finally
XSET dealError=/* error handling */
XSET job=$VOID_LINE
try`$BRif^{
    `wrapped^
}
catch (`err^)`$BRif^{
    `dealError^
}`...^
catch (`err^)`$BRif^{
    `dealError^
}`...^`
`finally...{{^
finally`$BRif^{
    `cursor^
}`}}^
