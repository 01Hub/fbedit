
.code

DecToBin proc lpStr:DWORD
	LOCAL	fNeg:DWORD

    push    ebx
    push    esi
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
    pop     esi
    pop     ebx
    ret

DecToBin endp

PutString proc lpString:DWORD

	invoke SendMessage,hOut,EM_REPLACESEL,FALSE,lpString
	invoke SendMessage,hOut,EM_REPLACESEL,FALSE,addr szCRLF
	invoke SendMessage,hOut,EM_SCROLLCARET,0,0
	ret

PutString endp

HexByte proc

	mov		ah,al
	shr		al,4
	and		ah,0Fh
	.if al<=9
		add		al,30h
	.else
		add		al,41h-0Ah
	.endif
	.if ah<=9
		add		ah,30h
	.else
		add		ah,41h-0Ah
	.endif
	ret

HexByte endp

HexDWORD proc uses ebx edi,lpBuff:DWORD,Val:DWORD

	mov		edi,lpBuff
	mov		ebx,Val
	xor		ecx,ecx
	.while ecx<4
		rol		ebx,8
		mov		eax,ebx
		invoke HexByte
		mov		[edi],ax
		inc		edi
		inc		edi
		inc		ecx
	.endw
	mov		byte ptr [edi],0
	ret

HexDWORD endp

DumpLine proc uses ebx esi edi,nAdr:DWORD,lpDumpData:DWORD,nBytes:DWORD
	LOCAL	buffer[256]:BYTE

	mov		ebx,nAdr
	mov		esi,lpDumpData
	lea		edi,buffer
	xor		ecx,ecx
	.while ecx<4
		rol		ebx,8
		mov		eax,ebx
		invoke HexByte
		mov		[edi],ax
		inc		edi
		inc		edi
		inc		ecx
	.endw
	mov		byte ptr [edi],' '
	inc		edi
	xor		ecx,ecx
	.while ecx<nBytes
		mov		al,[esi+ecx]
		invoke HexByte
		mov		[edi],ax
		inc		edi
		inc		edi
		.if ecx==7
			mov		byte ptr [edi],'-'
		.else
			mov		byte ptr [edi],' '
		.endif
		inc		edi
		inc		ecx
	.endw
	mov		ecx,16
	sub		ecx,nBytes
	.while ecx
		mov		dword ptr [edi],'   '
		add		edi,3
		dec		ecx
	.endw
	xor		ecx,ecx
	.while ecx<nBytes
		mov		al,[esi+ecx]
		.if al<20h || al>=80h
			mov		al,'.'
		.endif
		mov		[edi],al
		inc		edi
		inc		ecx
	.endw
	mov		dword ptr [edi],0A0Dh
	invoke SendMessage,hOut,EM_REPLACESEL,FALSE,addr buffer
	ret

DumpLine endp

