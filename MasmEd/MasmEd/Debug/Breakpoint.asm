
ID_EDIT							equ	65501

.code

GetFileIDFromProjectFileID proc uses ebx edi,ProjectFileID:DWORD

;	push	ProjectFileID
;	mov		eax,lpProc
;	call	[eax].ADDINPROCS.lpGetFileNameFromID
;	.if eax
;		mov		edi,eax
;		mov		ebx,dbg.hMemSource
;		xor		ecx,ecx
;		.while ecx<dbg.inxsource
;			push	ecx
;			invoke strcmpi,edi,addr [ebx].DEBUGSOURCE.FileName
;			.if !eax
;				pop		eax
;				ret
;			.endif
;			pop		ecx
;			inc		ecx
;			add		ebx,sizeof DEBUGSOURCE
;		.endw
;	.endif
	xor		eax,eax
	ret

GetFileIDFromProjectFileID endp

UnsavedFiles proc
	LOCAL	hTab:HWND
	LOCAL	nInx:DWORD
	LOCAL	tci:TCITEM
	LOCAL	hREd:HWND
	LOCAL	Unsaved:DWORD

;	mov		Unsaved,0
;	mov		eax,lpHandles
;	mov		eax,[eax].ADDINHANDLES.hTab
;	mov		hTab,eax
;	mov		tci.imask,TCIF_PARAM
;	mov		nInx,0
;	.while TRUE
;		invoke SendMessage,hTab,TCM_GETITEM,nInx,addr tci
;		.break .if !eax
;		invoke GetWindowLong,tci.lParam,0
;		.if eax==ID_EDIT
;			invoke GetWindowLong,tci.lParam,GWL_USERDATA
;			mov		hREd,eax
;			invoke SendMessage,hREd,EM_GETMODIFY,0,0
;			.if eax
;				inc		Unsaved
;			.endif
;		.endif
;		inc		nInx
;	.endw
	mov		eax,Unsaved
	ret

UnsavedFiles endp

NewerFiles proc
	LOCAL	hTab:HWND
	LOCAL	nInx:DWORD
	LOCAL	tci:TCITEM
	LOCAL	hREd:HWND
	LOCAL	hFile:HANDLE
	LOCAL	ftexe:FILETIME
	LOCAL	ftsource:FILETIME
	LOCAL	Newer:DWORD

	mov		Newer,0
	invoke CreateFile,addr szExeName,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
	.if eax!=INVALID_HANDLE_VALUE
		mov		hFile,eax
		invoke GetFileTime,hFile,NULL,NULL,addr ftexe
		invoke CloseHandle,hFile
;		mov		eax,lpHandles
;		mov		eax,[eax].ADDINHANDLES.hTab
;		mov		hTab,eax
;		mov		tci.imask,TCIF_PARAM
;		mov		nInx,0
;		.while TRUE
;			invoke SendMessage,hTab,TCM_GETITEM,nInx,addr tci
;			.break .if !eax
;			invoke GetWindowLong,tci.lParam,0
;			.if eax==ID_EDIT
;				mov		eax,lpData
;				invoke strcpy,addr szTempName,[eax].ADDINDATA.lpProjectPath
;				invoke GetWindowLong,tci.lParam,16
;				push	eax
;				mov		eax,lpProc
;				call	[eax].ADDINPROCS.lpGetFileNameFromID
;				invoke strcat,addr szTempName,eax
;				invoke CreateFile,addr szTempName,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
;				.if eax!=INVALID_HANDLE_VALUE
;					mov		hFile,eax
;					invoke GetFileTime,hFile,NULL,NULL,addr ftsource
;					invoke CloseHandle,hFile
;					mov		eax,ftexe.dwLowDateTime
;					sub		eax,ftsource.dwLowDateTime
;					mov		eax,ftexe.dwHighDateTime
;					sbb		eax,ftsource.dwHighDateTime
;					.if CARRY?
;						inc		Newer
;					.endif
;				.endif
;			.endif
;			inc		nInx
;		.endw
	.else
		; File not found
		mov		Newer,-1
	.endif
	mov		eax,Newer
	ret

NewerFiles endp

LockFiles proc fLock:DWORD
	LOCAL	hTab:HWND
	LOCAL	nInx:DWORD
	LOCAL	tci:TCITEM
	LOCAL	hREd:HWND

;	mov		eax,lpHandles
;	mov		eax,[eax].ADDINHANDLES.hTab
;	mov		hTab,eax
;	mov		tci.imask,TCIF_PARAM
;	mov		nInx,0
;	.while TRUE
;		invoke SendMessage,hTab,TCM_GETITEM,nInx,addr tci
;		.break .if !eax
;		invoke GetWindowLong,tci.lParam,0
;		.if eax==ID_EDIT
;			invoke GetWindowLong,tci.lParam,GWL_USERDATA
;			mov		hREd,eax
;			invoke SendMessage,hREd,REM_READONLY,0,fLock
;		.endif
;		inc		nInx
;	.endw
	ret

LockFiles endp

AnyBreakPoints proc uses esi

	mov		esi,offset breakpoint
	mov		ecx,512
	xor		eax,eax
	.while ecx
		.if [esi].BREAKPOINT.FileID
			inc		eax
			ret
		.endif
		inc		ecx
		add		esi,sizeof BREAKPOINT
	.endw
	ret

AnyBreakPoints endp

ClearBreakpoints proc

	invoke RtlZeroMemory,offset breakpoint,sizeof breakpoint
	invoke RtlZeroMemory,offset szBPSourceName,sizeof szBPSourceName
	ret

ClearBreakpoints endp

AddBreakpoint proc uses ebx esi,nLine:DWORD,lpFileName:DWORD

	mov		esi,offset szBPSourceName
	mov		ebx,0
	.while byte ptr [esi]
		invoke strcmpi,esi,lpFileName
		.break .if !eax
		lea		esi,[esi+MAX_PATH]
	.endw
	.if !byte ptr [esi]
		invoke strcpy,esi,lpFileName
	.endif
	mov		esi,offset breakpoint
	.while [esi].BREAKPOINT.FileID
		lea		esi,[esi+sizeof BREAKPOINT]
	.endw
	mov		[esi].BREAKPOINT.FileID,ebx
	mov		eax,nLine
	mov		[esi].BREAKPOINT.LineNumber,eax
	ret

AddBreakpoint endp
