if exists("g:__XPT_PLUGIN_HIGHLIGHT_VIM__")
    finish
endif
let g:__XPT_PLUGIN_HIGHLIGHT_VIM__ = 1



runtime plugin/xptemplate.vim

if '' == g:xptemplate_highlight 
    finish
endif



if !hlID( 'XPTcurrentPH' )
    hi def link XPTcurrentPH    DiffChange
endif
if !hlID( 'XPTfollowingPH' )
    hi def link XPTfollowingPH  CursorLine
endif
if !hlID( 'XPTnextItem' )
    hi def link XPTnextItem     IncSearch
endif


fun! s:UpdateHL(x, ctx) "{{{

    if !a:ctx.processing
        return 1
    endif


    call s:ClearHL(a:x, a:ctx)

    if pumvisible()
        return 1
    endif


    if g:xptemplate_highlight =~ 'current' && a:ctx.phase == 'fillin'
        let r = s:MarkRange( a:ctx.leadingPlaceHolder.mark )
        call s:HL( 'XPTcurrentPH', r[2:] )
    endif


    if g:xptemplate_highlight =~ 'following' && a:ctx.phase == 'fillin'
        let r = ''

        for ph in a:ctx.item.placeHolders
            let r .= '\|' . s:MarkRange( ph.mark )
        endfor

        call s:HL( 'XPTfollowingPH', r[2:] )
    endif


    if g:xptemplate_highlight =~ 'next'
        let r = ''

        for item in a:ctx.itemList
            if item.keyPH != {}
                let r .= '\|' . s:MarkRange( item.keyPH.editMark )
            else
                let r .= '\|' . s:MarkRange( item.placeHolders[0].mark )
            endif
        endfor

        if a:ctx.itemList == [] || 'cursor' != item.name 
            let pos = XPMposList( a:ctx.marks.tmpl.end, a:ctx.marks.tmpl.end )
            let r .= '\|' . XPTgetStaticRange( pos[0], [ pos[1][0], pos[1][1] + 1 ] )
        endif

        call s:HL( 'XPTnextItem', r[2:] )

    endif

    return 1

endfunction "}}}

fun! s:MarkRange( marks ) "{{{
    let pos = XPMposList( a:marks.start, a:marks.end )
    " echom string( a:marks ) . '=' . string( pos )
    if pos[0] == pos[1]
        let pos[1][1] += 1
    endif
    return XPTgetStaticRange( pos[0], pos[1] )
endfunction "}}}

fun! XPTgetStaticRange(p, q) "{{{
    let tl = a:p
    let br = a:q

    if tl[0] == br[0] && tl[1] + 1 == br[0]
        return '\%' . br[0] . 'l' . '\%' . br[1] . 'c'
    endif

    let r = ''
    if tl[0] == br[0]
        let r = r . '\%' . tl[0] . 'l'
        if tl[1] > 1
            let r = r . '\%>' . (tl[1]-1) .'c'
        endif

        let r = r . '\%<' . br[1] . 'c'
    else
        if tl[0] < br[0] - 1
            let r = r . '\%>' . tl[0] .'l' . '\%<' . br[0] . 'l'
        else
            let r = r . '\%' . ( tl[0] + 1 ) .'l'
        endif
        let r = r
                    \. '\|' .'\%('.'\%'.tl[0].'l\%>'.(tl[1]-1) .'c\)'
                    \. '\|' .'\%('.'\%'.br[0].'l\%<'.(br[1]+0) .'c\)'
    endif

    let r = '\%(' . r . '\)'
    return '\V'.r

endfunction "}}}

if exists( '*matchadd' )

    fun! s:HLinit() "{{{
        if !exists( 'b:__xptHLids' )
            let b:__xptHLids = []
        endif
    endfunction "}}}

    fun! s:ClearHL(x, ctx) "{{{
        call s:HLinit()
        for id in b:__xptHLids
            try
                call matchdelete( id )
            catch /.*/
            endtry
        endfor
        let b:__xptHLids = []
    endfunction "}}}

    fun! s:HL(grp, ptn) "{{{
        call s:HLinit()
        call add( b:__xptHLids, matchadd( a:grp, a:ptn, 30 ) )
    endfunction "}}}

else

    let s:matchingCmd = {
                \'XPTcurrentPH'     : '3match', 
                \'XPTfollowingPH'   : 'match', 
                \'XPTnextItem'      : '2match', 
                \}

    fun! s:ClearHL(x, ctx) "{{{
        for cmd in values( s:matchingCmd )
            exe cmd 'none'
        endfor
    endfunction "}}}

    fun! s:HL(grp, ptn) "{{{
        let cmd = get( s:matchingCmd, a:grp, '' )
        if '' != cmd
            exe cmd a:grp '/' . a:ptn . '/'
        endif
    endfunction "}}}

endif


exe XPT#let_sid
call g:XPTaddPlugin("start", 'after', function( '<SNR>' . s:sid . "UpdateHL" ) )
call g:XPTaddPlugin("update", 'after', function( '<SNR>' . s:sid . "UpdateHL" ) )
call g:XPTaddPlugin("ph_pum", 'before', function( '<SNR>' . s:sid . "ClearHL" ) )
call g:XPTaddPlugin("finishAll", 'after', function( '<SNR>' . s:sid . "ClearHL" ) )

