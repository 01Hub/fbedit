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

