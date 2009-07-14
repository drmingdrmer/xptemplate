let s:path = expand("%:p:h")
let s:files = globpath(s:path, "**/*.vim")

echo simplify(s:path.'/..')
finish

let s:ftp = globpath(simplify(s:path.'/../xptftplugins'), "**/*.vim")

let s:fs = split(s:files) + split(s:ftp)
let s:fs = s:fs + split(globpath(s:path, "doc/xptemplate.txt"))

let pre = expand("")
let i = 0
while i < len(s:fs)

  let s:fs[i] = 
  

  let i += 1
endwhile

call writefile(s:fs, s:path."/xpt.files.txt")

quit
