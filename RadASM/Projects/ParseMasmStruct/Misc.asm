
.code

; String handling
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

; Number convert
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

; File handling
ReadTheFile proc lpFileName:DWORD,hMem:HGLOBAL
	LOCAL	hFile:HANDLE
	LOCAL	BytesRead:DWORD

	invoke CreateFile,lpFileName,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
	mov		hFile,eax
	invoke ReadFile,hFile,hMem,200*1024,addr BytesRead,NULL
	invoke CloseHandle,hFile
	ret

ReadTheFile endp

ParseStructSizeFile proc uses ebx esi edi,hMemFile:HGLOBAL,hMemSize:HGLOBAL

	mov		esi,hMemFile
	mov		edi,hMemSize
	.while byte ptr [esi]
		; Skip empty line
		.while byte ptr [esi]==0Dh || byte ptr [esi]==0Ah
			inc		esi
		.endw
		; Get name
		xor		eax,eax
		xor		ebx,ebx
		.while byte ptr [esi]!=',' && byte ptr [esi]
			mov		al,[esi]
			.if al==':'
				mov		ah,al
				xor		al,al
			.endif
			mov		[edi].STRUCTSIZE.szName[ebx],al
			inc		esi
			inc		ebx
		.endw
		; Zero terminate name / alignment
		mov		[edi].STRUCTSIZE.szName[ebx],0
		.if ah!=':'
			; No alignment
			inc		ebx
			mov		[edi].STRUCTSIZE.szName[ebx],0
		.endif
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

ParseStructSizeFile endp

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

FindPredefinedTypeSize proc uses esi,lpszType:DWORD

	; Check predefined datatypes
	mov		esi,offset predatatype
	.while [esi].PREDATATYPE.lpName
		invoke strcmpi,lpszType,[esi].PREDATATYPE.lpName
		.if !eax
			; Found predefined datatype, convert it
			invoke strcpy,lpszType,[esi].PREDATATYPE.lpConvert
			; Get size
			mov		eax,[esi].PREDATATYPE.nSize
			jmp		Ex
		.endif
		; Point to next PREDATATYPE
		lea		esi,[esi+sizeof PREDATATYPE]
	.endw
	xor		eax,eax
  Ex:
	ret

FindPredefinedTypeSize endp

; Search type lists
FindTypeSize proc uses esi,lpszType:DWORD

	; Check predefined datatypes
	invoke FindPredefinedTypeSize,lpszType
	.if eax
		; Found
		xor		edx,edx
		jmp		Ex
	.endif
	; Check types
	mov		esi,hMemTypeSize
	.while [esi].STRUCTSIZE.szName
		invoke strcmp,lpszType,addr [esi].STRUCTSIZE.szName
		.if !eax
			; Get size
			mov		eax,[esi].STRUCTSIZE.nSize
			xor		edx,edx
			jmp		Ex
		.endif
		; Point to next STRUCTSIZE
		; Name lenght
		invoke strlen,addr [esi].STRUCTSIZE.szName
		lea		esi,[esi+eax+sizeof STRUCTSIZE]
	.endw
	; Check structures
	mov		esi,hMemStructSize
	.while [esi].STRUCTSIZE.szName
		invoke strcmp,lpszType,addr [esi].STRUCTSIZE.szName
		.if !eax
			push	esi
			; Get alignment
			; Name lenght
			invoke strlen,addr [esi].STRUCTSIZE.szName
			lea		esi,[esi+eax+sizeof STRUCTSIZE]
			xor		edx,edx
			.if byte ptr [esi]
				invoke FindPredefinedTypeSize,esi
				mov		edx,eax
			.endif
			pop		esi
			; Get size
			mov		eax,[esi].STRUCTSIZE.nSize
			jmp		Ex
		.endif
		; Point to next STRUCTSIZE
		; Name lenght
		invoke strlen,addr [esi].STRUCTSIZE.szName
		push	eax
		; Alignment lenght
		invoke strlen,addr [esi+eax+1].STRUCTSIZE.szName
		pop		edx
		lea		eax,[edx+eax+1]
		lea		esi,[esi+eax+sizeof STRUCTSIZE]
	.endw
	xor		eax,eax
	xor		edx,edx
  Ex:
	ret

FindTypeSize endp

; Pre parse. Destroys comments and replace tab with space
PreParse proc uses esi,lpszStruct:DWORD

	mov		esi,lpszStruct
	.while byte ptr [esi]
		.if byte ptr [esi]==';'
			call	DestroyToEol
		.elseif byte ptr [esi]==VK_TAB
			mov		byte ptr [esi],' '
		.endif
		inc		esi
	.endw
	ret

DestroyToEol:
	.while byte ptr [esi] && byte ptr [esi]!=0Dh
		mov		byte ptr [esi],' '
		inc		esi
	.endw
	retn

PreParse endp

; Parse the structure. esi is a pointer to the structure
ParseStruct proc lpszName:DWORD,lpSize:DWORD,lpOut:DWORD,nUnion:DWORD,nAlign:DWORD
	LOCAL	szitem1[64]:BYTE
	LOCAL	szitem2[64]:BYTE
	LOCAL	szitem3[64]:BYTE
	LOCAL	szitem4[64]:BYTE
	LOCAL	szout[512]:BYTE
	LOCAL	nsize:DWORD

	mov		nsize,0
	mov		szout,0
  Nxt:
	call	SkipCrLf
	lea		ebx,szitem1
	call	GetItem
	lea		ebx,szitem2
	call	GetItem
	lea		ebx,szitem3
	call	GetItem
	lea		ebx,szitem4
	call	GetItem
	call	SkipToEol
	invoke strcmpi,addr szitem2,addr szUnion
	.if !eax
		; Main Union
		.if szitem3
			invoke FindPredefinedTypeSize,addr szitem3
		.endif
		mov		nAlign,eax
		invoke ParseStruct,NULL,addr nsize,addr szout,0,eax
		; Union name
		invoke strcat,lpOut,addr szitem1
		; Alignment
		invoke strcat,lpOut,addr szColon
		.if szitem3
			invoke strcat,lpOut,addr szitem3
		.else
			invoke strcat,lpOut,addr szBYTE
		.endif
		; Size
		invoke strcat,lpOut,addr szComma
		mov		eax,nsize
		call	AlignIt
		mov		nsize,eax
		invoke BinToDec,addr szTemp,nsize
		invoke strcat,lpOut,addr szTemp
		; Itsms
		invoke strcat,lpOut,addr szout
		mov		eax,esi
		jmp		Ex
	.else
		invoke strcmpi,addr szitem2,addr szStruct
		.if !eax
			; Main Struct
			.if szitem3
				invoke FindPredefinedTypeSize,addr szitem3
			.endif
			mov		nAlign,eax
			invoke ParseStruct,NULL,addr nsize,addr szout,0,eax
			; Struct name
			invoke strcat,lpOut,addr szitem1
			; Alignment
			.if szitem3
				invoke strcat,lpOut,addr szColon
				invoke strcat,lpOut,addr szitem3
			.endif
			; Size
			invoke strcat,lpOut,addr szComma
			mov		eax,nAlign
			call	AlignIt
			invoke BinToDec,addr szTemp,nsize
			invoke strcat,lpOut,addr szTemp
			; Itsms
			invoke strcat,lpOut,addr szout
			mov		eax,esi
			jmp		Ex
		.else
			invoke strcmpi,addr szitem1,addr szUnion
			.if !eax
				; Sub union. Sub unions can not have an alignment but will inherit parent alignment
				mov		edx,lpSize
				mov		eax,[edx]
				mov		nsize,eax
				.if !szitem2
					; Anonymus
					invoke ParseStruct,NULL,addr nsize,addr szout,1,0
				.else
					; Named
					invoke ParseStruct,addr szitem2,addr nsize,addr szout,1,0
				.endif
				invoke strcat,lpOut,addr szout
				jmp		Nxt
			.else
				invoke strcmpi,addr szitem1,addr szStruct
				.if !eax
					; Sub struct. Sub structures can not have an alignment but will inherit parent alignment
					.if !szitem2
						; Anonymus
						invoke ParseStruct,NULL,addr nsize,addr szout,0,nAlign
					.else
						; Named
						invoke ParseStruct,addr szitem2,addr nsize,addr szout,0,nAlign
					.endif
					invoke strcat,lpOut,addr szout
					jmp		Nxt
				.else
					invoke strcmpi,addr szitem1,addr szEnds
					.if !eax
						; Anonymus ends
						.if nUnion
							mov		eax,nUnion
							mov		edx,lpSize
							add		[edx],eax
						.else
							mov		eax,nsize
							mov		edx,lpSize
							add		[edx],eax
						.endif
						mov		eax,esi
						jmp		Ex
					.else
						invoke strcmpi,addr szitem2,addr szEnds
						.if !eax
							; Named ends
							.if nUnion
								mov		eax,nUnion
								mov		edx,lpSize
								add		[edx],eax
							.else
								mov		eax,nsize
								mov		edx,lpSize
								add		[edx],eax
							.endif
							mov		eax,esi
							jmp		Ex
						.elseif szitem1 && szitem2
							; Item
							invoke FindTypeSize,addr szitem2
							.if eax
								mov		ebx,eax
								invoke strcat,lpOut,addr szComma
								invoke strcat,lpOut,addr szCrLf
								.if lpszName
									invoke strcat,lpOut,lpszName
									invoke strcat,lpOut,addr szDot
								.endif
								invoke strcat,lpOut,addr szitem1
								; Array
								mov		eax,dword ptr szitem4
								and		eax,5F5F5Fh
								.if eax=='PUD'
									invoke DecToBin,addr szitem3
									.if eax
										push	eax
										invoke BinToDec,addr szTemp,eax
										invoke strcat,lpOut,addr szLPA
										invoke strcat,lpOut,addr szTemp
										invoke strcat,lpOut,addr szRPA
										pop		eax
										mul		ebx
										mov		ebx,eax
									.endif
								.endif
								invoke strcat,lpOut,addr szColon
								invoke strcat,lpOut,addr szitem2
								invoke strcat,lpOut,addr szComma
								call	AlignIt
								mov		eax,nsize
								mov		edx,lpSize
								add		eax,[edx]
								invoke BinToDec,addr szTemp,eax
								invoke strcat,lpOut,addr szTemp
								add		nsize,ebx
;								.if nUnion
;									.if eax>nUnion
;										mov		nUnion,eax
;									.endif
;								.else
;									mov		edx,lpSize
;									add		[edx],eax
;								.endif
								jmp		Nxt
							.endif
						.endif
					.endif
				.endif
			.endif
		.endif
	.endif
	inc		nErr
	xor		eax,eax
  Ex:
	ret

SkipWhiteSpace:
	.while byte ptr [esi]==VK_SPACE
		inc		esi
	.endw
	retn

SkipCrLf:
	call	SkipWhiteSpace
	.if byte ptr [esi]==VK_RETURN
		inc		esi
		.if byte ptr [esi]==0Ah
			inc		esi
			jmp		SkipCrLf
		.endif
	.endif
	retn

SkipToEol:
	.while byte ptr [esi]!=VK_RETURN && byte ptr [esi]
		inc		esi
	.endw
	retn

GetItem:
	push	ebx
	call	SkipWhiteSpace
	.while byte ptr [esi]!=VK_SPACE && byte ptr [esi]!=VK_RETURN && byte ptr [esi]
		mov		al,[esi]
		mov		[ebx],al
		inc		esi
		inc		ebx
	.endw
	mov		byte ptr [ebx],0
	pop		eax
	retn

AlignIt:
	.if nAlign
		mov		ecx,nAlign
		.if  !(ecx & 3) && !(eax & 3) && (nsize && 3)
			; DWord align
			shr		nsize,2
			inc		nsize
			shl		nsize,2
		.elseif !(ecx & 1) && !(eax & 1) && (nsize && 3)
			; Word align
			shr		nsize,1
			inc		nsize
			shl		nsize,1
		.endif
	.endif
	retn

ParseStruct endp
