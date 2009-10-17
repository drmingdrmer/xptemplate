if exists("g:__MAPSAVER_CLASS_VIM__")
    finish
endif
let g:__MAPSAVER_CLASS_VIM__ = 1
runtime plugin/xptemplate.util.vim
runtime plugin/xpclass.vim
runtime plugin/mapstack.vim
exe g:XPTsid
fun! s:New( isLocal ) dict 
    let self.isLocal = !!a:isLocal
    let self.keys = []
    let self.saved = []
endfunction 
fun! s:Add( mode, key ) dict 
    if self.saved != []
        throw "keys are already saved and can not be added"
    endif
    let self.keys += [ [ a:mode, a:key ] ]
endfunction 
fun! s:AddList( ... ) dict 
    if a:0 > 0 && type( a:1 ) == type( [] )
        call call( self.AddList, a:1, self )
        return
    endif
    for item in a:000
        let [ mode, key ] = split( item, '^\w\zs_' )
        call self.Add( mode, key )
    endfor
endfunction 
fun! s:UnmapAll() dict 
    if self.saved == []
        throw "keys are not saved, can not unmap all"
    endif
    let localStr = self.isLocal ? '<buffer> ' : ''
    for [ mode, key ] in self.keys
        exe 'silent! ' . mode . 'unmap ' . localStr . key
    endfor
endfunction 
fun! s:Save() dict 
    if self.saved != []
        throw "keys are already saved and can not be save again"
    endif
    for [ mode, key ] in self.keys
        call insert( self.saved, g:MapPush( key, mode, self.isLocal ) )
    endfor
endfunction 
fun! s:Literalize() dict 
    if self.saved == []
        throw "keys are not saved yet, can not literalize"
    endif
    let localStr = self.isLocal ? '<buffer> ' : ''
    for [ mode, key ] in self.keys
        exe 'silent! ' . mode . 'noremap ' . localStr . key . ' ' . key
    endfor
endfunction 
fun! s:Restore() dict 
    if self.saved == []
        throw "keys are not saved yet"
    endif
    for info in self.saved
        call g:MapPop( info )
    endfor
    let self.saved = []
endfunction 
let g:MapSaver = g:XPclass( s:sid, {} )
