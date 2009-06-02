
.code

MyProc1 proc uses esi

	mov		eax,'abcd'
	ret

MyProc1 endp

MyProc2 proc uses esi

	mov		eax,'abcd'
	invoke MyProc4
	ret

MyProc2 endp
