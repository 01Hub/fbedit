
EnableMenu						PROTO
LockFiles						PROTO	:DWORD

THREAD struct
	htread					HANDLE ?				; Thread handle
	threadid				DWORD ?					; Thread ID
	lpthread				DWORD ?					; Pointer to thread creator
	lpline					DWORD ?					; Pointer to line
THREAD ends

DEBUG struct
	hDbgThread				HANDLE ?				; Thread that runs the debugger
	pinfo					PROCESS_INFORMATION <>	; Process information
	dbghand					HANDLE ?				; Handle to read / write process memory
	dbgfile					HANDLE ?				; File handle
	prevline				DWORD ?					; Previous hilited line
	prevhwnd				DWORD ?					; Previous hilited line window handle
	lpthread				DWORD ?					; Pointer to current thread
	thread					THREAD 32 dup(<>)		; Threads
	context					CONTEXT <>				; Context
	prevcontext				CONTEXT <>				; Previous Context
DEBUG ends

.const

szBP							db 0CCh
szDump							db 'Reg     Hex       Dec',0Dh,'-------------------------------',0Dh,0
szDec							db '  %u',0Dh,0
szRegs							db 'EAX     ',0,'ECX     ',0,'EDX     ',0,'EBX     ',0,'ESP     ',0,'EBP     ',0,'ESI     ',0,'EDI     ',0,'EIP     ',0,'EFL     ',0

.data?

dbg								DEBUG <>

.code

ShowContext proc uses ebx esi edi
	LOCAL	buffer[256]:BYTE
	LOCAL	hOut2:HWND
	LOCAL	nLine:DWORD

	mov		eax,lpHandles
	mov		eax,[eax].ADDINHANDLES.hOut2
	mov		hOut2,eax
	invoke SetWindowText,hOut2,addr szNULL
	invoke SendMessage,hOut2,EM_REPLACESEL,FALSE,addr szDump
	mov		nLine,2
	mov		esi,offset szRegs
	mov		ebx,dbg.context.regEax
	mov		edi,dbg.prevcontext.regEax
	call	RegOut
	mov		ebx,dbg.context.regEcx
	mov		edi,dbg.prevcontext.regEcx
	call	RegOut
	mov		ebx,dbg.context.regEdx
	mov		edi,dbg.prevcontext.regEdx
	call	RegOut
	mov		ebx,dbg.context.regEbx
	mov		edi,dbg.prevcontext.regEbx
	call	RegOut
	mov		ebx,dbg.context.regEsp
	mov		edi,dbg.prevcontext.regEsp
	call	RegOut
	mov		ebx,dbg.context.regEbp
	mov		edi,dbg.prevcontext.regEbp
	call	RegOut
	mov		ebx,dbg.context.regEsi
	mov		edi,dbg.prevcontext.regEsi
	call	RegOut
	mov		ebx,dbg.context.regEdi
	mov		edi,dbg.prevcontext.regEdi
	call	RegOut
	mov		ebx,dbg.context.regEip
	mov		edi,dbg.prevcontext.regEip
	call	RegOut
	mov		ebx,dbg.context.regFlag
	mov		edi,dbg.prevcontext.regFlag
	call	RegOut
	invoke RtlMoveMemory,addr dbg.prevcontext,addr dbg.context,sizeof CONTEXT
	ret

RegOut:
	invoke lstrcpy,addr buffer,esi
;	invoke SendMessage,hOut2,EM_REPLACESEL,FALSE,esi
	invoke HexDWORD,addr buffer[8],ebx
	invoke wsprintf,addr buffer[16],addr szDec,ebx
	invoke SendMessage,hOut2,EM_REPLACESEL,FALSE,addr buffer
	.if ebx!=edi
		invoke SendMessage,hOut2,REM_LINEREDTEXT,nLine,TRUE
	.endif
	invoke lstrlen,esi
	lea		esi,[esi+eax+1]
	inc		nLine
	retn

ShowContext endp

PrintSourceByte proc Address:DWORD,SourceByte:DWORD,File:DWORD
	LOCAL	buffer[256]:BYTE

	invoke wsprintf,addr buffer,addr szSourceByte,Address,SourceByte,File
	invoke PutString,addr buffer
	ret

PrintSourceByte endp

MapBreakPoints proc uses ebx esi edi
	LOCAL	CountBP:DWORD
	LOCAL	CountSource:DWORD
	LOCAL	Unhandled:DWORD

	mov		Unhandled,0
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
	mov		eax,Unhandled
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
			inc		Unhandled
			xor		ecx,ecx
			.while ecx<inxline
				.if eax==[esi].DEBUGLINE.LineNumber
					.if edx==[esi].DEBUGLINE.FileID
						mov		[esi].DEBUGLINE.BreakPoint,TRUE
						dec		Unhandled
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
			;movzx		eax,[edi].DEBUGLINE.SourceByte
			;invoke PrintSourceByte,[edi].DEBUGLINE.Address,eax,[edi].DEBUGLINE.FileID
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

SetBreakpointAtCurrentLine proc uses ebx esi edi
	LOCAL	chrg:CHARRANGE
	LOCAL	nLine:DWORD
	LOCAL	CountSource:DWORD

	mov		ebx,lpHandles
	; Get current line
	invoke SendMessage,[ebx].ADDINHANDLES.hEdit,EM_EXGETSEL,0,addr chrg
	invoke SendMessage,[ebx].ADDINHANDLES.hEdit,EM_LINEFROMCHAR,chrg.cpMin,0
	inc		eax
	mov		nLine,eax
	; Get project file ID
	invoke GetWindowLong,[ebx].ADDINHANDLES.hMdiCld,16
	push	eax
	mov		eax,lpProc
	call	[eax].ADDINPROCS.lpGetFileNameFromID
	mov		edi,eax
	mov		eax,inxsource
	mov		CountSource,eax
	mov		ebx,offset dbgsource
	.while CountSource
		invoke lstrcmpi,edi,addr [ebx].DEBUGSOURCE.FileName
		.if !eax
			mov		edx,[ebx].DEBUGSOURCE.FileID
			mov		eax,nLine		;LineNumber
			mov		esi,offset dbgline
			xor		ecx,ecx
			.while ecx<inxline
				.if eax==[esi].DEBUGLINE.LineNumber
					.if edx==[esi].DEBUGLINE.FileID
						.if [esi].DEBUGLINE.SourceByte==-1
							mov		[esi].DEBUGLINE.SourceByte,0
							invoke ReadProcessMemory,dbg.dbghand,[esi].DEBUGLINE.Address,addr [esi].DEBUGLINE.SourceByte,1,0
							invoke WriteProcessMemory,dbg.dbghand,[esi].DEBUGLINE.Address,addr szBP,1,0
						.endif
						jmp		Ex
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
Ex:
	ret

SetBreakpointAtCurrentLine endp

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
	.if edi
		.if [edi].DEBUGLINE.SourceByte!=-1
			invoke WriteProcessMemory,dbg.dbghand,[edi].DEBUGLINE.Address,addr [edi].DEBUGLINE.SourceByte,1,0
			mov		[edi].DEBUGLINE.SourceByte,-1
		.endif
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

ResumeAllThreads proc uses ebx

	lea		ebx,dbg.thread
	.while [ebx].THREAD.htread
		invoke ResumeThread,[ebx].THREAD.htread
		add		ebx,sizeof THREAD
	.endw
	ret

ResumeAllThreads endp

Debug proc uses ebx,lpFileName:DWORD
	LOCAL	sinfo:STARTUPINFO
	LOCAL	de:DEBUG_EVENT
	LOCAL	fContinue:DWORD
	LOCAL	buffer[256]:BYTE
	LOCAL	Old:BYTE

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
		.if !inxline
			invoke PutString,addr szNoDebugInfo
		.endif
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
		invoke MapBreakPoints
		.if eax
			invoke wsprintf,addr buffer,addr szUnhanfledBreakpoints,eax
			mov		edx,lpHandles
			invoke MessageBox,[edx].ADDINHANDLES.hWnd,addr buffer,addr szDebug,MB_OK or MB_ICONEXCLAMATION
		.endif
		invoke SetBreakPoints
		lea		ebx,dbg.thread
		mov		dbg.lpthread,ebx
		mov		eax,dbg.pinfo.hThread
		mov		[ebx].THREAD.htread,eax
		mov		eax,dbg.pinfo.dwThreadId
		mov		[ebx].THREAD.threadid,eax
		mov		[ebx].THREAD.lpthread,0
		.while TRUE
			invoke WaitForDebugEvent,addr de,INFINITE
			mov		fContinue,DBG_CONTINUE
			mov		eax,de.dwDebugEventCode
			.if eax==EXCEPTION_DEBUG_EVENT
				;invoke PutString,addr szEXCEPTION_DEBUG_EVENT
				mov		eax,de.u.Exception.pExceptionRecord.ExceptionCode
				.if eax==EXCEPTION_BREAKPOINT
					.if de.u.Exception.pExceptionRecord.ExceptionAddress<800000h
						lea		ebx,dbg.thread
						mov		eax,de.dwThreadId
						.while [ebx].THREAD.htread
							.if eax==[ebx].THREAD.threadid
								.break
							.endif
							add		ebx,sizeof THREAD
						.endw
						mov		dbg.lpthread,ebx
						invoke FindLine,de.u.Exception.pExceptionRecord.ExceptionAddress
						mov		[ebx].THREAD.lpline,eax
						.if eax
							invoke SelectLine,eax
						.endif
						;invoke PutString,addr szEXCEPTION_BREAKPOINT
						;PrintHex de.u.Exception.pExceptionRecord.ExceptionAddress
						invoke SuspendThread,[ebx].THREAD.htread
						mov		dbg.context.ContextFlags,CONTEXT_FULL;CONTEXT_CONTROL
						invoke GetThreadContext,[ebx].THREAD.htread,addr dbg.context
						mov		eax,de.u.Exception.pExceptionRecord.ExceptionAddress
						mov		dbg.context.regEip,eax
						invoke SetThreadContext,[ebx].THREAD.htread,addr dbg.context
						invoke ShowContext
					.else
						;invoke PutString,addr szEXCEPTION_BREAKPOINT
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
					;movzx		eax,Old
					;invoke PrintSourceByte,de.u.Exception.pExceptionRecord.ExceptionAddress,eax
					mov		fContinue,DBG_EXCEPTION_NOT_HANDLED
				.endif
			.elseif eax==CREATE_PROCESS_DEBUG_EVENT
				invoke PutString,addr szCREATE_PROCESS_DEBUG_EVENT
				mov		eax,de.u.CreateProcessInfo.hFile
				mov		dbg.dbgfile,eax
			.elseif eax==CREATE_THREAD_DEBUG_EVENT
				invoke PutString,addr szCREATE_THREAD_DEBUG_EVENT
				mov		ebx,dbg.lpthread
				mov		eax,ebx
				lea		ebx,dbg.thread
				.while [ebx].THREAD.htread
					add		ebx,sizeof THREAD
				.endw
				mov		[ebx].THREAD.lpthread,eax
				mov		eax,de.u.CreateThread.hThread
				mov		[ebx].THREAD.htread,eax
				mov		eax,de.dwThreadId
				mov		[ebx].THREAD.threadid,eax
				invoke SuspendThread,de.u.CreateThread.hThread
			.elseif eax==EXIT_THREAD_DEBUG_EVENT
				invoke PutString,addr szEXIT_THREAD_DEBUG_EVENT
				mov		edx,dbg.lpthread
				lea		ecx,[edx+sizeof THREAD]
				.while [ecx].THREAD.htread
					mov		eax,[ecx].THREAD.htread
					mov		[edx].THREAD.htread,eax
					mov		eax,[ecx].THREAD.threadid
					mov		[edx].THREAD.threadid,eax
					mov		eax,[ecx].THREAD.lpthread
					mov		[edx].THREAD.lpthread,eax
					mov		eax,[ecx].THREAD.lpline
					mov		[edx].THREAD.lpline,eax
					add		ecx,sizeof THREAD
					add		edx,sizeof THREAD
				.endw
				xor		eax,eax
				mov		[edx].THREAD.htread,eax
				mov		[edx].THREAD.threadid,eax
				mov		[edx].THREAD.lpthread,eax
				mov		[edx].THREAD.lpline,eax
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
				movzx	eax,de.u.DebugString.nDebugStringiLength
				invoke ReadProcessMemory,dbg.dbghand,de.u.DebugString.lpDebugStringData,addr buffer,eax,0
				invoke PutString,addr buffer
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
