exec xpt#once#init
let s:oldcpo = &cpo
set cpo-=< cpo+=B
fun! xpt#diff#Diff(a,b)
	let [a,b] = [a:a,a:b]
	let [astart,aend,bstart,bend] = [0,len(a),0,len(b)]
	let [i,lmin] = [0,min([aend,bend])]
	while i < lmin && a[i] == b[i] | let i += 1 | endwhile
	let [astart,bstart] = [i,i]
	let m = min([aend - astart,bend - bstart])
	let i = 1
	while i <= m && a[aend-i] == b[bend-i]
		let i += 1
	endwhile
	let [aend,bend] = [aend-i+1,bend-i+1]
	if type(a) == type('')
		let [a,b] = [strpart(a,astart,aend-astart),strpart(b,bstart,bend-bstart)]
	else
		let [a,b] = [a[astart :],b[bstart :]]
		if len(a) > aend - astart
			call remove(a,aend-astart,-1)
		endif
		if len(b) > bend - bstart
			call remove(b,bend-bstart,-1)
		endif
	endif
	let [la,lb] = [len(a),len(b)]
	let matrix = []
	let i = 0
	while i < la + 1
		let s = []
		let j = 0
		while j < lb + 1
			let s += [[0,0,0]]
			let j += 1
		endwhile
		let matrix += [s]
		let i += 1
	endwhile
	let [i] = [1]
	while i < la + 1
		let matrix[i][0] = [i-1,0,0]
		let i += 1
	endwhile
	let [j] = [1]
	while j < lb + 1
		let matrix[0][j] = [0,j-1,0]
		let j += 1
	endwhile
	let [i,j] = [0,0]
	while i < la
		let j = 0
		while j < lb
			let matrix[i+1][j+1] = a[i] == b[j] ? [i,j,matrix[i][j][2] + 1] : (matrix[i][j+1][2] > matrix[i+1][j][2] ? [i,j+1,matrix[i][j+1][2]] : [i+1,j,matrix[i+1][j][2]])
			let j += 1
		endwhile
		let i += 1
	endwhile
	let lst = []
	let [i,j] = [la,lb]
	while i > 0 || j > 0
		while (i > 0 || j > 0) && matrix[i][j][0] < i && matrix[i][j][1] < j
			let [i,j] = matrix[i][j][: 1]
		endwhile
		let [ii,jj] = [i,j]
		while (ii > 0 || jj > 0) && (matrix[ii][jj][0] == ii || matrix[ii][jj][1] == jj)
			let [ii,jj] = matrix[ii][jj][: 1]
		endwhile
		let chg = [[astart+ii,astart+i],[bstart+jj,bstart+j]]
		let lst = [chg] + lst
		let [i,j] = [ii,jj]
	endwhile
	return lst
endfunction
let &cpo = s:oldcpo
