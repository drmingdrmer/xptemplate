if exists("g:__XPT_PLUGIN_HIGHLIGHT_VIM__")
    finish
endif
let g:__XPT_PLUGIN_HIGHLIGHT_VIM__ = 1



runtime plugin/xptemplate.vim

if '' == g:xptemplate_highlight 
    finish
endif

exe g:XPTsid

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

    if g:xptemplate_highlight =~ 'current'
        let r = s:MarkRange( a:ctx.leadingPlaceHolder.mark )
        call s:HL( 'XPTcurrentPH', r[2:] )
    endif

    if g:xptemplate_highlight =~ 'following'
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

        call s:HL( 'XPTnextItem', r[2:] )

    endif

    return 1

endfunction "}}}

fun! s:MarkRange( marks ) "{{{
    let pos = XPMposList( a:marks.start, a:marks.end )
    return XPTgetStaticRange( pos[0], pos[1] )
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
        match none
        2match none
        3match none
    endfunction "}}}

    fun! s:HL(grp, ptn) "{{{
        let cmd = get( s:matchingCmd, a:grp, '' )
        if '' != cmd
            exe cmd, a:grp, '/'. a:ptn . '/'
        endif
    endfunction "}}}

endif


call g:XPTaddPlugin("update", 'after', function( '<SNR>' . s:sid . "UpdateHL" ) )
call g:XPTaddPlugin("finishAll", 'after', function( '<SNR>' . s:sid . "ClearHL" ) )
