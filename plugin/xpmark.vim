if exists("g:__XPMARK_VIM__")
    finish
endif
let g:__XPMARK_VIM__ = 1


com! XPMgetSID let s:sid =  matchstr("<SID>", '\zs\d\+_\ze')
XPMgetSID
delc XPMgetSID

runtime plugin/debug.vim


" probe mark
let g:xpm_mark = 'p'
let g:xpm_mark_nextline = 'l'
let g:xpm_changenr_level = 1000
let s:insertPattern = '[i]'

" TODO 'au matchparen' causes it to update 2 or 3 times for each cursor move
" TODO sorted updating for speeding up.
" TODO for mode 'R', nothing needed to do
" TODO joining lines cause marks lost


let s:log = CreateLogger( 'debug' )
" let s:log = CreateLogger( 'warn' )



fun! XPMadd( name, pos, prefer ) "{{{
    " @param name       mark name
    "
    " @param pos        list of [ line, column ]
    "
    " @param prefer     'l' or 'r' to indicate this mark is left-prefered or
    "                   right-prefered. Typing on a left-prefered mark add text
    "                   after mark, before mark for right-prefered.
    "                   Default : 'l' left-prefered

    call s:log.Log( "add mark of name " . string( a:name ) . ' at ' . string( a:pos ) )
    let d = s:bufData()
    let prefer = a:prefer == 'l' ? 0 : 1
    let d.marks[ a:name ] = a:pos + [ len( getline( a:pos[0] ) ), prefer ]



endfunction "}}}

fun! XPMhere( name, prefer ) "{{{
    call XPMadd( a:name, [ line( "." ), col( "." ) ], a:prefer )
endfunction "}}}

fun! XPMremove( name ) "{{{
    let d = s:bufData()
    call d.removeMark( a:name )
endfunction "}}}

fun! XPMremoveMarkStartWith(prefix) 
    let d = s:bufData()
    for key in keys( d.marks )
        if key =~# '^\V' . a:prefix
            call d.removeMark( key )
        endif
    endfor
endfunction

fun! XPMflush() "{{{
    let d = s:bufData()
    let d.marks = {}
    let d.orderedMarks = []
    let d.markHistory[ changenr() ] = { 'dict' : d.marks, 'list': d.orderedMarks }
endfunction "}}}

fun! XPMgoto( name ) "{{{
    let d = s:bufData()
    if has_key( d.marks, a:name )
        let pos = d.marks[ a:name ][ : 1 ]
        call cursor( pos )
    endif
endfunction "}}}

fun! XPMpos( name ) "{{{
    let d = s:bufData()
    if has_key( d.marks, a:name )
        return d.marks[ a:name ][ : 1 ]
    endif
    return [0, 0]
endfunction "}}}

fun! XPMsetUpdateStrategy( mode ) "{{{
    " 'manual'		: no update takes unless call directly to XPMupdate()  
    " 'auto'    	: update on any movements
    " 'insertMode'	: update only when action taken in insert mode
    " 'normalMode'	: update when action taken in normal mode, just leaving
    "                     normal mode, or just entering normal mode.
    let d = s:bufData()
    if a:mode == 'manual'
        " manual mode
        let d.updateStrategy = a:mode

    elseif a:mode == 'normalMode'
        let d.updateStrategy = a:mode

    elseif a:mode == 'insertMode'
        let d.updateStrategy = a:mode

    else
        " auto mode
        let d.updateStrategy = 'auto'
    endif
endfunction "}}}

fun! XPMupdateSpecificChangedRange(start, end) " {{{
    let d = s:bufData()

    let nr = changenr()

    call s:log.Log( "update specific range" )

    if nr != d.lastChangenr
        call d.snapshot()
    endif

    call d.initCurrentStat()
    call d.updateWithNewChangeRange( a:start, a:end )
    call d.saveCurrentStat()

endfunction " }}}

fun! XPMautoUpdate(msg) "{{{
    call s:log.Log( 'XPMautoUpdate from ' . a:msg )
    if !exists( 'b:_xpmark' )
        return ''
    endif


    " TODO not complete strategy
    let d = s:bufData()
    let isInsertMode = (d.lastMode == 'i' && mode() == 'i')
    if d.updateStrategy == 'manual' 
                \ || d.updateStrategy == 'normalMode' && isInsertMode
                \ || d.updateStrategy == 'insertMode' && !isInsertMode

        " call d.saveCurrentStat()
        return ''
    endif

    return XPMupdate('auto')
endfunction "}}}

fun! XPMupdate(...) " {{{
    if !exists( 'b:_xpmark' )
        return ''
    endif

    let d = s:bufData()

    let needUpdate = d.isUpdateNeeded()

    if !needUpdate
        call d.saveCurrentCursorStat()
        return ''
    endif


    " call s:log.Log( "update Called" ) 

    call d.initCurrentStat()


    if d.lastMode =~ s:insertPattern && d.stat.mode =~ s:insertPattern
        " stays in insert mode 
        call d.insertModeUpdate()

    else
        " *) just entered insert mode or just leave insert-like mode
        " *) stays in normal mode 
        call d.normalModeUpdate()

    endif


    call d.saveCurrentStat()

    return ''
endfunction "}}}

fun! XPMupdateStat()
    call s:log.Log( " --------step--------- " )

    let d = s:bufData()

    call d.saveCurrentStat()
endfunction
fun! XPMupdateCursorStat(...) "{{{
    call s:log.Log( " --------step--------- " )

    let d = s:bufData()

    call d.saveCurrentCursorStat()

endfunction "}}}


fun! XPMallMark() "{{{
    let d = s:bufData()

    let msg = ''
    for name in sort( keys( d.marks ) )
        let msg .= name . repeat( '-', 30-len( name ) ) . " : " . substitute( string( d.marks[ name ] ), '\<\d\>', ' &', 'g' ) . "\n"
    endfor
    return msg
endfunction "}}}



fun! s:isUpdateNeeded() dict "{{{

    if empty( self.marks ) && changenr() == self.lastChangenr
        " not undo/redo action, and no mark defined
        return 0
    endif

    return 1
endfunction "}}}

fun! s:initCurrentStat() dict "{{{
    let self.stat = {
                \    'currentPosition'  : [ line( '.' ), col( '.' ) ],
                \    'totalLine'        : line( "$" ),
                \    'currentLineLength': len( getline( "." ) ),
                \    'mode'             : mode(),
                \    'positionOfMarkP'  : [ line( "'" . g:xpm_mark ), col( "'" . g:xpm_mark ) ] 
                \}
endfunction "}}}

fun! s:snapshot() dict "{{{
    call s:log.Log( "take snapshot" )
    let nr = changenr()

    call s:log.Log( 'snapshot at :' . nr )

    let n = self.lastChangenr + 1
    while n < nr
        call s:log.Info( 'to link markHistory ' . n . ' to ' .(n - 1) )
        let self.markHistory[ n ] = self.markHistory[ n - 1 ]

        " clean the old
        if has_key( self.markHistory,  n - g:xpm_changenr_level )
            unlet self.markHistory[ n - g:xpm_changenr_level ]
        endif
        let n += 1
    endwhile

    let self.marks = copy( self.marks )
    let self.orderedMarks = copy( self.orderedMarks )
    let self.markHistory[ nr ] = { 'dict' : self.marks, 'list': self.orderedMarks }


endfunction "}}}

fun! s:handleUndoRedo() dict "{{{
    " return 1 : It is undo/redo action
    "        0 : It is normal action

    let nr = changenr()

    if nr < self.lastChangenr
        " undo action "{{{

        call s:log.Log( "undo" )


        if has_key( self.markHistory, nr )
            let self.marks = self.markHistory[ nr ].dict
            let self.orderedMarks = self.markHistory[ nr ].list
        else
            call s:log.Info( 'u : no ' . nr . ' in markHistory, create new mark set' )
            let self.marks = {}
            let self.orderedMarks = []
        endif

        return 1

        "}}}

    elseif nr > self.lastChangenr && nr <= self.changenrRange[1]
        " redo action "{{{

        call s:log.Log( "redo" )

        if has_key( self.markHistory, nr )
            let self.marks = self.markHistory[ nr ].dict
            let self.orderedMarks = self.markHistory[ nr ].list
        else
            call s:log.Info( "<C-r> no " . nr . ' in markHistory, create new mark set' )
            let self.marks = {}
            let self.orderedMarks = []
        endif

        return 1

        "}}}

    else
        " not an undo/redo action 
        return 0

    endif
endfunction "}}}

fun! s:insertModeUpdate() dict "{{{

    call s:log.Log( "update Insert" )

    if self.handleUndoRedo()
        return
    endif


    let stat = self.stat

    if changenr() != self.lastChangenr
        call self.snapshot()
    endif

    let lastPos = self.lastPositionAndLength[ : 1 ]
    let bLastPos = [ self.lastPositionAndLength[0] + stat.totalLine - self.lastTotalLine, 0 ]
    let bLastPos[1] = self.lastPositionAndLength[1] - self.lastPositionAndLength[2] + len( getline( bLastPos[0] ) )

    call s:log.Log( 'lastPos=' . string( lastPos ) )
    call s:log.Log( 'bLastPos=' . string( bLastPos ) )

    " TODO deal with <C-j>, <C-k>
    if bLastPos[0] * 10000 + bLastPos[1] >= lastPos[0] * 10000 + lastPos[1]

        " content added 
        call s:log.Log( "content added" )
        call self.updateWithNewChangeRange( self.lastPositionAndLength[ :1 ], stat.currentPosition )

    else
        " deletion 
        " TODO check if current position is really before last position
        call s:log.Log( "content removed" )
        call self.updateWithNewChangeRange( stat.currentPosition, stat.currentPosition )


    endif


endfunction "}}}

fun! s:normalModeUpdate() dict "{{{
    let stat = self.stat

    let nr = changenr()

    if nr == self.lastChangenr
        " no change was taken to buffer 
        return
    endif


    call s:log.Log( "update Normal" )


    if self.handleUndoRedo()
        return
    endif

    let cs = [ line( "'[" ), col( "'[" ) ]
    let ce = [ line( "']" ), col( "']" ) ]



    " normal action

    call self.snapshot()


    let diffOfLine = stat.totalLine - self.lastTotalLine

    " NOTE: when just enter insert mode, change-range is not valid
    if stat.mode =~ s:insertPattern
        " just entered insert mode "{{{
        " Maybe 'o' or 'O' command

        call s:log.Log( 'just insert mark p=' . string( [ line( "'p" ), col( "'p" ) ] ) )

        if diffOfLine > 0

            if self.lastPositionAndLength[0] < stat.positionOfMarkP[0]
                " 'O' 
                call self.updateMarksAfterLine( self.lastPositionAndLength[0] - 1 )

            else
                " 'o' ?  
                call self.updateMarksAfterLine( stat.currentPosition[0] - 1 )
            endif

        elseif self.lastMode =~ 's' || self.lastMode == "\<C-s>"
            " from select mode, entering something
            " NOTE: if 'a' is mapped, and 'abbb' is typed, the first typing
            " will not trigger any updates.

            call s:log.Log( "update from select mode" )
            call self.updateWithNewChangeRange([ line( "'<" ), col( "'<" ) ], stat.currentPosition)


        else
            " command 's'?
            " mark p may be deleted
            " is that a linewise deletion?
            " TODO 

            call s:log.Log( "update for 's' command or else" )
            call self.updateWithNewChangeRange(stat.currentPosition, stat.currentPosition)

        endif

        "}}}

    elseif self.lastMode =~ s:insertPattern
        " just left insert mode "{{{
        " nothing to do, everything is ok in insert mode
        " }}}

    else
        " change is taken in normal mode "{{{
        " delete, replace, paste 




        " TODO change range!!
        " The actual changed range is [cs, ce - 1]. 
        " And ce is always [ n, 1 ], that means changed range is lines
        " between cs[0] to ce[0] - 1
        "



        " Linewise deletion, '[ and '] may be wrong if 'startofline' set
        " to be 0 and the command is 'dd'.
        "
        " Only linewise deletion removes mark.

        let linewiseDeletion =  stat.positionOfMarkP[0] == 0

        call s:log.Log( "is linewise deletion :" . linewiseDeletion )

        let lineNrOfChangeEndInLastStat = ce[0] - diffOfLine

        if linewiseDeletion
            if cs == ce
                " linewise deletion "{{{

                call s:log.Log( 'linewise deletion range : ' . string( [ cs[0], lineNrOfChangeEndInLastStat ] ) )

                call self.updateForLinewiseDeletion(cs[0], lineNrOfChangeEndInLastStat)

                return
                "}}}

            else
                " replace, paste
                " same with normal changing, nothing to do
            endif

        elseif stat.positionOfMarkP[0] == line( "'" . g:xpm_mark_nextline ) 
                    \&& stat.totalLine < self.lastTotalLine
            " join single line
            " TODO join multi lines

            call s:log.Debug( 'update with line join' )

            let endPos = [ self.lastPositionAndLength[0], self.lastPositionAndLength[2] ]
            call self.updateWithNewChangeRange( endPos, endPos )

            return

        elseif cs == [1, 1] && ce == [ stat.totalLine, 1 ]
            " TODO to test if it is OK with buffer of only 1 line
            " substitute or other globally-affected command
            call s:log.Log( "substitute, remove all marks" )
            call XPMflush()
            return

        endif

        call self.updateWithNewChangeRange(cs, ce)


        "}}}

    endif


endfunction "}}}

fun! s:updateMarksAfterLine(line) dict "{{{
    let diffOfLine = self.stat.totalLine - self.lastTotalLine

    for [ n, v ] in items( self.marks )
        if v[0] > a:line
            let self.marks[ n ] = [ v[0] + diffOfLine, v[1], v[2], v[3] ]
        endif
    endfor
endfunction "}}}

fun! s:updateForLinewiseDeletion( fromLine, toLine ) dict "{{{
    for [n, mark] in items( self.marks )

        if mark[0] >= a:toLine
            let self.marks[ n ] = [ mark[0] + self.stat.totalLine - self.lastTotalLine, mark[1], mark[2], mark[3] ]

        elseif mark[0] >= a:fromLine && mark[0] < a:toLine
            call s:log.Log( 'remove mark at position:' . string( mark ) )
            call remove( self.marks, n )

        endif
    endfor
endfunction "}}}

fun! s:updateWithNewChangeRange( changeStart, changeEnd ) dict "{{{

    call s:log.Log( "parameters : " . string( [ a:changeStart, a:changeEnd ] ) )
    call s:log.Debug( 'self:' . string( self ) )

    let diffOfLine = self.stat.totalLine - self.lastTotalLine

    let bChangeEnd = [ a:changeEnd[0] - self.stat.totalLine, 
                \ a:changeEnd[1] - len( getline( a:changeEnd[0] ) ) ]

    let lineNrOfChangeEndInLastStat = a:changeEnd[0] - diffOfLine

    let lineLengthCS    = len( getline( a:changeStart[0] ) )
    let lineLengthCE    = len( getline( a:changeEnd[0] ) )

    call s:log.Log( string( a:changeEnd ), self.stat.totalLine )
    call s:log.Debug( "diffOfLine :" . diffOfLine )
    call s:log.Debug( "lineNrOfChangeEndInLastStat :" . lineNrOfChangeEndInLastStat )
    call s:log.Debug( "bChangeEnd:" . string( bChangeEnd ) )

    for [name, mark] in items( self.marks )

        let bMark = [ mark[0] - self.lastTotalLine, mark[1] - mark[2] ]

        call s:log.Debug( "mark:" . name . ' is ' . string( mark ) )
        call s:log.Debug( "bMark:" . string( bMark ) )

        if mark[0] < a:changeStart[0] 
            " before changed lines
            call s:log.Debug( "before change" )
            continue

        elseif mark[0] > lineNrOfChangeEndInLastStat
            " after changed lines
            let self.marks[ name ] = [ mark[0] + diffOfLine, mark[1], mark[2], mark[3] ]
            call s:log.Debug( 'after change:' . string( mark ) )


        elseif mark[ 0 : 1 ] == a:changeStart && bMark == bChangeEnd
            " between mark

            if mark[3] == 0
                " left mark 
                " update line length only
                let self.marks[ name ] = [ mark[0], mark[1], lineLengthCS, 0 ]
                call s:log.Debug( 'between mark, left mark' )

            else
                " right mark 

                let self.marks[ name ] = [ a:changeEnd[0], bMark[1] + lineLengthCE, lineLengthCE, 1 ]
                call s:log.Debug( 'between mark, right mark' )


            endif
            
        elseif mark[0] == a:changeStart[0] && mark[1] - 1 < a:changeStart[1]
            " change spans only right part of mark
            " update length only

            call s:log.Debug( 'span right part' )
            let self.marks[ name ] = [ mark[0], mark[1], lineLengthCS, mark[3] ]

        elseif bMark[0] == bChangeEnd[0] && bMark[1] >= bChangeEnd[1]
            " change spans only left part of mark 
            call s:log.Debug( 'span left part' )
            let self.marks[ name ] = [ a:changeEnd[0], bMark[1] + lineLengthCE, lineLengthCE, mark[3] ]

        else
            " change overides mark
            call s:log.Debug( 'override mark' )

            call self.removeMark( name )

        endif

        call s:log.Debug( "updated mark : " . (has_key( self.marks, name ) ? string( self.marks[ name ] ) : '' ) )

    endfor
endfunction "}}}


fun! s:saveCurrentCursorStat() dict "{{{

    call s:log.Debug( 'saveCurrentCursorStat' )

    let p = [ line( '.' ), col( '.' ) ]

    if p != self.lastPositionAndLength[ : 1 ]
        let self.lastPositionAndLength = p + [ len( getline( "." ) ) ]

        " NOTE: weird, 'normal! ***' causes exception in select mode. but 'k'
        " command is ok

        " if mode() ==? 's' || mode() == "\<C-s>" 
            exe 'k'.g:xpm_mark
            if p[0] < line( '$' )
                exe '+1k' . g:xpm_mark_nextline
            else
                exe 'delmarks ' . g:xpm_mark_nextline
            endif

        " else 
            " exe 'silent! normal! m' . g:xpm_mark
        " endif 

        " call s:log.Log( 'updated lastPositionAndLength:' . string(self.lastPositionAndLength) )
    endif

    let self.lastMode = mode()

endfunction "}}}

" TODO rename me
fun! s:saveCurrentStat() dict " {{{

    call self.saveCurrentCursorStat()

    let self.lastChangenr = changenr()

    let self.changenrRange[0] =  min( [ self.lastChangenr, self.changenrRange[0] ] )
    let self.changenrRange[1] =  max( [ self.lastChangenr, self.changenrRange[1] ] )

    let self.lastTotalLine = line( "$" )

endfunction " }}}

" TODO call back
fun! s:removeMark(name) dict "{{{
    call s:log.Log( "removed mark:" . a:name )
    call filter( self.orderedMarks, 'v:val != ' . string( a:name ) )
    call remove( self.marks, a:name )
endfunction "}}}

let s:prototype = {}
fun! s:Member(name) "{{{
    let s:prototype[ a:name ] = function( '<SNR>' . s:sid . a:name )
endfunction "}}}

call s:Member( 'isUpdateNeeded' )
call s:Member( 'initCurrentStat' )
call s:Member( 'snapshot' )
call s:Member( 'handleUndoRedo' )
call s:Member( 'insertModeUpdate' )
call s:Member( 'normalModeUpdate' )
call s:Member( 'saveCurrentStat' )
call s:Member( 'saveCurrentCursorStat' )
call s:Member( 'updateMarksAfterLine' )
call s:Member( 'updateForLinewiseDeletion' )
call s:Member( 'updateWithNewChangeRange' )
call s:Member( 'removeMark' )

fun! s:initBufData() "{{{
    let nr = changenr()
    let b:_xpmark = { 
                \ 'updateStrategy'       : 'auto', 
                \ 'stat'                 : {},
                \ 'orderedMarks'         : [],
                \ 'marks'                : {},
                \ 'markHistory'          : {}, 
                \ 'lastMode'             : 'n',
                \ 'lastPositionAndLength': [ line( '.' ), col( '.' ), len( getline( '.' ) ) ],
                \ 'lastTotalLine'        : line( '$' ),
                \ 'lastChangenr'         : nr,
                \ 'changenrRange'        : [nr, nr], 
                \ }

    let b:_xpmark.markHistory[ nr ] = { 'dict' : b:_xpmark.marks, 'list' : b:_xpmark.orderedMarks }



    call extend( b:_xpmark, s:prototype, 'force' )

    exe 'k' . g:xpm_mark
    if line( '.' ) < line( '$' )
        exe '+1k' . g:xpm_mark_nextline
    else
        exe 'delmarks ' . g:xpm_mark_nextline
    endif
endfunction "}}}

fun! s:bufData() "{{{
    if !exists('b:_xpmark')
        call s:initBufData()
    endif

    return b:_xpmark
endfunction "}}}


fun! PrintDebug()
    let d = s:bufData()

    let debugString  = changenr()
    let debugString .= ' p:' . string( getpos( "'" . g:xpm_mark )[ 1 : 2 ] )
    let debugString .= ' ' . string( [[ line( "'[" ), col( "'[" ) ], [ line( "']" ), col( "']" ) ]] ) . " "
    let debugString .= " " . mode() . string( [line( "." ), col( "." )] ) . ' last:' .string( d.lastPositionAndLength )

    return substitute( debugString, '\s', '' , 'g' )
endfunction



let s:count = 0
fun! Count()
    let s:count += 1
    let symbol = '|/-\'
    return ' ' . repeat( symbol[ s:count % 4 ], 4 ) . ' ' . s:count . ' '
endfunction


" set statusline=%#DiffText#%{Count()}%0*
" set statusline+=%{XPMautoUpdate('..')}
" set statusline+=%{PrintDebug()}
" set ruf=%{PrintDebug()}
" set statusline=


nnoremap ,m :call XPMhere('c')<cr>
nnoremap ,M :call XPMhere('c','r')<cr>
nnoremap ,g :call XPMgoto('c')<cr>




if &ruler && &rulerformat == ""
    " ruler set but rulerformat is set to be default 
    set rulerformat=%17(%<%f\ %h%m%r%=%-14.(%l,%c%V%)\ %P%)

elseif !&ruler
    " if no ruler set, display none 
    set rulerformat=

endif

" Always enable ruler so that if statusline disabled, update can be done
" through rulerformat
set ruler

let &rulerformat .= '%{XPMautoUpdate("ruler")}'

let &statusline   = '%{PrintDebug()}' . &statusline
let &statusline  .= '%{XPMautoUpdate("statusline")}'


" test range
"
" 000000000000000000000000000000000000000
" 111111111111111111111111111111111111111
" 222222222222222222222222222222222222222
" 33333333333*333333333333333333333333333
" 444444444444444444444444444444444444444
" 555555555555555555555555555555555555555
"
"
" left-prefered:
" ----*----
" xxxx
"     xxxx
"
" right-prefered:
" ----*----
" xxxxx
"      xxx

fun! XPMtest()
    call XPreplace( [477, 10], [478, 5], '=' )
    call XPreplace( [481, 10], [481, 11], '+' )
endfunction






" vim: set sw=4 sts=4 :
