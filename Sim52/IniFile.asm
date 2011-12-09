
.const

long				QWORD 100000000000
					QWORD 10000000000
					QWORD 1000000000
					QWORD 100000000
					QWORD 10000000
					QWORD 1000000
					QWORD 100000
					QWORD 10000
					QWORD 100
					QWORD 10
					QWORD 1

.code

DecToBin proc uses ebx esi,lpStr:DWORD
	LOCAL	fNeg:DWORD

    mov     esi,lpStr
    mov		fNeg,FALSE
    mov		al,[esi]
    .if al=='-'
		inc		esi
		mov		fNeg,TRUE
    .endif
    xor     eax,eax
  @@:
    cmp     byte ptr [esi],30h
    jb      @f
    cmp     byte ptr [esi],3Ah
    jnb     @f
    mov     ebx,eax
    shl     eax,2
    add     eax,ebx
    shl     eax,1
    xor     ebx,ebx
    mov     bl,[esi]
    sub     bl,30h
    add     eax,ebx
    inc     esi
    jmp     @b
  @@:
	.if fNeg
		neg		eax
	.endif
    ret

DecToBin endp

DecToBinLong proc uses ebx esi,lpStr:DWORD

    mov     esi,lpStr
    xor     eax,eax
    xor		edx,edx
	.while byte ptr [esi]>='0' && byte ptr [esi]<='9'
		call	Mul10
		movzx	ecx,byte ptr [esi]
		and		ecx,0Fh
		add		eax,ecx
		adc		edx,0
		inc		esi
	.endw
    ret

Mul2:
	add		eax,eax
	adc		edx,edx
	retn

Mul10:
	push	edx
	push	eax
	call	Mul2
	call	Mul2
	pop		ecx
	add		eax,ecx
	pop		ecx
	adc		edx,ecx
	call	Mul2
	retn

DecToBinLong endp

BinToDec proc dwVal:DWORD,lpAscii:DWORD
	LOCAL	buffer[8]:BYTE

	mov		dword ptr buffer,'d%'
	invoke wsprintf,lpAscii,addr buffer,dwVal
	ret

BinToDec endp

BinToDecLong proc uses edi,dwValLow:DWORD,dwValHigh:DWORD,lpAscii:DWORD
	LOCAL	buffer[8]:BYTE

	xor		ecx,ecx
	mov		edi,lpAscii
	mov		eax,dword ptr dwValLow
	mov		edx,dword ptr dwValHigh
	.while ecx<10
		xor		ebx,ebx
		.while TRUE
			sub		eax,dword ptr long[ecx*8]
			sbb		edx,dword ptr long[ecx*8+4]
			.if CARRY?
				add		eax,dword ptr long[ecx*8]
				adc		edx,dword ptr long[ecx*8+4]
				.break
			.endif
		inc		ebx
		.endw
		or		ebx,30h
		mov		[edi+ecx],bl
		inc		ecx
	.endw
	mov		byte ptr [edi+ecx],0
	mov		edi,lpAscii
PrintStringByAddr edi
	ret

BinToDecLong endp

GetItemInt proc uses esi edi,lpBuff:DWORD,nDefVal:DWORD

	mov		esi,lpBuff
	.if byte ptr [esi]
		mov		edi,esi
		invoke DecToBin,edi
		.while byte ptr [esi] && byte ptr [esi]!=','
			inc		esi
		.endw
		.if byte ptr [esi]==','
			inc		esi
		.endif
		push	eax
		invoke lstrcpy,edi,esi
		pop		eax
	.else
		mov		eax,nDefVal
	.endif
	ret

GetItemInt endp

GetItemLongInt proc uses esi edi,lpBuff:DWORD,nDefVal:QWORD

	mov		esi,lpBuff
	.if byte ptr [esi]
		mov		edi,esi
		invoke DecToBinLong,edi
		.while byte ptr [esi] && byte ptr [esi]!=','
			inc		esi
		.endw
		.if byte ptr [esi]==','
			inc		esi
		.endif
		push	eax
		push	edx
		invoke lstrcpy,edi,esi
		pop		edx
		pop		eax
	.else
		mov		eax,dword ptr nDefVal
		mov		edx,dword ptr nDefVal+4
	.endif
	ret

GetItemLongInt endp

PutItemInt proc uses esi edi,lpBuff:DWORD,nVal:DWORD

	mov		esi,lpBuff
	invoke lstrlen,esi
	mov		byte ptr [esi+eax],','
	invoke BinToDec,nVal,addr [esi+eax+1]
	ret

PutItemInt endp

PutItemIntLong proc uses esi edi,lpBuff:DWORD,nValLow:DWORD,nValHigh:DWORD

	mov		esi,lpBuff
	invoke lstrlen,esi
	mov		byte ptr [esi+eax],','
	invoke BinToDecLong,nValLow,nValHigh,addr [esi+eax+1]
	ret

PutItemIntLong endp

GetItemStr proc uses esi edi,lpBuff:DWORD,lpDefVal:DWORD,lpResult:DWORD,ccMax:DWORD

	mov		esi,lpBuff
	.if byte ptr [esi]
		mov		edi,esi
		.while byte ptr [esi] && byte ptr [esi]!=','
			inc		esi
		.endw
		lea		eax,[esi+1]
		sub		eax,edi
		.if eax>ccMax
			mov		eax,ccMax
		.endif
		invoke lstrcpyn,lpResult,edi,eax
		.if byte ptr [esi]
			inc		esi
		.endif
		invoke lstrcpy,edi,esi
	.else
		invoke lstrcpyn,lpResult,lpDefVal,ccMax
	.endif
	ret

GetItemStr endp

PutItemStr proc uses esi,lpBuff:DWORD,lpStr:DWORD

	mov		esi,lpBuff
	invoke lstrlen,esi
	mov		byte ptr [esi+eax],','
	invoke lstrcpy,addr [esi+eax+1],lpStr
	ret

PutItemStr endp

;'"Str,Str","Str",1,2','Str',1
GetItemQuotedStr proc uses esi edi,lpBuff:DWORD,lpDefVal:DWORD,lpResult:DWORD,ccMax:DWORD

	mov		esi,lpBuff
	.if byte ptr [esi]=="'"
		mov		edi,esi
		inc		esi
		.while byte ptr [esi] && byte ptr [esi]!="'"
			inc		esi
		.endw
		.if byte ptr [esi]=="'"
			inc		esi
		.endif
		lea		eax,[esi+1]
		sub		eax,edi
		.if eax>ccMax
			mov		eax,ccMax
			lea		eax,[eax+2]
		.endif
		invoke lstrcpyn,lpResult,addr [edi+1],addr [eax-2]
		.if byte ptr [esi]
			inc		esi
		.endif
		invoke lstrcpy,edi,esi
	.elseif byte ptr [esi]
		invoke GetItemStr,lpBuff,lpDefVal,lpResult,ccMax
	.else
		invoke lstrcpyn,lpResult,lpDefVal,ccMax
	.endif
	ret

GetItemQuotedStr endp

PutItemQuotedStr proc uses esi,lpBuff:DWORD,lpStr:DWORD

	mov		esi,lpBuff
	invoke lstrlen,esi
	lea		esi,[esi+eax]
	mov		word ptr [esi],"',"
	invoke lstrcpy,addr [esi+2],lpStr
	invoke lstrlen,esi
	mov		word ptr [esi+eax],"'"
	ret

PutItemQuotedStr endp

LoadSettings proc
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	rect:RECT
	LOCAL	fMax:DWORD

	invoke GetPrivateProfileString,addr szIniConfig,addr szIniPos,NULL,addr buffer,sizeof buffer,addr szIniFile
	invoke GetItemInt,addr buffer,10
	mov		rect.left,eax
	invoke GetItemInt,addr buffer,10
	mov		rect.top,eax
	invoke GetItemInt,addr buffer,800
	mov		rect.right,eax
	invoke GetItemInt,addr buffer,600
	mov		rect.bottom,eax
	invoke GetItemInt,addr buffer,0
	mov		fMax,eax
	invoke MoveWindow,addin.hWnd,rect.left,rect.top,rect.right,rect.bottom,FALSE
	.if fMax
		invoke ShowWindow,addin.hWnd,SW_SHOWMAXIMIZED
	.else
		invoke ShowWindow,addin.hWnd,SW_SHOWNORMAL
	.endif
	invoke GetPrivateProfileString,addr szIniConfig,addr szIniClock,NULL,addr buffer,sizeof buffer,addr szIniFile
;	invoke GetItemInt,addr buffer,2500000000
;	mov		dword ptr ComputerClock,eax
;	mov		dword ptr ComputerClock+4,edx
;	invoke GetItemInt,addr buffer,24000000
;	mov		MCUClock,eax
;	invoke SetTiming
	ret

LoadSettings endp

SaveSettings proc
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	fMax:DWORD

	invoke IsZoomed,addin.hWnd
	mov		fMax,eax
	mov		eax,WinRect.left
	sub		WinRect.right,eax
	mov		eax,WinRect.top
	sub		WinRect.bottom,eax
	mov		buffer,0
	invoke PutItemInt,addr buffer,WinRect.left
	invoke PutItemInt,addr buffer,WinRect.top
	invoke PutItemInt,addr buffer,WinRect.right
	invoke PutItemInt,addr buffer,WinRect.bottom
	invoke PutItemInt,addr buffer,fMax
	invoke WritePrivateProfileString,addr szIniConfig,addr szIniPos,addr buffer[1],addr szIniFile
	mov		buffer,0
;	invoke PutItemIntLong,addr buffer,ComputerClock
	invoke PutItemInt,addr buffer,MCUClock
	invoke WritePrivateProfileString,addr szIniConfig,addr szIniClock,addr buffer[1],addr szIniFile
	ret

SaveSettings endp
