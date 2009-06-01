
ID_EDIT					equ	65501

.const

szRADebugBP			db 'RADebugBP',0
szBPNULL			db 0,0
szCommaBP			db ',%u',0

.code

ClearBreakpoints proc
	LOCAL	hTab:HWND
	LOCAL	nInx:DWORD
	LOCAL	tci:TCITEM
	LOCAL	hREd:HWND
	LOCAL	nLine:DWORD

	invoke RtlZeroMemory,offset breakpoint,sizeof breakpoint
	mov		eax,lpData
	invoke WritePrivateProfileSection,addr szRADebugBP,addr szBPNULL,[eax].ADDINDATA.lpProject
	mov		eax,lpHandles
	mov		eax,[eax].ADDINHANDLES.hTab
	mov		hTab,eax
	mov		tci.imask,TCIF_PARAM
	mov		nInx,0
	.while TRUE
		invoke SendMessage,hTab,TCM_GETITEM,nInx,addr tci
		.break .if !eax
		invoke GetWindowLong,tci.lParam,0
		.if eax==ID_EDIT
			invoke GetWindowLong,tci.lParam,GWL_USERDATA
			mov		hREd,eax
			mov		nLine,-1
			.while TRUE
				invoke SendMessage,hREd,REM_NEXTBREAKPOINT,nLine,0
				.break .if eax==-1
				mov		nLine,eax
				invoke SendMessage,hREd,REM_SETBREAKPOINT,nLine,FALSE
			.endw
		.endif
		inc		nInx
	.endw
	ret

ClearBreakpoints endp

ToggleBreakpoint proc
	LOCAL	hREd:HWND
	LOCAL	chrg:CHARRANGE
	LOCAL	nLine:DWORD

	mov		eax,lpHandles
	mov		eax,[eax].ADDINHANDLES.hMdiCld
	invoke GetWindowLong,eax,0
	.if eax==ID_EDIT
		mov		eax,lpHandles
		mov		eax,[eax].ADDINHANDLES.hEdit
		mov		hREd,eax
		invoke SendMessage,hREd,EM_EXGETSEL,0,addr chrg
		invoke SendMessage,hREd,EM_EXLINEFROMCHAR,0,chrg.cpMin
		mov		nLine,eax
		invoke SendMessage,hREd,REM_GETLINESTATE,nLine,0
		and		eax,STATE_BREAKPOINT
		xor		eax,STATE_BREAKPOINT
		invoke SendMessage,hREd,REM_SETBREAKPOINT,nLine,eax
	.endif
	ret

ToggleBreakpoint endp

SaveBreakPoints proc uses ebx
	LOCAL	hREd:HWND
	LOCAL	nInx:DWORD
	LOCAL	nLine:DWORD
	LOCAL	buffer[1024]:BYTE
	LOCAL	szbp[8]:BYTE

	mov		eax,lpHandles
	mov		eax,[eax].ADDINHANDLES.hMdiCld
	invoke GetWindowLong,eax,0
	.if eax==ID_EDIT
		mov		eax,lpHandles
		mov		eax,[eax].ADDINHANDLES.hEdit
		mov		hREd,eax
		mov		eax,lpHandles
		invoke GetWindowLong,[eax].ADDINHANDLES.hMdiCld,16
		mov		nInx,eax
		mov		dword ptr buffer,0
		mov		nLine,-1
		mov		ebx,128
		.while ebx
			invoke SendMessage,hREd,REM_NEXTBREAKPOINT,nLine,0
			.break .if eax==-1
			mov		nLine,eax
			invoke wsprintf,addr szbp,addr szCommaBP,nLine
			invoke lstrcat,addr buffer,addr szbp
			dec		ebx
		.endw
		invoke wsprintf,addr szbp,addr szCommaBP,nInx
		mov		eax,lpData
		invoke WritePrivateProfileString,addr szRADebugBP,addr szbp[1],addr buffer[1],[eax].ADDINDATA.lpProject
	.endif
	ret

SaveBreakPoints endp

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

LoadBreakPoints proc uses esi
	LOCAL	hREd:HWND
	LOCAL	nInx:DWORD
	LOCAL	nLine:DWORD
	LOCAL	buffer[1024]:BYTE
	LOCAL	szbp[8]:BYTE

	mov		eax,lpHandles
	mov		eax,[eax].ADDINHANDLES.hMdiCld
	invoke GetWindowLong,eax,0
	.if eax==ID_EDIT
		mov		eax,lpHandles
		mov		eax,[eax].ADDINHANDLES.hEdit
		mov		hREd,eax
		mov		eax,lpHandles
		invoke GetWindowLong,[eax].ADDINHANDLES.hMdiCld,16
		mov		nInx,eax
		invoke wsprintf,addr szbp,addr szCommaBP,nInx
		mov		eax,lpData
		invoke GetPrivateProfileString,addr szRADebugBP,addr szbp[1],addr szNULL,addr buffer,sizeof buffer,[eax].ADDINDATA.lpProject
		lea		esi,buffer
		.while byte ptr [esi]
			mov		edx,esi
			.while byte ptr [esi]!=',' && byte ptr [esi]
				inc		esi
			.endw
			.if byte ptr [esi]==','
				mov		byte ptr [esi],0
				inc		esi
			.endif
			.if esi!=edx
				invoke DecToBin,edx
				invoke SendMessage,hREd,REM_SETBREAKPOINT,eax,TRUE
			.endif
		.endw
	.endif
	ret

LoadBreakPoints endp

LoadAllBreakPoints proc uses esi edi
	LOCAL	hMem:HGLOBAL
	LOCAL	ProjectFileID:DWORD
	LOCAL	nCount:DWORD

	invoke RtlZeroMemory,offset breakpoint,sizeof breakpoint
	invoke GlobalAlloc,GMEM_FIXED,32768
	.if eax
		mov		hMem,eax
		mov		eax,lpData
		invoke GetPrivateProfileSection,addr szRADebugBP,hMem,32768,[eax].ADDINDATA.lpProject
		mov		nCount,512
		mov		esi,hMem
		mov		edi,offset breakpoint
		.while byte ptr [esi] && nCount
			call	GetBP
		.endw
	.endif
	ret

GetBP:
	mov		edx,esi
	.while byte ptr [esi]!='='
		inc		esi
	.endw
	mov		byte ptr [esi],0
	inc		esi
	invoke DecToBin,edx
	mov		ProjectFileID,eax
	.while byte ptr [esi] && nCount
		mov		edx,esi
		.while byte ptr [esi]!=',' && byte ptr [esi]
			inc		esi
		.endw
		.if byte ptr [esi]==','
			mov		byte ptr [esi],0
			inc		esi
		.endif
		.if esi!=edx
			invoke DecToBin,edx
			mov		[edi].BREAKPOINT.LineNumber,eax
			mov		eax,ProjectFileID
			mov		[edi].BREAKPOINT.ProjectFileID,eax
			add		edi,sizeof BREAKPOINT
			dec		nCount
		.endif
	.endw
	inc		esi
	retn

LoadAllBreakPoints endp