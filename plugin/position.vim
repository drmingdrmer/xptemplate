if exists("g:__POSITION_VIM__")
  finish
endif
let g:__POSITION_VIM__ = 1

" deprecated
finish

" Position object 
"   
" members:
"   pos : [ line, col ]
"   bPos : [ line2end, col2end ]
"
" TODO position set

" s:sid {{{
com! PluginGetSID let s:sid =  matchstr("<SID>", '\zs\d\+_\ze')
PluginGetSID
delc PluginGetSID
" }}}


let s:PosPrototype = { 'pos' : [], 'from' : [], 'to' : [], 'text' : '' }

fun! s:Pos_p( ... ) dict "{{{

  if a:0 == 0
    " get 
    return self.pos
  else
    call Log( "to set :" . string( a:1 ) )
    let self.pos = a:1
  endif

endfunction "}}}

fun! s:Pos_sync() dict "{{{
  let self.bPos = [ self.pos[ 0 ] - line( "$" ), self.pos[ 1 ] - len( getline( self.pos[0] ) ) ]
  let self.bn = self.bPos[ 0 ] * 10000 + self.bPos[ 1 ]
endfunction "}}}

fun! s:Pos_syncb() dict "{{{
  let self.pos[ 0 ] = self.bPos[ 0 ] + line( "$" )
  let self.pos[ 1 ] = self.bPos[ 1 ] + len( getline( self.pos[0] ) )
  let self.n = self.pos[ 0 ] * 10000 + self.pos[ 1 ]
endfunction "}}}

fun! s:Pos_backPos() dict "{{{
  call self.b2f()
  return copy( self.pos )
endfunction "}}}

fun! s:Pos_frontPos() dict "{{{
  return copy( self.pos )
endfunction "}}}


" changeRange : the range changes taken to buffer, which may cause some
"               position changes
"               [ from       , to            ]
"               [ [ ln, col ], [ bLn, bCol ] ]
fun! s:Pos_fix( changeRange ) "{{{
  let [ n, bn ] = [ self.n  - ( a:changeRange[ 0 ][ 0 ] * 10000 + a:changeRange[ 0 ][ 1 ] ),
        \           self.bn - ( a:changeRange[ 1 ][ 0 ] * 10000 + a:changeRange[ 1 ][ 1 ] ) ]

  if n >= 0 && bn < 0
    throw "change covers position : ".string( self )

  elseif n < 0
    " changes after me 
    call self.f2b()

  elseif bn >= 0
    " changes befroe me 
    call self.b2f()

  else
    throw "never happened:".string( self ) . ' changes:' . string( a:changeRange )
  endif

endfunction "}}}


let s:PosPrototype.p        = function( '<SNR>' . s:sid . 'Pos_p' )
let s:PosPrototype.sync     = function( '<SNR>' . s:sid . 'Pos_sync' )
let s:PosPrototype.syncb    = function( '<SNR>' . s:sid . 'Pos_syncb' )
let s:PosPrototype.backPos  = function( '<SNR>' . s:sid . 'Pos_frontPos' )
let s:PosPrototype.frontPos = function( '<SNR>' . s:sid . 'Pos_backPos' )
let s:PosPrototype.fix      = function( '<SNR>' . s:sid . 'Pos_fix' )




" 2 special position
" ====================
let XPstartPos = {}
fun! XPstartPos.p()
  return [ 1, 1 ]
endfunction

  
let XPendPos = {}
fun! XPendPos.p()
  return [ line( "$" ), col( [ "$", "$" ] ) ]
endfunction



fun! XPposNew( pos, ... ) "{{{
  let obj = deepcopy( s:PosPrototype )
  call obj.set( a:pos )

  if a:0 == 0
    " no reference position
    let obj.ref = XPstartPos
  else
    let obj.ref = a:1
  endif

  return obj
endfunction "}}}






" API of position list
" =====================

let s:positionListPrototype = { 'list' : [] }


fun! s:PL_add( pos ) dict
  let ps = self.start.p()
  let pe = self.end.p()



endfunction

" @param pos      list of two elements representing position in [ line, column ]
" @param a:1      after which element to insert, without checking relative position.
fun! s:PL_addat( pos, idx ) dict
  
endfunction

fun! s:PL_remove( pos ) dict
endfunction

fun! s:PL_checkBroken() dict
endfunction

fun! s:PL_fixb( i, p ) dict
  let next = self.end.p()
  let i = len( self.list ) - 1
  while i
    let p = self.list[ i ]

    if p.to[0] == 0
      let exp = [ next[0], next[1] + p.to[1] ]
    else
      let exp = [ next[0] + p.to[0], p.to[1] + len( getline( next[0] + p.to[0] ) ) ]
    endif

    if exp != p
      return -1
    endif

    if a:p == p
      " ok, to fix between a:p and the one before a:p

    endif

    let i -= 1
  endwhile

endfunction

fun! s:PL_fix() dict
  let prev = self.start.p()

  let i = 0
  for p in self.list
    let exp = [ prev[0] + p.from[0], prev[1] * (!p.from[0]) + p.from[1] ]

    if exp != p.pos
      " broken at before p 
      return self.fixb(i, p)
    endif

    let prev = p.pos
    let i += 1
  endfor

  " TODO fix last

  return 1
endfunction


fun! s:PL_fixChange( range ) dict
  let prev = self.start.p()
  let next = self.end.p()

  let [i, j] = [0, len(self.list) - 1]
  for p in self.list
    let exp = [ prev[0] + p.from[0],  prev[1] * (!p.from[0]) + p.from[1] ]

    if exp != p.pos
      " broken at before p 
      return self.fixb(i, p)
    endif

    let prev = p.pos
    " let i += 1
  endfor

  " TODO fix last

  return 1

endfunction



let s:positionListPrototype.add         = function( '<SNR>' . s:sid . 'PL_add' )
let s:positionListPrototype.addat       = function( '<SNR>' . s:sid . 'PL_addat' )
let s:positionListPrototype.remove      = function( '<SNR>' . s:sid . 'PL_remove' )
let s:positionListPrototype.checkBroken = function( '<SNR>' . s:sid . 'PL_checkBroken' )
let s:positionListPrototype.fix         = function( '<SNR>' . s:sid . 'PL_fix' )
let s:positionListPrototype.fixb        = function( '<SNR>' . s:sid . 'PL_fixb' )
let s:positionListPrototype.fixChange   = function( '<SNR>' . s:sid . 'PL_fixChange' )



fun! PLnew(range)
  let o = deepcopy( s:positionListPrototype )

  let [ o.start, o.end ] = a:range
  let o.list = []

  return o
endfunction

finish

" ==================
" test
" ==================

let cur = XPposNew( [ line( "." ), col( "." ) ] )

let ch = XPposNew( [ 89, 1 ] )

call cur.fix( [ ch.pos, ch.bPos ] )

echo string( cur )











