XPTemplate priority=lang

let s:f = g:XPTfuncs()

XPTvar $TRUE          1
XPTvar $FALSE         0
XPTvar $NULL          NULL
XPTvar $UNDEFINED     NULL
XPTvar $VOID_LINE     /* void */;
XPTvar $BRif \n

XPTinclude
      \ _common/common
      \ _condition/lisp.like

" ========================= Function and Variables =============================

" ================================= Snippets ===================================
XPTemplateDef
XPT begin hint=(begin\ ..\ )
(begin
   (`todo0^) `...^
   (`todon^)`...^)


XPT case hint=(case\ (of)\ ((match)\ (expr))\ ..)
(case (`of^)
      ({`match^} `expr1^) `...^
      ({`matchn^} `exprn^)`...^
      `else...^\(else \`cursor\^\)^^)



XPT cond hint=(cond\ ([condi]\ (expr))\ ..)
(cond ([`condition^] `expr1^) `...^
      ([`condition^] `exprn^)`...^
      `else...^\(else \`cursor\^\)^^)


XPT let hint=(let\ [(var\ (val))\ ..]\ (body))
(let [(`newVar^ `value^ `...^)
      (`newVarn^ `valuen^`...^)]
     (`cursor^))


XPT letrec hint=(letrec\ [(var\ (val))\ ..]\ (body))
(letrec [(`newVar^ `value^ `...^)
         (`newVarn^ `valuen^`...^)]
     (`cursor^))


XPT lambda hint=(lambda\ [params]\ (body))
(lambda [`params^]
        (`cursor^))


XPT defun hint=(define\ var\ (lambda\ ..))
(define `funName^
    (lambda [`params^]
        (`cursor^))
 )


XPT def hint=(define\ var\ (ex))
(define `varName^ `cursor^)


XPT do hint=(do\ ..)
(do {(`var1^ `init1^ `step1^) `...0^
     (`varn^ `initn^ `stepn^)`...0^}
   ([`test^] `exprs^ `...1^ `exprs^`...1^^)
   (`command0^) `...2^^
   (`command1^)`...2^)


