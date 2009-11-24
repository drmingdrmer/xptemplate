XPTemplate priority=lang

let s:f = g:XPTfuncs()

XPTvar $VOID_LINE  /* void */
XPTvar $CURSOR_PH      /* cursor */

XPTvar $CL    /*
XPTvar $CM
XPTvar $CR    */

XPTinclude
      \ _common/common
      \ _comment/doubleSign


" ========================= Function and Variables =============================


" ================================= Snippets ===================================
XPTemplateDef


XPT digraph hint=digraph\ ..\ {\ ..\ }
digraph `graphName^
{
    `cursor^
}
..XPT


XPT graph hint=graph\ ..\ {\ ..\ }
graph `graphName^
{
    `cursor^
}
..XPT

XPT subgraph hint=subgraph\ ..\ {\ ..\ }
subgraph `clusterName^
{
    `cursor^
}
..XPT

XPT node hint=..\ [...]
XSET shape=Choose(['box',  'polygon',  'ellipse',  'circle',  'point',  'egg',  'triangle',  'plaintext',  'diamond',  'trapezium',  'parallelogram',  'house',  'pentagon',  'hexagon',  'septagon',  'octagon',  'doublecircle',  'doubleoctagon',  'tripleoctagon',  'invtriangle',  'invtrapezium',  'invhouse',  'Mdiamond',  'Msquare',  'Mcircle',  'rect',  'rectangle',  'none',  'note',  'tab',  'folder',  'box3d',  'component'])
`node^` `details...{{^ [shape=`shape^, label="`^"]`}}^
..XPT

XPT lbl hint=[label=".."]
[label="`cursor^"]


XPT shapeNode hint=
`node^ [shape=`shape^` `label...{{^, label="`lbl^"`}}^]

..XPT

XPT circle alias=shapeNode hint=..\[shape="circle"..]
XSET shape|pre=circle
XSET shape=Next()


XPT diamond alias=shapeNode hint=..\[shape="diamond"..]
XSET shape|pre=diamond
XSET shape=Next()


XPT box alias=shapeNode hint=..\[shape="box"..]
XSET shape|pre=box
XSET shape=Next()


XPT ellipse alias=shapeNode hint=..\[shape="ellipse"..]
XSET shape|pre=ellipse
XSET shape=Next()


XPT record hint=..\[shape="record",\ label=".."]
`node^ [shape=record, label="`<`id`>^ `lbl^`...^| `<`id`>^ `lbl^`...^"]

..XPT


XPT triangle hint=..\[shape="triangle",\ label=".."]
`node^ [shape=triangle, label="`<`id`>^ `lbl^`...^| `<`id`>^ `lbl^`...^"]

..XPT


XPT row hint={..|...\ }
{`<`id`>^ `lbl^`...^| `<`id`>^ `lbl^`...^}

..XPT



XPT col hint={..|...\ }
{`<`id`>^ `lbl^`...^| `<`id`>^ `lbl^`...^}

..XPT








XPT subgraph_ hint=subgraph\ ..\ {\ SEL\ }
subgraph `clusterName^
{
    `wrapped^
}
..XPT

