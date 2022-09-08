" File Description {{{
" =============================================================================
" Functions for snippets.
"
"
"                                                  by drdr.xp
"                                                     drdr.xp@gmail.com
" Usage :
"
" =============================================================================
" }}}

if exists( "g:__AL_XPT_SNIPFUNC_VIM__" ) && g:__AL_XPT_SNIPFUNC_VIM__ >= XPT#ver
    finish
endif
let g:__AL_XPT_SNIPFUNC_VIM__ = XPT#ver



let s:oldcpo = &cpo
set cpo-=< cpo+=B

let s:log = xpt#debug#Logger( 'warn' )
let s:log = xpt#debug#Logger( 'debug' )

fun! xpt#snipfunc#Extend( container ) "{{{
    call extend( a:container, s:f, 'keep' )
endfunction "}}}


let s:f = {}

" snip-functions "{{{

" Use to force pre-eval
fun! s:f.Pre( a ) "{{{
    return a:a
endfunction "}}}

fun! s:f.SnipObject() "{{{

    " TODO rename phFilterContexts to parseContext

    return self.phFilterContext isnot 0
          \ ? self.phFilterContext.snipObject
          \ : self.renderContext.snipObject

endfunction "}}}

fun! s:f.PHs( snipText ) "{{{

    let so = self.SnipObject()

    let slave = xpt#snip#NewSlave( so, a:snipText )
    call xpt#snip#CompileAndParse( slave )

    " NOTE: Do not need to deepcopy because "slave" should be discarded after
    "       then.
    return slave.parsedSnip

endfunction "}}}

fun! s:f.Inline( snipText ) "{{{

    return { 'action' : 'embed', 'phs' : self.PHs( a:snipText ) }

endfunction "}}}

fun! s:f.Inc( targetName, keepCursor, params ) "{{{

    " TODO recursive inclusion detect

    let so = self.SnipObject()
    let snipDict = so.ftScope.allTemplates

    if has_key( snipDict, a:targetName )


        let tsnip = snipDict[ a:targetName ]
        call xpt#snip#CompileAndParse( tsnip )


        let phs = xpt#phfilter#Filter( tsnip, 'xpt#phfilter#ReplacePH',
              \ { 'replParams' : a:params } )

        if !a:keepCursor
            call xpt#snip#DumbCursorInPlace( tsnip, phs )
        endif


        " TODO in runtime building, merging should be taken into renderContext.setting
        call xpt#st#Merge( so.setting, tsnip.setting )

        " nIndent set to 0 because included contents is not created within the
        " context of Inc()
        return { 'action' : 'embed', 'nIndent' : 0,  'phs' : phs }

    else
        return 0
    endif

endfunction "}}}

fun! s:f.GetDict( ... ) "{{{
    return
endfunction "}}}

" TODO bad, this function should not depends on phase of rendering
fun! s:f.GetVar( name ) "{{{

    if a:name =~# '\V\^$_x'

        let n = a:name[ 1 : ]

        if has_key( self, n )
            return self[ n ]()
        endif

    endif

    " no such function or it is static variable

    " TODO simplify and universalize varScopes

    let varScopes = []

    if has_key( self, 'evalContext' )
        call add( varScopes, self.evalContext.variables )
    endif

    if has_key( self, 'renderContext' )
        call add( varScopes, get( self.renderContext.snipSetting, 'variables', {} ) )
    endif

    call add( varScopes, self )

    for sc in varScopes
        let val = get( sc, a:name )
        if val isnot 0
            return val
        endif
    endfor

    return a:name


    " let r = self.renderContext

    " let ev = get( self.evalContext, 'variables', {} )
    " let rv = get( r.snipSetting, 'variables', {} )

    " return get( ev, a:name,
    "       \     get( rv, a:name,
    "       \         get( self, a:name, a:name ) ) )



endfunction "}}}

fun! s:f._xSnipName() "{{{
    return self.renderContext.snipObject.name
endfunction "}}}

fun! s:f.EmbedWrappedText() "{{{

    let wrapData = self.renderContext.userWrapped

    if !has_key( wrapData, 'text' )
        return 0
    endif

    let ph = self.phFilterContext.ph
    if has_key( ph, 'isKey' )

        let n = len( wrapData.lines )


        let nIndent = self.phFilterContext.phEvalContext.pos[ 1 ]
              \ - self.phFilterContext.phEvalContext.nIndAdd

        if self.phFilterContext.phEvalContext.pos[ 0 ] == 0
            " only when wrapper-ph is at first line, position includes offset
            let nIndent += self.phFilterContext.phEvalContext.offset
        endif

        let sep = "\n"


        let ph = extend( deepcopy( ph ), {
              \ 'name' : '', 
              \ 'value' :1,
              \ }, 'force' )
        unlet ph.isKey


        let newPHs = []

        let i = 0
        while i < n

            let newph = extend( deepcopy( ph ), {
                  \ 'displayText' : wrapData.lines[ i ], }, 'force' )

            call extend( newPHs, [ newph, sep ] )

            let i += 1
        endwhile

        " remove sep
        call remove( newPHs, -1 )

        return { 'action' : 'embed', 'nIndent' : nIndent, 'phs' : newPHs }

    else
        return { 'nIndent'  : wrapData.indent,
              \  'text'     : wrapData.text }
    endif

endfunction "}}}


" TODO what is this
fun! s:f.WrapAlignAfter( min ) "{{{
    let userWrapped = self.renderContext.userWrapped
    let n = max( [ a:min, userWrapped.max ] ) - len( userWrapped.curline )
    return repeat( ' ', n )
endfunction "}}}

" TODO and this
fun! s:f.WrapAlignBefore( min ) "{{{
    let userWrapped = self.renderContext.userWrapped
    let n = max( [ a:min, userWrapped.max ] ) - len( userWrapped.lines[ 0 ] )
    return repeat( ' ', n )
endfunction "}}}

fun! s:f.Item() "{{{
    return get( self.renderContext, 'item', {} )
endfunction "}}}

" current name
fun! s:f.ItemName() "{{{
    return get( self.Item(), 'name', '' )
endfunction "}}}

" name with edge
fun! s:f.ItemFullname() "{{{
    return get( self.Item(), 'fullname', '')
endfunction "}}}

" current value user typed
fun! s:f.ItemValue() dict "{{{
    return get( self.evalContext, 'userInput', '' )
endfunction "}}}

fun! s:f.PrevItem( n ) "{{{
    let hist = get( self.renderContext, 'history', [] )
    return get( hist, a:n, {} )
endfunction "}}}

fun! s:f.ItemInitValue() "{{{
    return get( self.Item(), 'initValue', '' )
endfunction "}}}

fun! s:f.ItemInitValueWithEdge() "{{{
    let [ l, r ] = self.ItemEdges()
    return l . self.ItemInitValue() . r
endfunction "}}}

fun! s:f.ItemValueStripped( ... ) "{{{
    let ptn = a:0 == 0 || a:1 =~ 'lr'
          \ ? '\V\^\s\*\|\s\*\$'
          \ : ( a:1 == 'l'
          \     ? '\V\^\s\*'
          \     : '\V\s\*\$' )
    return substitute( self.ItemValue(), ptn, '', 'g' )
endfunction "}}}

fun! s:f.ItemPos() "{{{
    return XPMposStartEnd( self.renderContext.leadingPlaceHolder.mark )
endfunction "}}}


" if value match one of the regexps
fun! s:f.Vmatch( ... ) "{{{
    let v = self.V()
    for reg in a:000
        if match(v, reg) != -1
            return 1
        endif
    endfor

    return 0
endfunction "}}}

" value matchstr
fun! s:f.VMS( reg ) "{{{
    return matchstr(self.V(), a:reg)
endfunction "}}}

" edge stripped value
fun! s:f.ItemStrippedValue() "{{{
    let v = self.V()

    let [edgeLeft, edgeRight] = self.ItemEdges()

    let v = substitute( v, '\V\^' . edgeLeft,       '', '' )
    let v = substitute( v, '\V' . edgeRight . '\$', '', '' )

    return v
endfunction "}}}

fun! s:f.Phase() dict "{{{
    return get( self.renderContext, 'phase', '' )
endfunction "}}}

" TODO this is not needed at all except as a shortcut.
" equals to expand()
fun! s:f.E(s) "{{{
    return expand(a:s)
endfunction "}}}

" return the context
fun! s:f.Context() "{{{
    return self.renderContext
endfunction "}}}

" TODO this is not needed at all except as a shortcut.
" post filter	substitute
fun! s:f.S(str, ptn, rep, ...) "{{{
    let flg = a:0 >= 1 ? a:1 : 'g'
    return substitute(a:str, a:ptn, a:rep, flg)
endfunction "}}}

" equals to S(C().value, ...)
fun! s:f.SubstituteWithValue(ptn, rep, ...) "{{{
    let flg = a:0 >= 1 ? a:1 : 'g'
    return substitute(self.V(), a:ptn, a:rep, flg)
endfunction "}}}

fun! s:f.HasStep( name ) "{{{
    let namedStep = get( self.renderContext, 'namedStep', {} )
    return has_key( namedStep, a:name )
endfunction "}}}

" reference to another finished item value
fun! s:f.Reference(name) "{{{
    let namedStep = get( self.renderContext, 'namedStep', {} )
    return get( namedStep, a:name, '' )
endfunction "}}}

" TODO use key 'tmpl' ?
fun! s:f.Snippet( name ) "{{{
    return get( self.renderContext.ftScope.allTemplates, a:name, { 'tmpl' : '' } )[ 'tmpl' ]
endfunction "}}}

" black hole
fun! s:f.Void(...) "{{{
    return ""
endfunction "}}}

" Echo several expression and concat them.
" That's the way to use normal vim script expression instead of mixed string
fun! s:f.Echo( ... ) "{{{
    if a:0 > 0
        return a:1
    else
        return ''
    endif
    " return join( a:000, '' )
endfunction "}}}

fun! s:f.EchoIf( isTrue, ... ) "{{{
    if a:isTrue
        return join( a:000, '' )
    else
        return self.V()
    endif
endfunction "}}}

fun! s:f.EchoIfEq( expected, ... ) "{{{
    if self.V() ==# a:expected
        return join( a:000, '' )
    else
        return self.V()
    endif
endfunction "}}}

fun! s:f.EchoIfNoChange( ... ) "{{{
    if self.V0() ==# self.ItemName()
        return join( a:000, '' )
    else
        return self.V()
    endif
endfunction "}}}

fun! s:f.Commentize( text ) "{{{
    if has_key( self, '$CL' )
        return self[ '$CL' ] . ' ' . a:text . ' ' . self[ '$CR' ]

    elseif has_key( self, '$CS' )
        return self[ '$CS' ] . ' ' . a:text

    endif

    return a:text
endfunction "}}}

fun! s:f.VoidLine() "{{{
    return self.Commentize( 'void' )
endfunction "}}}

fun! s:f.Empty() "{{{
    return self.ItemValue() == ''
endfunction "}}}

fun! s:f.IsChanged() "{{{
    let initFull =  self.ItemInitValueWithEdge()
    let v = self.ItemValue()

    call s:log.Debug( 'initFull=' . string( initFull ) )
    call s:log.Debug( 'v=' . string( v ) )

    " return v isnot '' && initFull !=# v
    return initFull !=# v

    " let fn = substitute( self.ItemInitValueWithEdge(), "\\V\n\\|\\s", '', 'g')
    " let v = substitute( self.V(), "\\V\n\\|\\s", '', 'g')
    " return v isnot '' && fn is v
endfunction "}}}

fun! s:f.EmbedPHs( phsID ) "{{{
    let snipObject = self.renderContext.snipObject
    return { 'action' : 'embed',
          \  'phs' : xpt#ftsc#GetPHPieces( snipObject.ftScope, a:phsID ) }
endfunction "}}}



" Same with Echo* except echoed text is to be build to generate dynamic place
" holders
fun! s:f.Build( ... ) "{{{
    return { 'action' : 'build', 'text' : join( a:000, '' ) }
endfunction "}}}

fun! s:f.BuildIfChanged( ... ) "{{{
    let v = substitute( self.V(), "\\V\n\\|\\s", '', 'g')
    let fn = substitute( self.ItemInitValueWithEdge(), "\\V\n\\|\\s", '', 'g')

    if v ==# fn || v == ''
        " return { 'action' : 'keepIndent', 'text' : self.V() }
        return ''
    else
        return { 'action' : 'build', 'text' : join( a:000, '' ) }
    endif
endfunction "}}}

fun! s:f.BuildIfNoChange( ... ) "{{{
    let v = substitute( self.V(), "\\V\n\\|\\s", '', 'g')
    let fn = substitute( self.ItemInitValueWithEdge(), "\\V\n\\|\\s", '', 'g')


    if v ==# fn
        return { 'action' : 'build', 'text' : join( a:000, '' ) }
    else
        return 0
    endif
endfunction "}}}

" trigger nested template
fun! s:f.Trigger( name ) "{{{
    return {'action' : 'expandTmpl', 'tmplName' : a:name}
endfunction "}}}

fun! s:f.Finish(...) "{{{

    return self.FinishPH( a:0 > 0 ? { 'text' : a:1 } : {} )

endfunction "}}}

fun! s:f.FinishOuter( ... ) "{{{

    return self.FinishPH( a:0 > 0
          \ ? { 'text' : a:1, 'marks' : 'mark' }
          \ : { 'marks' : 'mark' } )

endfunction "}}}

fun! s:f.FinishPH( opt ) "{{{
    " opt.cursor    'current',	// keep cursor position
    "
    "               [ line, col ],	// move cursor to
    "
    "               { 'rel'    : 'which'/1,	// keep cursor position relative
    "                                           to PH 'which' or current PH when
    "                                           set to 1
    "
    "                 'where'  : 'innerMarks.start',	// reference position
    "                                                   of PH described by
    "                                                   mark name.
    "
    "                 'offset' : [ line, col ] },	// offset
    "
    "               [ 'innerMarks.start', [ line, col ] ]	// shortcut
    "                                                           way.
    "
    " opt.marks     'innerMarks', 'mark'	// which part text to fill in.
    " opt.text      string	// text to fill into current PH.
    " opt.postponed string	// actions to do after Finish PH.

    let opt = a:opt

    if empty( self.renderContext.groupList )

        let o = { 'action' : g:XPTact.finishPH }
        call extend( o, opt, 'keep' )
        return o

    else
        return get( opt, 'text', 0 )
    endif

endfunction "}}}

" TODO use phs instead of text
fun! s:f.Embed( snippetText ) "{{{
    return { 'action' : g:XPTact.embed, 'text' : a:snippetText }
endfunction "}}}

fun! s:f.Next( ... ) "{{{

    let rst = { 'action' : 'next' }

    if a:0 > 0

        let phs = deepcopy( a:000 )
        call filter( phs, 'type(v:val)==' . type( '' ) )

        if len( phs ) < len( a:000 )
            let rst.phs = a:000
        else

            let text = join( a:000, '' )
            let so = self.SnipObject()

            if match( text, so.ptn.lft ) >= 0
                let rst.phs = self.PHs( text )
            else
                let rst.text = text
            endif

        endif

    endif

    return rst
    " return { 'action' : 'next', 'text' : join( a:000, '' ) }

endfunction "}}}

fun! s:f.Remove() "{{{
    return { 'action' : 'remove' }
endfunction "}}}

" This function is intended to be used for popup selection :
" XSET bidule=Choose([' ','dabadi','dabada'])
fun! s:f.Choose( lst, ... ) "{{{
    let val = { 'action' : 'pum', 'pum' : a:lst }

    if a:0 == 1
        let val.acceptEmpty = a:1 != 0
    endif

    return val
endfunction "}}}

fun! s:f.ChooseStr(...) "{{{
    return copy( a:000 )
endfunction "}}}

fun! s:f.Complete( key, ... ) "{{{

    let val = { 'action' : 'complete', 'pum' : a:key }

    if a:0 == 1
        let val.acceptEmpty = a:1 != 0
    endif

    return val
endfunction "}}}

" XXX
" Fill in postType, and finish template rendering at once.
" This make nested template rendering go back to upper level, top-level
" template rendering quit.
fun! s:f.xptFinishTemplateWith(postType) dict "{{{
endfunction "}}}

" XXX
" Fill in postType, jump to next item. For creating item being able to be
" automatically filled in
fun! s:f.xptFinishItemWith(postType) dict "{{{
endfunction "}}}

" TODO test me
fun! s:f.UnescapeMarks(string) dict "{{{
    let patterns = self.renderContext.snipObject.ptn
    let charToEscape = '\(\[' . patterns.l . patterns.r . ']\)'

    let r = substitute( a:string,  '\v(\\*)\1\\?\V' . charToEscape, '\1\2', 'g')

    return r
endfunction "}}}

fun! s:f.headerSymbol(...) "{{{
    let h = expand('%:t')
    let h = substitute(h, '\.', '_', 'g') " replace . with _
    let h = substitute(h, '.', '\U\0', 'g') " make all characters upper case

    return '__'.h.'__'
endfunction "}}}

fun! s:f.date(...) "{{{
    return strftime( self.GetVar( '$DATE_FMT' ) )
endfunction "}}}
fun! s:f.datetime(...) "{{{
    return strftime( self.GetVar( '$DATETIME_FMT' ) )
endfunction "}}}
fun! s:f.time(...) "{{{
    return strftime( self.GetVar( '$TIME_FMT' ) )
endfunction "}}}
fun! s:f.file(...) "{{{
    return expand("%:t")
endfunction "}}}
fun! s:f.fileRoot(...) "{{{
    return expand("%:t:r")
endfunction "}}}
fun! s:f.fileExt(...) "{{{
    return expand("%:t:e")
endfunction "}}}
fun! s:f.path(...) "{{{
    return expand("%:p")
endfunction "}}}

fun! s:f.UpperCase( v ) "{{{
    return substitute(a:v, '.', '\u&', 'g')
endfunction "}}}

fun! s:f.LowerCase( v ) "{{{
    return substitute(a:v, '.', '\l&', 'g')
endfunction "}}}

" Return Item Edges
fun! s:f.ItemEdges() "{{{
    let leader =  get( self.renderContext, 'leadingPlaceHolder', {} )
    if has_key( leader, 'leftEdge' )
        return [ leader.leftEdge, leader.rightEdge ]
    else
        return [ '', '' ]
    endif
endfunction "}}}

fun! s:f.ItemCreate( name, edges, filters ) "{{{
    let [ ml, mr ] = XPTmark()


    let item = ml . a:name

    if has_key( a:edges, 'left' )
        let item = ml . a:edges.left . item
    endif

    if has_key( a:edges, 'right' )
        let item .= ml . a:edges.right
    endif

    let item .= mr

    if has_key( a:filters, 'post' )
        let item .= a:filters.post . mr . mr
    endif

    return item

endfunction "}}}

" {{{ Quick Repetition
" If something typed, <tab>ing to next generate another item other than the
" typed.
"
" If nothing typed but only <tab> to next, clear it.
"
" Normal clear typed, also clear it
" TODO escape mark character in a:sep or a:item
" }}}
fun! s:f.ExpandIfNotEmpty( sep, item, ... ) "{{{
    let v = self.V()

    let [ ml, mr ] = XPTmark()

    if a:0 != 0
        let r = a:1
    else
        let r = ''
    endif

    " let t = ( v == '' || v == a:item || v == ( a:sep . a:item . r ) )
    let t = ( v == '' || v =~ '\V' . a:item )
          \ ? ''
          \ : self.Build( v
          \       . ml . a:sep . ml . a:item . ml . r . mr
          \       . 'ExpandIfNotEmpty(' . string( a:sep ) . ', ' . string( a:item )  . ')' . mr . mr )

    return t
endfunction "}}}

fun! s:f.ExpandInsideEdge( newLeftEdge, newRightEdge ) "{{{
    let v = self.V()
    let fullname = self.ItemFullname()

    let [ el, er ] = self.ItemEdges()

    if v ==# fullname || v == ''
        return ''
    endif

    return substitute( v, '\V' . er . '\$' , '' , '' )
          \. self.ItemCreate( self.ItemName(), { 'left' : a:newLeftEdge, 'right' : a:newRightEdge }, {} )
          \. er
endfunction "}}}

fun! s:f.NIndent() "{{{
    return &shiftwidth
endfunction "}}}

fun! s:f.ResetIndent( nIndent, text ) "{{{
    return { 'action' : 'resetIndent',
          \  'resetIndent' : 1, 'nIndent' : a:nIndent, 'text' : a:text }
endfunction "}}}

fun! s:f.CmplQuoter_pre() dict "{{{
    if !g:xptemplate_brace_complete
        return ''
    endif

    let v = substitute( self.ItemStrippedValue(), '\V\^\s\*', '', '' )

    let first = matchstr( v, '\V\^\[''"]' )
    if first == ''
        return ''
    endif

    let v = substitute( v, '\V\[^' . first . ']', '', 'g' )
    if v == first
        " only 1 quoter
        return first
    else
        return ''
    endif
endfunction "}}}

fun! s:f.AutoCmpl( keepInPost, list, ... ) "{{{

    if !a:keepInPost && self.Phase() == 'post'
        return ''
    endif

    if type( a:list ) == type( [] )
        let list = a:list
    else
        let list = [ a:list ] + a:000
    endif


    let v = self.V0()
    if v == ''
        return ''
    endif


    for word in list
        if word =~ '\V\^' . v
            return word[ len( v ) : ]
        endif
    endfor

    return ''
endfunction "}}}
"}}}

" snip-function shortcuts {{{
let s:f.Edges = s:f.ItemEdges
let s:f.UE = s:f.UnescapeMarks
let s:f.VOID = s:f.Void
let s:f.R = s:f.Reference
let s:f.SV = s:f.SubstituteWithValue
let s:f.C = s:f.Context
let s:f.V0 = s:f.ItemStrippedValue
let s:f.IVE = s:f.ItemInitValueWithEdge
let s:f.VS = s:f.ItemValueStripped
let s:f.IV = s:f.ItemInitValue
let s:f.V = s:f.ItemValue
let s:f.NN = s:f.ItemFullname
let s:f.N = s:f.ItemName
"}}}





let &cpo = s:oldcpo
