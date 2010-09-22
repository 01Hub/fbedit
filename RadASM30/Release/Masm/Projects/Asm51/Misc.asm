.code

PrintStringz proc lpText:DWORD

	invoke lstrlen,lpText
	invoke WriteFile,hOut,lpText,eax,offset dwTemp,NULL
	ret

PrintStringz endp

ReadAsmFile proc uses esi,lpFile:DWORD
	LOCAL	hFile:DWORD
	LOCAL	nBytes:DWORD

	invoke CreateFile,lpFile,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
	.if eax!=INVALID_HANDLE_VALUE
		mov		hFile,eax
		invoke GetFileSize,hFile,addr nBytes
		push	eax
		inc		eax
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,eax
		mov		esi,eax
		pop		edx
		invoke ReadFile,hFile,esi,edx,addr nBytes,NULL
		invoke CloseHandle,hFile
		mov		eax,esi
	.else
		xor		eax,eax
	.endif
	ret

ReadAsmFile endp


