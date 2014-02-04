syn match xptlogStack /^\w\+:::.*/ contains=xptlogFunctionName,xptlogLevel
syn match xptlogLevel /^\w\+\ze:::/ contained
syn match xptlogFunctionName /[^:.]\+\ze\%(\.\.\|$\)/ contained contains=xptlogFunctionSID
syn match xptlogFunctionSID /<SNR>\d\+_/

hi def link xptlogStack             Statement
hi def link xptlogLevel             Label
hi def link xptlogFunctionName      Function
hi def link xptlogFunctionSID       Title
