
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

DumpSymbols proc uses ebx esi edi,lpSymbol:DWORD,nSymbols:DWORD
	LOCAL	SectionNumber:DWORD
	LOCAL	nType:DWORD
	LOCAL	StorageClass:DWORD
	LOCAL	NumberOfAuxSymbols:DWORD

	mov		NumberOfAuxSymbols,0
	mov		esi,lpSymbol
	mov		ebx,nSymbols
	.while sdword ptr ebx>0
		.if NumberOfAuxSymbols
			.if word ptr SectionNumber==IMAGE_SYM_DEBUG
				invoke SendMessage,hEdt,EM_REPLACESEL,FALSE,addr [esi].COFFSYMBOL.szShortName
				invoke SendMessage,hEdt,EM_REPLACESEL,FALSE,addr szCrLf
			.endif
			mov		eax,NumberOfAuxSymbols
			sub		ebx,eax
			mov		edx,sizeof COFFSYMBOL
			mul		edx
			lea		esi,[esi+eax]
		.endif
		movzx	eax,[esi].COFFSYMBOL.SectionNumber
		mov		SectionNumber,eax
		movzx	eax,[esi].COFFSYMBOL.nType
		mov		nType,eax
		movzx	eax,[esi].COFFSYMBOL.StorageClass
		mov		StorageClass,eax
		movzx	eax,[esi].COFFSYMBOL.NumberOfAuxSymbols
		mov		NumberOfAuxSymbols,eax
		mov		eax,[esi].COFFSYMBOL.Zeroes
		.if !eax
			mov		edi,hMemFile
			mov		eax,[edi].COFFHEADER.NumberOfSymbols
			mov		edx,sizeof COFFSYMBOL
			mul		edx
			add		eax,[edi].COFFHEADER.PointerToSymbolTable
			add		eax,[esi].COFFSYMBOL.nOffset[4]
			add		eax,hMemFile
		.else
			invoke lstrcpyn,addr szSection,addr [esi].COFFSYMBOL.szShortName,9
			mov		eax,offset szSection
		.endif
		invoke wsprintf,addr szOutput,addr szCoffSymbol,eax,[esi].COFFSYMBOL.Value,SectionNumber,nType,StorageClass,NumberOfAuxSymbols
		invoke SendMessage,hEdt,EM_REPLACESEL,FALSE,addr szOutput
		lea		esi,[esi+sizeof COFFSYMBOL]
		dec		ebx
	.endw
	ret

DumpSymbols endp

DumpProcs proc uses ebx esi edi,lpSymbol:DWORD,nSymbols:DWORD
	LOCAL	SectionNumber:DWORD
	LOCAL	nType:DWORD
	LOCAL	StorageClass:DWORD
	LOCAL	NumberOfAuxSymbols:DWORD

	mov		NumberOfAuxSymbols,0
	mov		esi,lpSymbol
	xor		ebx,ebx
	.while ebx<nSymbols
		.if NumberOfAuxSymbols
;			.if word ptr SectionNumber==IMAGE_SYM_DEBUG
;				invoke SendMessage,hEdt,EM_REPLACESEL,FALSE,addr [esi].COFFSYMBOL.szShortName
;				invoke SendMessage,hEdt,EM_REPLACESEL,FALSE,addr szCrLf
;			.endif
;			mov		eax,NumberOfAuxSymbols
;			sub		ebx,eax
;			mov		edx,sizeof COFFSYMBOL
;			mul		edx
;			lea		esi,[esi+eax]
		.endif
		movzx	eax,[esi].COFFSYMBOL.SectionNumber
		mov		SectionNumber,eax
		movzx	eax,[esi].COFFSYMBOL.nType
		mov		nType,eax
		movzx	eax,[esi].COFFSYMBOL.StorageClass
		mov		StorageClass,eax
		movzx	eax,[esi].COFFSYMBOL.NumberOfAuxSymbols
		mov		NumberOfAuxSymbols,eax
		.if StorageClass==2 && nType==20h && SectionNumber>0
			mov		eax,[esi].COFFSYMBOL.Zeroes
			.if !eax
				mov		edi,hMemFile
				mov		eax,[edi].COFFHEADER.NumberOfSymbols
				mov		edx,sizeof COFFSYMBOL
				mul		edx
				add		eax,[edi].COFFHEADER.PointerToSymbolTable
				add		eax,[esi].COFFSYMBOL.nOffset[4]
				add		eax,hMemFile
			.else
				invoke lstrcpyn,addr szSection,addr [esi].COFFSYMBOL.szShortName,9
				mov		eax,offset szSection
			.endif
			invoke wsprintf,addr szOutput,addr szCoffSymbol,eax,[esi].COFFSYMBOL.Value,SectionNumber,nType,StorageClass,NumberOfAuxSymbols
			invoke SendMessage,hEdt,EM_REPLACESEL,FALSE,addr szOutput
			.if NumberOfAuxSymbols
				lea		esi,[esi+sizeof COFFSYMBOL]
;PrintDec ebx
				inc		ebx
				mov		edx,[esi].COFFAUX1.PointerToLinenumber
				add		edx,hMemFile
				movzx	eax,[edx].COFFLINENUMBERS.Linenumber
				.if !eax
					mov		eax,[edx].COFFLINENUMBERS.SymbolTableIndex
				.endif
;PrintDec eax
			.endif
		.elseif StorageClass==101
			;.bf and .ef Symbols
			;StorageClass=101 (.bf and .ef)
			mov		eax,[esi].COFFSYMBOL.Zeroes
			.if !eax
				mov		edi,hMemFile
				mov		eax,[edi].COFFHEADER.NumberOfSymbols
				mov		edx,sizeof COFFSYMBOL
				mul		edx
				add		eax,[edi].COFFHEADER.PointerToSymbolTable
				add		eax,[esi].COFFSYMBOL.nOffset[4]
				add		eax,hMemFile
			.else
				invoke lstrcpyn,addr szSection,addr [esi].COFFSYMBOL.szShortName,9
				mov		eax,offset szSection
			.endif
			invoke wsprintf,addr szOutput,addr szCoffSymbol,eax,[esi].COFFSYMBOL.Value,SectionNumber,nType,StorageClass,NumberOfAuxSymbols
			invoke SendMessage,hEdt,EM_REPLACESEL,FALSE,addr szOutput
			.if NumberOfAuxSymbols
				lea		esi,[esi+sizeof COFFSYMBOL]
;PrintDec ebx
				inc		ebx
				movzx	edx,[esi].COFFAUX2.Linenumber
PrintDec edx
;				add		edx,hMemFile
;				movzx	eax,[edx].COFFLINENUMBERS.Linenumber
;				.if !eax
;					mov		eax,[edx].COFFLINENUMBERS.SymbolTableIndex
;				.endif
;PrintDec eax
			.endif
		.endif
		lea		esi,[esi+sizeof COFFSYMBOL]
		inc		ebx
	.endw
	ret

DumpProcs endp

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
	.if eax!=INVALID_HANDLE_VALUE
		mov		hFile,eax
		invoke GetFileSize,hFile,0
		mov		edx,eax
;PrintDec edx
		invoke ReadFile,hFile,hMem,edx,addr BytesRead,NULL
;PrintDec BytesRead
		invoke CloseHandle,hFile
		xor		eax,eax
	.endif
	ret

ReadTheFile endp

ReadSectionHeaders proc uses ebx esi edi

	mov		esi,hMemFile
	movzx	eax,[esi].COFFHEADER.SizeOfOptionalHeader
	lea		esi,[esi+eax+sizeof COFFHEADER]
	mov		edi,offset SectionHeader
	mov		ebx,nCoffHeaders
	.while ebx
		mov		eax,[esi].COFFSECTIONHEADER.PointerToLinenumbers
		invoke RtlMoveMemory,edi,esi,sizeof COFFSECTIONHEADER
		lea		esi,[esi+sizeof COFFSECTIONHEADER]
		lea		edi,[edi+sizeof COFFSECTIONHEADER]
		dec		ebx
	.endw
	ret

ReadSectionHeaders endp

CloseOBJ proc uses esi

	invoke SendMessage,hEdt,WM_SETTEXT,0,addr szNULL
	.if hMemFile
		; Free the file memory
		invoke GlobalFree,hMemFile
		xor		eax,eax
		mov		hMemFile,eax
		mov		nCoffHeader,eax
		mov		nCoffHeaders,eax
	.endif
	ret

CloseOBJ endp

