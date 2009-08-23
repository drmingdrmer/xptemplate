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
`node^` `details...^[shape=\`shape\^, label="\`lbl\^"]^^

..XPT

XPT lbl hint=[label=".."]
[label="`cursor^"]


XPT circle hint=..\[shape="circle"..]
`node^ [shape=circle` `label...^, label="\`lbl\^"^^]

..XPT

XPT diamond hint=..\[shape="diamond"..]
`node^ [shape=diamond` `label...^, label="\`lbl\^"^^]

..XPT

XPT box hint=..\[shape="box"..]
`node^ [shape=box` `label...^, label="\`lbl\^"^^]

..XPT

XPT ellipse hint=..\[shape="ellipse"..]
`node^ [shape=ellipse` `label...^, label="\`lbl\^"^^]

..XPT

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

