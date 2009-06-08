SymEnumSourceFiles				PROTO	:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
;SymEnumSourceLines				PROTO	:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD

SOURCEFILE struct DWORD
	ModBase					QWORD ?
	FileName				DWORD ?
SOURCEFILE ends

SRCCODEINFO struct DWORD
	SizeOfStruct            DWORD ?
	Key                     PVOID ?
	ModBase                 QWORD ?
	Obj         			BYTE MAX_PATH+1 dup(?)
	FileName				BYTE MAX_PATH+1 dup(?)
	LineNumber              DWORD ?
	Address                 DWORD ?
SRCCODEINFO ends

.const

szSymInitialize					db 'SymInitialize',0
szSymLoadModule					db 'SymLoadModule',0
szSymGetModuleInfo				db 'SymGetModuleInfo',0
szSymEnumerateSymbols			db 'SymEnumerateSymbols',0
szSymEnumSourceFiles			db 'SymEnumSourceFiles',0
szSymEnumSourceLines			db 'SymEnumSourceLines',0
szSymUnloadModule				db 'SymUnloadModule',0
szSymCleanup					db 'SymCleanup',0

szVersionInfo					db '\StringFileInfo\040904B0\FileVersion',0
szVersion						db 'DbgHelp version %s',0
szSymOk							db 'Symbols OK',0
szSymbol						db 'Name: %s Adress: %X Size %u',0
szSourceFile					db 'FileName: %s',0
szSourceLine					db 'FileName: %s Adress: %X Line %u',0
szSymLoadModuleFailed			db 'SymLoadModule failed.',0
szSymInitializeFailed			db 'SymInitialize failed.',0
szSymEnumTypes					db 'SymEnumTypes',0
szFinal							db 'DbgHelp found %u sources containing %u lines and %u symbols,',0Dh,0
szDbgHelpFail					db 'Could not find DbgHelp.dll',0

.data?

dwModuleBase					DWORD ?
im								IMAGEHLP_MODULE <>

.code

GetDbgHelpVersion proc
	LOCAL	buffer[2048]:BYTE
	LOCAL	lpbuff:DWORD
	LOCAL	lpsize:DWORD

	invoke GetFileVersionInfo,addr DbgHelpDLL,NULL,sizeof buffer,addr buffer
	.if eax
		invoke VerQueryValue,addr buffer,addr szVersionInfo,addr lpbuff,addr lpsize
		.if eax
			mov		eax,lpbuff
			invoke wsprintf,addr buffer,addr szVersion,eax
			invoke PutString,addr buffer
		.endif
	.endif
	ret

GetDbgHelpVersion endp

EnumSymbolsCallback proc uses edi,SymbolName:DWORD,SymbolAddress:DWORD,SymbolSize:DWORD,UserContext:DWORD
	LOCAL	buffer[512]:BYTE

	.if SymbolSize
		.if fOptions & 1
			invoke wsprintf,addr buffer,addr szSymbol,SymbolName,SymbolAddress,SymbolSize
			invoke PutString,addr buffer
		.endif
		mov		eax,dbg.inxsymbol
		mov		edx,sizeof DEBUGSYMBOL
		mul		edx
		mov		edi,dbg.hMemSymbol
		lea		edi,[edi+eax]
		mov		eax,SymbolAddress
		mov		[edi].DEBUGSYMBOL.Address,eax
		mov		eax,SymbolSize
		mov		[edi].DEBUGSYMBOL.nSize,eax
		invoke lstrcpy,addr [edi].DEBUGSYMBOL.szName,SymbolName
		inc		dbg.inxsymbol
	.endif
	mov		eax,TRUE
	ret

EnumSymbolsCallback endp

EnumSourceFilesCallback proc uses ebx edi,pSourceFile:DWORD,UserContext:DWORD
	LOCAL	buffer[512]:BYTE

	mov		ebx,pSourceFile
	.if fOptions & 1
		invoke wsprintf,addr buffer,addr szSourceFile,[ebx].SOURCEFILE.FileName
		invoke PutString,addr buffer
	.endif
	mov		eax,dbg.inxsource
	mov		edx,sizeof DEBUGSOURCE
	mul		edx
	mov		edi,dbg.hMemSource
	lea		edi,[edi+eax]
	mov		eax,dbg.inxsource
	mov		[edi].DEBUGSOURCE.FileID,ax
	invoke lstrcpy,addr [edi].DEBUGSOURCE.FileName,[ebx].SOURCEFILE.FileName
	inc		dbg.inxsource
	mov		eax,TRUE
	ret

EnumSourceFilesCallback endp

EnumLinesCallback proc uses ebx esi edi,pLineInfo:DWORD,UserContext:DWORD
	LOCAL	buffer[512]:BYTE

	mov		ebx,pLineInfo
	.if fOptions & 1
		invoke wsprintf,addr buffer,addr szSourceLine,addr [ebx].SRCCODEINFO.FileName,[ebx].SRCCODEINFO.Address,[ebx].SRCCODEINFO.LineNumber
		invoke PutString,addr buffer
	.endif
	; Find source file
	xor		ecx,ecx
	.while ecx<dbg.inxsource
		push	ecx
		mov		eax,ecx
		mov		edx,sizeof DEBUGSOURCE
		mul		edx
		mov		esi,dbg.hMemSource
		lea		esi,[esi+eax]
		invoke lstrcmpi,addr [esi].DEBUGSOURCE.FileName,addr [ebx].SRCCODEINFO.FileName
		.if !eax
			mov		eax,dbg.inxline
			mov		edx,sizeof DEBUGLINE
			mul		edx
			mov		edi,dbg.hMemLine
			lea		edi,[edi+eax]
			mov		ax,[esi].DEBUGSOURCE.FileID
			mov		[edi].DEBUGLINE.FileID,ax
			mov		eax,[ebx].SRCCODEINFO.LineNumber
			mov		[edi].DEBUGLINE.LineNumber,eax
			mov		eax,[ebx].SRCCODEINFO.Address
			mov		[edi].DEBUGLINE.Address,eax
;			mov		[edi].DEBUGLINE.SourceByte,0
;			mov		[edi].DEBUGLINE.BpSet,FALSE
;			mov		[edi].DEBUGLINE.NoDebug,FALSE
;			mov		[edi].DEBUGLINE.BreakPoint,FALSE
			inc		dbg.inxline
			pop		ecx
			.break
		.endif
		pop		ecx
		inc		ecx
	.endw
	mov		eax,TRUE
	ret

EnumLinesCallback endp

DbgHelp proc uses ebx,hProcess:DWORD,lpFileName
	LOCAL	buffer[MAX_PATH]:BYTE

	invoke LoadLibrary,addr DbgHelpDLL
	.if eax
		mov		hDbgHelpDLL,eax
		invoke GetDbgHelpVersion

		; Allocate memory for DEBUGLINE, max 128K lines
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,128*1024*sizeof DEBUGLINE
		mov		dbg.hMemLine,eax
		; Allocate memory for DEBUGSYMBOL, max 16K symbols
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,16*1024*sizeof DEBUGSYMBOL
		mov		dbg.hMemSymbol,eax
		; Allocate memory for DEBUGSOURCE, max 512 sources
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,512*sizeof DEBUGSOURCE
		mov		dbg.hMemSource,eax
		; Zero the indexes
		mov		dbg.inxsource,0
		mov		dbg.inxline,0
		mov		dbg.inxsymbol,0
		;invoke SymInitialize,hProcess,0,FALSE
		invoke GetProcAddress,hDbgHelpDLL,addr szSymInitialize
		.if eax
			mov		ebx,eax
			push	FALSE
			push	0
			push	hProcess
			call	ebx
		.endif
		.if eax
			;invoke SymLoadModule,hProcess,0,lpFileName,0,0,0
			invoke GetProcAddress,hDbgHelpDLL,addr szSymLoadModule
			.if eax
				mov		ebx,eax
				push	0
				push	0
				push	0
				push	lpFileName
				push	0
				push	hProcess
				call	ebx
			.endif
			.if eax
				mov		dwModuleBase,eax
				mov		im.SizeOfStruct,sizeof IMAGEHLP_MODULE
				mov		im.SymType1,SymNone
				;invoke SymGetModuleInfo,hProcess,dwModuleBase,addr im
				invoke GetProcAddress,hDbgHelpDLL,addr szSymGetModuleInfo
				.if eax
					mov		ebx,eax
					lea		eax,im
					push	eax
					push	dwModuleBase
					push	hProcess
					call	ebx
				.endif
				.if im.SymType1!=SymNone
					;invoke SymEnumerateSymbols,hProcess,dwModuleBase,addr EnumSymbolsCallback,0
;					invoke GetProcAddress,hDbgHelpDLL,addr szSymEnumerateSymbols
;					.if eax
;						mov		ebx,eax
;						.if fOptions & 1
;							invoke PutString,addr szSymOk
;						.endif
;						push	0
;						push	offset EnumSymbolsCallback
;						push	dwModuleBase
;						push	hProcess
;						call	ebx
;					.endif
					;invoke SymEnumSourceFiles,hProcess,dwModuleBase,0,0,offset EnumSourceFilesCallback,0
					invoke GetProcAddress,hDbgHelpDLL,addr szSymEnumSourceFiles
					.if eax
						mov		ebx,eax
						.if fOptions & 1
							invoke PutString,addr szSymEnumSourceFiles
						.endif
						push	0
						push	offset EnumSourceFilesCallback
						push	0
						push	0
						push	dwModuleBase
						push	hProcess
						call	ebx
					.endif
					;invoke SymEnumSourceLines,hProcess,dwModuleBase,0,0,0,0,0,offset EnumLinesCallback,0
					invoke GetProcAddress,hDbgHelpDLL,addr szSymEnumSourceLines
					.if eax
						mov		ebx,eax
						.if fOptions & 1
							invoke PutString,addr szSymEnumSourceLines
						.endif
						push	0
						push	offset EnumLinesCallback
						push	0
						push	0
						push	0
						push	0
						push	0
						push	dwModuleBase
						push	hProcess
						call	ebx
					.endif
	
	;				;invoke SymEnumTypes,hProcess,dwModuleBase,EnumerateSymbolsCallback,0
	;				invoke GetProcAddress,hDbgHelpDLL,addr szSymEnumTypes
	;				.if eax
	;					mov		ebx,eax
	;					.if fOptions & 1
	;						invoke PutString,addr szSymEnumTypes
	;					.endif
	;					push	1
	;					push	offset EnumSymbolsCallback
	;					push	0
	;					push	dwModuleBase
	;					push	hProcess
	;					call	ebx
	;				.endif
	
					;invoke SymUnloadModule,hProcess,dwModuleBase
					invoke GetProcAddress,hDbgHelpDLL,addr szSymUnloadModule
					.if eax
						mov		ebx,eax
						push	dwModuleBase
						push	hProcess
						call	ebx
					.endif
				.endif
			.else
				invoke PutString,addr szSymLoadModuleFailed
			.endif
			;invoke SymCleanup,hProcess
			invoke GetProcAddress,hDbgHelpDLL,addr szSymCleanup
			.if eax
				mov		ebx,eax
				push	hProcess
				call	ebx
			.endif
			invoke wsprintf,addr buffer,addr szFinal,dbg.inxsource,dbg.inxline,dbg.inxsymbol
			invoke PutString,addr buffer
		.else
			invoke PutString,addr szSymInitializeFailed
		.endif
		invoke FreeLibrary,hDbgHelpDLL
		mov		hDbgHelpDLL,0
	.else
		invoke PutString,addr szDbgHelpFail
	.endif
	ret

DbgHelp endp

