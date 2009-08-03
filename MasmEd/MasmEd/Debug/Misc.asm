GetFileIDFromProjectFileID		PROTO	:DWORD
AnyBreakPoints					PROTO

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

strcmpn proc uses esi edi,lpStr1:DWORD,lpStr2:DWORD,nCount:DWORD

	mov		esi,lpStr1
	mov		edi,lpStr2
	xor		ecx,ecx
	dec		ecx
  @@:
	inc		ecx
	cmp		ecx,nCount
	je		@f
	mov		al,[esi+ecx]
	sub		al,[edi+ecx]
	jne		@f
	cmp		al,[esi+ecx]
	jne		@b
  @@:
	cbw
	cwde
	ret

strcmpn endp

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

; Numbers
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

IsDec proc uses esi,lpStr:DWORD

	mov		esi,lpStr
	.if byte ptr [esi]=='-'
		inc		esi
	.endif
	.while TRUE
		mov		al,[esi]
		.if al>='0' && al<='9'
		.elseif !al || al==']'
			mov		eax,esi
			sub		eax,lpStr
			jmp		Ex
		.else
			.break
		.endif
		inc		esi
	.endw
	xor		eax,eax
  Ex:
	ret

IsDec endp

HexToBin proc uses esi,lpStr:DWORD

	mov		esi,lpStr
	xor		edx,edx
	.while byte ptr [esi]
		mov		al,[esi]
		.if al>='0' && al<='9'
			sub		al,'0'
		.elseif al>='A' && al<='F'
			sub		al,'A'-10
		.elseif al>='a' && al<='f'
			sub		al,'a'-10
		.else
			jmp		Ex
		.endif
		shl		edx,4
		or		dl,al
		inc		esi
	.endw
  Ex:
	mov		eax,edx
    ret

HexToBin endp

IsHex proc uses esi,lpStr:DWORD

	mov		esi,lpStr
	.while byte ptr [esi]
		mov		al,[esi]
		.if al>='0' && al<='9' || al>='A' && al<='F' || al>='a' && al<='f'
		.elseif (al=='h' || al=='H') && (!byte ptr [esi+1] || byte ptr [esi+1]==']')
			mov		eax,esi
			sub		eax,lpStr
			jmp		Ex
		.else
			.break
		.endif
		inc		esi
	.endw
	xor		eax,eax
  Ex:
	ret

IsHex endp

AnyToBin proc lpStr:DWORD

	invoke IsHex,lpStr
	.if eax
		invoke HexToBin,lpStr
		mov		edx,eax
		mov		eax,TRUE
		jmp		Ex
	.else
		invoke IsDec,lpStr
		.if eax
			invoke DecToBin,lpStr
			mov		edx,eax
			mov		eax,TRUE
			jmp		Ex
		.endif
	.endif
	xor		edx,edx
	xor		eax,eax
  Ex:
	ret

AnyToBin endp

PutString proc lpString:DWORD,fRed:DWORD
	LOCAL	chrg:CHARRANGE

	mov		chrg.cpMin,-1
	mov		chrg.cpMax,-1
	invoke SendMessage,hOut,EM_EXSETSEL,0,addr chrg
	invoke SendMessage,hOut,EM_LINELENGTH,-1,0
	.if eax
		invoke SendMessage,hOut,EM_REPLACESEL,FALSE,addr szCR
	.endif
	.if fRed
		invoke SendMessage,hOut,EM_EXGETSEL,0,addr chrg
		invoke SendMessage,hOut,EM_EXLINEFROMCHAR,0,chrg.cpMin
		invoke SendMessage,hOut,REM_LINEREDTEXT,eax,TRUE
	.endif
	invoke SendMessage,hOut,EM_REPLACESEL,FALSE,lpString
	invoke SendMessage,hOut,EM_REPLACESEL,FALSE,addr szCR
	invoke SendMessage,hOut,EM_SCROLLCARET,0,0
	ret

PutString endp

PutStringOut proc lpString:DWORD,hWin:HWND

	invoke SendMessage,hWin,EM_REPLACESEL,FALSE,lpString
	invoke SendMessage,hWin,EM_REPLACESEL,FALSE,addr szCR
	invoke SendMessage,hWin,EM_SCROLLCARET,0,0
	ret

PutStringOut endp

HexBYTE proc uses ebx edi,lpBuff:DWORD,Val:DWORD

	mov		edi,lpBuff
	mov		eax,Val
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
	mov		[edi],ax
	ret

HexBYTE endp

HexWORD proc uses ecx ebx edi,lpBuff:DWORD,Val:DWORD

	mov		edi,lpBuff
	mov		ebx,Val
	rol		ebx,16
	xor		ecx,ecx
	.while ecx<2
		rol		ebx,8
		mov		eax,ebx
		invoke HexBYTE,edi,eax
		inc		edi
		inc		edi
		inc		ecx
	.endw
	mov		byte ptr [edi],0
	ret

HexWORD endp

HexDWORD proc uses ecx ebx edi,lpBuff:DWORD,Val:DWORD

	mov		edi,lpBuff
	mov		ebx,Val
	xor		ecx,ecx
	.while ecx<4
		rol		ebx,8
		mov		eax,ebx
		invoke HexBYTE,edi,eax
		inc		edi
		inc		edi
		inc		ecx
	.endw
	mov		byte ptr [edi],0
	ret

HexDWORD endp

HexQWORD proc uses ecx ebx edi,lpBuff:DWORD,Val:QWORD

	mov		edi,lpBuff
	mov		ebx,dword ptr Val[4]
	xor		ecx,ecx
	.while ecx<4
		rol		ebx,8
		mov		eax,ebx
		invoke HexBYTE,edi,eax
		inc		edi
		inc		edi
		inc		ecx
	.endw
	mov		ebx,dword ptr Val
	xor		ecx,ecx
	.while ecx<4
		rol		ebx,8
		mov		eax,ebx
		invoke HexBYTE,edi,eax
		inc		edi
		inc		edi
		inc		ecx
	.endw
	mov		byte ptr [edi],0
	ret

HexQWORD endp

BinOut proc  uses ecx edi,lpBuff:DWORD,Val:DWORD,nSize:DWORD

	xor		ecx,ecx
	mov		eax,Val
	mov		edi,lpBuff
	.while ecx<nSize
		mov		edx,nSize
		sub		edx,ecx
		.if edx==8 || edx==16 || edx==24
			mov		byte ptr [edi+ecx],'-'
			inc		edi
		.endif
		shl		eax,1
		mov		byte ptr [edi+ecx],'0'
		.if CARRY?
			mov		byte ptr [edi+ecx],'1'
		.endif
		inc		ecx
	.endw
	mov		byte ptr [edi+ecx],'b'
	mov		byte ptr [edi+ecx+1],0
	ret

BinOut endp

DumpLineBYTE proc uses ebx esi edi,hWin:HWND,nAdr:DWORD,lpDumpData:DWORD,nBytes:DWORD
	LOCAL	buffer[256]:BYTE

	mov		ebx,nAdr
	mov		esi,lpDumpData
	lea		edi,buffer
	xor		ecx,ecx
	.while ecx<4
		rol		ebx,8
		mov		eax,ebx
		invoke HexBYTE,edi,eax
		inc		edi
		inc		edi
		inc		ecx
	.endw
	mov		byte ptr [edi],' '
	inc		edi
	xor		ecx,ecx
	.while ecx<nBytes
		mov		al,[esi+ecx]
		invoke HexBYTE,edi,eax
		add		edi,2
		inc		ecx
		.if ecx==8
			mov		byte ptr [edi],'-'
		.else
			mov		byte ptr [edi],' '
		.endif
		inc		edi
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
	mov		word ptr [edi],0Dh
	invoke SendMessage,hWin,EM_REPLACESEL,FALSE,addr buffer
	ret

DumpLineBYTE endp

DumpLineWORD proc uses ebx esi edi,hWin:HWND,nAdr:DWORD,lpDumpData:DWORD,nBytes:DWORD
	LOCAL	buffer[256]:BYTE

	mov		ebx,nAdr
	mov		esi,lpDumpData
	lea		edi,buffer
	xor		ecx,ecx
	.while ecx<4
		rol		ebx,8
		mov		eax,ebx
		invoke HexBYTE,edi,eax
		inc		edi
		inc		edi
		inc		ecx
	.endw
	mov		byte ptr [edi],' '
	inc		edi
	xor		ecx,ecx
	.while ecx<nBytes
		mov		ax,[esi+ecx]
		invoke HexWORD,edi,eax
		add		edi,4
		add		ecx,2
		.if ecx==8
			mov		byte ptr [edi],'-'
		.else
			mov		byte ptr [edi],' '
		.endif
		inc		edi
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
	mov		word ptr [edi],0Dh
	invoke SendMessage,hWin,EM_REPLACESEL,FALSE,addr buffer
	ret

DumpLineWORD endp

DumpLineDWORD proc uses ebx esi edi,hWin:HWND,nAdr:DWORD,lpDumpData:DWORD,nBytes:DWORD
	LOCAL	buffer[256]:BYTE

	mov		ebx,nAdr
	mov		esi,lpDumpData
	lea		edi,buffer
	xor		ecx,ecx
	.while ecx<4
		rol		ebx,8
		mov		eax,ebx
		invoke HexBYTE,edi,eax
		inc		edi
		inc		edi
		inc		ecx
	.endw
	mov		byte ptr [edi],' '
	inc		edi
	xor		ecx,ecx
	.while ecx<nBytes
		mov		eax,[esi+ecx]
		invoke HexDWORD,edi,eax
		add		edi,8
		add		ecx,4
		.if ecx==8
			mov		byte ptr [edi],'-'
		.else
			mov		byte ptr [edi],' '
		.endif
		inc		edi
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
	mov		word ptr [edi],0Dh
	invoke SendMessage,hWin,EM_REPLACESEL,FALSE,addr buffer
	ret

DumpLineDWORD endp

DumpLineQWORD proc uses ebx esi edi,hWin:HWND,nAdr:DWORD,lpDumpData:DWORD,nBytes:DWORD
	LOCAL	buffer[256]:BYTE

	mov		ebx,nAdr
	mov		esi,lpDumpData
	lea		edi,buffer
	xor		ecx,ecx
	.while ecx<4
		rol		ebx,8
		mov		eax,ebx
		invoke HexBYTE,edi,eax
		inc		edi
		inc		edi
		inc		ecx
	.endw
	mov		byte ptr [edi],' '
	inc		edi
	xor		ecx,ecx
	.while ecx<nBytes
		invoke HexQWORD,edi,qword ptr[esi+ecx]
		add		edi,16
		add		ecx,8
		.if ecx==8
			mov		byte ptr [edi],'-'
		.else
			mov		byte ptr [edi],' '
		.endif
		inc		edi
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
	mov		word ptr [edi],0Dh
	invoke SendMessage,hWin,EM_REPLACESEL,FALSE,addr buffer
	ret

DumpLineQWORD endp

FindWord proc uses esi,lpWord:DWORD,lpType:DWORD

	invoke SendMessage,hPrp,PRM_FINDFIRST,lpType,lpWord
	mov		esi,eax
	.if esi
		call	GetLen
		invoke strcmpn,esi,lpWord,eax
		.if eax
		  @@:
			invoke SendMessage,hPrp,PRM_FINDNEXT,0,0
			mov		esi,eax
			.if esi
				call	GetLen
				invoke strcmpn,esi,lpWord,eax
				.if eax
					jmp		@b
				.endif
			.endif
		.endif
	.endif
	.if esi
		invoke SendMessage,hPrp,PRM_FINDGETTYPE,0,0
		mov		edx,eax
	.endif
	mov		eax,esi
	ret

GetLen:
	xor		eax,eax
	.while byte ptr [esi+eax]!=':' && byte ptr [esi+eax]!='['
		inc		eax
	.endw
	retn

FindWord endp

FindTypeSize proc uses ebx esi,lpType:DWORD
	LOCAL buffer[256]:BYTE

	mov		eax,lpType
	mov		eax,[eax]
	and		eax,0FF5F5F5Fh
	.if eax==' RTP'
		mov		eax,4
		mov		edx,TRUE
	.else
		invoke FindWord,lpType,addr szPrpTWc
		.if eax
			mov		ebx,edx
			mov		esi,eax
			invoke strlen,esi
			lea		esi,[esi+eax+1]
			invoke DoMath,esi
			mov		edx,eax
			.if eax
				mov		edx,ebx
				mov		eax,var.Value
			.endif
		.else
			mov		ebx,dbg.inxtype
			mov		esi,dbg.hMemType
			.while ebx
				invoke strcmp,lpType,addr [esi].DEBUGTYPE.szName
				.if !eax
					mov		eax,[esi].DEBUGTYPE.nSize
					mov		edx,'T'
					jmp		Ex
				.endif
				dec		ebx
				lea		esi,[esi+sizeof DEBUGTYPE]
			.endw
			; Type size not found
			xor		eax,eax
			xor		edx,edx
		.endif
	.endif
  Ex:
	ret

FindTypeSize endp

FindLine proc uses ebx esi edi,Address:DWORD
	LOCAL	inx:DWORD
	LOCAL	lower:DWORD
	LOCAL	upper:DWORD

	mov		eax,dbg.lastadr
	.if Address>eax
		mov		Address,eax
	.endif
	mov		eax,dbg.inxline
	mov		lower,0
	mov		upper,eax
	xor		ebx,ebx
	.while TRUE
		mov		eax,upper
		sub		eax,lower
		.break .if !eax
		shr		eax,1
		add		eax,lower
		mov		inx,eax
		call	Compare
		.if !eax || ebx>30
			; Found
			jmp		Ex
		.elseif sdword ptr eax<0
			; Smaller
			mov		eax,inx
			mov		upper,eax
		.elseif sdword ptr eax>0
			; Larger
			mov		eax,inx
			mov		lower,eax
		.endif
		inc		ebx
	.endw
	; Not found, should never happend
	call	Linear
  Ex:
	mov		eax,edi
	ret

Compare:
	call	GetPointerFromInx
	mov		eax,Address
	sub		eax,[edi].DEBUGLINE.Address
	retn

GetPointerFromInx:
	mov		eax,inx
	mov		edx,sizeof DEBUGLINE
	mul		edx
	mov		edi,dbg.hMemLine
	lea		edi,[edi+eax]
	retn

Linear:
	mov		ebx,dbg.inxline
	mov		edi,dbg.hMemLine
	mov		eax,Address
	.while ebx
		.if eax==[edi].DEBUGLINE.Address
			retn
		.elseif eax<[edi].DEBUGLINE.Address
			lea		edi,[edi-sizeof DEBUGLINE]
			retn
		.endif
		lea		edi,[edi+sizeof DEBUGLINE]
		dec		ebx
	.endw
	lea		edi,[edi-sizeof DEBUGLINE]
	retn

FindLine endp

GetPredefinedDatatype proc uses esi edi,lpType:DWORD

	mov		edi,offset datatype
	.while [edi].DATATYPE.lpszType
		invoke strcmpi,[edi].DATATYPE.lpszType,lpType
		.if !eax
			movzx	edx,[edi].DATATYPE.nSize
			movzx	ecx,[edi].DATATYPE.fSigned
			mov		eax,[edi].DATATYPE.lpszConvertType
			jmp		Ex
		.endif
		lea		edi,[edi+sizeof DATATYPE]
	.endw
	xor		eax,eax
  Ex:
	ret

GetPredefinedDatatype endp

FindSymbol proc uses esi,lpName:DWORD

	;Get pointer to symbol list
	mov		esi,dbg.hMemSymbol
	;Loop trough the symbol list
	.while [esi].DEBUGSYMBOL.szName
		invoke strcmp,lpName,addr [esi].DEBUGSYMBOL.szName
		.if !eax
			mov		eax,esi
			jmp		Ex			
		.endif
		;Move to next symbol
		lea		esi,[esi+sizeof DEBUGSYMBOL]
	.endw
	; Not found
	xor		eax,eax
  Ex:
	ret

FindSymbol endp

FindLocalVar proc uses esi edi,lpName:DWORD,lplpLocal:DWORD

	mov		esi,lplpLocal
	mov		esi,[esi]
	.while byte ptr [esi+sizeof DEBUGVAR]
		invoke strcmp,addr [esi+sizeof DEBUGVAR],lpName
		.if !eax
			invoke strlen,addr [esi+sizeof DEBUGVAR]
			invoke strcpy,addr var.szArray,addr [esi+eax+1+sizeof DEBUGVAR]
			mov		eax,[esi].DEBUGVAR.nSize
			mov		var.nSize,eax
			mov		eax,[esi].DEBUGVAR.nArray
			mov		var.nArray,eax
			mov		eax,[esi].DEBUGVAR.nOfs
			mov		var.nOfs,eax
			mov		eax,TRUE
			jmp		Ex
		.endif
		lea		esi,[esi+sizeof DEBUGVAR]
		invoke strlen,esi
		lea		esi,[esi+eax+1]
		invoke strlen,esi
		lea		esi,[esi+eax+1]
	.endw
	mov		eax,lplpLocal
	mov		[eax],esi
	xor		eax,eax
  Ex:
	ret

FindLocalVar endp

FindLastLineNumber proc uses ebx esi,lpLine:DWORD,Address:DWORD

	mov		esi,lpLine
	mov		eax,Address
	xor		ecx,ecx
	xor		ebx,ebx
	.while [esi].DEBUGLINE.LineNumber
		.if eax<[esi].DEBUGLINE.Address
			mov		eax,ebx
			jmp		Ex
		.endif
		.if [esi].DEBUGLINE.LineNumber>ecx
			mov		ecx,[esi].DEBUGLINE.LineNumber
			mov		ebx,esi
		.endif
		lea		esi,[esi+sizeof DEBUGLINE]
	.endw
	xor		eax,eax
  Ex:
	ret

FindLastLineNumber endp

FindLocal proc uses esi,lpName:DWORD,nLine:DWORD
	LOCAL	nOfs:DWORD
	LOCAL	nSize:DWORD
	LOCAL	lpLocal:DWORD

	mov		esi,dbg.lpProc
	invoke FindLine,[esi].DEBUGSYMBOL.Address
	push	eax
	mov		edx,[esi].DEBUGSYMBOL.Address
	add		edx,[esi].DEBUGSYMBOL.nSize
	invoke FindLastLineNumber,eax,edx
	pop		edx
	.if edx && eax
		mov		ecx,[edx].DEBUGLINE.LineNumber
		mov		eax,[eax].DEBUGLINE.LineNumber
		.if nLine>=ecx && nLine<eax
			movzx	eax,[edx].DEBUGLINE.FileID
			mov		edx,sizeof DEBUGSOURCE
			mul		edx
			add		eax,dbg.hMemSource
			mov		eax,[eax].DEBUGSOURCE.FileID
			mov		var.FileID,eax
			mov		eax,[esi].DEBUGSYMBOL.lpType
			mov		lpLocal,eax
			invoke FindLocalVar,lpName,addr lpLocal
			.if eax
				mov		edx,var.nInx
				.if edx<var.nArray
					; PROC Parameter
					mov		eax,var.nSize
					mul		edx
					add		eax,dbg.context.regEbp
					add		eax,var.nOfs
					add		eax,4
					mov		var.Address,eax
					invoke strcpy,addr var.szName,lpName
					mov		eax,'P'
					jmp		Ex
				.endif
			.else
				; LOCAL
				mov		eax,lpLocal
				lea		eax,[eax+sizeof DEBUGVAR+2]
				mov		lpLocal,eax
				invoke FindLocalVar,lpName,addr lpLocal
				.if eax
					mov		edx,var.nInx
					.if edx<var.nArray
						mov		eax,var.nSize
						mul		edx
						add		eax,dbg.context.regEbp
						sub		eax,var.nOfs
						mov		var.Address,eax
						invoke strcpy,addr var.szName,lpName
						mov		eax,'L'
						jmp		Ex
					.endif
				.endif
			.endif
		.endif
	.endif
	xor		eax,eax
  Ex:
	ret

FindLocal endp

FindReg proc uses esi,lpName:DWORD

	mov		esi,offset reg32
	.while [esi].REG.szName
		invoke strcmpi,lpName,addr [esi].REG.szName
		.if !eax
			mov		eax,esi
			jmp		Ex
		.endif
		lea		esi,[esi+sizeof REG]
	.endw
	xor		eax,eax
  Ex:
	ret

FindReg endp

GetIndex proc uses esi,lpVar:DWORD

	mov		esi,lpVar
	.while byte ptr [esi]
		.if byte ptr [esi]=='('
			mov		byte ptr [esi],0
			inc		esi
			invoke CalculateIt,'('
			jmp		Ex
		.endif
		inc		esi
	.endw
	xor		eax,eax
  Ex:
	ret

GetIndex endp

FindVar proc uses esi edi,lpName:DWORD,nLine:DWORD

	push	var.IsSZ
	invoke RtlZeroMemory,addr var,sizeof var
	pop		var.IsSZ
	invoke GetIndex,lpName
	mov		var.nInx,eax
	invoke FindReg,lpName
	.if eax
		; REGISTER
		mov		esi,eax
		invoke strcpy,addr var.szName,lpName
		mov		eax,[esi].REG.nSize
		mov		var.nSize,eax
		mov		eax,[esi].REG.nOfs
		lea		eax,[dbg.context+eax]
		mov		var.Address,eax
		mov		eax,'R'
		jmp		Ex
	.endif
	.if dbg.lpProc
		; Is in a proc, find parameter or local
		invoke FindLocal,lpName,nLine
		.if eax
			jmp		Ex
		.endif
	.endif
	mov		var.FileID,0
	; Global
	invoke FindSymbol,lpName
	.if eax
		mov		esi,eax
		invoke strcpy,addr var.szName,addr [esi].DEBUGSYMBOL.szName
		.if [esi].DEBUGSYMBOL.nType=='p'
			; PROC
			mov		var.nType,99
			mov		eax,[esi].DEBUGSYMBOL.nSize
			mov		var.nSize,eax
			mov		eax,[esi].DEBUGSYMBOL.Address
			mov		var.Address,eax
			mov		var.nArray,1
			mov		eax,'p'
			jmp		Ex
		.elseif [esi].DEBUGSYMBOL.nType=='d'
			; GLOBAL
			mov		eax,var.nInx
			mov		edx,[esi].DEBUGSYMBOL.nSize
			mul		edx
			add		eax,[esi].DEBUGSYMBOL.Address
			mov		var.Address,eax
			mov		eax,[esi].DEBUGSYMBOL.nSize
			mov		var.nSize,eax
			movzx	eax,[esi].DEBUGSYMBOL.nType
			mov		var.nType,eax
			mov		esi,[esi].DEBUGSYMBOL.lpType
			; Point to type
			mov		eax,var.nInx
			.if eax<[esi].DEBUGVAR.nArray
				mov		eax,[esi].DEBUGVAR.nArray
				mov		var.nArray,eax
				invoke strlen,addr [esi+sizeof DEBUGVAR]
				lea		edi,[esi+eax+1+sizeof DEBUGVAR]
				invoke strcpy,addr var.szArray,edi
				mov		eax,'d'
				jmp		Ex
			.else
				mov		var.nErr,ERR_INDEX
				xor		eax,eax
				jmp		Ex
			.endif
		.endif
	.else
		invoke IsHex,lpName
		.if eax
			invoke HexToBin,lpName
			mov		var.Value,eax
			mov		eax,'H'
			jmp		Ex
		.else
			invoke IsDec,lpName
			.if eax
				invoke DecToBin,lpName
				mov		var.Value,eax
				mov		eax,'D'
				jmp		Ex
			.else
				invoke FindTypeSize,lpName
				.if edx
					mov		var.Value,eax
					mov		eax,'C'
					.if edx=='T'
						mov		eax,edx
					.endif
					jmp		Ex
				.endif
			.endif
		.endif
	.endif
	mov		var.nErr,ERR_NOTFOUND
	xor		eax,eax
  Ex:
	ret

FindVar endp

FormatOutput proc uses ebx,lpOutput:DWORD

	.if var.lpFormat
		mov		ebx,esp
		mov		edx,var.nFormat
		.if edx & FMT_SZ
			lea		eax,var.szValue
			push	eax
		.endif
		.if edx & FMT_DEC
			push	var.Value
		.endif
		.if edx & FMT_HEX
			push	var.Value
		.endif
		.if edx & FMT_SIZE
			push	var.nSize
		.endif
		.if edx & FMT_ADDRESS
			push	var.Address
		.endif
		.if edx & FMT_TYPE
			lea		eax,var.szArray
			push	eax
		.endif
		.if edx & FMT_NAME
			lea		eax,var.szName
			push	eax
		.endif
		invoke wsprintf,lpOutput,var.lpFormat
		mov		esp,ebx
	.endif
	ret

FormatOutput endp

GetVarVal proc uses ebx esi edi,lpName:DWORD,nLine:DWORD,fShow:DWORD

	mov		var.Value,0
	.if dbg.hDbgThread
		invoke FindVar,lpName,nLine
		.if eax=='R'
			; REGISTER
			mov		eax,var.Address
			mov		eax,[eax]
			mov		edx,var.nSize
			.if edx==2
				movzx	eax,ax
				mov		edx,offset szReg16
			.elseif edx==1
				movzx	eax,al
				mov		edx,offset szReg8
			.elseif edx==3
				movzx	eax,ah
				mov		edx,offset szReg8
			.else
				mov		edx,offset szReg32
			.endif
			mov		var.Value,eax
			mov		var.lpFormat,edx
			mov		var.nFormat,FMT_NAME or FMT_HEX or FMT_DEC
		.elseif eax=='p'
			; PROC
			mov		var.lpFormat,offset szProc
			mov		var.nFormat,FMT_NAME or FMT_SIZE
		.elseif eax=='d'
			; GLOBAL
			mov		eax,var.nSize
			.if eax
				; Known size
				.if var.IsSZ==1
					mov		eax,var.nArray
					sub		eax,var.nInx
					.if eax>256
						mov		eax,256
					.endif
					invoke ReadProcessMemory,dbg.hdbghand,var.Address,addr var.szValue,eax,0
					mov		var.lpFormat,offset szDataSZ
					mov		var.nFormat,FMT_NAME or FMT_TYPE or FMT_ADDRESS or FMT_SIZE or FMT_SZ
				.elseif var.IsSZ==2
					mov		var.nErr,ERR_SYNTAX
				.else
					.if eax==3 || eax>4
						; Struct ,union ,QWORD or TBYTE
						mov		var.lpFormat,offset szData
						mov		var.nFormat,FMT_NAME or FMT_TYPE or FMT_ADDRESS or FMT_SIZE
					.else
						invoke ReadProcessMemory,dbg.hdbghand,var.Address,addr var.Value,var.nSize,0
						mov		eax,var.nSize
						mov		edx,offset szData32
						.if eax==1
							mov		edx,offset szData8
						.elseif eax==2
							mov		edx,offset szData16
						.endif
						mov		var.lpFormat,edx
						mov		var.nFormat,FMT_NAME or FMT_TYPE or FMT_ADDRESS or FMT_SIZE or FMT_HEX or FMT_DEC
					.endif
				.endif
			.else
				; Unknown size
				mov		var.lpFormat,offset szData
				mov		var.nFormat,FMT_NAME or FMT_TYPE or FMT_ADDRESS or FMT_SIZE
			.endif
		.elseif eax=='P'
			; PROC Parameter
			mov		eax,var.nSize
			.if eax==3 || eax>4
				; Struct ,union ,QWORD or TBYTE
				mov		var.lpFormat,offset szParam
				mov		var.nFormat,FMT_NAME or FMT_TYPE or FMT_ADDRESS or FMT_SIZE
			.else
				invoke ReadProcessMemory,dbg.hdbghand,var.Address,addr var.Value,var.nSize,0
				mov		eax,var.nSize
				mov		edx,offset szParam32
				.if eax==2
					mov		edx,offset szParam16
				.elseif eax==1
					mov		edx,offset szParam8
				.endif
				mov		var.lpFormat,edx
				mov		var.nFormat,FMT_NAME or FMT_TYPE or FMT_ADDRESS or FMT_SIZE or FMT_HEX or FMT_DEC
			.endif
		.elseif eax=='L'
			; LOCAL
			mov		eax,var.nSize
			.if eax
				.if var.IsSZ==1
					mov		eax,var.nArray
					sub		eax,var.nInx
					.if eax>255
						mov		eax,255
					.endif
					invoke ReadProcessMemory,dbg.hdbghand,var.Address,addr var.szValue,eax,0
					mov		var.lpFormat,offset szLocalSZ
					mov		var.nFormat,FMT_NAME or FMT_TYPE or FMT_ADDRESS or FMT_SIZE or FMT_SZ
				.elseif var.IsSZ==2
					mov		var.nErr,ERR_SYNTAX
				.else
					.if eax==3 || eax>4
						; Struct ,union ,QWORD or TBYTE
						mov		var.lpFormat, offset szLocal
						mov		var.nFormat,FMT_NAME or FMT_TYPE or FMT_ADDRESS or FMT_SIZE
					.else
						invoke ReadProcessMemory,dbg.hdbghand,var.Address,addr var.Value,var.nSize,0
						mov		eax,var.nSize
						mov		edx,offset szLocal32
						.if eax==2
							mov		edx,offset szLocal16
						.elseif eax==1
							mov		edx,offset szLocal8
						.endif
						mov		var.lpFormat,edx
						mov		var.nFormat,FMT_NAME or FMT_TYPE or FMT_ADDRESS or FMT_SIZE or FMT_HEX or FMT_DEC
					.endif
				.endif
			.endif
		.elseif eax=='H' || eax=='D'
			; Hex or Decimal value
			mov		var.lpFormat,offset szValue
			mov		var.nFormat,FMT_HEX or FMT_DEC
		.elseif eax=='C'
			; Constant Hex and Decimal value
			invoke strcpy,addr var.szName,lpName
			mov		var.lpFormat,offset szConst
			mov		var.nFormat,FMT_NAME or FMT_HEX or FMT_DEC
		.elseif eax=='T'
			; TypeSize Hex and Decimal value
			invoke strcpy,addr var.szName,lpName
			mov		var.lpFormat,offset szTypeSize
			mov		var.nFormat,FMT_NAME or FMT_HEX or FMT_DEC
		.else
			.if var.nErr==ERR_NOTFOUND
				mov		var.lpFormat,offset szErrVariableNotFound
				mov		var.nFormat,FMT_NAME
			.elseif var.nErr==ERR_INDEX
				mov		var.lpFormat,offset szErrIndexOutOfRange
				mov		var.nFormat,FMT_NAME
			.endif
			.if fShow
				invoke FormatOutput,addr outbuffer
			.endif
			xor		eax,eax
			jmp		Ex
		.endif
		.if fShow
			invoke FormatOutput,addr outbuffer
		.endif
		mov		eax,TRUE
	.else
		xor		eax,eax
	.endif
  Ex:
	ret

GetVarVal endp

GetVarAdr proc lpName:DWORD,nLine:DWORD

	.if dbg.hDbgThread
		invoke FindVar,lpName,nLine
		.if eax=='R' || eax=='P' || eax=='L'
			; REGISTER, PROC Parameter or LOCAL
		.elseif eax=='d'
			; GLOBAL
			.if !var.nType
				xor		eax,eax
			.endif
		.else
			xor		eax,eax
			jmp		Ex
		.endif
	.else
		xor		eax,eax
		jmp		Ex
	.endif
  Ex:
	ret

GetVarAdr endp

WatchVars proc uses esi
	LOCAL	buffer[256]:BYTE

	mov		esi,offset szWatchList
	.if byte ptr [esi]
		invoke SetWindowText,hOut,addr szNULL
		.while byte ptr [esi]
			invoke strcpy,addr buffer,esi
			.if word ptr buffer==':z' || word ptr buffer==':Z'
				mov		var.IsSZ,1
				invoke GetVarVal,addr buffer[2],dbg.prevline,TRUE
			.elseif word ptr buffer==':s' || word ptr buffer==':S'
				mov		var.IsSZ,2
				invoke GetVarVal,addr buffer[2],dbg.prevline,TRUE
			.else
				invoke GetVarVal,addr buffer,dbg.prevline,TRUE
			.endif
			.if eax
				invoke PutStringOut,addr outbuffer,hOut
			.else
				invoke wsprintf,addr outbuffer,addr szErrVariableNotFound,esi
				invoke PutStringOut,addr outbuffer,hOut
			.endif
			invoke strlen,esi
			lea		esi,[esi+eax+1]
		.endw
	.endif
	ret

WatchVars endp
