
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

BinToDec proc lpszDec:DWORD,nVal:DWORD
	
	invoke wsprintf,lpszDec,addr szFmtDec,nVal
	ret

BinToDec endp

ReadTheFile proc lpFileName:DWORD,hMem:HGLOBAL
	LOCAL	hFile:HANDLE
	LOCAL	BytesRead:DWORD

	invoke CreateFile,lpFileName,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
	mov		hFile,eax
	invoke ReadFile,hFile,hMem,200*1024,addr BytesRead,NULL
	invoke CloseHandle,hFile
	ret

ReadTheFile endp

ParseSizeFile proc uses ebx esi edi,hMemFile:HGLOBAL,hMemSize:HGLOBAL

	mov		esi,hMemFile
	mov		edi,hMemSize
	.while byte ptr [esi]
		; Skip empty line
		.while byte ptr [esi]==0Dh || byte ptr [esi]==0Ah
			inc		esi
		.endw
		; Get name
		xor		ebx,ebx
		.while byte ptr [esi]!=',' && byte ptr [esi]
			mov		al,[esi]
			mov		[edi].STRUCTSIZE.szName[ebx],al
			inc		esi
			inc		ebx
		.endw
		; Zero terminate name
		mov		[edi].STRUCTSIZE.szName[ebx],0
		; Get size
		inc		esi
		invoke DecToBin,esi
		mov		[edi].STRUCTSIZE.nSize,eax
		; Move to next line
		.while byte ptr [esi-1]!=0Ah && byte ptr [esi]
			inc		esi
		.endw
		; Pont to next STRUCTSIZE
		lea		edi,[edi+ebx+sizeof STRUCTSIZE]
	.endw
	ret

ParseSizeFile endp

FindTypeSize proc uses esi,lpszType:DWORD

	; Check predefined datatypes
	mov		esi,offset predatatype
	.while [esi].PREDATATYPE.lpName
		invoke lstrcmpi,lpszType,[esi].PREDATATYPE.lpName
		.if !eax
			; Found predefined datatype, convert it
			invoke lstrcpy,lpszType,[esi].PREDATATYPE.lpConvert
			; Get size
			mov		eax,[esi].PREDATATYPE.nSize
			jmp		Ex
		.endif
		; Point to next PREDATATYPE
		lea		esi,[esi+sizeof PREDATATYPE]
	.endw
	; Check structures
	mov		esi,hMemStructSize
	.while [esi].STRUCTSIZE.szName
		invoke lstrcmp,lpszType,addr [esi].STRUCTSIZE.szName
		.if !eax
			; Get size
			mov		eax,[esi].STRUCTSIZE.nSize
			jmp		Ex
		.endif
		; Point to next STRUCTSIZE
		invoke lstrlen,addr [esi].STRUCTSIZE.szName
		lea		esi,[esi+eax+sizeof STRUCTSIZE]
	.endw
	xor		eax,eax
  Ex:
	ret

FindTypeSize endp

ParseStruct proc lpszName:DWORD,nUnion:DWORD,lpSize:DWORD,lpOut:DWORD
	LOCAL	szitem1[64]:BYTE
	LOCAL	szitem2[64]:BYTE
	LOCAL	szitem3[64]:BYTE
	LOCAL	szitem4[64]:BYTE
	LOCAL	szout[512]:BYTE
	LOCAL	nsize:DWORD

  Nxt:
	lea		ebx,szitem1
	call	GetItem
	lea		ebx,szitem2
	call	GetItem
	lea		ebx,szitem3
	call	GetItem
	lea		ebx,szitem4
	call	GetItem
	call	SkipCrLf
	invoke lstrcmpi,addr szitem1,addr szUnion
	.if !eax
		; Sub union
		mov		szout,0
		mov		edx,lpSize
		mov		eax,[edx]
		mov		nsize,eax
		.if !szitem2
			invoke ParseStruct,NULL,1,addr nsize,addr szout
		.else
			invoke ParseStruct,addr szitem2,1,addr nsize,addr szout
		.endif
		mov		eax,nsize
		mov		edx,lpSize
		mov		[edx],eax
		invoke lstrcat,lpOut,addr szout
		jmp		Nxt
	.else
		invoke lstrcmpi,addr szitem1,addr szStruct
		.if !eax
			; Sub struct
			mov		szout,0
			mov		edx,lpSize
			mov		eax,[edx]
			mov		nsize,eax
			.if !szitem2
				; Anonymus
				invoke ParseStruct,NULL,FALSE,addr nsize,addr szout
			.else
				; Named
				invoke ParseStruct,addr szitem2,FALSE,addr nsize,addr szout
			.endif
			mov		eax,nsize
			mov		edx,lpSize
			mov		[edx],eax
			invoke lstrcat,lpOut,addr szout
			jmp		Nxt
		.else
			invoke lstrcmpi,addr szitem2,addr szUnion
			.if !eax
				; Main Union
				mov		szout,0
				mov		nsize,0
				invoke ParseStruct,NULL,FALSE,addr nsize,addr szout
				invoke lstrcat,lpOut,addr szitem1
				invoke lstrcat,lpOut,addr szComma
				invoke BinToDec,addr szitem4,nsize
				invoke lstrcat,lpOut,addr szitem4
				invoke lstrcat,lpOut,addr szout
			.else
				invoke lstrcmpi,addr szitem2,addr szStruct
				.if !eax
					; Main Struct
					mov		szout,0
					mov		nsize,0
					invoke ParseStruct,NULL,FALSE,addr nsize,addr szout
					invoke lstrcat,lpOut,addr szitem1
					invoke lstrcat,lpOut,addr szComma
					invoke BinToDec,addr szitem4,nsize
					invoke lstrcat,lpOut,addr szitem4
					invoke lstrcat,lpOut,addr szout
				.else
					invoke lstrcmpi,addr szitem1,addr szEnds
					.if !eax
						; Anonymus ends
						.if nUnion
							mov		eax,nUnion
							mov		edx,lpSize
							add		[edx],eax
						.endif
						jmp		Ex
					.else
						invoke lstrcmpi,addr szitem2,addr szEnds
						.if !eax
							; Named ends
							.if nUnion
								mov		eax,nUnion
								mov		edx,lpSize
								add		[edx],eax
							.endif
							jmp		Ex
						.else
							; Item
							invoke lstrcat,lpOut,addr szComma
							invoke lstrcat,lpOut,addr szCrLf
							.if lpszName
								invoke lstrcat,lpOut,lpszName
								invoke lstrcat,lpOut,addr szDot
							.endif
							invoke lstrcat,lpOut,addr szitem1
							invoke lstrcat,lpOut,addr szColon
							invoke lstrcat,lpOut,addr szitem2
							invoke lstrcat,lpOut,addr szComma
							mov		edx,lpSize
							mov		eax,[edx]
							invoke BinToDec,addr szitem4,eax
							invoke lstrcat,lpOut,addr szitem4
							invoke FindTypeSize,addr szitem2
							.if nUnion
								.if eax>nUnion
									mov		nUnion,eax
								.endif
							.else
								mov		edx,lpSize
								add		[edx],eax
							.endif
							jmp		Nxt
						.endif
					.endif
				.endif
			.endif
		.endif
	.endif
	xor		eax,eax
  Ex:
	ret

SkipCrLf:
	.while byte ptr [esi]==VK_RETURN || byte ptr [esi]==0Ah
		inc		esi
	.endw
	retn

SkipWhiteSpace:
	.while byte ptr [esi]==VK_TAB || byte ptr [esi]==VK_SPACE
		inc		esi
	.endw
	retn

GetItem:
	push	ebx
	call	SkipWhiteSpace
	.while byte ptr [esi]!=VK_SPACE && byte ptr [esi]!=VK_TAB && byte ptr [esi]!=VK_RETURN && byte ptr [esi]
		mov		al,[esi]
		mov		[ebx],al
		inc		esi
		inc		ebx
	.endw
	mov		byte ptr [ebx],0
	pop		eax
	retn

ParseStruct endp
