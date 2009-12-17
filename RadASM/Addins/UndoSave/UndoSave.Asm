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
	mov		eax,RAM_EDITOPEN OR RAM_EDITCLOSED
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
	LOCAL	key[32]:BYTE

	invoke wsprintf,addr key,addr szFmtd,pfid
	invoke GlobalAlloc,GMEM_FIXED,1024*1024
	mov		hMem,eax
	mov		nSize,10*1024
	.while nSize
		invoke SendMessage,hREd,REM_GETUNDO,10*1024,hMem
		.if eax<16000
			mov		nSize,eax
			.break
		.endif
		sub		nSize,1024
	.endw
	.if nSize
		invoke GlobalAlloc,GMEM_FIXED,64*1024
		mov		hMemOut,eax
		mov		edi,eax
		invoke wsprintf,edi,addr szFmtd,nSize
		invoke lstrcat,edi,addr szComma
		invoke lstrlen,edi
		lea		edi,[edi+eax]
		mov		esi,hMem
		xor		ebx,ebx
		.while ebx<nSize
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
			inc		ebx
		.endw
		mov		byte ptr [edi+ebx*2],0
		mov		eax,lpData
		invoke WritePrivateProfileString,addr szUndo,addr key,hMemOut,[eax].ADDINDATA.lpProject
		invoke GlobalFree,hMemOut
	.else
		mov		eax,lpData
		invoke WritePrivateProfileString,addr szUndo,addr key,addr szNULL,[eax].ADDINDATA.lpProject
	.endif
	invoke GlobalFree,hMem
	ret

SaveUndo endp

LoadUndo proc uses ebx esi edi,hWin:HWND,hREd:HWND,pfid:DWORD
	LOCAL	hMem:HGLOBAL
	LOCAL	hMemOut:HGLOBAL
	LOCAL	nSize:DWORD
	LOCAL	key[32]:BYTE

	invoke wsprintf,addr key,addr szFmtd,pfid
	invoke GlobalAlloc,GMEM_FIXED,1024*1024
	mov		hMem,eax
	mov		esi,eax
	mov		eax,lpData
	invoke GetPrivateProfileString,addr szUndo,addr key,addr szNULL,hMem,32767,[eax].ADDINDATA.lpProject
	.while byte ptr [esi]
		.if byte ptr [esi]==','
			mov		byte ptr [esi],0
			inc		esi
			.break
		.endif
		inc		esi
	.endw
	invoke DecToBin,hMem
	.if eax
		mov		nSize,eax
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,64*1024
		mov		hMemOut,eax
		mov		edi,eax
		xor		ebx,ebx
		.while ebx<nSize
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
		invoke SendMessage,hREd,REM_SETUNDO,nSize,hMemOut
	.endif
	invoke GlobalFree,hMem
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
	.elseif eax==AIM_EDITCLOSED
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
