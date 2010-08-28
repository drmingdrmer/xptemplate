" File Description {{{
" =============================================================================
" Snippet Setting which contains everything a snippet needed besides
"                                                  by drdr.xp
"                                                     drdr.xp@gmail.com
" Usage :
"
" =============================================================================
" }}}
if exists( "g:__AL_XPT_ST_VIM__" ) && g:__AL_XPT_ST_VIM__ >= XPT#ver
    finish
endif
let g:__AL_XPT_ST_VIM__ = XPT#ver


let s:oldcpo = &cpo
set cpo-=< cpo+=B

" TODO move more init values here, comeLast for cursor, default value for cursor
let s:proto  = {
      \    'hidden'           : 0,
      \    'variables'        : {},
      \    'preValues'        : { 'cursor' : xpt#flt#New( 0, '$CURSOR_PH' ) },
      \    'defaultValues'    : {},
      \    'mappings'         : {},
      \    'ontypeFilters'    : {},
      \    'postFilters'      : {},
      \    'replacements'     : {},
      \    'comeFirst'        : [],
      \    'comeLast'         : [],
      \}

let s:keyToFilter = [ 'preValues' ]


fun! xpt#st#New() "{{{
    return deepcopy( s:proto )
endfunction "}}}

fun! xpt#st#Extend( setting ) "{{{
    call extend( a:setting, deepcopy( s:proto ), 'keep' )

    for pkey in s:keyToFilter
        call extend( a:setting[ pkey ], deepcopy( s:proto[ pkey ] ), 'keep' )
    endfor

endfunction "}}}

fun! xpt#st#What() "{{{

endfunction "}}}

fun! xpt#st#Simplify( setting ) "{{{
    " -987654 is assumed to be an pseudo NONE value
    call filter( a:setting, 'v:val!=get(s:proto,v:key,-987654)' )

    for pkey in s:keyToFilter
        let pv = s:proto[ pkey ]
        if has_key( a:setting, pkey )
            call filter( a:setting[ pkey ], 'v:val!=get(pv,v:key,-987654)' )
        endif
    endfor

endfunction "}}}




let &cpo = s:oldcpo
