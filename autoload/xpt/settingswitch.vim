exec xpt#once#init
let s:oldcpo = &cpo
set cpo-=< cpo+=B
let s:log = xpt#debug#Logger( 'warn' )
fun! xpt#settingswitch#New()
	return { 'settings':[], 'saved':[], }
endfunction
fun! xpt#settingswitch#Add(inst,key,value)
	if a:inst.saved != []
		throw "settings are already saved and can not be added again"
	endif
	let a:inst.settings += [[a:key,a:value]]
endfunction
fun! xpt#settingswitch#AddList(inst,...)
	if a:inst.saved != []
		throw "settings are already saved and can not be added again"
	endif
	for item in a:000
		let a:inst.settings += [[item[0],item[1]]]
	endfor
endfunction
fun! xpt#settingswitch#Switch(inst)
	if a:inst.saved != []
		return
	endif
	for [key,value] in a:inst.settings
		call insert(a:inst.saved,[key,eval(key)])
		if type( value ) == type( '' )
			exe 'let ' key '=' string( value )
		elseif type(value) == type({})
			if has_key( value, 'exe' )
				exe value.exe
			endif
		endif
		unlet value
	endfor
endfunction
fun! xpt#settingswitch#Restore(inst)
	if a:inst.saved == []
		return
	endif
	for setting in a:inst.saved
		exe 'let '. setting[0] . '=' . string( setting[1] )
	endfor
	let a:inst.saved = []
endfunction
let &cpo = s:oldcpo
