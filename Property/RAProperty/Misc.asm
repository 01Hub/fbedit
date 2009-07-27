.code

;SetupCasetab proc uses ebx
;
;	;Setup whole CaseTab
;	xor		ebx,ebx
;	.while ebx<256
;		invoke IsCharAlpha,ebx
;		.if eax
;			invoke CharUpper,ebx
;			.if eax==ebx
;				invoke CharLower,ebx
;			.endif
;			mov		Casetab[ebx],al
;		.else
;			mov		Casetab[ebx],bl
;		.endif
;		inc		ebx
;	.endw
;	ret
;
;SetupCasetab endp

strlen proc lpSource:DWORD

	mov	eax,lpSource
	sub	eax,4
align 4
@@:
	add	eax, 4
	movzx	edx,word ptr [eax]
	test	dl,dl
	je	@lb1
	
	test	dh, dh
	je	@lb2
	
	movzx	edx,word ptr [eax+2]
	test	dl, dl
	je	@lb3

	test	dh, dh
	jne	@B
	
	sub	eax,lpSource
	add	eax,3
	ret

@lb3:
	sub	eax,lpSource
	add	eax,2
	ret

@lb2:
	sub	eax,lpSource
	add	eax,1
	ret

@lb1:
	sub	eax,lpSource
	ret

strlen endp

strcpy proc uses ebx,lpdest:DWORD,lpsource:DWORD

	mov		ebx,lpsource
	mov		edx,lpdest
	xor		ecx,ecx
  @@:
	mov		al,[ebx+ecx]
	mov		[edx+ecx],al
	inc		ecx
	or		al,al
	jne		@b
	ret

strcpy endp

strcpyn proc uses ebx,lpdest:DWORD,lpsource:DWORD,nmax:DWORD

	.if nmax
		mov		ebx,lpsource
		mov		edx,lpdest
		dec		nmax
		xor		ecx,ecx
	  @@:
		mov		al,[ebx+ecx]
		.if ecx==nmax
			xor		al,al
		.endif
		mov		[edx+ecx],al
		inc		ecx
		or		al,al
		jne		@b
	.endif
	ret

strcpyn endp

strcat proc uses esi edi,lpword1:DWORD,lpword2:DWORD

	mov		esi,lpword1
	mov		edi,lpword2
	invoke strlen,esi
	xor		ecx,ecx
	lea		esi,[esi+eax]
  @@:
	mov		al,[edi+ecx]
	mov		[esi+ecx],al
	inc		ecx
	or		al,al
	jne		@b
	ret

strcat endp

strcatn proc uses esi edi,lpword1:DWORD,lpword2:DWORD,nmax:DWORD

	mov		esi,lpword1
	mov		edi,lpword2
	invoke strlen,esi
	xor		ecx,ecx
	lea		esi,[esi+eax]
	dec		nmax
  @@:
	mov		al,[edi+ecx]
	.if ecx==nmax
		xor		al,al
	.endif
	mov		[esi+ecx],al
	inc		ecx
	or		al,al
	jne		@b
	ret

strcatn endp

strcmp proc uses esi edi,lpword1:DWORD,lpword2:DWORD

	mov		esi,lpword1
	mov		edi,lpword2
	xor		ecx,ecx
	dec		ecx
	mov		eax,ecx
	mov		edx,ecx
  @@:
	or		eax,edx
	je		Found
	inc		ecx
	movzx	eax,byte ptr [esi+ecx]
	movzx	edx,byte ptr [edi+ecx]
	sub		eax,edx
	je		@b
  Found:
	ret

strcmp endp

;strcmpi proc uses esi edi,lpword1:DWORD,lpword2:DWORD
;
;	mov		esi,lpword1
;	mov		edi,lpword2
;	xor		ecx,ecx
;	dec		ecx
;	mov		eax,ecx
;	mov		edx,ecx
;  @@:
;	or		eax,edx
;	je		Found
;	inc		ecx
;	movzx	eax,byte ptr [esi+ecx]
;	movzx	edx,byte ptr [edi+ecx]
;	cmp		eax,edx
;	je		@b
;	movzx	edx,byte ptr Casetab[edx]
;	cmp		eax,edx
;	je		@b
;	movzx	edx,byte ptr Casetab[edx]
;	sub		eax,edx
;  Found:
;	ret
;
;strcmpi endp

strcmpin proc uses esi edi,lpStr1:DWORD,lpStr2:DWORD,nCount:DWORD

	mov		esi,lpStr1
	mov		edi,lpStr2
	xor		ecx,ecx
	dec		ecx
  @@:
	inc		ecx
	cmp		ecx,nCount
	je		@f
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

strcmpin endp

DwToAscii proc uses ebx esi edi,dwVal:DWORD,lpAscii:DWORD

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
	ret

DwToAscii endp

AsciiToDw proc lpStr:DWORD
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

AsciiToDw endp
