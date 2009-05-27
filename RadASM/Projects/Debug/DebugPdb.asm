

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

PDB_SIGNATURE struct
	abSignature			db PDB_SIGNATURE_TEXT+4 dup(?)
PDB_SIGNATURE ends

PDB_STREAM_FREE				equ -1

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
	awRootPages 		WORD 32 dup(?)		;[] pages containing PDB_ROOT
PDB_HEADER ends

PDB_ROOT struct
	wStreams			WORD ?				; number of streams
	wReserved			WORD ?				; not used
	aStreams			PDB_STREAM <>		; stream size list
PDB_ROOT ends

.data

szPdbFileName			db 'TestDebug.pdb',0

.data?


.code

ReadPage proc uses esi,lpHeader:DWORD,nPage:DWORD,hFile:HANDLE,lpData:DWORD
	LOCAL	BytesRead:DWORD

	mov		esi,lpHeader
	mov		eax,[esi].PDB_HEADER.dPageBytes
	mov		edx,nPage
	mul		edx
	invoke SetFilePointer,hFile,eax,NULL,FILE_BEGIN
	invoke ReadFile,hFile,lpData,[esi].PDB_HEADER.dPageBytes,addr BytesRead,NULL
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
		invoke DumpLine,ebx,edi
		add		ebx,16
		add		edi,16
	.endw
	invoke GlobalFree,hMem
	ret

DumpPage endp

OpenPdbFile proc uses ebx,lpFileName:DWORD
	LOCAL	hPdbFile:HANDLE
	LOCAL	pdbheader:PDB_HEADER
	LOCAL	BytesRead:DWORD

	invoke CreateFile,lpFileName,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
	mov		hPdbFile,eax
	invoke ReadFile,hPdbFile,addr pdbheader,sizeof PDB_HEADER,addr BytesRead,NULL

	invoke DumpPage,addr pdbheader,0,hPdbFile
	movzx		eax,pdbheader.awRootPages[0]
	invoke DumpPage,addr pdbheader,eax,hPdbFile
	invoke CloseHandle,hPdbFile

PrintHex pdbheader.dPageBytes
PrintHex pdbheader.wStartPage
PrintHex pdbheader.wFilePages
PrintHex pdbheader.awRootPages

PrintHex pdbheader.RootStream.dStreamBytes

	ret

OpenPdbFile endp

