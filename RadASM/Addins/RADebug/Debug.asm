
EnableMenu			PROTO
LockFiles			PROTO	:DWORD

THREAD struct
	htread			HANDLE ?
	lpline			DWORD ?
	threadid		DWORD ?
	htreadcaller	HANDLE ?
THREAD ends

DEBUG struct
	hDbgThread		HANDLE ?					; Thread that runs the debugger
	pinfo			PROCESS_INFORMATION <>		; Process information
	dbghand			HANDLE ?					; Handle to read / write process memory
	dbgfile			HANDLE ?					; File handle
	lpline			DWORD ?						; Pointer to current line
	prevline		DWORD ?						; Previous hilited line
	prevhwnd		DWORD ?						; Previous hilited line window handle
	lpthread		DWORD ?						; Pointer to current thread
	thread			THREAD 32 dup(<>)
DEBUG ends

.const

szBP				db 0CCh

.data?

dbg				DEBUG <>

.code

PrintSourceByte proc Address:DWORD,SourceByte:DWORD,File:DWORD
	LOCAL	buffer[256]:BYTE

	invoke wsprintf,addr buffer,addr szSourceByte,Address,SourceByte,File
	invoke PutString,addr buffer
	ret

PrintSourceByte endp

MapBreakPoints proc uses ebx esi edi
	LOCAL	CountBP:DWORD
	LOCAL	CountSource:DWORD

	mov		CountBP,512
	mov		esi,offset breakpoint
	.while CountBP
		mov		eax,[esi].BREAKPOINT.ProjectFileID
		.if eax
			push	esi
			push	eax
			mov		eax,lpProc
			call	[eax].ADDINPROCS.lpGetFileNameFromID
			call	MatchIt
			pop		esi
		.endif
		dec		CountBP
		add		esi,sizeof BREAKPOINT
	.endw
	ret

MatchIt:
	mov		edi,eax
	mov		eax,inxsource
	mov		CountSource,eax
	mov		ebx,offset dbgsource
	.while CountSource
		invoke lstrcmpi,edi,addr [ebx].DEBUGSOURCE.FileName
		.if !eax
			mov		edx,[ebx].DEBUGSOURCE.FileID
			mov		eax,[esi].BREAKPOINT.LineNumber
			inc		eax		;LineNumber
			mov		esi,offset dbgline
			xor		ecx,ecx
			.while ecx<inxline
				.if eax==[esi].DEBUGLINE.LineNumber
					.if edx==[esi].DEBUGLINE.FileID
						mov		[esi].DEBUGLINE.BreakPoint,TRUE
						.break
					.endif
				.endif
				inc		ecx
				add		esi,sizeof DEBUGLINE
			.endw
			.break
		.endif
		dec		CountSource
		add		ebx,sizeof DEBUGSOURCE
	.endw
	retn

MapBreakPoints endp

SetBreakPointsAll proc uses ebx edi

	mov		edi,offset dbgline
	xor		ebx,ebx
	.while ebx<inxline
		.if [edi].DEBUGLINE.SourceByte==-1
			mov		[edi].DEBUGLINE.SourceByte,0
			invoke ReadProcessMemory,dbg.dbghand,[edi].DEBUGLINE.Address,addr [edi].DEBUGLINE.SourceByte,1,0
			invoke WriteProcessMemory,dbg.dbghand,[edi].DEBUGLINE.Address,addr szBP,1,0
;			movzx		eax,[edi].DEBUGLINE.SourceByte
;			invoke PrintSourceByte,[edi].DEBUGLINE.Address,eax,[edi].DEBUGLINE.FileID
		.endif
		add		edi,sizeof DEBUGLINE
		inc		ebx
	.endw
	ret

SetBreakPointsAll endp

SetBreakPoints proc uses ebx edi

	mov		edi,offset dbgline
	xor		ebx,ebx
	.while ebx<inxline
		.if [edi].DEBUGLINE.SourceByte==-1 && [edi].DEBUGLINE.BreakPoint==TRUE
			mov		[edi].DEBUGLINE.SourceByte,0
			invoke ReadProcessMemory,dbg.dbghand,[edi].DEBUGLINE.Address,addr [edi].DEBUGLINE.SourceByte,1,0
			invoke WriteProcessMemory,dbg.dbghand,[edi].DEBUGLINE.Address,addr szBP,1,0
			;movzx		eax,[edi].DEBUGLINE.SourceByte
			;invoke PrintSourceByte,[edi].DEBUGLINE.Address,eax
		.endif
		add		edi,sizeof DEBUGLINE
		inc		ebx
	.endw
	ret

SetBreakPoints endp

ClearBreakPointsAll proc uses ebx edi

	mov		edi,offset dbgline
	xor		ebx,ebx
	.while ebx<inxline
		.if [edi].DEBUGLINE.SourceByte!=-1
			invoke WriteProcessMemory,dbg.dbghand,[edi].DEBUGLINE.Address,addr [edi].DEBUGLINE.SourceByte,1,0
			mov		[edi].DEBUGLINE.SourceByte,-1
		.endif
		add		edi,sizeof DEBUGLINE
		inc		ebx
	.endw
	ret

ClearBreakPointsAll endp

RestoreSourceByte proc uses ebx edi,lpLine:DWORD

	mov		edi,lpLine
	.if [edi].DEBUGLINE.SourceByte!=-1
		invoke WriteProcessMemory,dbg.dbghand,[edi].DEBUGLINE.Address,addr [edi].DEBUGLINE.SourceByte,1,0
		mov		[edi].DEBUGLINE.SourceByte,-1
	.endif
	ret

RestoreSourceByte endp

FindLine proc uses ebx edi,Address:DWORD

	mov		edi,offset dbgline
	mov		eax,Address
	xor		ebx,ebx
	.while ebx<inxline
		.if eax==[edi].DEBUGLINE.Address
			mov		eax,edi
			jmp		Ex
		.endif
		add		edi,sizeof DEBUGLINE
		inc		ebx
	.endw
	xor		eax,eax
  Ex:
	mov		dbg.lpline,eax
	ret

FindLine endp

SelectLine proc uses ebx esi edi,lpDEBUGLINE:DWORD
	LOCAL	chrg:CHARRANGE

	mov		edi,lpHandles
	mov		ebx,lpDEBUGLINE
	.if dbg.prevline!=-1
		invoke SendMessage,dbg.prevhwnd,REM_SETHILITELINE,dbg.prevline,0
	.endif
	mov		eax,[ebx].DEBUGLINE.LineNumber
	dec		eax
	mov		dbg.prevline,eax
	mov		eax,[ebx].DEBUGLINE.FileID
	mov		edx,sizeof DEBUGSOURCE
	mul		edx
	lea		esi,[eax+offset dbgsource]
	mov		edx,lpData
	invoke lstrcpy,addr szSourceName,[edx].ADDINDATA.lpProjectPath
	invoke lstrcat,addr szSourceName,addr [esi].DEBUGSOURCE.FileName
	invoke PostMessage,[edi].ADDINHANDLES.hWnd,WM_USER+998,0,addr szSourceName
	invoke WaitForSingleObject,dbg.pinfo.hProcess,100
	mov		eax,[edi].ADDINHANDLES.hEdit
	mov		dbg.prevhwnd,eax
	invoke SendMessage,dbg.prevhwnd,EM_LINEINDEX,dbg.prevline,0
	mov		chrg.cpMin,eax
	mov		chrg.cpMax,eax
	invoke SendMessage,dbg.prevhwnd,EM_EXSETSEL,0,addr chrg
	invoke SendMessage,dbg.prevhwnd,EM_SCROLLCARET,0,0
	invoke SetForegroundWindow,[edi].ADDINHANDLES.hWnd
	invoke SetFocus,dbg.prevhwnd
	invoke SendMessage,dbg.prevhwnd,REM_SETHILITELINE,dbg.prevline,1
	ret

SelectLine endp

Debug proc uses ebx,lpFileName:DWORD
	LOCAL	sinfo:STARTUPINFO
	LOCAL	de:DEBUG_EVENT
	LOCAL	fContinue:DWORD
	LOCAL	buffer[256]:BYTE
	LOCAL	Old:BYTE
	LOCAL	context:CONTEXT

	invoke RtlZeroMemory,addr sinfo,sizeof STARTUPINFO
	mov		sinfo.cb,SizeOf STARTUPINFO
	mov		sinfo.dwFlags,STARTF_USESHOWWINDOW
	mov		sinfo.wShowWindow,SW_NORMAL
	;Create process
	invoke CreateProcess,NULL,lpFileName,NULL,NULL,FALSE,NORMAL_PRIORITY_CLASS Or DEBUG_PROCESS Or DEBUG_ONLY_THIS_PROCESS,NULL,NULL,addr sinfo,addr dbg.pinfo
	.if eax
		invoke WaitForSingleObject,dbg.pinfo.hProcess,10
		invoke OpenProcess,PROCESS_ALL_ACCESS,TRUE,dbg.pinfo.dwProcessId
		mov		dbg.dbghand,eax
		invoke DbgHelp,dbg.pinfo.hProcess,lpFileName
;		mov		edx,offset dbgsource
;		xor		ecx,ecx
;		.while ecx<inxsource
;			push	ecx
;			push	edx
;			invoke PutString,addr [edx].DEBUGSOURCE.FileName
;			pop		edx
;			pop		ecx
;			add		edx,sizeof DEBUGSOURCE
;			inc		ecx
;		.endw
;		mov		edx,offset dbgline
;		xor		ecx,ecx
;		.while ecx<inxline
;			push	ecx
;			push	edx
;			PrintHex [edx].DEBUGLINE.Address
;			pop		edx
;			pop		ecx
;			add		edx,sizeof DEBUGLINE
;			inc		ecx
;		.endw
;		mov		dbgdump,400000h
;		.while eax
;			invoke Dump,dbgdump
;			.if eax
;				add		dbgdump,256
;			.endif
;		.endw
		mov		dbg.prevline,-1
		mov		dbg.lpline,0
		invoke MapBreakPoints
		invoke SetBreakPoints
		lea		edx,dbg.thread
		mov		dbg.lpthread,edx
		mov		eax,dbg.pinfo.hThread
		mov		dbg.thread.htread,eax
		mov		eax,dbg.pinfo.dwThreadId
		mov		dbg.thread.threadid,eax
		mov		dbg.thread.htreadcaller,0
		.while TRUE
			invoke WaitForDebugEvent,addr de,INFINITE
			mov		fContinue,DBG_CONTINUE
			mov		eax,de.dwDebugEventCode
			.if eax==EXCEPTION_DEBUG_EVENT
				;invoke PutString,addr szEXCEPTION_DEBUG_EVENT
				mov		eax,de.u.Exception.pExceptionRecord.ExceptionCode
				.if eax==EXCEPTION_BREAKPOINT
					.if de.u.Exception.pExceptionRecord.ExceptionAddress<800000h
						invoke FindLine,de.u.Exception.pExceptionRecord.ExceptionAddress
						.if eax
							invoke SelectLine,eax
						.endif
						lea		ebx,dbg.thread
						mov		eax,de.dwThreadId
						.while [ebx].THREAD.htread
							.if eax==[ebx].THREAD.threadid
								.break
							.endif
							add		ebx,sizeof THREAD
						.endw
						mov		dbg.lpthread,ebx
						mov		eax,dbg.lpline
						mov		[ebx].THREAD.lpline,eax
						;invoke PutString,addr szEXCEPTION_BREAKPOINT
;						PrintHex de.u.Exception.pExceptionRecord.ExceptionAddress
						mov		context.ContextFlags,CONTEXT_CONTROL
						invoke GetThreadContext,[ebx].THREAD.htread,addr context
						mov		eax,de.u.Exception.pExceptionRecord.ExceptionAddress
						mov		context.regEip,eax
						invoke SetThreadContext,[ebx].THREAD.htread,addr context
						invoke SuspendThread,[ebx].THREAD.htread
					.else
						invoke PutString,addr szEXCEPTION_BREAKPOINT
						mov		fContinue,DBG_EXCEPTION_NOT_HANDLED
					.endif
				.elseif eax==EXCEPTION_ACCESS_VIOLATION
					invoke PutString,addr szEXCEPTION_ACCESS_VIOLATION
					mov		fContinue,DBG_EXCEPTION_NOT_HANDLED
				.elseif eax==EXCEPTION_FLT_DIVIDE_BY_ZERO
					mov		fContinue,DBG_EXCEPTION_NOT_HANDLED
				.elseif eax==EXCEPTION_INT_DIVIDE_BY_ZERO
					mov		fContinue,DBG_EXCEPTION_NOT_HANDLED
				.elseif eax==EXCEPTION_DATATYPE_MISALIGNMENT
					mov		fContinue,DBG_EXCEPTION_NOT_HANDLED
				.elseif eax==EXCEPTION_SINGLE_STEP
					mov		fContinue,DBG_EXCEPTION_NOT_HANDLED
				.elseif eax==DBG_CONTROL_C
				.else
					invoke ReadProcessMemory,dbg.dbghand,de.u.Exception.pExceptionRecord.ExceptionAddress,addr Old,1,0
;					movzx		eax,Old
;					invoke PrintSourceByte,de.u.Exception.pExceptionRecord.ExceptionAddress,eax
					mov		fContinue,DBG_EXCEPTION_NOT_HANDLED
				.endif
			.elseif eax==CREATE_PROCESS_DEBUG_EVENT
				invoke PutString,addr szCREATE_PROCESS_DEBUG_EVENT
				mov		eax,de.u.CreateProcessInfo.hFile
				mov		dbg.dbgfile,eax
			.elseif eax==CREATE_THREAD_DEBUG_EVENT
				invoke PutString,addr szCREATE_THREAD_DEBUG_EVENT
				invoke SuspendThread,de.u.CreateThread.hThread
				mov		edx,dbg.lpthread
				mov		eax,[edx].THREAD.htread
				add		edx,sizeof THREAD
				mov		[edx].THREAD.htreadcaller,eax
				mov		eax,de.u.CreateThread.hThread
				mov		[edx].THREAD.htread,eax
				mov		eax,de.dwThreadId
				mov		[edx].THREAD.threadid,eax
				mov		dbg.lpthread,edx
			.elseif eax==EXIT_THREAD_DEBUG_EVENT
				invoke PutString,addr szEXIT_THREAD_DEBUG_EVENT
				mov		edx,dbg.lpthread
				mov		[edx].THREAD.htread,0
				mov		eax,[edx].THREAD.htreadcaller
				sub		dbg.lpthread,sizeof THREAD
				invoke ResumeThread,eax
			.elseif eax==EXIT_PROCESS_DEBUG_EVENT
				invoke PutString,addr szEXIT_PROCESS_DEBUG_EVENT
				invoke ContinueDebugEvent,de.dwProcessId,de.dwThreadId,DBG_CONTINUE
				.break
			.elseif eax==LOAD_DLL_DEBUG_EVENT
				mov		buffer,0
				;invoke GetModuleFileName,de.LoadDll.lpBaseOfDll,addr buffer,256
				invoke PutString,addr szLOAD_DLL_DEBUG_EVENT
				;invoke PutString,addr buffer
			.elseif eax==UNLOAD_DLL_DEBUG_EVENT
				mov		buffer,0
				;invoke GetModuleFileName,de.UnloadDll.lpBaseOfDll,addr buffer,256
				invoke PutString,addr szUNLOAD_DLL_DEBUG_EVENT
				;invoke PutString,addr buffer
			.elseif eax==OUTPUT_DEBUG_STRING_EVENT
				invoke PutString,addr szOUTPUT_DEBUG_STRING_EVENT
;				nln=de.DebugString.nDebugStringLength
;				If nln>255 Then
;					nln=255
;				EndIf
;				lret=ReadProcessMemory(dbghand,de.DebugString.lpDebugStringData,@buffer,nln,0)
;				PutString(@buffer)
			.elseif eax==RIP_EVENT
				invoke PutString,addr szRIP_EVENT
			.endif
			invoke ContinueDebugEvent,de.dwProcessId,de.dwThreadId,fContinue
		.endw
		invoke CloseHandle,dbg.dbgfile
		invoke CloseHandle,dbg.dbghand
		invoke CloseHandle,dbg.pinfo.hThread
		invoke CloseHandle,dbg.pinfo.hProcess
	.endif
	invoke CloseHandle,dbg.hDbgThread
	mov		dbg.hDbgThread,0
	.if dbg.prevline!=-1
		invoke SendMessage,dbg.prevhwnd,REM_SETHILITELINE,dbg.prevline,0
	.endif
	invoke EnableMenu
	invoke LockFiles,FALSE
	invoke PutString,addr szDebugStopped
	ret

Debug endp
