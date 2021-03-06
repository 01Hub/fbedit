

PDB_SIGNATURE_TEXT			equ 40

PDB_PAGE_SIZE_1K			equ 0x0400		; bytes per page
PDB_PAGE_SIZE_2K			equ 0x0800
PDB_PAGE_SIZE_4K			equ 0x1000
PDB_PAGE_SHIFT_1K			equ 10			; log2 (PDB_PAGE_SIZE_*)
PDB_PAGE_SHIFT_2K			equ 11
PDB_PAGE_SHIFT_4K			equ 12
PDB_PAGE_COUNT_1K			equ 0xFFFF		; page number < PDB_PAGE_COUNT_*
PDB_PAGE_COUNT_2K			equ 0xFFFF
PDB_PAGE_COUNT_4K			equ 0x7FFF

PDB_STREAM_DIRECTORY		equ 0
PDB_STREAM_PDB				equ 1
PDB_STREAM_PUBSYM			equ 7

PDB_STREAM_FREE				equ -1

PDB_SIGNATURE struct
	abSignature			db PDB_SIGNATURE_TEXT+4 dup(?)
PDB_SIGNATURE ends

PDB_STREAM struct
	dStreamBytes		DWORD ?				; stream size (-1 = unused)
	pReserved			DWORD ?				; implementation dependent
PDB_STREAM ends

PDB_HEADER struct
	Signature			PDB_SIGNATURE <>	; PDB_SIGNATURE_200
	dPageBytes			DWORD ?				; 0x0400, 0x0800, 0x1000
	wStartPage			WORD ?				; 0x0009, 0x0005, 0x0002
	wFilePages			WORD ?				; file size / dPageSize
	RootStream			PDB_STREAM <>		; stream directory
	awRootPages 		WORD 256 dup(?)		;[] pages containing PDB_ROOT
PDB_HEADER ends

PDB_ROOT struct
	wStreams			WORD ?				; number of streams
	wReserved			WORD ?				; not used
PDB_ROOT ends

.data

szPdbFileName			db 'C:\FbEdit\Projects\Applications\FbEdit\RadASM\Projects\Debug\TestDebug.pdb',0
szWrite					db 'C:\FbEdit\Projects\Applications\FbEdit\RadASM\Projects\Debug\Stream.%.3lu'

.data?


.code

ReadPage proc uses esi,lpHeader:DWORD,nPage:DWORD,hFile:HANDLE,lpMem:DWORD
	LOCAL	BytesRead:DWORD

	mov		esi,lpHeader
	mov		eax,[esi].PDB_HEADER.dPageBytes
	mov		edx,nPage
	mul		edx
	invoke SetFilePointer,hFile,eax,NULL,FILE_BEGIN
	invoke ReadFile,hFile,lpMem,[esi].PDB_HEADER.dPageBytes,addr BytesRead,NULL
	ret

ReadPage endp

DumpPage proc uses ebx esi edi,lpHeader:DWORD,nPage:DWORD,hFile:HANDLE
	LOCAL	hMem:HGLOBAL
	LOCAL	buffer[256]:BYTE

	invoke wsprintf,addr buffer,addr szPage,nPage
	invoke SendMessage,hEdt,EM_REPLACESEL,FALSE,addr buffer
	mov		esi,lpHeader
	invoke GlobalAlloc,GMEM_FIXED,[esi].PDB_HEADER.dPageBytes
	mov		hMem,eax
	invoke ReadPage,lpHeader,nPage,hFile,hMem
	xor		ebx,ebx
	mov		edi,hMem
	.while ebx<[esi].PDB_HEADER.dPageBytes
		invoke DumpLine,ebx,edi,16
		add		ebx,16
		add		edi,16
	.endw
	invoke GlobalFree,hMem
	ret

DumpPage endp

DumpStream proc uses esi edi,lpStream:DWORD,nStream:DWORD
	LOCAL	buffer[256]:BYTE

	invoke LoadCursor,0,IDC_WAIT
	invoke SetCursor,eax
	invoke SendMessage,hEdt,WM_SETTEXT,0,addr szNULL
	invoke wsprintf,addr buffer,addr szStream,nStream
	invoke SendMessage,hEdt,EM_REPLACESEL,FALSE,addr buffer
	mov		esi,lpStream
	mov		ebx,[esi].STREAM.dBytes
	mov		edi,[esi].STREAM.hmem
	xor		ebx,ebx
	.while ebx<[esi].STREAM.dBytes
		mov		ecx,[esi].STREAM.dBytes
		sub		ecx,ebx
		.if ecx>16
			mov		ecx,16
		.endif
		invoke DumpLine,ebx,edi,ecx
		add		ebx,16
		add		edi,16
	.endw
	invoke LoadCursor,0,IDC_ARROW
	invoke SetCursor,eax
	ret

DumpStream endp

ReadStreamBytes proc uses esi,lpHeader:DWORD,nPage:DWORD,nBytes:DWORD,hFile:HANDLE,lpMem:DWORD
	LOCAL	BytesRead:DWORD

	mov		esi,lpHeader
	mov		eax,[esi].PDB_HEADER.dPageBytes
	mov		edx,nPage
	mul		edx
	invoke SetFilePointer,hFile,eax,NULL,FILE_BEGIN
	invoke ReadFile,hFile,lpMem,nBytes,addr BytesRead,NULL
	ret

ReadStreamBytes endp

ReadStream proc uses ebx esi edi,lpHeader:DWORD,lpPages:DWORD,nBytes:DWORD,hFile:HANDLE,lpMem:DWORD

	mov		esi,lpHeader
	mov		ebx,lpPages
	xor		edi,edi
	.while edi<nBytes
		; Get page number
		movzx	eax,word ptr [ebx]
		mov		ecx,nBytes
		sub		ecx,edi
		.if ecx>[esi].PDB_HEADER.dPageBytes
			; Read the whole page
			mov		ecx,[esi].PDB_HEADER.dPageBytes
		.endif
		mov		edx,lpMem
		lea		edx,[edx+edi]
		invoke ReadStreamBytes,lpHeader,eax,ecx,hFile,edx
		add		edi,[esi].PDB_HEADER.dPageBytes
		add		ebx,2
	.endw
	; Return the new pages pointer
	mov		eax,ebx
	ret

ReadStream endp

SaveStream proc uses esi,nStream:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	hFile:HANDLE
	LOCAL	BytesWritten:DWORD
	LOCAL	chrg:CHARRANGE

	invoke LoadCursor,0,IDC_WAIT
	invoke SetCursor,eax
	invoke wsprintf,addr buffer,offset szWrite,nStream
	mov		eax,nStream
	mov		esi,offset stream
	lea		esi,[esi+eax*sizeof STREAM]
	invoke CreateFile,addr buffer,GENERIC_WRITE,FILE_SHARE_READ,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL
	.if eax!=INVALID_HANDLE_VALUE
		mov		hFile,eax
		invoke WriteFile,hFile,[esi].STREAM.hmem,[esi].STREAM.dBytes,addr BytesWritten,NULL
		invoke CloseHandle,hFile
		invoke lstrcat,addr buffer,addr szCRLF
		mov		chrg.cpMin,-1
		mov		chrg.cpMax,-1
		invoke SendMessage,hEdt,EM_EXSETSEL,0,addr chrg
		invoke SendMessage,hEdt,EM_REPLACESEL,FALSE,addr szSaving
		invoke SendMessage,hEdt,EM_REPLACESEL,FALSE,addr buffer
		invoke SetFocus,hEdt
		invoke SendMessage,hEdt,EM_SCROLLCARET,0,0
	.endif
	invoke LoadCursor,0,IDC_ARROW
	invoke SetCursor,eax
	ret

SaveStream endp

CloseStreams proc uses esi

	invoke SendMessage,hEdt,WM_SETTEXT,0,addr szNULL
	mov		esi,offset stream
	.while [esi].STREAM.hmem
		invoke GlobalFree,[esi].STREAM.hmem
		mov		[esi].STREAM.dBytes,0
		mov		[esi].STREAM.hmem,0
		add		esi,sizeof STREAM
	.endw
	mov		nStreams,0
	mov		nCurrentStream,0
	ret

CloseStreams endp

OpenPdbFile proc uses ebx esi edi,lpFileName:DWORD
	LOCAL	hPdbFile:HANDLE
	LOCAL	BytesRead:DWORD
	LOCAL	pdbheader:PDB_HEADER
	LOCAL	dirstream:STREAM
	LOCAL	lpPages:DWORD

	invoke LoadCursor,0,IDC_WAIT
	invoke SetCursor,eax
	; Open the pdb file
	invoke CreateFile,lpFileName,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
	.if eax!=INVALID_HANDLE_VALUE
		mov		hPdbFile,eax
		; Get the pdb header
		invoke ReadFile,hPdbFile,addr pdbheader,sizeof PDB_HEADER,addr BytesRead,NULL
		; Get the stream directory
		invoke GlobalAlloc,GMEM_FIXED,pdbheader.RootStream.dStreamBytes
		mov		dirstream.hmem,eax
		mov		eax,pdbheader.RootStream.dStreamBytes
		mov		dirstream.dBytes,eax
		lea		eax,pdbheader.awRootPages
		invoke ReadStream,addr pdbheader,eax,dirstream.dBytes,hPdbFile,dirstream.hmem
		; Read the streams
		mov		esi,dirstream.hmem
		; Get number of streams
		movzx	eax,[esi].PDB_ROOT.wStreams
		mov		nStreams,eax
		; Point to PDB_STREAM array
		lea		esi,[esi+sizeof PDB_ROOT]
		; Get pointer to pages array
		mov		eax,sizeof PDB_STREAM
		mov		edx,nStreams
		mul		edx
		lea		edi,[esi+eax]
		; Get pointer to STREAM array
		mov		ebx,offset stream
		push	nStreams
		.while nStreams
			mov		eax,[esi].PDB_STREAM.dStreamBytes
			mov		[ebx].STREAM.dBytes,eax
			invoke GlobalAlloc,GMEM_FIXED,eax
			mov		[ebx].STREAM.hmem,eax
			invoke ReadStream,addr pdbheader,edi,[ebx].STREAM.dBytes,hPdbFile,[ebx].STREAM.hmem
			mov		edi,eax
			add		ebx,sizeof STREAM
			add		esi,sizeof PDB_STREAM
			dec		nStreams
		.endw
		pop		nStreams
		invoke CloseHandle,hPdbFile
		invoke GlobalFree,dirstream.hmem
	.endif
	invoke LoadCursor,0,IDC_ARROW
	invoke SetCursor,eax
	ret

OpenPdbFile endp

