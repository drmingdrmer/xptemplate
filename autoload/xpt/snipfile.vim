exec xpt#once#init
let s:oldcpo = &cpo
set cpo-=< cpo+=B
let s:log = xpt#debug#Logger( 'warn' )
exec XPT#importConst
fun! xpt#snipfile#New(filename)
  let r = { 'filename':a:filename, 'ptn':xpt#snipfile#GenPattern( {'l':'`', 'r':'^'} ), 'priority':xpt#priority#Get('default'), 'filetype':'', 'inheritFT':0, }
  return r
endfunction
fun! xpt#snipfile#Push()
	let x = b:xptemplateData
	let x.snipFileScopeStack += [x.snipFileScope]
	unlet x.snipFileScope
endfunction
fun! xpt#snipfile#Pop()
	let x = b:xptemplateData
	if len(x.snipFileScopeStack) > 0
		let x.snipFileScope = remove(x.snipFileScopeStack,-1)
	else
		throw "snipFileScopeStack is empty"
	endif
endfunction
fun! xpt#snipfile#GenPattern(marks)
	return { 'l':a:marks.l, 'r':a:marks.r, 'lr':a:marks.l . a:marks.r, 'lft':'\V' . s:nonEscaped . a:marks.l, 'rt':'\V' . s:nonEscaped . a:marks.r, 'item_var':'\V' . '$\w\+', 'item_qvar':'\V' . '{$\w\+}', 'item_func':'\V' . '\w\+(\.\*)', 'item_qfunc':'\V' . '{\w\+(\.\*)}', 'itemContent':'\V' . '\_.\{-}', 'item':'\V' . s:nonEscaped . a:marks.l . '\%(' . '\_.\{-}' . '\)' . s:nonEscaped . a:marks.r, }
endfunction
let &cpo = s:oldcpo
