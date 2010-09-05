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

exe XPT#importConst

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

fun! xpt#st#Merge( setting, fromSettings ) "{{{

    let a:setting.comeFirst += a:fromSettings.comeFirst
    let a:setting.comeLast = a:fromSettings.comeLast + a:setting.comeLast
    call xpt#st#InitItemOrderList( a:setting )

    call extend( a:setting.preValues, a:fromSettings.preValues, 'keep' )
    call extend( a:setting.defaultValues, a:fromSettings.defaultValues, 'keep' )
    call extend( a:setting.postFilters, a:fromSettings.postFilters, 'keep' )
    call extend( a:setting.variables, a:fromSettings.variables, 'keep' )

    for key in keys( a:fromSettings.mappings )

        if !has_key( a:setting.mappings, key )

            let a:setting.mappings[ key ] =
                  \ { 'saver' : xpt#msvr#New( 1 ), 'keys' : {} }

        endif

        for keystroke in keys( a:fromSettings.mappings[ key ].keys )

            let a:setting.mappings[ key ].keys[ keystroke ] = a:fromSettings.mappings[ key ].keys[ keystroke ]

            call xpt#msvr#Add( a:setting.mappings[ key ].saver, 'i', keystroke )

        endfor

    endfor

endfunction "}}}

fun! xpt#st#Parse( setting, snipObject ) "{{{
    " TODO keyword parsing should be here so that Alias can use non-keyword char

    let setting = a:setting


    let wraponly = get( setting, 'wraponly', 0 )

    let wrap = get( setting, 'wrap', wraponly )
    let wrap = wrap is 1 ? 'cursor' : wrap


    let setting.iswrap = wrap isnot 0
    let setting.wraponly = wraponly isnot 0
    let setting.wrap = wrap



    " Note: empty means nothing, "" means something that can override others
    if has_key(setting, 'rawHint')

        if setting.rawHint !~  s:regEval

            let setting.hint = xpt#util#UnescapeChar( setting.rawHint, s:nonsafe )

        else

            " TODO bad code. To make xpt#eval#Eval() be able to use snippet-related
            " variables like $_xSnipName
            let x = b:xptemplateData
            let x.renderContext.snipObject = a:snipObject

            let setting.hint = xpt#eval#Eval( setting.rawHint,
                  \ x.filetypes[ x.snipFileScope.filetype ].funcs,
                  \ { 'variables' : setting.variables } )

        endif

    endif


    call xpt#st#ParsePostQuoter( setting )


    if has_key( setting, 'extension' )
        let ext = setting.extension
        let a:snipObject.ftScope.extensionTable[ ext ] = get( a:snipObject.ftScope.extensionTable, ext, [] )
        let a:snipObject.ftScope.extensionTable[ ext ]  += [ a:snipObject.name ]
    endif

endfunction "}}}

fun! xpt#st#ParsePostQuoter( setting ) "{{{
    if !has_key( a:setting, 'postQuoter' )
          \ || type( a:setting.postQuoter ) == type( {} )
        return
    endif


    let quoters = split( a:setting.postQuoter, ',' )
    if len( quoters ) < 2
        throw 'postQuoter must be separated with ","! :' . a:setting.postQuoter
    endif

    let a:setting.postQuoter = { 'start' : quoters[0], 'end' : quoters[1] }
endfunction "}}}

fun! xpt#st#InitItemOrderList( setting ) "{{{
    " TODO move me to template creation phase

    if match( a:setting.comeLast, 'cursor' ) < 0
        call add( a:setting.comeLast, 'cursor' )
    endif

    call s:log.Debug( 'has cursor item?:' . string( a:setting.comeLast ) )
    let a:setting.comeFirst = xpt#util#RemoveDuplicate( a:setting.comeFirst )
    let a:setting.comeLast  = xpt#util#RemoveDuplicate( a:setting.comeLast )

endfunction "}}}

let &cpo = s:oldcpo
