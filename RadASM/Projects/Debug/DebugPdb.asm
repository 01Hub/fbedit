
;#define PDB_SIGNATURE_200 \
;“Microsoft C/C++ program database 2.00\r\n\x1AJG\0”
;#define PDB_SIGNATURE_TEXT 40
;// -----------------------------------------------------------------
;typedef struct _PDB_SIGNATURE
;{
;BYTE abSignature [PDB_SIGNATURE_TEXT+4]; // PDB_SIGNATURE_nnn
;}
;PDB_SIGNATURE, *PPDB_SIGNATURE, **PPPDB_SIGNATURE;
;#define PDB_SIGNATURE_ sizeof (PDB_SIGNATURE)
;// -----------------------------------------------------------------
;#define PDB_STREAM_FREE -1
;// -----------------------------------------------------------------
;typedef struct _PDB_STREAM
;{
;DWORD dStreamSize; // in bytes, -1 = free stream
;PWORD pwStreamPages; // array of page numbers
;}
;PDB_STREAM, *PPDB_STREAM, **PPPDB_STREAM;
;#define PDB_STREAM_ sizeof (PDB_STREAM)
;// -----------------------------------------------------------------
;#define PDB_PAGE_SIZE_1K 0x0400 // bytes per page
;#define PDB_PAGE_SIZE_2K 0x0800
;#define PDB_PAGE_SIZE_4K 0x1000
;#define PDB_PAGE_SHIFT_1K 10 // log2 (PDB_PAGE_SIZE_*)
;#define PDB_PAGE_SHIFT_2K 11
;#define PDB_PAGE_SHIFT_4K 12
;#define PDB_PAGE_COUNT_1K 0xFFFF // page number < PDB_PAGE_COUNT_*
;#define PDB_PAGE_COUNT_2K 0xFFFF
;#define PDB_PAGE_COUNT_4K 0x7FFF
;// -----------------------------------------------------------------
;typedef struct _PDB_HEADER
;{
;PDB_SIGNATURE Signature; // PDB_SIGNATURE_200
;DWORD dPageSize; // 0x0400, 0x0800, 0x1000
;WORD wStartPage; // 0x0009, 0x0005, 0x0002
;WORD wFilePages; // file size / dPageSize
;PDB_STREAM RootStream; // stream directory
;WORD awRootPages []; // pages containing PDB_ROOT
;}
;PDB_HEADER, *PPDB_HEADER, **PPPDB_HEADER;
;#define PDB_HEADER_ sizeof (PDB_HEADER)

;#define PDB_STREAM_DIRECTORY 0
;#define PDB_STREAM_PDB 1
;#define PDB_STREAM_PUBSYM 7
;// -----------------------------------------------------------------
;typedef struct _PDB_ROOT
;{
;WORD wCount; // < PDB_STREAM_MAX
;WORD wReserved; // 0
;PDB_STREAM aStreams []; // stream #0 reserved for stream table
;}
;PDB_ROOT, *PPDB_ROOT, **PPPDB_ROOT;
;#define PDB_ROOT_ sizeof (PDB_ROOT)

PDB_SIGNATURE_TEXT			equ 40

PDB_SIGNATURE struct
	abSignature			db PDB_SIGNATURE_TEXT+4 dup(?)
PDB_SIGNATURE ends

PDB_STREAM_FREE				equ -1

PDB_STREAM struct
	dStreamSize			DWORD ?				; in bytes, -1 = free stream
	pwStreamPages		WORD ?				; array of page numbers
PDB_STREAM ends

PDB_PAGE_SIZE_1K			equ 0x0400		; bytes per page
PDB_PAGE_SIZE_2K			equ 0x0800
PDB_PAGE_SIZE_4K			equ 0x1000
PDB_PAGE_SHIFT_1K			equ 10			; log2 (PDB_PAGE_SIZE_*)
PDB_PAGE_SHIFT_2K			equ 11
PDB_PAGE_SHIFT_4K			equ 12
PDB_PAGE_COUNT_1K			equ 0xFFFF		; page number < PDB_PAGE_COUNT_*
PDB_PAGE_COUNT_2K			equ 0xFFFF
PDB_PAGE_COUNT_4K			equ 0x7FFF

PDB_HEADER struct
	Signature			PDB_SIGNATURE <>	; PDB_SIGNATURE_200
	dPageSize			DWORD ?				; 0x0400, 0x0800, 0x1000
	wStartPage			WORD ?				; 0x0009, 0x0005, 0x0002
	wFilePages			WORD ?				; file size / dPageSize
	RootStream			PDB_STREAM <>		; stream directory
	awRootPages 		WORD ?				;[] pages containing PDB_ROOT
PDB_HEADER ends


PDB_STREAM_DIRECTORY		equ 0
PDB_STREAM_PDB				equ 1
PDB_STREAM_PUBSYM			equ 7

PDB_ROOT struct
	wCount				WORD ?				; < PDB_STREAM_MAX
	wReserved			WORD ?				; 0
PDB_ROOT ends

.data

szPdbFileName			db 'TestDebug.pdb',0

.data?


.code

ReadPage proc uses esi,lpHeader:DWORD,nPage:DWORD,hFile:HANDLE,lpData:DWORD
	LOCAL	BytesRead:DWORD

	mov		esi,lpHeader
	mov		eax,[esi].PDB_HEADER.dPageSize
	mov		edx,nPage
	mul		edx
	invoke SetFilePointer,hFile,eax,NULL,FILE_BEGIN
	invoke ReadFile,hFile,lpData,[esi].PDB_HEADER.dPageSize,addr BytesRead,NULL
	ret

ReadPage endp

DumpPage proc uses ebx esi edi,lpHeader:DWORD,nPage:DWORD,hFile:HANDLE
	LOCAL	hMem:HGLOBAL
	LOCAL	buffer[256]:BYTE

	invoke wsprintf,addr buffer,addr szPage,nPage
	invoke SendMessage,hEdt,EM_REPLACESEL,FALSE,addr buffer
	mov		esi,lpHeader
	invoke GlobalAlloc,GMEM_FIXED,[esi].PDB_HEADER.dPageSize
	mov		hMem,eax
	invoke ReadPage,lpHeader,nPage,hFile,hMem
	xor		ebx,ebx
	mov		edi,hMem
	.while ebx<[esi].PDB_HEADER.dPageSize
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
	invoke DumpPage,addr pdbheader,0166h,hPdbFile
;	invoke SetFilePointer,hPdbFile,0,NULL,FILE_BEGIN
;	invoke GlobalAlloc,GMEM_FIXED,64*1024
;	push	eax
;	mov		hMem,eax
;	invoke ReadPage,addr pdbheader,0,hPdbFile,hMem
;	;invoke ReadFile,hPdbFile,hMem,64*1024,addr BytesRead,NULL
;	xor		ebx,ebx
;	.while ebx<pdbheader.dPageSize
;		invoke DumpLine,ebx,hMem
;		add		ebx,16
;		add		hMem,16
;	.endw
;	pop		eax
;	invoke GlobalFree,eax
	invoke CloseHandle,hPdbFile

PrintHex pdbheader.dPageSize
PrintHex pdbheader.wStartPage
PrintHex pdbheader.wFilePages
PrintHex pdbheader.awRootPages

PrintHex pdbheader.RootStream.dStreamSize
PrintHex pdbheader.RootStream.pwStreamPages


	ret

OpenPdbFile endp

