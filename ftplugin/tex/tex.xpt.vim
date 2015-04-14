XPTemplate priority=lang mark=`~

let s:f = g:XPTfuncs()

XPTinclude
      \ _common/common

XPT _arg1 hidden " \\$_xSnipName\{..}
\\`$_xSnipName~{`cursor~}

XPT _arg2 hidden " \\$_xSnipName\{..}\{..}
\\`$_xSnipName~{`a~}{`b~}

XPT _sub hidden " \\{$_xSnipName}_..
\\`$_xSnipName~_`sub~

XPT _sub_super hidden " \\{$_xSnipName}_..^..
\\`$_xSnipName~_`sub~^`super~

XPT _begin wrap hidden " \begin{..} .. end{..}
\begin{`sth~}`{`what?`}~
    `cursor~
\end{`sth~}

XPT _block wrap hidden " \begin\{$_xSnipName} .. \end\{$_xSnipName}
\begin{`$_xSnipName~}
    `cursor~
\end{`$_xSnipName~}

XPT _block_t wrap hidden " \begin\{$_xSnipName} .. \end\{$_xSnipName}
\begin{`$_xSnipName~}{`title~}
    `cursor~
\end{`$_xSnipName~}

XPT section alias=_arg1
XPT label alias=_arg1
XPT ref alias=_arg1

XPT frac alias=_arg2

XPT abstract alias=_block
XPT document alias=_block
XPT equation alias=_block
XPT slide alias=_block

XPT frame alias=_block_t
XPT block alias=_block_t

XPT lim alias=_sub

XPT int alias=_sub_super

XPT info " title author date
\title{`title~}
\author{`$author~}
\date{`date()~}

XPT array " begin{array}{..}... end{array}
\begin{array}{`kind~rcl~}
`what~` `...0~ & `what~` `...0~ \\\\` `...1~
`what~` `...2~ & `what~` `...2~ \\\\` `...1~
\end{array}

XPT table " begin{tabular}{..}... end{tabular}
XSET hline..|post=\hline
XSET what*|post=ExpandIfNotEmpty( ' & ', 'what*' )
\begin{tabular}{`kind~|r|c|l|~}
`hline..~
`what*~ \\\\` `...1~
`hline..~
`what*~ \\\\` `...1~
\end{tabular}


" backward compatible
XPT lbl " label{..}
\label{`cursor~}

" backward compatible
XPT integral " int_..^..
\int_`begin~^`end~{`cursor~}

XPT itemize " begin{itemize} ... end{itemize}
\begin{itemize}
    \item `what~~`...~
    \item `what~~`...~
\end{itemize}

XPT enumerate " begin{enumerate} ... end{enumerate}
\begin{enumerate}
    \item `what~~`...~
    \item `what~~`...~
\end{enumerate}

XPT description " begin{description} ... end{description}
\begin{description}
    \item[`what~] `content~~`...~
    \item[`what~] `content~~`...~
\end{description}

XPT sqrt " sqrt[..]{..}
\sqrt`[`nth?`]~{`cursor~}

XPT sum " sum{..}~..{}
\sum_{`init~}^`end~{`cursor~}

XPT documentclass " documentclass[..]{..}
XSET kind=Choose(['article','book','report', 'letter','slides'])
\documentclass[`11~pt]{`kind~}

XPT toc " \tableofcontents
\tableofcontents

" backward compatible
XPT beg alias=_begin

XPT columns " \begin{columns}...
\begin{columns}
    \begin{column}[l]{`size~5cm~}
    \end{column}`...~

    \begin{column}[l]{`size~5cm~}
    \end{column}`...~
    `cursor~
\end{columns}

XPT enclose_ wraponly=wrapped " \begin{..} SEL \end{..}
\begin{`something~}
    `wrapped~
\end{`something~}

XPT as_ wraponly=wrapped " SEL{..}
\\`wrapped~{`cursor~}

XPT with_ wraponly=wrapped " \\.. {SEL}
\\`cursor~{`wrapped~}

