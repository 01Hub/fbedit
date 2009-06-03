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

DEBUGSOURCE struct
	FileID					DWORD ?
	FileName				BYTE MAX_PATH dup(?)
DEBUGSOURCE ends

DEBUGLINE struct
	FileID					DWORD ?
	LineNumber              DWORD ?
	Address                 DWORD ?
	SourceByte				WORD ?
	BreakPoint				WORD ?
DEBUGLINE ends

.const

szSymOk							db 'Symbols OK',0
szAllFiles						db '*.*',0
szSymbol						db 'Name: %s Adress: %X Size %u',0
szSymEnumSourceFiles			db 'SymEnumSourceFiles',0
szSourceFile					db 'FileName: %s',0
szSymEnumSourceLines			db 'SymEnumSourceLines',0
szSourceLine					db 'FileName: %s Adress: %X Line %u',0
szVersionInfo					db '\StringFileInfo\040904B0\FileVersion',0
szVersion						db 'DbgHelp.dll version %s',0
szSymLoadModule					db 'SymLoadModule failed.',0
szSymInitialize					db 'SymInitialize failed.',0

.data?

dwModuleBase					DWORD ?
im								IMAGEHLP_MODULE <>
inxsource						DWORD ?
dbgsource						DEBUGSOURCE 256 dup(<>)
inxline							DWORD ?
dbgline							DEBUGLINE 65536 dup(<>)

.code

GetDbgHelpVersion proc
	LOCAL	buffer[2048]:BYTE
	LOCAL	lpbuff:DWORD
	LOCAL	lpsize:DWORD

	invoke GetFileVersionInfo,addr DbgHelpDLL,NULL,sizeof buffer,addr buffer
	lea ebx,buffer
	mov		ecx,32
	invoke VerQueryValue,addr buffer,addr szVersionInfo,addr lpbuff,addr lpsize
	mov		eax,lpbuff
	invoke wsprintf,addr buffer,addr szVersion,eax
	invoke PutString,addr buffer
	ret

GetDbgHelpVersion endp

EnumerateSymbolsCallback proc uses esi,SymbolName:DWORD,SymbolAddress:DWORD,SymbolSize:DWORD,UserContext:DWORD
	LOCAL	buffer[512]:BYTE

	.if fOptions & 1
		invoke wsprintf,addr buffer,addr szSymbol,SymbolName,SymbolAddress,SymbolSize
		invoke PutString,addr buffer
	.endif
	mov		eax,TRUE
	ret

EnumerateSymbolsCallback endp

EnumSourceFilesCallback proc uses ebx edi,pSourceFile:DWORD,UserContext:DWORD
	LOCAL	buffer[512]:BYTE

	mov		ebx,pSourceFile
	.if fOptions & 1
		invoke wsprintf,addr buffer,addr szSourceFile,[ebx].SOURCEFILE.FileName
		invoke PutString,addr buffer
	.endif
	mov		eax,inxsource
	mov		edx,sizeof DEBUGSOURCE
	mul		edx
	lea		edi,[eax+offset dbgsource]
	mov		eax,inxsource
	mov		[edi].DEBUGSOURCE.FileID,eax
	invoke lstrcpy,addr [edi].DEBUGSOURCE.FileName,[ebx].SOURCEFILE.FileName
	inc		inxsource
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
	.while ecx<inxsource
		push	ecx
		mov		eax,ecx
		mov		edx,sizeof DEBUGSOURCE
		mul		edx
		lea		esi,[eax+offset dbgsource]
		invoke lstrcmpi,addr [esi].DEBUGSOURCE.FileName,addr [ebx].SRCCODEINFO.FileName
		.if !eax
			mov		eax,inxline
			mov		edx,sizeof DEBUGLINE
			mul		edx
			lea		edi,[eax+offset dbgline]
			mov		eax,[esi].DEBUGSOURCE.FileID
			mov		[edi].DEBUGLINE.FileID,eax
			mov		eax,[ebx].SRCCODEINFO.LineNumber
			mov		[edi].DEBUGLINE.LineNumber,eax
			mov		eax,[ebx].SRCCODEINFO.Address
			mov		[edi].DEBUGLINE.Address,eax
			mov		[edi].DEBUGLINE.SourceByte,-1
			mov		[edi].DEBUGLINE.BreakPoint,0
			inc		inxline
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

	invoke GetDbgHelpVersion
	mov		inxsource,0
	mov		inxline,0
	invoke RtlZeroMemory,addr dbgsource,sizeof dbgsource
	invoke RtlZeroMemory,addr dbgline,sizeof dbgline
	invoke SymInitialize,hProcess,0,FALSE
	.if eax
		invoke SymLoadModule,hProcess,0,lpFileName,0,0,0
		.if eax
			mov		dwModuleBase,eax
			mov		im.SizeOfStruct,sizeof IMAGEHLP_MODULE
			invoke SymGetModuleInfo,hProcess,dwModuleBase,addr im
			.if im.SymType1!=SymNone
				.if fOptions & 1
					invoke PutString,addr szSymOk
				.endif
				invoke SymEnumerateSymbols,hProcess,dwModuleBase,addr EnumerateSymbolsCallback,0
				invoke GetProcAddress,hDbgHelpDLL,addr szSymEnumSourceFiles
				invoke SymEnumSourceFiles,hProcess,dwModuleBase,0,0,offset EnumSourceFilesCallback,0
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
				;invoke SymEnumTypes,hProcess,dwModuleBase,EnumerateSymbolsCallback,0
				invoke SymUnloadModule,hProcess,dwModuleBase
			.endif
		.else
			invoke PutString,addr szSymLoadModule
		.endif
		invoke SymCleanup,hProcess
	.else
		invoke PutString,addr szSymInitialize
	.endif
	ret

DbgHelp endp

