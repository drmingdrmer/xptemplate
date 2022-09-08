if exists( "g:__AL_XPT_PHFILTER_VIM__" ) && g:__AL_XPT_PHFILTER_VIM__ >= XPT#ver
    finish
endif
let g:__AL_XPT_PHFILTER_VIM__ = XPT#ver



let s:oldcpo = &cpo
set cpo-=< cpo+=B

let s:log = xpt#debug#Logger( 'warn' )
let s:log = xpt#debug#Logger( 'debug' )

exe XPT#importConst

fun! xpt#phfilter#Filter( so, PHFilterName, extContext ) "{{{

    let fctx = {
          \ 'snipObject' : a:so,
          \ 'snipSetting': a:so.setting,
          \ 'phptns'     : a:so.ptn,
          \
          \ 'phEvalContext' : {
          \         'variables' : a:so.setting.variables,
          \         'pos'       : [ 0, 0 ],
          \         'nIndAdd'   : 0 },
          \
          \ 'srcPHs'       : a:so.parsedSnip,
          \ 'rstPHs'       : [],
          \
          \ 'skip'         : '\v[^]',
          \ 'forceNotSkip' : '\v.',
          \ }

    call extend( fctx, a:extContext, 'force' )

    call extend( fctx.phEvalContext, { 'pos' : [ 0, 0 ], 'nIndAdd' : 0 }, 'force' )

    let fctx.srcPHs = deepcopy( fctx.srcPHs )

    if len( fctx.srcPHs ) == 0
        return []
    endif


    call add( b:xptemplateData.phFilterContexts, fctx )


    " Add a "\n" for creating indent.
    " NOTE: Add it here but not in creation phase because rstPHs may be overwritten
    " NOTE: "\n" make it all the same extracting indent
    call add( fctx.rstPHs, "\n" )


    try

        while !empty( fctx.srcPHs )

            let fctx.ph = remove( fctx.srcPHs, 0 )
            let r = {a:PHFilterName}( fctx )

        endwhile

    finally
        call remove( b:xptemplateData.phFilterContexts, -1 )
        call s:log.Debug( 'last phFilterContexts removed. current len=' . len( b:xptemplateData.phFilterContexts ) )
    endtry


    call s:log.Debug( 'fctx.rstPHs=' . xpt#debug#List( fctx.rstPHs ) )


    let rst = fctx.rstPHs

    " Remove the first "\n" added at beginning
    if !empty( rst )
        let rst[ 0 ] = rst[ 0 ][ 1 : ]
    endif

    call filter( rst, 'len(v:val) > 0' )

    call s:log.Debug( 'fctx.rstPHs after filtering empty phs=' . xpt#debug#List( fctx.rstPHs ) )

    return rst

endfunction "}}}

fun! xpt#phfilter#EvalInstantFilters( fctx ) "{{{


    call s:log.Debug( 'len of a:fctx.rstPHs=' . string( len( a:fctx.rstPHs ) ) )


    if type( a:fctx.ph ) == type( {} )

        for a:fctx.key in [ 'leftEdge', 'displayText', 'rightEdge' ]

            if s:EvalPHElt( a:fctx ) isnot s:GOON
                return
            endif

        endfor

    endif


    call xpt#phfilter#FeedPH( a:fctx )


    call s:log.Debug( 'ph added=' . string( a:fctx.ph ) )
    call s:log.Debug( 'phs=' . xpt#debug#List( a:fctx.rstPHs ) )

endfunction "}}}

fun! xpt#phfilter#EvalPresetFilters( fctx ) "{{{


    call s:log.Debug( 'len of a:fctx.rstPHs=' . string( len( a:fctx.rstPHs ) ) )


    if type( a:fctx.ph ) == type( {} )


        " TODO Is it better overriding ph[ 'displayText' ] even if it is an
        "      instant value?
        if type( a:fctx.ph[ 'displayText' ] ) == type( '' )

            " TODO move xpt#ph#GetPresetFilter into this file
            let flt = xpt#ph#GetPresetFilter( a:fctx.ph, a:fctx.snipSetting )

            if flt isnot g:EmptyFilter
                let a:fctx.ph[ 'displayText' ] = flt
            endif

        endif


        for a:fctx.key in [ 'leftEdge', 'displayText', 'rightEdge' ]

            if s:EvalPHElt( a:fctx ) isnot s:GOON
                return
            endif

        endfor


    endif


    call xpt#phfilter#FeedPH( a:fctx )


    call s:log.Debug( 'ph added=' . string( a:fctx.ph ) )
    call s:log.Debug( 'phs=' . xpt#debug#List( a:fctx.rstPHs ) )

endfunction "}}}

fun! s:EvalPHElt( fctx, ... ) "{{{

    " fctx = {
    "     'ph'         : Placeholder,
    "     'key'        : Element key to eval 'leftEdge|displayText|rightEdge',
    "     'phEvalContext' {
    "           'variables'  : additional variables.
    "           'nIndAdd' : Indent of current line.
    "      }
    " }


    " To eval:
    "     spacing variables
    "     function call to embed other snippet or adjust indent
    " Not to eval:
    "     function call to print dynamic content like time
    "     dynamic variables like $_xSnipName


    let a:fctx.key = a:0 > 0 ? a:1 : a:fctx.key

    let [ ph, key ] = [ a:fctx.ph, a:fctx.key ]


    if has_key( ph, key )
          \ && type( ph[ key ] ) == type( {} )

        let flt = ph[ key ]

        if flt.text =~# a:fctx.forceNotSkip
              \ || flt.text !~# a:fctx.skip


            call s:log.Debug( 'eval ph element:' . string( flt ) . ' indent=' . string( a:fctx.phEvalContext.nIndAdd ) )

            call xpt#flt#Eval( flt,
                  \            a:fctx.snipObject.ftScope.funcs,
                  \            a:fctx.phEvalContext )


            call s:log.Log( 'filter after eval=' . string( flt ) )

            return xpt#phfilter#HandleEltFilterRst( a:fctx, flt )

        endif

    endif

    return s:GOON

endfunction "}}}

fun! xpt#phfilter#HandleEltFilterRst( fctx, flt ) "{{{

    let frst = a:flt.rst

    if frst.rc > 0

        if has_key( frst, 'action' )

            let rc = s:HandleAction( a:fctx, a:flt )
            if rc is s:DONE
                return rc
            endif

        endif


        if has_key( frst, 'text' )
            let a:fctx.ph[ a:fctx.key ] = frst.text
            return s:GOON
        else
            call XPT#info( 'Failed to pre-eval filter: ' . string( frst ) . ' filter=' . string( a:flt.text ) )
            return s:UNDONE
        endif

    endif

    " Nothing to do if a:flt.rst.rc == 0
    return s:GOON


endfunction "}}}

fun! s:HandleAction( fctx, flt ) "{{{

    " NOTE: ResetIndent action does not produce any phs.
    " TODO handle actions other than 'embed'.

    let frst = a:flt.rst

    if frst.action == 'embed'

        call extend( a:fctx.srcPHs, frst.phs, 0 )

        call s:log.Debug( 'ph removed=' . string( a:fctx.ph ) )
        call s:log.Debug( 'phs add back=' . xpt#debug#List( frst.phs ) )

    else
        " TODO handle other action

        return s:UNDONE

    endif


    return s:DONE

endfunction "}}}

fun! xpt#phfilter#ReplacePH( fctx ) "{{{
    let ph = a:fctx.ph
    let phptns = a:fctx.phptns
    let params = a:fctx.replParams
    let rst = a:fctx.rstPHs

    if type( ph ) == type( '' )
          \ || !has_key( params, ph.name )

        call xpt#phfilter#FeedPH( a:fctx )

    else

        let rep = params[ ph.name ]

        if rep =~ phptns.lft

            " Backward compatible: "{{{
            " Old fashion replacement does not need
            " the start and end mark.
            "
            " Example,
            "   { 'a' : '`edge`foo`edge^' }
            "
            " is new fashion this version of xpt uses. The same
            " replacement in old fashion is:
            "   { 'a' : 'edge`foo`edge' }
            " "}}}
            " TODO if replacement ends with normal string ph, the test will be
            "      broken!
            if rep !~ phptns.rt . '\$'
                let rep = phptns.l . rep . phptns.r
            endif


            let slaveSnip = xpt#snip#NewSlave( a:fctx.snipObject, rep )
            call xpt#snip#CompileAndParse( slaveSnip )

            " TODO should be pushed back to srcPHs
            for a:fctx.ph in slaveSnip.parsedSnip
                call xpt#phfilter#FeedPH( a:fctx )
            endfor
            let a:fctx.ph = ph


        else

            let ph.name = rep
            let ph.displayText = rep

            if ph.displayText =~ '\V' . phptns.item_var . '\|' . phptns.item_func . '\|\n'
                let filterText = xpt#util#UnescapeChar( ph.displayText, phptns.lr )

                let ph.displayText = xpt#flt#New( -a:fctx.phEvalContext.nIndAdd, filterText )
            endif

            call xpt#phfilter#FeedPH( a:fctx )

        endif

    endif

endfunction "}}}

fun! xpt#phfilter#PostQuote( fctx ) "{{{

    let ph     = a:fctx.ph
    let quoter = a:fctx.snipObject.setting.postQuoter


    if type( ph ) == type( '' )

        call xpt#phfilter#AppendRst( a:fctx, a:fctx.pqStack[ -1 ], ph )

    else

        call extend( a:fctx.pqStack[ -1 ], [ ph, '' ] )


        call s:log.Debug( 'ph=' . string( ph ) )

        if ph.name[ -len( quoter.start ) : ] ==# quoter.start

            let ph.name = ph.name[ 0 : -1 - len( quoter.start ) ]
            let ph.displayText = ph.name

            call add( a:fctx.pqStack[ -1 ], a:fctx.phEvalContext.nIndAdd )
            call add( a:fctx.pqStack, [''] )



        elseif ph.name == quoter.end

            let stack =  remove( a:fctx.pqStack, -1 )


            " remove the empty string ''
            call remove( stack, -1 )
            " remove the end quote '}}'
            call remove( stack, -1 )

            call filter( stack, 'len(v:val) > 0' )

            let nIndent = remove( a:fctx.pqStack[ -1 ], -1 )

            " the last one is empty string for concat next string ph
            let startPH = a:fctx.pqStack[ -1 ][ -2 ]


            let id = xpt#ftsc#PushPHPieces( a:fctx.snipObject.ftScope, stack )

            call s:log.Debug( 'postQuote stack pushed:' . string( stack ) )


            if startPH.name[ -1 : -1 ] == '!'
                let funcCall = 'Echo(IsChanged()?EmbedPHs(' . string( id ) . '):0)'
                let startPH.name = startPH.name[ 0 : -len( quoter.start ) ]
                let startPH.displayText = startPH.name
            else
                let funcCall = 'Echo(!IsChanged()?EmbedPHs(' . string( id ) . '):0)'
            endif


            let a:fctx.snipObject.setting.postFilters[ startPH.name ] =
                  \ xpt#flt#New( -nIndent, funcCall )


        endif

    endif

    call s:log.Debug( 'pqStack=' . string( a:fctx.pqStack ) )


endfunction "}}}


" TODO line-wise repetition
" TODO Post-quote parsing produces an repetion-like ph.
fun! xpt#phfilter#Repetition( fctx ) "{{{
    let ph = a:fctx.ph

    if type( ph ) == type( '' )

        call xpt#phfilter#AppendRst( a:fctx, a:fctx.repStack[ -1 ], ph )

    else

        call extend( a:fctx.repStack[ -1 ], [ ph, '' ] )

        if ph.name =~ s:ptnRepetition
              \ && !has_key( a:fctx.snipObject.setting.postFilters, ph.name )

            if !has_key( a:fctx.repHeads, ph.name )

                let a:fctx.repHeads[ ph.name ] = 1

                call add( a:fctx.repStack[ -1 ], a:fctx.phEvalContext.nIndAdd )
                call add( a:fctx.repStack, [''] )

            else

                call remove( a:fctx.repHeads, ph.name )

                let stack =  remove( a:fctx.repStack, -1 )

                " remove all empty string
                call filter( stack, 'len(v:val) > 0' )

                let nIndent = remove( a:fctx.repStack[ -1 ], -1 )

                " the last one is empty string for concat next string ph
                let startPH = a:fctx.repStack[ -1 ][ -2 ]


                let id = xpt#ftsc#PushPHPieces( a:fctx.snipObject.ftScope, stack )
                let funcCall = 'Echo(!IsChanged()?EmbedPHs(' . string( id ) . '):0)'

                let a:fctx.snipObject.setting.postFilters[ startPH.name ] =
                      \ xpt#flt#New( -nIndent, funcCall )
            endif

        endif

    endif

endfunction "}}}


fun! xpt#phfilter#UpdateIndent( fctx, last ) "{{{

    let evalctx = a:fctx.phEvalContext

    if a:last =~ '\V\n'

        let evalctx.nIndAdd =
              \ xpt#util#LastIndent( a:last )

        call s:log.Debug( 'indent set=' . string( evalctx.nIndAdd ) )

    endif

endfunction "}}}

fun! xpt#phfilter#AppendRst( fctx, lst, ph ) "{{{

    let evalctx = a:fctx.phEvalContext

    if a:ph =~ '\V\n'

        let lines = split( a:ph, '\V\n', 1 )
        let evalctx.pos[ 0 ] += len( lines ) - 1
        let evalctx.pos[ 1 ] = len( lines[ -1 ] )

        call s:log.Debug( 'update indent with string ph=' . string( a:ph ) )
        call s:log.Debug( 'evalctx.pos=' . string( evalctx.pos ) )

    else
        let evalctx.pos[ 1 ] += len( a:ph )
    endif

    let a:lst[ -1 ] .= a:ph

    call xpt#phfilter#UpdateIndent( a:fctx, a:lst[ -1 ] )

endfunction "}}}

fun! xpt#phfilter#FeedPH( fctx ) "{{{

    if type( a:fctx.ph ) == type( {} ) && has_key( a:fctx.ph, 'value' )
        let ph = s:MergeEltsIfAllString( a:fctx.ph )
    else
        let ph = a:fctx.ph
    endif


    if type( ph ) == type( '' )

        call xpt#phfilter#AppendRst( a:fctx, a:fctx.rstPHs, ph )

    else
        call extend( a:fctx.rstPHs, [ ph, '' ] )
    endif

endfunction "}}}


fun! s:MergeEltsIfAllString( ph ) "{{{

    if has_key( a:ph, 'value' )
          \ && type( a:ph[ 'displayText' ] ) == type( '' )
          \ && type( get( a:ph, 'leftEdge', '' ) ) == type( '' )
          \ && type( get( a:ph, 'rightEdge', '' ) ) == type( '' )

        return get( a:ph, 'leftEdge', '' )
              \ . get( a:ph, 'displayText', '' )
              \ . get( a:ph, 'rightEdge', '' )

    else

        return a:ph

    endif

endfunction "}}}

let &cpo = s:oldcpo
