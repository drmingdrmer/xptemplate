exec xpt#once#init
let s:oldcpo = &cpo
set cpo-=< cpo+=B
fun! xpt#diff#Diff(a,b)
	let a = a:a
	let b = a:b
	let [astart,aend] = [0,strlen(a)]
	let [bstart,bend] = [0,strlen(b)]
	while a[astart] == b[bstart] && astart < aend && bstart < bend
		let [astart,bstart] = [astart + 1,bstart + 1]
	endwhile
	while a[aend-1] == b[bend-1] && aend > astart && bend > bstart
		let [aend,bend] = [aend - 1,bend - 1]
	endwhile
	let [a,b] = [strpart(a,astart,aend-astart),strpart(b,bstart,bend-bstart)]
	let cur = [ {'longest': 0, 'changes':{'a': [], 'b': []}} ]
	let pre_row = []
	let changes = []
	let [end_b,len] = [0,strlen(b)]
	while end_b <= len
		let pre_row += [ { 'longest' : 0, 'changes': { 'a' : [], 'b' : changes + [] } } ]
		let changes += [end_b]
		let end_b += 1
	endwhile
	let cur = pre_row
	let [end_a,len_a] = [1,strlen(a)]
	while end_a <= len_a
		let char_a = a[end_a - 1]
		let pre_b = { 'longest' : 0, 'changes' : { 'a' : pre_row[0]['changes']['a'] + [ end_a - 1 ], 'b' : [] } }
		let cur = [pre_b]
		let [end_b,len_b] = [1,strlen(b)]
		while end_b <= len_b
			let char_b = b[end_b - 1]
			if char_a == char_b
				let pre = pre_row[end_b - 1]
				let cur += [ {'longest' : pre.longest + 1, 'changes':{ 'a': pre.changes.a + [], 'b': pre.changes.b + [] } }]
			else
				let pre_a = pre_row[end_b]
				let pre = {}
				let [chg_a,chg_b] = [[],[]]
				if pre_a.longest > pre_b.longest
					let pre = pre_a
					let chg_a = [end_a - 1]
				else
					let pre = pre_b
					let chg_b = [end_b - 1]
				endif
				let cur += [ { 'longest': pre.longest, 'changes':{ 'a': pre.changes.a + chg_a, 'b':pre.changes.b + chg_b } }]
			endif
			let pre_b = cur[-1]
			let end_b += 1
		endwhile
		let pre_row = cur
		let end_a += 1
	endwhile
	let last = cur[-1]
	let ca = last.changes.a
	call map(ca, 'v:val + astart')
	let cb = last.changes.b
	call map(cb, 'v:val + bstart')
	return { 'longest':last.longest + astart + strlen(a:a) - aend, 'changes':{ 'a':ca, 'b':cb, }, }
endfunction
let &cpo = s:oldcpo
