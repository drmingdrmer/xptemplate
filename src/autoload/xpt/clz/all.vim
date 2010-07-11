if exists("g:__ALL_VIM__") && g:__ALL_VIM__ >= XPT#ver
    finish
endif
let g:__ALL_VIM__ = XPT#ver


runtime plugin/classes/MapSaver.vim
runtime plugin/classes/SettingSwitch.vim
runtime plugin/classes/FiletypeScope.vim
runtime plugin/classes/FilterValue.vim
runtime plugin/classes/RenderContext.vim
