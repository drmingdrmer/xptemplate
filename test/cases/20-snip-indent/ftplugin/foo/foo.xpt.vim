XPTemplate priority=lang

let s:f = g:XPTfuncs()

XPTinclude
      \ _common/common

XPT snip-indent
line1
    1-indent
     1-indent-and-1-space
          2-indent-and-2-space

XPT 5-spaces
line1
     line2

XPT 1-tab-1-space
line1
	 line2

XPT xsetm
XSETm ph
ph-line-1
    ph-line-2
XSETm END
line1
    `ph^

XPT xset
XSET ph=ph-line-1\n    ph-line-2
line1
    `ph^

XPT xset-2tab-indent
XSET ph=ph-line-1\n		ph-line-2
line1
    `ph^

XPT xset-action-echo
XSET ph=Echo("ph-line-1\n    ph-line-2")
line1
    `ph^

XPT xset-action-build
XSET ph=Build("ph-line-1\n    ph-line-2")
line1
    `ph^

XPT xset-post
XSET ph|post=line-1\n    line-2
line1
    `ph^
        `ph^

XPT xsetm-post
XSETm ph|post
line-1
    line-2
XSETm END
line1
    `ph^
        `ph^

XPT xsetm-post-build
XSETm ph|post
`ph1^
    `ph2^
XSETm END
line1
    `ph^

XPT xset-post-build
XSET ph|post=`ph1^\n    `ph2^
line1
    `ph^

XPT xset-reset-indent-backward-4
XSET ph=ResetIndent(-4,"ph-line-1\n    ph-line-2")
line1-`ph^

XPT instant-1-indent
line1`Echo("\n    ")^line2

XPT instant-reset-indent-backward-4
line1-`ResetIndent(-4,"ph-line-1\nph-line-2")^

XPT instant-reset-indent-backward-4-edge
line1-`edge-`ResetIndent(-4,"ph-line-1\nph-line-2")`-edge^

XPT indent-in-edge-instant
    -`
    `Echo("line-1\n     line-2")`
    (right)^=

XPT tab-in-edge-instant
    -`
	`Echo("line-1\n	line-2")`
    (right)^=
