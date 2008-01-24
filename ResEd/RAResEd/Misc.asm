
.code

SetupCasetab proc uses ebx

	;Setup whole CaseTab
	xor		ebx,ebx
	.while ebx<256
		invoke IsCharAlpha,ebx
		.if eax
			invoke CharUpper,ebx
			.if eax==ebx
				invoke CharLower,ebx
			.endif
			mov		Casetab[ebx],al
		.else
			mov		Casetab[ebx],bl
		.endif
		inc		ebx
	.endw
	ret

SetupCasetab endp

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

strcmpi proc uses esi edi,lpword1:DWORD,lpword2:DWORD

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
	cmp		eax,edx
	je		@b
	movzx	edx,byte ptr Casetab[edx]
	cmp		eax,edx
	je		@b
	movzx	edx,byte ptr Casetab[edx]
	sub		eax,edx
  Found:
	ret

strcmpi endp

xGlobalAlloc proc fFlags:DWORD,nSize:DWORD

	invoke GlobalAlloc,fFlags,nSize
	.if !eax
		invoke MessageBox,hDEd,addr szMemFail,addr szAppName,MB_OK or MB_ICONERROR
		xor		eax,eax
	.endif
	ret

xGlobalAlloc endp

ResEdBinToDec proc dwVal:DWORD,lpAscii:DWORD

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

ResEdBinToDec endp

ResEdDecToBin proc lpStr:DWORD
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

ResEdDecToBin endp

HexToBin proc lpStr:DWORD

	push	esi
	xor		eax,eax
	xor		edx,edx
	mov		esi,lpStr
  @@:
	shl		eax,4
	add		eax,edx
	movzx	edx,byte ptr [esi]
	.if edx>='0' && edx<='9'
		sub		edx,'0'
		inc		esi
		jmp		@b
	.elseif  edx>='A' && edx<='F'
		sub		edx,'A'-10
		inc		esi
		jmp		@b
	.elseif  edx>='a' && edx<='f'
		sub		edx,'a'-10
		inc		esi
		jmp		@b
	.endif
	pop		esi
	ret

HexToBin endp

hexEax proc

	pushad
	mov     edi,offset strHex+7
	call    hexNibble
	call    hexNibble
	call    hexNibble
	call    hexNibble
	call    hexNibble
	call    hexNibble
	call    hexNibble
	call    hexNibble
	popad
	ret

  hexNibble:
	push    eax
	and     eax,0fh
	cmp     eax,0ah
	jb      hexNibble1
	add     eax,07h
  hexNibble1:
	add     eax,30h
	mov     [edi],al
	dec     edi
	pop     eax
	shr     eax,4
	ret
	
hexEax endp

GetStrItem proc	lpSource:DWORD,lpDest:DWORD

	push	esi
	push	edi
	mov		esi,lpSource
	mov		edi,lpDest
  @@:
	mov		al,[esi]
	cmp		al,','
	jz		@f
	or		al,al
	jz		@f
	mov		[edi],al
	inc		esi
	inc		edi
	jmp		@b
  @@:
	or		al,al
	jz		@f
	inc		esi
	mov		al,0
  @@:
	mov		[edi],al
	mov		eax,edi
	sub		eax,lpDest
	push	eax
	mov		edi,lpSource
  @@:
	mov		al,[esi]
	mov		[edi],al
	inc		esi
	inc		edi
	or		al,al
	jnz		@b
	pop		eax
	pop		edi
	pop		esi
	ret

GetStrItem endp

ResEdDo_ImageList proc phInst:HINSTANCE,pidBmp:DWORD,nSize:DWORD,nImg:DWORD,fMap:DWORD,fBack:DWORD,fFore:DWORD
	LOCAL	lhIml:DWORD
	LOCAL	cm[2]:COLORMAP

	invoke ImageList_Create,nSize,nSize,ILC_COLOR8 or ILC_MASK,nImg,0
	mov		lhIml,eax
	.if	fMap
		mov		cm.From,0FFFFFFh
		mov		eax,fBack
		mov		cm.To,eax
		mov		cm[sizeof COLORMAP].From,0h
		mov		eax,fFore
		mov		cm[sizeof COLORMAP].To,eax
		invoke CreateMappedBitmap,phInst,pidBmp,NULL,addr cm,fMap
	.else
		invoke LoadBitmap,phInst,pidBmp
	.endif
	push	eax
	invoke ImageList_AddMasked,lhIml,eax,fBack
	pop		eax
	invoke DeleteObject,eax
	mov		eax,lhIml
	ret

ResEdDo_ImageList endp

NotifyParent proc uses ebx
	LOCAL	nmhdr:NMHDR

	lea		ebx,nmhdr
	mov		eax,hRes
	mov		[ebx].NMHDR.hwndFrom,eax
	invoke GetWindowLong,hRes,GWL_ID
	push	eax
	mov		[ebx].NMHDR.idFrom,eax
	mov		[ebx].NMHDR.code,0
	invoke GetParent,hRes
	pop		edx
	invoke SendMessage,eax,WM_NOTIFY,edx,ebx
	ret

NotifyParent endp

RemoveProjectPath proc uses esi edi,lpFileName:DWORD

	mov		edi,lpFileName
	mov		esi,offset szProjectPath
	jmp		@f
  Nxt:
	inc		esi
	inc		edi
  @@:
	mov		al,[esi]
	or		al,al
	je		@f
	mov		ah,[edi]
	.if al>='a' && al<='z'
		and		al,5Fh
	.endif
	.if ah>='a' && ah<='z'
		and		ah,5Fh
	.endif
	cmp		al,ah
	je		Nxt
  @@:
	.if byte ptr [edi]=='\'
		inc		edi
	.else
		mov		edi,lpFileName
	.endif
	mov		eax,edi
	ret

RemoveProjectPath endp

SaveHexVal proc pVal:DWORD,fComma:DWORD

	push	esi
	push	edi
	mov		al,'0'
	stosb
	mov		al,'x'
	stosb
	mov		eax,pVal
	invoke hexEax
	invoke strcpy,edi,addr strHex
	pop		edi
	pop		esi
	add		edi,10
	.if fComma
		mov		al,','
		stosb
	.endif
	ret

SaveHexVal endp

SaveVal proc pVal:DWORD,fComma:DWORD
	LOCAL	buffer[16]:BYTE

	push	esi
	push	edi
	invoke ResEdBinToDec,pVal,addr buffer
	invoke strcpy,edi,addr buffer
	invoke lstrlen,addr buffer
	pop		edi
	pop		esi
	add		edi,eax
	.if fComma
		mov		al,','
		stosb
	.endif
	ret

SaveVal endp

SaveStr proc uses ecx esi edi,lpDest:DWORD,lpSrc:DWORD

	mov		esi,lpSrc
	mov		edi,lpDest
	dec		esi
	dec		edi
	mov		ecx,-1
  @@:
	inc		ecx
	inc		esi
	inc		edi
	mov		al,[esi]
	mov		[edi],al
	or		al,al
	jne		@b
	mov		eax,ecx
	ret

SaveStr endp

GetTypeMem proc uses esi,lpProMem:DWORD,nType:DWORD

	mov		esi,lpProMem
	xor		eax,eax
	mov		edx,nType
	.while [esi].PROJECT.hmem
		.if edx==[esi].PROJECT.ntype
			jmp		Ex
		.endif
		add		esi,sizeof PROJECT
	.endw
  Ex:
	mov		eax,esi
	ret

GetTypeMem endp

AddTypeMem proc uses esi,lpProMem:DWORD,nSize:DWORD,nType:DWORD
	LOCAL	hMem:DWORD

	mov		esi,lpProMem
	.while [esi].PROJECT.hmem
		add		esi,sizeof PROJECT
	.endw
	invoke xGlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,nSize
	mov     hMem,eax
	invoke GlobalLock,hMem
	mov		eax,hMem
	mov		[esi].PROJECT.hmem,eax
	mov		eax,nType
	mov		[esi].PROJECT.ntype,eax
	mov		eax,hMem
	ret

AddTypeMem endp

AddName proc uses esi edi,lpProMem:DWORD,lpName:DWORD,lpValue:DWORD

	invoke GetTypeMem,lpProMem,TPE_NAME
	mov		esi,[eax].PROJECT.hmem
	.while [esi].NAMEMEM.szname || [esi].NAMEMEM.value
		add		esi,sizeof NAMEMEM
	.endw
	invoke strcpyn,addr [esi].NAMEMEM.szname,lpName,MaxName
	mov		[esi].NAMEMEM.delete,FALSE
	mov		eax,lpValue
	.if word ptr [eax]=='x0'
		add		eax,2
		invoke HexToBin,eax
	.else
		invoke ResEdDecToBin,eax
	.endif
	mov		[esi].NAMEMEM.value,eax
	ret

AddName endp

FindName proc uses esi,lpProMem:DWORD,lpName:DWORD

	invoke GetTypeMem,lpProMem,TPE_NAME
	mov		eax,[eax].PROJECT.hmem
	.if eax
		mov		esi,eax
		.while [esi].NAMEMEM.szname || [esi].NAMEMEM.value
			.if ![esi].NAMEMEM.delete
				invoke lstrcmp,addr [esi].NAMEMEM.szname,lpName
				.if !eax
					mov		eax,esi
					jmp		Ex
				.endif
			.endif
			add		esi,sizeof NAMEMEM
		.endw
		xor		eax,eax
	.endif
  Ex:
	ret

FindName endp

ClipDataSet proc lpData:LPSTR,dwSize:dword
	LOCAL	hMem:HANDLE
	LOCAL	pMem:dword

	mov		eax,dwSize
	inc		eax
	invoke xGlobalAlloc, GHND or GMEM_DDESHARE, eax
	test	eax,eax
	je		@exit2
	mov		hMem,eax
	invoke GlobalLock,eax	;hGlob
	test	eax,eax
	je		@exit1
	mov		pMem,eax
	invoke RtlMoveMemory,eax,lpData,dwSize
	mov		eax,pMem
	add		eax,dwSize
	mov		byte ptr [eax],0
	invoke GlobalUnlock,hMem
	invoke OpenClipboard,NULL
	.if eax
		invoke EmptyClipboard
		invoke SetClipboardData,CF_TEXT,hMem
		invoke CloseClipboard
		xor		eax,eax		;0 - Ok
		jmp		@exit3
	.endif
  @exit1:
	invoke  GlobalFree, hMem
	xor     eax, eax
  @exit2:
	dec     eax          ; -1 - error
  @exit3:
	ret

ClipDataSet endp

ConvertDpiSize proc nPix:DWORD
	LOCAL	lpx:DWORD

	invoke GetDC,NULL
	push	eax
	invoke GetDeviceCaps,eax,LOGPIXELSX
	mov		lpx,eax
	pop		eax
	invoke ReleaseDC,NULL,eax
	mov		eax,nPix
	shl		eax,16
	cdq
	mov		ecx,96
	div		ecx
	mov		ecx,lpx
	mul		ecx
	shr		eax,16
	ret

ConvertDpiSize endp

StreamOutProc proc pMem:DWORD,pBuffer:DWORD,NumBytes:DWORD,pBytesWritten:DWORD

	mov		eax,NumBytes
	push	eax
	inc		eax
	mov		edx,pMem
	invoke strcpyn,[edx],pBuffer,eax
	pop		eax
	mov		edx,pMem
	add		[edx],eax
	mov		edx,pBytesWritten
	mov		[edx],eax
	mov		eax,0
	ret

StreamOutProc endp

SaveToMem proc hWin:DWORD,hMem:DWORD
	LOCAL	editstream:EDITSTREAM

	;stream the text to the memory
	lea		eax,hMem
	mov		editstream.dwCookie,eax
	mov		editstream.pfnCallback,offset StreamOutProc
	invoke SendMessage,hWin,EM_STREAMOUT,SF_TEXT,addr editstream
	ret

SaveToMem endp

