if exists("g:__ALL_VIM__") && g:__ALL_VIM__ >= XPT#ver
    finish
endif
let g:__ALL_VIM__ = XPT#ver



fun! xpt#clz#all#Load() "{{{
endfunction "}}}

runtime autoload/xpt/clz/FiletypeScope.vim
runtime autoload/xpt/clz/FilterValue.vim
runtime autoload/xpt/clz/MapSaver.vim
runtime autoload/xpt/clz/RenderContext.vim
runtime autoload/xpt/clz/SettingSwitch.vim
runtime autoload/xpt/clz/SnippetScope.vim
