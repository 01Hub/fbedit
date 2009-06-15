
.code

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

DumpLine proc uses ebx esi edi,nAdr:DWORD,lpData:DWORD,nBytes:DWORD
	LOCAL	buffer[256]:BYTE

	mov		ebx,nAdr
	mov		esi,lpData
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
	invoke SendMessage,hEdt,EM_REPLACESEL,FALSE,addr buffer
	ret

DumpLine endp

DumpSection proc uses ebx esi edi,lpSection:DWORD,nSize:DWORD

	xor		ebx,ebx
	mov		esi,lpSection
	mov		edi,nSize
	.while edi>=16
		invoke DumpLine,ebx,esi,16
		sub		edi,16
		add		ebx,16
		add		esi,16
	.endw
	.if edi
		invoke DumpLine,ebx,esi,edi
	.endif
	ret

DumpSection endp

ShowCoffHeader proc uses esi,lpHeader:DWORD
	LOCAL	Machine:DWORD
	LOCAL	NumberOfSections:DWORD
	LOCAL	SizeOfOptionalHeader:DWORD
	LOCAL	Characteristics:DWORD

	mov		esi,lpHeader
	movzx	eax,[esi].COFFHEADER.Machine
	mov		Machine,eax
	movzx	eax,[esi].COFFHEADER.NumberOfSections
	mov		NumberOfSections,eax
	movzx	eax,[esi].COFFHEADER.SizeOfOptionalHeader
	mov		SizeOfOptionalHeader,eax
	movzx	eax,[esi].COFFHEADER.Characteristics
	mov		Characteristics,eax
	invoke wsprintf,addr szOutput,addr szCoffHeader,Machine,NumberOfSections,[esi].COFFHEADER.TimeDateStamp,[esi].COFFHEADER.PointerToSymbolTable,[esi].COFFHEADER.NumberOfSymbols,SizeOfOptionalHeader,Characteristics
	invoke SetWindowText,hEdt,addr szOutput
	ret

ShowCoffHeader endp

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

