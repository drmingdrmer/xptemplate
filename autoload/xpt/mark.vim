exec xpt#once#init
let s:oldcpo = &cpo
set cpo-=< cpo+=B
fun! xpt#mark#InitBuf()
	if ! exists('b:_xpt_snapshot')
		let b:_xpt_snapshot = {'lines': getline(1, "$"), 'marks': []}
	endif
	return b:_xpt_snapshot
endfunction
fun! xpt#mark#Add(positions,opt)
	let snp = xpt#mark#InitBuf()
	let snp.marks += a:positions
endfunction
fun! xpt#mark#Update()
	let snp = xpt#mark#InitBuf()
	let lines_b = getline(1, "$")
	let marks = snp.marks
	let marks = xpt#mark#UpdateMarks(snp.lines,lines_b,marks)
	let snp.lines = lines_b
	let snp.marks = marks
	return marks
endfunction
fun! xpt#mark#UpdateMarks(lines_a,lines_b,marks)
	let n_lines_a = len(a:lines_a)
	let marks = a:marks[:]
	call filter(marks, 'v:val[0]<n_lines_a')
	call map(marks, 'v:val[:]')
	let changes = xpt#diff#Diff(a:lines_a,a:lines_b)
	let [i,j,li,lj,line_offset] = [0,0,len(marks),len(changes),0]
	while i < li && j < lj
		let [m,c] = [marks[i],changes[j]]
		let [ca,cb] = c
		let [linenr,colnr] = m
		let [cstart,cend] = ca
		if linenr < cstart || (linenr == cstart && colnr == 0)
			let m[0] += line_offset
			let i += 1
		elseif linenr >= cend
			let line_offset += (cb[1] - cb[0]) - (cend - cstart)
			let j += 1
		else
			if cb[0] == cb[1]
				let ii = i
				while ii < li && marks[ii][0] < cend
					let marks[ii] = [cstart[0] + line_offset,0]
					let ii += 1
				endwhile
			else
				let ii = i
				while ii < li && marks[ii][0] < cend
					let ii += 1
				endwhile
				let changed_marks = marks[i : ii - 1]
				call map(changed_marks, '[v:val[0]-cstart, v:val[1]]')
				let changed_2 = xpt#mark#UpdateLineChange(a:lines_a[cstart : cend-1],a:lines_b[cb[0] : cb[1] - 1],changed_marks)
				call map(changed_2, '[v:val[0]+cstart+line_offset, v:val[1]]')
				let marks = marks[: i][: -2] + changed_2 + marks[ii :]
				let i += len(changed_2)
				let li = len(marks)
			endif
		endif
	endwhile
	while i < li
		let marks[i][0] += line_offset
		let i += 1
	endwhile
	return marks
endfunction
fun! xpt#mark#UpdateLineChange(lines_a,lines_b,marks)
	let joined_offset = []
	let offset = 0
	for l in a:lines_a
		let joined_offset += [offset]
		let offset += len(l) + 1
	endfor
	let n_lines_a = len(a:lines_a)
	let marks = a:marks[:]
	call filter(marks, 'v:val[0]<n_lines_a')
	call map(marks, 'joined_offset[v:val[0]] + v:val[1]')
	let changes = xpt#diff#Diff(join(a:lines_a, "\n"), join(a:lines_b, "\n"))
	let [i,j,li,lj,offset] = [0,0,len(marks),len(changes),0]
	while i < li && j < lj
		let [m,c] = [marks[i],changes[j]]
		let [ca,cb] = c
		if m <= ca[0] || m < ca[1]
			let marks[i] = min([m,ca[0]]) + offset
			let i += 1
		else
			let offset += (cb[1] - cb[0]) - (ca[1] - ca[0])
			let j += 1
		endif
	endwhile
	while i < li
		let marks[i] += offset
		let i += 1
	endwhile
	let lb_ranges = []
	let offset = 0
	for l in a:lines_b
		let lb_ranges += [[offset,offset + len(l) + 1]]
		let offset = lb_ranges[-1][1]
	endfor
	let [i,j] = [0,0]
	let [li,lj] = [len(marks),len(lb_ranges)]
	let splitted = []
	while i < li && j < lj
		let m = marks[i]
		let [_start,_end] = lb_ranges[j]
		if m < _end
			let splitted += [[j,m - _start]]
			let i += 1
		else
			let j += 1
		endif
	endwhile
	return splitted
endfunction
let &cpo = s:oldcpo
