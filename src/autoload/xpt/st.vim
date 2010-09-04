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


let s:log = xpt#debug#Logger( 'warn' )
let s:log = xpt#debug#Logger( 'debug' )


" TODO move more init values here, comeLast for cursor, default value for cursor
let s:proto  = {
      \    'hidden'           : 0,
      \    'variables'        : {},
      \    'preValues'        : {},
      \    'defaultValues'    : {},
      \    'mappings'         : {},
      \    'ontypeFilters'    : {},
      \    'postFilters'      : {},
      \    'replacements'     : {},
      \    'postQuoter'       : {},
      \    'comeFirst'        : [],
      \    'comeLast'         : [],
      \}


let s:protoDefault = {
      \    'preValues'        : { 'cursor' : xpt#flt#New( 0, '$CURSOR_PH' ) },
      \    'postQuoter'       : { 'start' : '{{', 'end' : '}}' },
      \ }


fun! xpt#st#New() "{{{
    return deepcopy( s:proto )
endfunction "}}}

fun! xpt#st#Extend( setting ) "{{{
    for k in [ 'preValues', 'defaultValues', 'ontypeFilters', 'postFilters' ]
        if has_key( a:setting, k )
            for val in values( a:setting[k] )
                call xpt#flt#Extend( val )
            endfor
        endif
    endfor

    if has_key( a:setting, 'mappings' )
        for phMapping in values( a:setting.mappings )
            for mapFilter in values( phMapping.keys )
                call xpt#flt#Extend( mapFilter )
            endfor
        endfor
    endif

    call extend( a:setting, deepcopy( s:proto ), 'keep' )

    for [ k, v ] in items( s:protoDefault )
        call extend( a:setting[ k ], deepcopy( v ), 'keep' )
    endfor

endfunction "}}}

fun! xpt#st#What() "{{{

endfunction "}}}

fun! xpt#st#Simplify( setting ) "{{{

    call s:log.Debug( 'To simplify: ' . string( a:setting ) )
    call filter( a:setting, '!has_key(s:proto,v:key) || v:val!=s:proto[v:key]' )

endfunction "}}}

fun! xpt#st#Merge( toSettings, fromSettings ) "{{{

    let a:toSettings.comeFirst += a:fromSettings.comeFirst
    let a:toSettings.comeLast = a:fromSettings.comeLast + a:toSettings.comeLast
    call s:InitItemOrderList( a:toSettings )

    call extend( a:toSettings.preValues, a:fromSettings.preValues, 'keep' )
    call extend( a:toSettings.defaultValues, a:fromSettings.defaultValues, 'keep' )
    call extend( a:toSettings.postFilters, a:fromSettings.postFilters, 'keep' )
    call extend( a:toSettings.variables, a:fromSettings.variables, 'keep' )

    for key in keys( a:fromSettings.mappings )

        if !has_key( a:toSettings.mappings, key )

            let a:toSettings.mappings[ key ] =
                  \ { 'saver' : xpt#msvr#New( 1 ), 'keys' : {} }

        endif

        for keystroke in keys( a:fromSettings.mappings[ key ].keys )

            let a:toSettings.mappings[ key ].keys[ keystroke ] = a:fromSettings.mappings[ key ].keys[ keystroke ]

            call xpt#msvr#Add( a:toSettings.mappings[ key ].saver, 'i', keystroke )

        endfor

    endfor

endfunction "}}}


let &cpo = s:oldcpo
