
.code

MyProc1 proc

	mov		eax,'abcd'
	ret

MyProc1 endp

MyProc2 proc

	mov		eax,'abcd'
	invoke MyProc4
	ret

MyProc2 endp
