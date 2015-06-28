exec xpt#once#init
let s:oldcpo = &cpo
set cpo-=< cpo+=B
let s:f = xpt#snipfunction#funcs
let s:num_keys = { "nIndent" : 1, "parseIndent" : 1, }
let s:action_names = { "build" : 1, "pum" : 1, "text" : 1, "next" : 1, "remove" : 1, "finishTemplate" : 1, }
fun! s:f.Action(...)
	let rst = {}
	for kvs in a:000
		if type(kvs) == type({})
			call extend(rst, kvs, 'force')
			continue
		endif
		for kv in split(kvs, ' ', 0)
			if has_key(s:action_names,kv)
				let rst.action = kv
			else
				let [k, v] = split(kv, '=', 1)
				if has_key(s:num_keys,k)
					let rst[k] = v + 0
				else
					let rst[k] = v
				endif
			endif
		endfor
	endfor
	return rst
endfunction
let &cpo = s:oldcpo
