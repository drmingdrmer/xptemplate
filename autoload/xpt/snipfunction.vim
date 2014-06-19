if exists( "g:__AL_XPT_EVAL_y732hj43k__" ) && g:__AL_XPT_EVAL_y732hj43k__ >= XPT#ver
	finish
endif
let g:__AL_XPT_EVAL_y732hj43k__ = XPT#ver
let s:oldcpo = &cpo
set cpo-=< cpo+=B
let s:f = {}
let xpt#snipfunction#funcs = s:f
runtime! autoload/xpt/snipfuncs/*
let &cpo = s:oldcpo
