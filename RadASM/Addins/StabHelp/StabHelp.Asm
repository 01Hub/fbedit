.486
.model flat,stdcall
option casemap:none

include StabHelp.inc

.code

DllEntry proc hInst:HINSTANCE,reason:DWORD,reserved1:DWORD

	mov		eax,hInst
	mov		hInstance,eax
	mov		eax,TRUE
	ret

DllEntry Endp

SymInitialize proc hProcess:HANDLE,UserSearchPath:LPSTR,fInvadeProcess:BOOL

	mov		eax,hProcess
	mov		hProcessDbg,eax
	mov		eax,TRUE
	ret

SymInitialize endp

SymLoadModule proc uses ebx,hProcess:HANDLE,hFileOpt:HANDLE,ImageName:LPSTR,ModuleName:LPSTR,BaseOfDll:DWORD,SizeOfDll:DWORD
	LOCAL	hFile:HANDLE
	LOCAL	dwBytesRead:DWORD

	invoke CreateFile,ImageName,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
	.if eax!=INVALID_HANDLE_VALUE
		mov		hFile,eax
		invoke GetFileSize,hFile,NULL
		mov		ebx,eax
		inc		ebx
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,ebx
		mov		hMemFile,eax
		invoke ReadFile,hFile,hMemFile,ebx,addr dwBytesRead,NULL
		invoke CloseHandle,hFile
		mov		eax,TRUE
	.else
		xor		eax,eax
	.endif
	ret

SymLoadModule endp

SymGetModuleInfo proc uses ebx,hProcess:HANDLE,dwAddr:DWORD,ModuleInfo:DWORD;PIMAGEHLP_MODULE

	mov		ebx,ModuleInfo
	mov		eax,SymPdb
	mov		[ebx].IMAGEHLP_MODULE,al
	mov		eax,TRUE
	ret

SymGetModuleInfo endp

SymEnumTypes proc hProcess:HANDLE,BaseOfDll:ULONG64,EnumSymbolsCallback:DWORD,UserContext:DWORD

	mov		eax,TRUE
	ret

SymEnumTypes endp

SymEnumerateSymbols proc hProcess:HANDLE,BaseOfDll:DWORD,EnumSymbolsCallback:DWORD,UserContext:DWORD

	mov		eax,TRUE
	ret

SymEnumerateSymbols endp

SymEnumSourceFiles proc hProcess:HANDLE,BaseOfDll:ULONG64,pMask:DWORD,EnumSymbolsCallback:DWORD,UserContext:DWORD

	mov		eax,TRUE
	ret

SymEnumSourceFiles endp

SymEnumSourceLines proc hProcess:HANDLE,BaseOfDll:ULONG64,Obj:DWORD,File:DWORD,Line:DWORD,Flags:DWORD,EnumLinesCallback:DWORD,UserContext:DWORD

	mov		eax,TRUE
	ret

SymEnumSourceLines endp

SymUnloadModule proc hProcess:HANDLE,BaseOfDll:DWORD

	invoke GlobalFree,hMemFile
	mov		hMemFile,0
	mov		eax,TRUE
	ret

SymUnloadModule endp

SymCleanup proc hProcess:HANDLE

	mov		eax,TRUE
	ret

SymCleanup endp

End DllEntry
