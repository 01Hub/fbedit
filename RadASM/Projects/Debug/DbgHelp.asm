SymEnumSourceFiles		PROTO	:HANDLE,:DWORD,:PCSTR,:DWORD,:PVOID
;    IN HANDLE  hProcess,
;    IN ULONG64 ModBase,
;    IN PCSTR   Mask,
;    IN PSYM_ENUMSOURCFILES_CALLBACK cbSrcFiles,
;    IN PVOID   UserContext

SymNone			equ 0
SymExport		equ 4

SYMBOL_INFO struct
    SizeOfStruct    ULONG    ?   ;
    TypeIndex       ULONG    ?   ;        // Type Index of symbol
    Reserved1	    ULONG64  ?   ;
    Reserved2	    ULONG64  ?   ;
    Reserved3	    ULONG64  ?   ;
    Index           ULONG    ?   ;
    nSize           ULONG    ?   ;
    ModBase         ULONG64  ?   ;          // Base Address of module comtaining this symbol
    Flags           ULONG    ?   ;
    Value           ULONG64  ?   ;            // Value of symbol, ValuePresent should be 1
    Address         ULONG64  ?   ;          // Address of symbol including base address of module
    Register        ULONG    ?   ;         // register holding value or pointer to value
    Scope           ULONG    ?   ;            // scope of the symbol
    Tag             ULONG    ?   ;              // pdb classification
    NameLen         ULONG    ?   ;          // Actual length of name
    MaxNameLen      ULONG    ?   ;
    szName         CHAR     ?   ;          // Name of symbol
SYMBOL_INFO ends

.const

szSymOk			db 'Symbols OK',0
szAllFiles		db '*.*',0

.data?

hProcess		HANDLE ?
dwModuleBase	DWORD ?
im				IMAGEHLP_MODULE <>
syminf			SYMBOL_INFO <>

.code

EnumSourceFilesCallback proc pSourceFile:DWORD,UserContext:DWORD

	mov		eax,TRUE
	ret

EnumSourceFilesCallback endp

EnumerateSymbolsCallback proc pSymInfo:DWORD,SymbolSize:DWORD,UserContext:DWORD

PrintHex SymbolSize
	mov		eax,pSymInfo
PrintHex eax
	
	mov		eax,TRUE
	ret

EnumerateSymbolsCallback endp

DbgHelp proc

	invoke SymInitialize,hProcess,0,FALSE
	.if eax
		invoke SymLoadModule,hProcess,0,addr szFileName,0,0,0
		.if eax
			mov		dwModuleBase,eax
			mov		im.SizeOfStruct,sizeof IMAGEHLP_MODULE
			invoke SymGetModuleInfo,hProcess,dwModuleBase,addr im
			.if im.SymType1!=SymNone
				invoke PutString,addr szSymOk

				invoke SymEnumerateSymbols64,hProcess,dwModuleBase,0,addr EnumerateSymbolsCallback,0
;				invoke SymEnumTypes,hProcess,dwModuleBase,EnumerateSymbolsCallback,0
;				invoke SymEnumSourceFiles,hProcess,dwModuleBase,addr szAllFiles,addr EnumSourceFilesCallback,0

				invoke SymUnloadModule,hProcess,dwModuleBase
				invoke SymCleanup,hProcess
			.endif
		.else
			PrintText "SymLoadModule failed"
		.endif
	.else
		PrintText "SymInitialize failed"
	.endif
	ret

DbgHelp endp