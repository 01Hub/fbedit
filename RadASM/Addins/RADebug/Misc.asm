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

FindVar proc uses esi,lpName:DWORD

	invoke RtlZeroMemory,addr var,sizeof var
	invoke FindReg,lpName
	.if eax
		mov		esi,eax
		invoke lstrcpy,addr var.szName,lpName
		mov		var.szType,0
		mov		var.nType,0
		mov		var.nArray,0
		mov		eax,[esi].REG.nSize
		mov		var.nSize,eax
		mov		var.fPtr,0
		mov		eax,[esi].REG.nOfs
		mov		var.Address,eax
		mov		eax,'R'
		jmp		Ex
	.endif
	.if dbg.lpProc
		; Is in a proc
	.endif
	; Global
	invoke FindSymbol,lpName
	.if eax
		mov		esi,eax
		invoke lstrcpy,addr var.szName,lpName
		.if [esi].DEBUGSYMBOL.nType=='p'
			; PROC
			mov		var.szType,0
			mov		var.nType,99
			mov		var.nArray,0
			mov		var.fPtr,0
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
			mov		var.nArray,0
			mov		eax,[esi].DEBUGSYMBOL.nSize
			mov		var.nSize,eax
			mov		var.fPtr,0
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
