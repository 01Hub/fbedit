
ResEdDllEntry proc public hInst:HINSTANCE, reason:DWORD, reserved1:DWORD

	.if reason==DLL_PROCESS_ATTACH
		invoke ResEdInstall,hInst
	.elseif reason==DLL_PROCESS_DETACH
		invoke ResEdUninstall
	.endif
    mov     eax,TRUE
    ret

ResEdDllEntry Endp

GetDef proc public nInx:DWORD

	mov		eax,nInx
	.if !eax
		;Get the toolbox bitmap
		invoke LoadBitmap,hInstance,IDB_DLG
		mov		ccdef1.hbmp,eax
		;Return pointer to inited struct
		mov		eax,offset ccdef1
	.elseif eax==1
		;Get the toolbox bitmap
		invoke LoadBitmap,hInstance,IDB_TBX
		mov		ccdef2.hbmp,eax
		;Return pointer to inited struct
		mov		eax,offset ccdef2
	.elseif eax==2
		;Get the toolbox bitmap
		invoke LoadBitmap,hInstance,IDB_PRP
		mov		ccdef3.hbmp,eax
		;Return pointer to inited struct
		mov		eax,offset ccdef3
	.elseif eax==3
		;Get the toolbox bitmap
		invoke LoadBitmap,hInstance,IDB_PRJ
		mov		ccdef4.hbmp,eax
		;Return pointer to inited struct
		mov		eax,offset ccdef4
	.else
		xor		eax,eax
	.endif
	ret

GetDef endp

ENDIF

End ResEdDllEntry
