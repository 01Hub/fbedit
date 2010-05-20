
.data?

rseed		dd ?

.code

Random proc uses ecx edx,range:DWORD

	mov eax, rseed
	mov ecx, 23
	mul ecx
	add eax, 7
	and eax, 0FFFFFFFFh
	ror eax, 1
	xor eax, rseed
	mov rseed, eax
	mov ecx, range
	xor edx, edx
	div ecx
	mov eax, edx
	ret

Random endp

TestProc proc uses ebx esi edi,Param:DWORD
	LOCAL	nLnStart:DWORD
	LOCAL	nLnEnd:DWORD
	LOCAL	chrg:CHARRANGE

;	invoke GetTickCount
;	mov		rseed,eax
	.while ebx<100000
		invoke Random,10
		.if eax<=6
			call	Copy
			call	Paste
		.else
			call	Cut
			call	Paste
		.endif
		invoke Sleep,200
		inc		ebx
	.endw
	ret

Cut:
	invoke SendMessage,ha.hEdt,EM_GETLINECOUNT,0,0
	sub		eax,50
	invoke Random,eax
	mov		nLnStart,eax
	invoke Random,30
	inc		eax
	add		eax,nLnStart
	mov		nLnEnd,eax
	invoke SendMessage,ha.hEdt,EM_LINEINDEX,nLnStart,0
	mov		chrg.cpMin,eax
	invoke SendMessage,ha.hEdt,EM_LINEINDEX,nLnEnd,0
	mov		chrg.cpMax,eax
	invoke SendMessage,ha.hEdt,EM_EXSETSEL,0,addr chrg
	invoke SendMessage,ha.hEdt,WM_CUT,0,0
	retn

Copy:
	invoke SendMessage,ha.hEdt,EM_GETLINECOUNT,0,0
	sub		eax,50
	invoke Random,eax
	invoke Random,30
	inc		eax
	add		eax,nLnStart
	mov		nLnEnd,eax
	invoke SendMessage,ha.hEdt,EM_LINEINDEX,nLnStart,0
	mov		chrg.cpMin,eax
	invoke SendMessage,ha.hEdt,EM_LINEINDEX,nLnEnd,0
	mov		chrg.cpMax,eax
	invoke SendMessage,ha.hEdt,EM_EXSETSEL,0,addr chrg
	invoke SendMessage,ha.hEdt,WM_COPY,0,0
	retn

Paste:
	invoke SendMessage,ha.hEdt,EM_GETLINECOUNT,0,0
	dec		eax
	invoke Random,eax
	mov		nLnStart,eax
	invoke SendMessage,ha.hEdt,EM_LINEINDEX,nLnStart,0
	mov		chrg.cpMin,eax
	mov		chrg.cpMax,eax
	invoke SendMessage,ha.hEdt,EM_EXSETSEL,0,addr chrg
	invoke SendMessage,ha.hEdt,WM_PASTE,0,0
	retn

TestProc ENDP

