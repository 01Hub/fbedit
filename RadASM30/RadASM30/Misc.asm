.code

strcpy proc uses esi edi,lpDest:DWORD,lpSource:DWORD

	mov		esi,lpSource
	xor		ecx,ecx
	mov		edi,lpDest
  @@:
	mov		al,[esi+ecx]
	mov		[edi+ecx],al
	inc		ecx
	or		al,al
	jne		@b
	ret

strcpy endp

strcpyn proc uses esi edi,lpDest:DWORD,lpSource:DWORD,nLen:DWORD

	mov		esi,lpSource
	mov		edx,nLen
	dec		edx
	xor		ecx,ecx
	mov		edi,lpDest
  @@:
	.if sdword ptr ecx<edx
		mov		al,[esi+ecx]
		mov		[edi+ecx],al
		inc		ecx
		or		al,al
		jne		@b
	.else
		mov		byte ptr [edi+ecx],0
	.endif
	ret

strcpyn endp

strcat proc uses esi edi,lpDest:DWORD,lpSource:DWORD

	xor		eax,eax
	xor		ecx,ecx
	dec		eax
	mov		edi,lpDest
  @@:
	inc		eax
	cmp		[edi+eax],cl
	jne		@b
	mov		esi,lpSource
	lea		edi,[edi+eax]
  @@:
	mov		al,[esi+ecx]
	mov		[edi+ecx],al
	inc		ecx
	or		al,al
	jne		@b
	ret

strcat endp

strlen proc uses esi,lpSource:DWORD

	xor		eax,eax
	dec		eax
	mov		esi,lpSource
  @@:
	inc		eax
	cmp		byte ptr [esi+eax],0
	jne		@b
	ret

strlen endp

strcmp proc uses esi edi,lpStr1:DWORD,lpStr2:DWORD

	mov		esi,lpStr1
	mov		edi,lpStr2
	xor		ecx,ecx
	dec		ecx
  @@:
	inc		ecx
	mov		al,[esi+ecx]
	sub		al,[edi+ecx]
	jne		@f
	cmp		al,[esi+ecx]
	jne		@b
  @@:
	cbw
	cwde
	ret

strcmp endp

strcmpi proc uses esi edi,lpStr1:DWORD,lpStr2:DWORD

	mov		esi,lpStr1
	mov		edi,lpStr2
	xor		ecx,ecx
	dec		ecx
  @@:
	inc		ecx
	mov		al,[esi+ecx]
	mov		ah,[edi+ecx]
	.if al>='a' && al<='z'
		and		al,5Fh
	.endif
	.if ah>='a' && ah<='z'
		and		ah,5Fh
	.endif
	sub		al,ah
	jne		@f
	cmp		al,[esi+ecx]
	jne		@b
  @@:
	cbw
	cwde
	ret

strcmpi endp

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

BinToDec proc dwVal:DWORD,lpAscii:DWORD
	LOCAL	buffer[8]:BYTE

	mov		dword ptr buffer,'d%'
	invoke wsprintf,lpAscii,addr buffer,dwVal
	ret

    push    ebx
    push    ecx
    push    edx
    push    esi
    push    edi
	mov		eax,dwVal
	mov		edi,lpAscii
	or		eax,eax
	jns		pos
	mov		byte ptr [edi],'-'
	neg		eax
	inc		edi
  pos:      
	mov		ecx,429496730
	mov		esi,edi
  @@:
	mov		ebx,eax
	mul		ecx
	mov		eax,edx
	lea		edx,[edx*4+edx]
	add		edx,edx
	sub		ebx,edx
	add		bl,'0'
	mov		[edi],bl
	inc		edi
	or		eax,eax
	jne		@b
	mov		byte ptr [edi],al
	.while esi<edi
		dec		edi
		mov		al,[esi]
		mov		ah,[edi]
		mov		[edi],al
		mov		[esi],ah
		inc		esi
	.endw
    pop     edi
    pop     esi
    pop     edx
    pop     ecx
    pop     ebx
    ret

BinToDec endp

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
		invoke strcpy,edi,esi
		pop		eax
	.else
		mov		eax,nDefVal
	.endif
	ret

GetItemInt endp

PutItemInt proc uses esi edi,lpBuff:DWORD,nVal:DWORD

	mov		esi,lpBuff
	invoke strlen,esi
	mov		byte ptr [esi+eax],','
	invoke BinToDec,nVal,addr [esi+eax+1]
	ret

PutItemInt endp

GetItemStr proc uses esi edi,lpBuff:DWORD,lpDefVal:DWORD,lpResult

	mov		esi,lpBuff
	.if byte ptr [esi]
		mov		edi,esi
		.while byte ptr [esi] && byte ptr [esi]!=','
			inc		esi
		.endw
		inc		esi
		mov		eax,esi
		sub		eax,edi
		invoke strcpyn,lpResult,edi,eax
		invoke strcpy,edi,esi
	.else
		invoke strcpy,lpResult,lpDefVal
	.endif
	ret

GetItemStr endp

PutItemStr proc uses esi,lpBuff:DWORD,lpStr:DWORD

	mov		esi,lpBuff
	invoke strlen,esi
	mov		byte ptr [esi+eax],','
	invoke strcpy,addr [esi+eax+1],lpStr
	ret

PutItemStr endp

UpdateAll proc uses ebx esi edi,nFunction:DWORD,lParam:DWORD
	LOCAL	nInx:DWORD
	LOCAL	tci:TC_ITEM

	invoke SendMessage,ha.hTab,TCM_GETITEMCOUNT,0,0
	mov		nInx,eax
	mov		tci.imask,TCIF_PARAM
	.while nInx
		dec		nInx
		invoke SendMessage,ha.hTab,TCM_GETITEM,nInx,addr tci
		.if eax
			mov		ebx,tci.lParam
			mov		eax,nFunction
			.if eax==UAM_ISOPEN
				invoke lstrcmpi,lParam,addr [ebx].TABMEM.filename
				.if !eax
					mov		eax,[ebx].TABMEM.hwnd
					jmp		Ex
				.endif
			.elseif eax==UAM_ISOPENACTIVATE
				invoke lstrcmpi,lParam,addr [ebx].TABMEM.filename
				.if !eax
					invoke SendMessage,ha.hTab,TCM_SETCURSEL,nInx,0
					invoke TabToolActivate
					mov		eax,[ebx].TABMEM.hwnd
					jmp		Ex
				.endif
			.elseif eax==UAM_ISRESOPEN
				invoke GetWindowLong,[ebx].TABMEM.hedt,GWL_ID
				.if eax==ID_EDITRES
					mov		eax,[ebx].TABMEM.hwnd
					jmp		Ex
				.endif
			.elseif eax==UAM_SAVEALL
				invoke GetWindowLong,[ebx].TABMEM.hedt,GWL_ID
				.if eax==ID_EDITCODE
					invoke SendMessage,[ebx].TABMEM.hedt,EM_GETMODIFY,0,0
				.elseif eax==ID_EDITTEXT
					invoke SendMessage,[ebx].TABMEM.hedt,EM_GETMODIFY,0,0
				.elseif eax==ID_EDITHEX
					invoke SendMessage,[ebx].TABMEM.hedt,EM_GETMODIFY,0,0
				.elseif eax==ID_EDITRES
					invoke SendMessage,[ebx].TABMEM.hedt,PRO_GETMODIFY,0,0
				.elseif eax==ID_EDITUSER
					xor		eax,eax
				.endif
				.if eax
					.if lParam
						invoke WantToSave,[ebx].TABMEM.hwnd
						.if eax
							xor		eax,eax
							jmp		Ex
						.endif
					.else
						invoke SaveTheFile,[ebx].TABMEM.hwnd
					.endif
				.endif
			.elseif eax==UAM_CLOSEALL
				invoke GetWindowLong,[ebx].TABMEM.hedt,GWL_ID
				.if eax==ID_EDITCODE || eax==ID_EDITTEXT || eax==ID_EDITHEX
					invoke SendMessage,[ebx].TABMEM.hedt,EM_SETMODIFY,FALSE,0
				.elseif eax==ID_EDITRES
					invoke SendMessage,[ebx].TABMEM.hedt,PRO_SETMODIFY,FALSE,0
				.elseif eax==ID_EDITUSER
					xor		eax,eax
				.endif
				invoke SendMessage,[ebx].TABMEM.hwnd,WM_CLOSE,0,0
			.endif
		.endif
	.endw
	mov		eax,-1
  Ex:
	ret

UpdateAll endp

IsFileType proc uses ebx esi edi,lpFileType:DWORD,lpFileTypes:DWORD

	mov		esi,lpFileTypes
	mov		edi,lpFileType
	.while TRUE
		xor		ecx,ecx
		.while byte ptr [edi+ecx]
			mov		al,[edi+ecx]
			mov		ah,[esi+ecx]
			.if al>='a' && al<='z'
				and		al,5Fh
			.endif
			.if ah>='a' && ah<='z'
				and		ah,5Fh
			.endif
			.break .if al!=ah
			inc		ecx
		.endw
		.if !byte ptr [edi+ecx]
			mov		eax,TRUE
			jmp		Ex
		.endif
		inc		esi
		.while byte ptr [esi]!='.'
			inc		esi
		.endw
		.break .if !byte ptr [esi+1]
	.endw
	xor		eax,eax
  Ex:
	ret

IsFileType endp

