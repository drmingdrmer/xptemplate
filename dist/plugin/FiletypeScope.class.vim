if exists("g:__FILETYPESCOPE_CLASS_VIM__")
    finish
endif
let g:__FILETYPESCOPE_CLASS_VIM__ = 1
com! GetSID let s:sid =  matchstr("<SID>", '\zs\d\+_\ze')
GetSID
delc GetSID
runtime plugin/xpclass.vim
let s:proto = {
            \}
fun! s:New() dict 
    let self.filetype        = ''
    let self.normalTemplates = {}
    let self.funcs           = { '$CURSOR_PH' : 'CURSOR' }
    let self.varPriority     = {}
    let self.loadedSnipFiles = {}
endfunction 
fun! s:IsSnippetLoaded( filename ) dict 
    return has_key( self.loadedSnipFiles, a:filename )
endfunction 
fun! s:SetSnippetLoaded( filename ) 
    let self.loadedSnipFiles[ a:filename ] = 1
endfunction 
fun! s:CheckAndSetSnippetLoaded( filename ) dict 
    let loaded = has_key( self.loadedSnipFiles, a:filename )
    let self.loadedSnipFiles[ a:filename ] = 1
    return loaded
endfunction 
let g:FiletypeScope = g:XPclass( s:sid, s:proto )
