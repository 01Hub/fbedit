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

SymInitialize proc

	ret

SymInitialize endp

SymLoadModule proc

	ret

SymLoadModule endp

SymGetModuleInfo proc

	ret

SymGetModuleInfo endp

SymEnumTypes proc

	ret

SymEnumTypes endp

SymEnumerateSymbols proc

	ret

SymEnumerateSymbols endp

SymEnumSourceFiles proc

	ret

SymEnumSourceFiles endp

SymEnumSourceLines proc

	ret

SymEnumSourceLines endp

SymUnloadModule proc

	ret

SymUnloadModule endp

SymCleanup proc

	ret

SymCleanup endp

End DllEntry
