GetFileIDFromProjectFileID		PROTO	:DWORD
AnyBreakPoints					PROTO

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

	invoke SendMessage,hOut1,EM_REPLACESEL,FALSE,lpString
	invoke SendMessage,hOut1,EM_REPLACESEL,FALSE,addr szCRLF
	invoke SendMessage,hOut1,EM_SCROLLCARET,0,0
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
	invoke SendMessage,hOut1,EM_REPLACESEL,FALSE,addr buffer
	ret

DumpLine endp

EnableMenu proc uses esi edi
	LOCAL	hREd:HWND
	LOCAL	chrg:CHARRANGE
	LOCAL	nLine:DWORD
	LOCAL	nInx:DWORD

	mov		esi,offset IDAddIn+4
	mov		eax,lpData
	.if [eax].ADDINDATA.fProject && !fNoDebugInfo
		; Toggle &Breakpoint
		invoke EnableMenuItem,hMnu,[esi],MF_BYCOMMAND or MF_GRAYED
		; Run &To Caret
		invoke EnableMenuItem,hMnu,[esi+24],MF_BYCOMMAND or MF_GRAYED
		mov		eax,lpHandles
		.if [eax].ADDINHANDLES.hEdit
			mov		edx,[eax].ADDINHANDLES.hEdit
			mov		hREd,edx
			invoke GetWindowLong,[eax].ADDINHANDLES.hMdiCld,0
			.if eax==ID_EDIT
				.if dbg.hDbgThread
					invoke SendMessage,hREd,EM_EXGETSEL,0,addr chrg
					invoke SendMessage,hREd,EM_EXLINEFROMCHAR,0,chrg.cpMin
					mov		nLine,eax
					mov		eax,lpHandles
					invoke GetWindowLong,[eax].ADDINHANDLES.hMdiCld,16
					invoke GetFileIDFromProjectFileID,eax
					.if eax
						mov		edx,nLine
						inc		edx
						xor		ecx,ecx
						mov		edi,dbg.hMemLine
						.while ecx<dbg.inxline
							.if edx==[edi].DEBUGLINE.LineNumber
								.if ax==[edi].DEBUGLINE.FileID
									.break
								.endif
							.endif
							inc		ecx
							add		edi,sizeof DEBUGLINE
						.endw
						.if ecx!=dbg.inxline
							; Toggle &Breakpoint
							invoke EnableMenuItem,hMnu,[esi],MF_BYCOMMAND or MF_ENABLED
							; Run &To Caret
							invoke EnableMenuItem,hMnu,[esi+24],MF_BYCOMMAND or MF_ENABLED
						.endif
					.endif
				.else
					; Toggle &Breakpoint
					invoke EnableMenuItem,hMnu,[esi],MF_BYCOMMAND or MF_ENABLED
				.endif
			.endif
		.endif
		; &Clear Breakpoints
		invoke AnyBreakPoints
		.if eax
			invoke EnableMenuItem,hMnu,[esi+4],MF_BYCOMMAND or MF_ENABLED
		.else
			invoke EnableMenuItem,hMnu,[esi+4],MF_BYCOMMAND or MF_GRAYED
		.endif
		; &Run
		invoke EnableMenuItem,hMnu,[esi+8],MF_BYCOMMAND or MF_ENABLED
		; Do not Debug
		invoke EnableMenuItem,hMnu,[esi+28],MF_BYCOMMAND or MF_ENABLED
		.if dbg.hDbgThread
			; &Stop
			invoke EnableMenuItem,hMnu,[esi+12],MF_BYCOMMAND or MF_ENABLED
			; Step &Into
			invoke EnableMenuItem,hMnu,[esi+16],MF_BYCOMMAND or MF_ENABLED
			; Step &Over
			mov		eax,MF_BYCOMMAND or MF_GRAYED
			.if dbg.inxsource
				mov		eax,MF_BYCOMMAND or MF_ENABLED
			.endif
			invoke EnableMenuItem,hMnu,[esi+20],eax
		.else
			; &Stop
			invoke EnableMenuItem,hMnu,[esi+12],MF_BYCOMMAND or MF_GRAYED
			; Step &Into
			invoke EnableMenuItem,hMnu,[esi+16],MF_BYCOMMAND or MF_GRAYED
			; Step &Over
			invoke EnableMenuItem,hMnu,[esi+20],MF_BYCOMMAND or MF_GRAYED
			; Run &To Caret
			invoke EnableMenuItem,hMnu,[esi+24],MF_BYCOMMAND or MF_GRAYED
		.endif
	.else
		; No project loaded, disable all
		.while dword ptr [esi]
			invoke EnableMenuItem,hMnu,[esi],MF_BYCOMMAND or MF_GRAYED
			add		esi,4
		.endw
	.endif
	ret

EnableMenu endp

FindLine proc uses ebx esi edi,Address:DWORD
	LOCAL	inx:DWORD
	LOCAL	lower:DWORD
	LOCAL	upper:DWORD

	mov		eax,dbg.inxline
	mov		lower,0
	mov		upper,eax
	.while TRUE
		mov		eax,upper
		sub		eax,lower
		.break .if !eax
		shr		eax,1
		add		eax,lower
		mov		inx,eax
		call	Compare
		.if sdword ptr eax<0
			; Smaller
			mov		eax,inx
			mov		upper,eax
		.elseif sdword ptr eax>0
			; Larger
			mov		eax,inx
			mov		lower,eax
		.else
			; Found
			jmp		Ex
		.endif
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
		.endif
		lea		edi,[edi+sizeof DEBUGLINE]
		dec		ebx
	.endw
	xor		edi,edi
	retn

FindLine endp

FindSymbol proc uses esi,lpName:DWORD

	;Get pointer to symbol list
	mov		esi,dbg.hMemSymbol
	;Loop trough the symbol list
	.while [esi].DEBUGSYMBOL.szName
		invoke lstrcmp,lpName,addr [esi].DEBUGSYMBOL.szName
		.if !eax
			mov		eax,esi
			jmp		Ex			
		.endif
		;Move to next word
		lea		esi,[esi+sizeof DEBUGSYMBOL]
	.endw
	xor		eax,eax
  Ex:
	ret
	ret

FindSymbol endp

FindType proc uses esi,lpType:DWORD

	mov		esi,offset szDWORD
	.while byte ptr [esi]
		invoke lstrcmp,esi,lpType
		.if !eax
			mov		eax,4
			jmp		Ex
		.endif
		invoke lstrlen,esi
		lea		esi,[esi+eax+1]
	.endw
	mov		esi,offset szWORD
	.while byte ptr [esi]
		invoke lstrcmp,esi,lpType
		.if !eax
			mov		eax,2
			jmp		Ex
		.endif
		invoke lstrlen,esi
		lea		esi,[esi+eax+1]
	.endw
	mov		esi,offset szBYTE
	.while byte ptr [esi]
		invoke lstrcmp,esi,lpType
		.if !eax
			mov		eax,1
			jmp		Ex
		.endif
		invoke lstrlen,esi
		lea		esi,[esi+eax+1]
	.endw
	xor		eax,eax
  Ex:
	ret

FindType endp

FindLocalVar proc uses esi edi,lpName:DWORD,lpLocal:DWORD,nOfs:DWORD,nMove:DWORD
	LOCAL	nArray:DWORD

	mov		esi,lpLocal
	mov		edi,nOfs
	.while byte ptr [esi]
		call	Compare
		.if eax
			.if sdword ptr nMove<0
				sub		edi,edx
			.endif
			mov		eax,edi
			jmp		Ex
		.endif
		.if sdword ptr nMove>0
			add		edi,edx
		.else
			sub		edi,edx
		.endif
	.endw
	xor		eax,eax
  Ex:
	ret

Compare:
	mov		edx,lpName
	.while TRUE
		mov		ah,[edx]
		mov		al,[esi]
		.if !ah && (al==':' || al=='[' || al==',' || !al)
			mov		eax,TRUE
			jmp		ExCompare
		.endif
		.break .if !al
		sub		al,ah
		.break .if al
		inc		esi
		inc		edx
	.endw
	xor		eax,eax
ExCompare:
	push	eax
	mov		nArray,1
	xor		edx,edx
	.while byte ptr [esi] && byte ptr [esi]!=','
		inc		esi
		.if byte ptr [esi-1]==':'
			xor		ecx,ecx
			.while byte ptr [esi+ecx] && byte ptr [esi+ecx]!=','
				mov		al,[esi+ecx]
				.if al>='a' && al<='z'
					and		al,5Fh
				.endif
				mov		typeupper[ecx],al
				inc		ecx
			.endw
			mov		typeupper[ecx],0
			invoke FindType,offset typeupper
			mov		edx,eax
			.if !edx
				mov		edx,4
			.endif
			mov		eax,nArray
			mul		edx
			mov		edx,eax
		.elseif byte ptr [esi-1]=='['
			invoke DecToBin,esi
			mov		nArray,eax
		.endif
	.endw
	.if byte ptr [esi]==','
		inc		esi
	.endif
	pop		eax
	retn

FindLocalVar endp

FindLocal proc uses esi,lpName:DWORD,nLine:DWORD
	LOCAL	nOfs:DWORD
	LOCAL	nSize:DWORD

	mov		esi,dbg.lpProc
	invoke FindLine,[esi].DEBUGSYMBOL.Address
	push	eax
	mov		eax,[esi].DEBUGSYMBOL.Address
	add		eax,[esi].DEBUGSYMBOL.nSize
	invoke FindLine,eax
	pop		edx
	.if edx && eax
		mov		edx,[edx].DEBUGLINE.LineNumber
		dec		edx
		mov		ecx,[eax].DEBUGLINE.LineNumber
		dec		ecx
		.if nLine>=edx && nLine<ecx
			; PROC Parameter
			invoke FindLocalVar,lpName,[esi].DEBUGSYMBOL.lpType,8,1
			.if eax
				mov		var.Address,eax
				mov		var.nSize,edx
				invoke lstrcpy,addr var.szName,lpName
				invoke lstrcpy,addr var.szType,addr typeupper
				mov		eax,'P'
				jmp		Ex
			.else
				; LOCAL
				invoke lstrlen,[esi].DEBUGSYMBOL.lpType
				add		eax,[esi].DEBUGSYMBOL.lpType
				inc		eax
				invoke FindLocalVar,lpName,eax,0,-1
				.if eax
					mov		var.Address,eax
					mov		var.nSize,edx
					invoke lstrcpy,addr var.szName,lpName
					invoke lstrcpy,addr var.szType,addr typeupper
					mov		eax,'L'
					jmp		Ex
				.endif
			.endif
		.endif
	.endif
	xor		eax,eax
  Ex:
	ret

;	invoke FindLocalVar,lpName,[esi].DEBUGSYMBOL.lpType,8,1
;	.if eax
;		mov		nOfs,eax
;		mov		nSize,edx
;		invoke FindLine,[esi].DEBUGSYMBOL.Address
;		push	eax
;		mov		eax,[esi].DEBUGSYMBOL.Address
;		add		eax,[esi].DEBUGSYMBOL.nSize
;		invoke FindLine,eax
;		pop		edx
;		.if edx && eax
;			mov		edx,[edx].DEBUGLINE.LineNumber
;			dec		edx
;			mov		ecx,[eax].DEBUGLINE.LineNumber
;			dec		ecx
;			.if nLine>=edx && nLine<ecx
;				mov		edx,dbg.context.regEbp
;				add		edx,nOfs
;;				mov		nDWORD,0
;;				invoke ReadProcessMemory,dbg.hdbghand,edx,addr nDWORD,nSize,0
;;				invoke wsprintf,offset outbuffer,addr szParam,addr buffer,nOfs,nDWORD,nDWORD
;;				mov		ti.lpszText,offset outbuffer
;;				call	Activate
;			.else
;;				call	DeActivate
;			.endif
;		.else
;;			call	DeActivate
;		.endif
;	.else
;		; LOCAL
;		invoke lstrlen,[esi].DEBUGSYMBOL.lpType
;		add		eax,[esi].DEBUGSYMBOL.lpType
;		inc		eax
;		invoke FindLocalVar,lpName,eax,0,-1
;		.if eax
;			mov		nOfs,eax
;			mov		nSize,edx
;			invoke FindLine,[esi].DEBUGSYMBOL.Address
;			push	eax
;			mov		eax,[esi].DEBUGSYMBOL.Address
;			add		eax,[esi].DEBUGSYMBOL.nSize
;			invoke FindLine,eax
;			pop		edx
;			.if edx && eax
;				mov		edx,[edx].DEBUGLINE.LineNumber
;				dec		edx
;				mov		ecx,[eax].DEBUGLINE.LineNumber
;				dec		ecx
;				.if nLine>=edx && nLine<ecx
;					mov		edx,dbg.context.regEbp
;					add		edx,nOfs
;;					mov		nDWORD,0
;;					invoke ReadProcessMemory,dbg.hdbghand,edx,addr nDWORD,nSize,0
;;					invoke wsprintf,offset outbuffer,addr szLocal,addr buffer,nOfs,nDWORD,nDWORD
;;					mov		ti.lpszText,offset outbuffer
;;					call	Activate
;				.else
;;					call	DeActivate
;				.endif
;			.else
;;				call	DeActivate
;			.endif
;		.else
;;			call	DeActivate
;		.endif
;	.endif

FindLocal endp

FindReg proc uses esi,lpName:DWORD

	mov		esi,offset reg32
	.while [esi].REG.szName
		invoke lstrcmpi,lpName,addr [esi].REG.szName
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

FindVar proc uses esi,lpName:DWORD,nLine:DWORD

	invoke RtlZeroMemory,addr var,sizeof var
	invoke FindReg,lpName
	.if eax
		mov		esi,eax
		invoke lstrcpy,addr var.szName,lpName
		mov		eax,[esi].REG.nSize
		mov		var.nSize,eax
		mov		eax,[esi].REG.nOfs
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
	; Global
	invoke FindSymbol,lpName
	.if eax
		mov		esi,eax
		invoke lstrcpy,addr var.szName,lpName
		.if [esi].DEBUGSYMBOL.nType=='p'
			; PROC
			mov		var.nType,99
			mov		eax,[esi].DEBUGSYMBOL.nSize
			mov		var.nSize,eax
			mov		eax,[esi].DEBUGSYMBOL.Address
			mov		var.Address,eax
			mov		eax,'p'
			jmp		Ex
		.elseif [esi].DEBUGSYMBOL.nType=='d'
			; GLOBAL
			mov		edx,[esi].DEBUGSYMBOL.lpType
			xor		ecx,ecx
			.while byte ptr [edx+ecx]!=' ' && byte ptr [edx+ecx] && ecx<64
				mov		al,[edx+ecx]
				.if al>='a' && al<='z'
					and		al,5Fh
				.endif
				mov		var.szType[ecx],al
				inc		ecx
			.endw
			mov		var.szType[ecx],0
			invoke FindType,addr var.szType
			mov		var.nType,eax
			mov		eax,[esi].DEBUGSYMBOL.nSize
			mov		var.nSize,eax
			mov		eax,[esi].DEBUGSYMBOL.Address
			mov		var.Address,eax
			mov		eax,'d'
			jmp		Ex
		.endif
	.endif
	xor		eax,eax
  Ex:
	ret

FindVar endp
