
;Structure used to update rows
ROWDATA struct
	nImage				DWORD ?			;Data for Break Point column. Double word value
	lpszLabel			DWORD ?			;Data for Label column. Pointer to string
	lpszCode			DWORD ?			;Data for Code column. Pointer to string
ROWDATA ends

.data?

rdta					ROWDATA <>

.code

ParseList proc uses ebx esi edi,lpFileName:DWORD
	LOCAL	hFile:HANDLE
	LOCAL	BytesRead:DWORD
	LOCAL	buffer[1024]:BYTE
	LOCAL	lbl[1024]:BYTE
	LOCAL	paddr:DWORD
	LOCAL	nBytes:DWORD
	LOCAL	nBytesParsed:DWORD

	invoke CreateFile,lpFileName,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
	.if eax!=INVALID_HANDLE_VALUE
		mov		hFile,eax
		.if hMemFile
			invoke GlobalFree,hMemFile
			mov		hMemFile,0
		.endif
		invoke GetFileSize,hFile,0
		mov		ebx,eax
		; Allocate memory for file
		inc		eax
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,eax
		mov		hMemFile,eax
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,65536*sizeof MCUADDR
		mov		hMemAddr,eax
		mov		paddr,eax
		invoke ReadFile,hFile,hMemFile,ebx,addr BytesRead,NULL
		invoke CloseHandle,hFile
		mov		esi,hMemFile
		mov		addin.nAddr,0
		invoke SendMessage,hGrd,GM_RESETCONTENT,0,0
		.while byte ptr [esi]
			mov		nBytes,0
			mov		nBytesParsed,0
			call	SkipWhiteSpace
			call	IsLineNumber
			.if eax
				call	SkipWhiteSpace
				.if byte ptr [esi]>='1' && byte ptr [esi]<='9' && byte ptr [esi+1]==VK_SPACE
					inc		esi
					call	SkipWhiteSpace
				.endif
				call	IsAddress
				.if eax
					call	GetAddress
					mov		edi,offset addin.Code
					lea		edi,[edi+ebx]
					call	SkipWhiteSpace
					call	IsCodeByte
					.if eax
						call	GetCodeByte
						mov		byte ptr [edi],dl
						inc		nBytesParsed
						mov		ecx,paddr
						mov		al,Cycles[edx]
						mov		[ecx].MCUADDR.cycles,al
						movzx	eax,Bytes[edx]
						mov		[ecx].MCUADDR.bytes,al
						mov		nBytes,eax
						inc		edi
						call	IsCodeByte
						.if eax
							call	GetCodeByte
							mov		byte ptr [edi],dl
							inc		nBytesParsed
							inc		edi
							call	IsCodeByte
							.if eax
								call	GetCodeByte
								mov		byte ptr [edi],dl
								inc		nBytesParsed
								inc		edi
								call	IsCodeByte
								.if eax
									call	GetCodeByte
									mov		byte ptr [edi],dl
									inc		nBytesParsed
									inc		edi
								.endif
							.endif
						.endif
					.endif
					call	SkipWhiteSpace
					call	GetSourceLine
					mov		rdta.nImage,1
					mov		rdta.lpszLabel,0
					call	IsSourceLineLabel
					.if eax
						mov		edi,eax
						lea		ecx,buffer
						sub		ecx,edi
						neg		ecx
						inc		ecx
						invoke lstrcpyn,addr lbl,addr buffer,ecx
						lea		eax,lbl
						mov		rdta.lpszLabel,eax
						invoke lstrcpy,addr buffer,edi
					.endif
					lea		eax,buffer
					.while byte ptr [eax]==VK_SPACE || byte ptr [eax]==VK_TAB
						inc		eax
					.endw
					mov		rdta.lpszCode,eax
					.while byte ptr [eax] && byte ptr [eax]!=0Dh
						.if byte ptr [eax]==VK_TAB
							mov		byte ptr [eax],VK_SPACE
						.endif
						inc		eax
					.endw
					invoke SendMessage,hGrd,GM_ADDROW,0,addr rdta
					.if nBytesParsed
						invoke SendMessage,hGrd,GM_GETROWCOUNT,0,0
						dec		eax
						mov		edx,paddr
						mov		[edx].MCUADDR.mcuaddr,bx
						mov		[edx].MCUADDR.lbinx,ax
						mov		[edx].MCUADDR.fbp,0
						lea		edx,[edx+sizeof MCUADDR]
						mov		paddr,edx
						inc		addin.nAddr
					.endif
					mov		eax,nBytes
					.if eax!=nBytesParsed
						call	IsSourceLineDB
						.if !eax
							PrintHex bx
							PrintDec nBytes
							PrintDec nBytesParsed
						.endif
					.endif
				.endif
			.endif
			call	SkipLine
		.endw
		invoke Reset
		xor		eax,eax
	.endif
	ret

SkipWhiteSpace:
	.while byte ptr [esi]==VK_SPACE || byte ptr [esi]==VK_TAB
		inc		esi
	.endw
	retn

SkipLine:
	.while byte ptr [esi]!=00h && byte ptr [esi]!=0Dh && byte ptr [esi]!=0Ah
		inc		esi
	.endw
	.while byte ptr [esi]==0Dh || byte ptr [esi]==0Ah
		inc		esi
	.endw
	retn

IsLineNumber:
	xor		eax,eax
	xor		ecx,ecx
	.while byte ptr [esi]>='0' && byte ptr [esi]<='9' && ecx<=5
		inc		ecx
		inc		esi
	.endw
	.if byte ptr [esi]==':' || byte ptr [esi]=='+'
		inc		esi
		inc		eax
	.endif
	retn

IsAddress:
	xor		eax,eax
	xor		ecx,ecx
	.while (byte ptr [esi+ecx]>='0' && byte ptr [esi+ecx]<='9') || (byte ptr [esi+ecx]>='A' && byte ptr [esi+ecx]<='F')
		inc		ecx
	.endw
	.if ecx==4
		inc		eax
	.endif
	retn

GetAddress:
	xor		ecx,ecx
	xor		ebx,ebx
	.while ecx<4
		movzx	eax,byte ptr [esi]
		.if eax<='9'
			sub		eax,'0'
		.else
			sub		eax,'A'-10
		.endif
		shl		ebx,4
		or		ebx,eax
		inc		esi
		inc		ecx
	.endw
	retn

IsCodeByte:
	xor		eax,eax
	xor		ecx,ecx
	.while (byte ptr [esi+ecx]>='0' && byte ptr [esi+ecx]<='9') || (byte ptr [esi+ecx]>='A' && byte ptr [esi+ecx]<='F')
		inc		ecx
	.endw
	.if ecx==2 && (byte ptr [esi+ecx]==VK_SPACE || byte ptr [esi+ecx]==VK_TAB)
		inc		eax
	.endif
	retn

GetCodeByte:
	xor		ecx,ecx
	xor		edx,edx
	.while ecx<2
		movzx	eax,byte ptr [esi]
		.if eax<='9'
			sub		eax,'0'
		.else
			sub		eax,'A'-10
		.endif
		shl		edx,4
		or		edx,eax
		inc		esi
		inc		ecx
	.endw
	inc		esi
	retn

GetSourceLine:
	lea		edx,buffer
	xor		ecx,ecx
	.while byte ptr [esi]!=00h && byte ptr [esi]!=0Dh && byte ptr [esi]!=0Ah
		mov		al,[esi]
		mov		[edx],al
		inc		edx
		inc		esi
		inc		ecx
	.endw
	mov		byte ptr [edx],0
	retn

IsSourceLineLabel:
	lea		edx,buffer
	xor		eax,eax
	.while byte ptr [edx]
		mov		cl,[edx]
		.if (cl>='0' && cl<='9') || (cl>='A' && cl<='Z') || (cl>='a' && cl<='z') || cl=='_'
			inc		edx
		.elseif cl==':'
			inc		edx
			mov		eax,edx
			.break
		.else
			.break
		.endif
	.endw
	retn

IsSourceLineDB:
	lea		edx,buffer
	xor		eax,eax
	.while byte ptr [edx]
		.if word ptr [edx]=='BD'
			inc		eax
			.break
		.endif
		inc		edx
	.endw
	retn

ParseList endp
