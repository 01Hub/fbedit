;#########################################################################
;		Assembler directives

.486
.model flat,stdcall
option casemap:none

;#########################################################################
;		Include file

include UndoSave.inc

.code

;#########################################################################
;		Common AddIn Procedures

DllEntry proc hInst:HINSTANCE,reason:DWORD,reserved1:DWORD

	mov		eax,hInst
	mov		hInstance,eax
	mov		eax,TRUE
	ret

DllEntry Endp

; Export this proc (it is autoexported if MakeDef is enabled with option 2)
InstallDll proc uses ebx,hWin:DWORD,fOpt:DWORD

	mov		ebx,hWin
	;Get pointer to handles struct
	invoke SendMessage,ebx,AIM_GETHANDLES,0,0
	mov		lpHandles,eax
	;Get pointer to proc struct
	invoke SendMessage,ebx,AIM_GETPROCS,0,0
	mov		lpProc,eax
	;Get pointer to data struct
	invoke SendMessage,ebx,AIM_GETDATA,0,0	
	mov		lpData,eax
	; Messages to hook into
	mov		eax,RAM_EDITOPEN OR RAM_EDITSAVED
	; ECX and EDX must be null before we return
	xor		ecx,ecx
	xor		edx,edx
	ret 

InstallDll Endp

DecToBin proc lpStr:DWORD
	LOCAL	fNeg:DWORD

    push    ebx
    push    esi
    mov     esi,lpStr
    mov		fNeg,FALSE
    mov		al,[esi]
    .if al=='-'
		inc		esi
		mov		fNeg,TRUE
    .endif
    xor     eax,eax
  @@:
    cmp     byte ptr [esi],30h
    jb      @f
    cmp     byte ptr [esi],3Ah
    jnb     @f
    mov     ebx,eax
    shl     eax,2
    add     eax,ebx
    shl     eax,1
    xor     ebx,ebx
    mov     bl,[esi]
    sub     bl,30h
    add     eax,ebx
    inc     esi
    jmp     @b
  @@:
	.if fNeg
		neg		eax
	.endif
    pop     esi
    pop     ebx
    ret

DecToBin endp

SaveUndo proc uses ebx esi edi,hWin:HWND,hREd:HWND,pfid:DWORD
	LOCAL	hMem:HGLOBAL
	LOCAL	hMemOut:HGLOBAL
	LOCAL	nSize:DWORD
	LOCAL	app[32]:BYTE
	LOCAL	key[32]:BYTE
	LOCAL	hFile:HANDLE
	LOCAL	ft:FILETIME
	LOCAL	fat:DWORD
	LOCAL	ninx:DWORD

	invoke wsprintf,addr key,addr szFmtd,pfid
	invoke lstrcpy,addr app,addr szUndo
	invoke lstrcat,addr app,addr key
	invoke RtlZeroMemory,addr key,sizeof key
	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,4*1024*1024
	mov		hMem,eax
	invoke SendMessage,hREd,REM_GETUNDO,4*1024*1024-256*1024,hMem
	.if eax
		mov		nSize,eax
		invoke GlobalAlloc,GMEM_FIXED,8*1024*1024
		mov		hMemOut,eax
		mov		edi,eax
		; Get file time
		mov		eax,lpData
		invoke CreateFile,[eax].ADDINDATA.lpFile,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
		mov		hFile,eax
		invoke GetFileTime,hFile,NULL,NULL,addr ft
		invoke CloseHandle,hFile
		invoke FileTimeToDosDateTime,addr ft,addr fat+2,addr fat
		invoke lstrcpy,edi,addr szFt
		invoke lstrcat,edi,addr szEqu
		invoke lstrlen,edi
		lea		edi,[edi+eax]
		invoke wsprintf,edi,addr szFmtd,fat
		invoke lstrlen,edi
		lea		edi,[edi+eax+1]
		invoke lstrcpy,edi,addr szRp
		invoke lstrcat,edi,addr szEqu
		invoke lstrlen,edi
		lea		edi,[edi+eax]
		mov		esi,hMem
		mov		eax,[esi]
		lea		esi,[esi+4]
		invoke wsprintf,edi,addr szFmtd,eax
		invoke lstrlen,edi
		lea		edi,[edi+eax+1]
		mov		ninx,1
		.while [esi].RAUNDO.cb
			call	HexIt
			mov		eax,[esi].RAUNDO.cb
			inc		ninx
			lea		esi,[esi+eax+sizeof RAUNDO]
		.endw
		call	HexIt
		mov		byte ptr [edi],0
		mov		eax,lpData
		invoke WritePrivateProfileSection,addr app,hMemOut,[eax].ADDINDATA.lpProject
		invoke GlobalFree,hMemOut
	.endif
	invoke GlobalFree,hMem
	ret

HexByte:
	mov		al,[esi+ebx]
	mov		ah,al
	shr		al,4
	and		ah,0Fh
	.if al<=9
		or		al,30h
	.else
		add		al,'A'-10
	.endif
	.if ah<=9
		or		ah,30h
	.else
		add		ah,'A'-10
	.endif
	mov		[edi+ebx*2],ax
	retn

HexIt:
	invoke wsprintf,edi,addr szFmtd,ninx
	invoke lstrcat,edi,addr szEqu
	invoke lstrlen,edi
	lea		edi,[edi+eax]
	xor		ebx,ebx
	mov		ecx,[esi].RAUNDO.cb
	lea		ecx,[ecx+sizeof RAUNDO]
	.while ebx<ecx
		call	HexByte
		inc		ebx
	.endw
	mov		byte ptr [edi+ebx*2],0
	lea		edi,[edi+ebx*2+1]
	retn

SaveUndo endp

LoadUndo proc uses ebx esi edi,hWin:HWND,hREd:HWND,pfid:DWORD
	LOCAL	hMem:HGLOBAL
	LOCAL	hMemOut:HGLOBAL
	LOCAL	app[32]:BYTE
	LOCAL	key[32]:BYTE
	LOCAL	hFile:HANDLE
	LOCAL	ft:FILETIME
	LOCAL	fat:DWORD
	LOCAL	ninx:DWORD

	invoke wsprintf,addr key,addr szFmtd,pfid
	invoke lstrcpy,addr app,addr szUndo
	invoke lstrcat,addr app,addr key
	; Check file time
	mov		eax,lpData
	invoke CreateFile,[eax].ADDINDATA.lpFile,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
	mov		hFile,eax
	invoke GetFileTime,hFile,NULL,NULL,addr ft
	invoke CloseHandle,hFile
	invoke FileTimeToDosDateTime,addr ft,addr fat+2,addr fat
	mov		eax,lpData
	invoke GetPrivateProfileInt,addr app,addr szFt,0,[eax].ADDINDATA.lpProject
	.if eax==fat
		invoke GlobalAlloc,GMEM_FIXED,64*1024
		mov		hMem,eax
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,4*1024*1024
		mov		hMemOut,eax
		mov		edi,eax
		mov		eax,lpData
		invoke GetPrivateProfileInt,addr app,addr szRp,0,[eax].ADDINDATA.lpProject
		mov		[edi],eax
		lea		edi,[edi+4]
		mov		ninx,1
		.while TRUE
			invoke wsprintf,addr key,addr szFmtd,ninx
			mov		eax,lpData
			invoke GetPrivateProfileString,addr app,addr key,addr szNULL,hMem,32767,[eax].ADDINDATA.lpProject
			mov		esi,hMem
			.break .if !byte ptr [esi]
			xor		ebx,ebx
			.while byte ptr [esi+ebx*2]
				mov		ax,[esi+ebx*2]
				.if al>'9'
					sub		al,'A'-10
				.else
					and		al,0Fh
				.endif
				.if ah>'9'
					sub		ah,'A'-10
				.else
					and		ah,0Fh
				.endif
				shl		al,4
				or		al,ah
				mov		[edi+ebx],al
				inc		ebx
			.endw
			lea		edi,[edi+ebx]
			inc		ninx
		.endw
		mov		eax,edi
		sub		eax,hMemOut
		invoke SendMessage,hREd,REM_SETUNDO,eax,hMemOut
		invoke GlobalFree,hMemOut
		invoke GlobalFree,hMem
	.endif
	ret

LoadUndo endp

DllProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==AIM_EDITOPEN
		mov		eax,lpData
		.if [eax].ADDINDATA.fProject
			invoke GetWindowLong,hWin,16
			.if sdword ptr eax>0
				invoke LoadUndo,hWin,wParam,eax
			.endif
		.endif
	.elseif eax==AIM_EDITSAVED
		mov		eax,lpData
		.if [eax].ADDINDATA.fProject
			invoke GetWindowLong,hWin,16
			.if sdword ptr eax>0
				invoke SaveUndo,hWin,wParam,eax
			.endif
		.endif
	.endif
	mov		eax,FALSE
	ret

DllProc Endp

;#########################################################################

end DllEntry
