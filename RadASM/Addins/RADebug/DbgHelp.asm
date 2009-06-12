
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

SYMBOL_INFO struct
	SizeOfStruct			DWORD ?
	TypeIndex				DWORD ?
	Reserved				QWORD 2 dup(?)
	Index					DWORD ?
	nSize					DWORD ?
	ModBase					QWORD ?
	Flags					DWORD ?
	Value					QWORD ?
	Address					DWORD 2 dup(?)
	Register				DWORD ?
	Scope					DWORD ?
	Tag						DWORD ?
	NameLen					DWORD ?
	MaxNameLen				DWORD ?
	szName					BYTE ?
SYMBOL_INFO ends

.const

szSymInitialize					db 'SymInitialize',0
szSymLoadModule					db 'SymLoadModule',0
szSymGetModuleInfo				db 'SymGetModuleInfo',0
szSymEnumerateSymbols			db 'SymEnumerateSymbols',0
szSymEnumTypes					db 'SymEnumTypes',0
szSymEnumSourceFiles			db 'SymEnumSourceFiles',0
szSymEnumSourceLines			db 'SymEnumSourceLines',0
szSymFromAddr					db 'SymFromAddr',0
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
szFinal							db 'DbgHelp found %u source files containing %u lines and %u symbols,',0Dh,0
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

FindWord proc uses esi,lpWord:DWORD

	mov		edx,lpData
	;Get pointer to word list
	mov		esi,[edx].ADDINDATA.lpWordList
	;Skip the words loaded from .api files
	add		esi,[edx].ADDINDATA.rpProjectWordList
	;Loop trough the word list
	.while [esi].PROPERTIES.nSize
		call	TestWord
		.if eax
			mov		eax,esi
			jmp		Ex			
		.endif
		;Move to next word
		mov		eax,[esi].PROPERTIES.nSize
		lea		esi,[esi+eax+sizeof PROPERTIES]
	.endw
	xor		eax,eax
  Ex:
	ret

TestWord:
	lea		ecx,[esi+sizeof PROPERTIES]
	mov		edx,lpWord
	.if [esi].PROPERTIES.nType=='p'
		invoke lstrcmp,ecx,edx
		.if !eax
			inc		eax
			retn
		.endif
	.else
		.while TRUE
			mov		al,[ecx]
			mov		ah,[edx]
			.if !ah
				.if al!='[' && al!=':'
					xor		eax,eax
				.endif
				retn
			.elseif al!=ah
				xor		eax,eax
				retn
			.endif
			inc		ecx
			inc		edx
		.endw
	.endif
	retn

FindWord endp

FindTypeSize proc lpType:DWORD

	ret

FindTypeSize endp

AddVar proc uses ebx esi edi,lpName:DWORD,nSize:DWORD
	LOCAL	buffer[256]:BYTE
	LOCAL	lpArray:DWORD
	LOCAL	lpType:DWORD

	mov		lpArray,0
	mov		lpType,0
	mov		esi,lpName
	lea		edi,buffer
	.while TRUE
		mov		al,[esi]
		.if al=='['
			mov		byte ptr [edi],0
			inc		edi
			mov		lpArray,edi
			mov		[edi],al
			inc		edi
		.elseif al==':'
			mov		byte ptr [edi],0
			inc		edi
			mov		lpType,edi
			mov		[edi],al
			inc		edi
		.elseif al
			mov		[edi],al
			inc		edi
		.else
			xor		eax,eax
			mov		[edi],ax
			.break
		.endif
		inc		esi
	.endw
	mov		edi,dbg.lpvar
	; Add name
	invoke lstrcpy,addr [edi+sizeof DEBUGVAR],addr buffer
	invoke lstrlen,addr buffer
	lea		ebx,[eax+1]
	.if lpArray
		invoke lstrcpy,addr [edi+ebx+sizeof DEBUGVAR],lpArray
		invoke lstrlen,lpArray
		lea		ebx,[ebx+eax]
	.endif
	.if lpType
		invoke lstrcpy,addr [edi+ebx+sizeof DEBUGVAR],lpType
		invoke lstrlen,lpType
		lea		ebx,[ebx+eax]
	.endif
	mov		byte ptr [edi+ebx+sizeof DEBUGVAR],0
	mov		eax,lpArray
	.if eax
		invoke AnyToBin,addr [eax+1]
	.endif
	mov		[edi].DEBUGVAR.nArray,eax
	.if nSize
		mov		eax,nSize
		mov		[edi].DEBUGVAR.nSize,eax
	.elseif lpType
		mov		eax,lpType
		lea		eax,[eax+1]
		invoke FindTypeSize,eax
		mov		[edi].DEBUGVAR.nSize,eax
	.endif
	lea		eax,[edi+ebx+1+sizeof DEBUGVAR]
	mov		dbg.lpvar,eax
	ret

AddVar endp

AddVarList proc uses esi edi,lpList:DWORD
	LOCAL	buffer[256]:BYTE

	mov		esi,lpList
	.while byte ptr [esi]
		lea		edi,buffer
		.while TRUE
			mov		al,[esi]
			.if !al
				mov		[edi],al
				invoke AddVar,addr buffer,0
				.break
			.elseif al==','
				mov		byte ptr [edi],0
				invoke AddVar,addr buffer,0
				inc		esi
				.break
			.else
				mov		[edi],al
				inc		esi
				inc		edi
			.endif
		.endw
	.endw
	ret

AddVarList endp

EnumerateSymbolsCallback proc uses ebx edi,SymbolName:DWORD,SymbolAddress:DWORD,SymbolSize:DWORD,UserContext:DWORD
	LOCAL	buffer[512]:BYTE
	LOCAL	Displacement:QWORD

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
		invoke FindWord,SymbolName
		.if eax
			mov		esi,eax
			movzx	edx,[esi].PROPERTIES.nType
			mov		[edi].DEBUGSYMBOL.nType,dx
			.if edx=='p'
				; Proc
				mov		eax,dbg.lpvar
				mov		[edi].DEBUGSYMBOL.lpType,eax
				; Point to parameters
				invoke lstrlen,addr [esi+sizeof PROPERTIES]
				lea		esi,[esi+eax+1+sizeof PROPERTIES]
				invoke AddVarList,esi
				; Point to locals
				invoke lstrlen,esi
				lea		esi,[esi+eax+1]
				invoke AddVarList,esi
			.elseif edx=='d'
				; Variable
				invoke AddVar,addr [esi+sizeof PROPERTIES],[edi].DEBUGSYMBOL.nSize
			.endif
		.endif
		inc		dbg.inxsymbol
	.endif
	mov		eax,TRUE
	ret

EnumerateSymbolsCallback endp

;EnumTypesCallback proc uses ebx esi edi,pSymInfo:DWORD,SymbolSize:DWORD,UserContext:DWORD
;
;	mov		esi,pSymInfo
;	mov		eax,[esi].SYMBOL_INFO.Address
;PrintHex eax
;	mov		eax,TRUE
;	ret
;
;EnumTypesCallback endp

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
		; Allocate memory for var definitions
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,256*1024
		mov		dbg.hMemVar,eax
		mov		dbg.lpvar,eax
		; Zero the indexes
		mov		dbg.inxsource,0
		mov		dbg.inxline,0
		mov		dbg.inxsymbol,0
		;invoke SymInitialize,hProcess,0,FALSE
		invoke GetProcAddress,hDbgHelpDLL,addr szSymInitialize
		.if eax
			mov		ebx,eax
			push	FALSE
			push	NULL
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
				.if im.SymType1==SymPdb
					;invoke SymEnumerateSymbols,hProcess,dwModuleBase,addr EnumerateSymbolsCallback,0
					invoke GetProcAddress,hDbgHelpDLL,addr szSymEnumerateSymbols
					.if eax
						mov		ebx,eax
						.if fOptions & 1
							invoke PutString,addr szSymOk
						.endif
						push	0
						push	offset EnumerateSymbolsCallback
						push	dwModuleBase
						push	hProcess
						call	ebx
					.endif
					; Does not return anything useful
					;invoke SymEnumTypes,hProcess,BaseOfDll,EnumSymbolsCallback,UserContext
					;invoke GetProcAddress,hDbgHelpDLL,addr szSymEnumTypes
					;.if eax
					;	mov		ebx,eax
					;	.if fOptions & 1
					;		invoke PutString,addr szSymEnumTypes
					;	.endif
					;	push	0
					;	push	offset EnumTypesCallback
					;	push	0
					;	push	dwModuleBase
					;	push	hProcess
					;	call	ebx
					;.endif
					;invoke SymEnumSourceFiles,hProcess,dwModuleBase,Mask,offset EnumSourceFilesCallback,UserContext
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

