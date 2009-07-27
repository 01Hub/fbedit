
EnableMenu						PROTO
LockFiles						PROTO	:DWORD

.const

szBP							db 0CCh
szDump							db 'Reg     Hex                 Dec',0Dh,
								   '-------------------------------',0Dh,0
szDec							db '%d',0Dh,0
szRegs							db 'EAX     ',0,
								   'ECX     ',0,
								   'EDX     ',0,
								   'EBX     ',0,
								   'ESP     ',0,
								   'EBP     ',0,
								   'ESI     ',0,
								   'EDI     ',0,
								   'EIP     ',0,
								   'EFL     ',0

szDecSpace						db '                ',0

.data?

szContext						db 1024 dup(?)
LineChanged						dd 32 dup(?)

.code

ShowContext proc uses ebx esi edi
	LOCAL	buffer[256]:BYTE
	LOCAL	decbuff[32]:BYTE
	LOCAL	nLine:DWORD
	LOCAL	szContextPtr:DWORD
	LOCAL	LineChangedInx:DWORD

	mov		szContextPtr,offset szContext
	mov		LineChangedInx,0
	mov		LineChanged,0
	mov		eax,offset szDump
	call	AddText
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
	invoke SetWindowText,hOut,addr szContext
	mov		ebx,offset LineChanged
	.while dword ptr [ebx]
		invoke SendMessage,hOut,REM_LINEREDTEXT,[ebx],TRUE
		lea		ebx,[ebx+4]
	.endw
	ret

AddText:
	invoke strcpy,szContextPtr,eax
	invoke strlen,szContextPtr
	add		szContextPtr,eax
	retn

RegOut:
	invoke strcpy,addr buffer,esi
	invoke HexDWORD,addr buffer[8],ebx
	invoke strcat,addr buffer,addr szDecSpace
	invoke wsprintf,addr decbuff,addr szDec,ebx
	invoke strlen,addr decbuff
	mov		edx,15
	sub		edx,eax
	invoke strcpy,addr buffer[edx+17],addr decbuff
	lea		eax,buffer
	call	AddText
	.if ebx!=edi
		mov		edx,LineChangedInx
		lea		edx,[edx*4+offset LineChanged]
		mov		eax,nLine
		mov		[edx],eax
		mov		dword ptr [edx+4],0
		inc		LineChangedInx
	.endif
	invoke strlen,esi
	lea		esi,[esi+eax+1]
	inc		nLine
	retn

ShowContext endp

MapBreakPoints proc uses ebx esi edi
	LOCAL	CountBP:DWORD
	LOCAL	CountSource:DWORD
	LOCAL	Unhandled:DWORD

	mov		Unhandled,0
	mov		CountBP,512
	mov		esi,offset breakpoint
	.while CountBP
		mov		eax,[esi].BREAKPOINT.LineNumber
		.if eax
			push	esi
			call	MatchIt
			pop		esi
		.endif
		dec		CountBP
		add		esi,sizeof BREAKPOINT
	.endw
	mov		eax,Unhandled
	ret

MatchIt:
	mov		eax,[esi].BREAKPOINT.FileID
	mov		edx,MAX_PATH
	mul		edx
	mov		edi,offset szBPSourceName
	lea		edi,[edi+eax]
	mov		eax,dbg.inxsource
	mov		CountSource,eax
	mov		ebx,dbg.hMemSource
	.while CountSource
		invoke strcmpi,edi,addr [ebx].DEBUGSOURCE.FileName
		.if !eax
			mov		edx,[ebx].DEBUGSOURCE.FileID
			mov		eax,[esi].BREAKPOINT.LineNumber
			mov		esi,dbg.hMemLine
			inc		Unhandled
			xor		ecx,ecx
			.while ecx<dbg.inxline
				.if eax==[esi].DEBUGLINE.LineNumber
					.if dx==[esi].DEBUGLINE.FileID
						.if [esi].DEBUGLINE.NoDebug==0
							mov		[esi].DEBUGLINE.BreakPoint,TRUE
							dec		Unhandled
						.endif
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

MapNoDebug proc uses ebx esi edi
	LOCAL	buffer[256]:BYTE
	LOCAL	buffer1[8]:BYTE
	LOCAL	nInx:DWORD

;	mov		edi,dbg.hMemSymbol
;	mov		ebx,dbg.inxsymbol
;	xor		eax,eax
;	.while ebx
;		mov		[edi].DEBUGSYMBOL.NoDebug,ax
;		dec		ebx
;		add		edi,sizeof DEBUGSYMBOL
;	.endw
;	mov		ecx,dbg.inxline
;	mov		esi,dbg.hMemLine
;	.while ecx
;		mov		[esi].DEBUGLINE.NoDebug,al
;		dec		ecx
;		lea		esi,[esi+sizeof DEBUGLINE]
;	.endw
;	; Do not debug the proc line
;	mov		esi,dbg.hMemSymbol
;	mov		ecx,dbg.inxsymbol
;	.while ecx
;		.if [esi].DEBUGSYMBOL.nType=='p'
;			mov		eax,[esi].DEBUGSYMBOL.Address
;			mov		ebx,dbg.inxline
;			mov		edi,dbg.hMemLine
;			.while ebx
;				.if eax==[edi].DEBUGLINE.Address
;					mov		[edi].DEBUGLINE.NoDebug,TRUE
;					.break
;				.endif
;				dec		ebx
;				lea		edi,[edi+sizeof DEBUGLINE]
;			.endw
;		.endif
;		dec		ecx
;		lea		esi,[esi+sizeof DEBUGSYMBOL]
;	.endw
;	; Map procs that sould not be debugged
;	mov		nInx,0
;	.while TRUE
;		invoke wsprintf,addr buffer1,addr szCommaBP[1],nInx
;		mov		eax,lpData
;		invoke GetPrivateProfileString,addr szNoDebug,addr buffer1,addr szNULL,addr buffer,sizeof buffer,[eax].ADDINDATA.lpProject
;		.break .if !eax
;		mov		edi,dbg.hMemSymbol
;		mov		ebx,dbg.inxsymbol
;		.while ebx
;			invoke strcmp,addr buffer,addr [edi].DEBUGSYMBOL.szName
;			.if !eax
;				mov		[edi].DEBUGSYMBOL.NoDebug,1
;				mov		edx,[edi].DEBUGSYMBOL.Address
;				mov		eax,edx
;				add		edx,[edi].DEBUGSYMBOL.nSize
;				mov		ecx,dbg.inxline
;				mov		esi,dbg.hMemLine
;				.while ecx
;					.if [esi].DEBUGLINE.Address>=eax
;						.if [esi].DEBUGLINE.Address<edx
;							mov		[esi].DEBUGLINE.NoDebug,1
;						.endif
;					.endif
;					dec		ecx
;					lea		esi,[esi+sizeof DEBUGLINE]
;				.endw
;				.break
;			.endif
;			dec		ebx
;			lea		edi,[edi+sizeof DEBUGSYMBOL]
;		.endw
;		inc		nInx
;	.endw
	ret

MapNoDebug endp

RestoreSourceByte proc uses ebx edi,Address:DWORD
	
	mov		eax,Address
	.if eax
		call	Restore
	.else
		lea		ebx,dbg.thread
		.while [ebx].DEBUGTHREAD.htread
			mov		eax,[ebx].DEBUGTHREAD.address
			.if eax
				call	Restore
			.endif
			lea		ebx,[ebx+sizeof DEBUGTHREAD]
		.endw
	.endif
	ret

Restore:
	mov		edi,dbg.hMemNoBP
	add		edi,eax
	sub		edi,dbg.minadr
	invoke WriteProcessMemory,dbg.hdbghand,eax,edi,1,0
	retn

RestoreSourceByte endp

SetBreakPointsAll proc

	;Step Into
	mov		edx,dbg.minadr
	mov		ecx,dbg.maxadr
	sub		ecx,edx
	invoke WriteProcessMemory,dbg.hdbghand,edx,dbg.hMemBP,ecx,0
	ret

SetBreakPointsAll endp

SetBreakPoints proc uses ebx edi

	mov		edi,dbg.hMemLine
	mov		ebx,dbg.inxline
	.while ebx
		.if [edi].DEBUGLINE.BreakPoint; && ![edi].DEBUGLINE.NoDebug
			invoke WriteProcessMemory,dbg.hdbghand,[edi].DEBUGLINE.Address,addr szBP,1,0
		.endif
		lea		edi,[edi+sizeof DEBUGLINE]
		dec		ebx
	.endw
	ret

SetBreakPoints endp

SetBreakpointAtCurrentLine proc uses ebx esi edi,nLine:DWORD,lpFileName:DWORD

	mov		edi,dbg.inxsource
	mov		ebx,dbg.hMemSource
	.while edi
		invoke strcmpi,lpFileName,addr [ebx].DEBUGSOURCE.FileName
		.if !eax
			mov		edx,[ebx].DEBUGSOURCE.FileID
			mov		eax,nLine		;LineNumber
			mov		esi,dbg.hMemLine
			xor		ecx,ecx
			.while ecx<dbg.inxline
				.if eax==[esi].DEBUGLINE.LineNumber
					.if dx==[esi].DEBUGLINE.FileID
						invoke WriteProcessMemory,dbg.hdbghand,[esi].DEBUGLINE.Address,addr szBP,1,0
						jmp		Ex
					.endif
				.endif
				inc		ecx
				add		esi,sizeof DEBUGLINE
			.endw
			.break
		.endif
		dec		edi
		lea		ebx,[ebx+sizeof DEBUGSOURCE]
	.endw
  Ex:
	ret

SetBreakpointAtCurrentLine endp

ClearBreakPointsAll proc

	mov		edx,dbg.minadr
	mov		ecx,dbg.maxadr
	sub		ecx,edx
	invoke WriteProcessMemory,dbg.hdbghand,edx,dbg.hMemNoBP,ecx,0
	ret

ClearBreakPointsAll endp

ResetSelectLine proc

	.if dbg.prevline!=-1
		push	0
		push	0
		push	CB_RESET
		call	lpCallBack
	.endif
	ret

ResetSelectLine endp

SelectLine proc uses ebx esi edi,lpDEBUGLINE:DWORD
	LOCAL	chrg:CHARRANGE

	mov		ebx,lpDEBUGLINE
	movzx	eax,[ebx].DEBUGLINE.FileID
	mov		edx,sizeof DEBUGSOURCE
	mul		edx
	mov		esi,dbg.hMemSource
	lea		esi,[esi+eax]
	lea		eax,[esi].DEBUGSOURCE.FileName
	push	eax
	mov		eax,[ebx].DEBUGLINE.LineNumber
	mov		dbg.prevline,eax
	push	eax
	push	CB_BREAK
	call	lpCallBack
	mov		dbg.prevhwnd,eax
	ret

SelectLine endp

FindThread proc uses ebx,ThreadID:DWORD

	lea		ebx,dbg.thread
	mov		eax,ThreadID
	.while [ebx].DEBUGTHREAD.htread
		.if eax==[ebx].DEBUGTHREAD.threadid
			mov		eax,ebx
			jmp		Ex
		.endif
		add		ebx,sizeof DEBUGTHREAD
	.endw
	xor		eax,eax
  Ex:
	ret

FindThread endp

AddThread proc uses ebx,hThread:HANDLE,ThreadID:DWORD

	lea		ebx,dbg.thread
	.while [ebx].DEBUGTHREAD.htread
		lea		ebx,[ebx+sizeof DEBUGTHREAD]
	.endw
	mov		eax,hThread
	mov		[ebx].DEBUGTHREAD.htread,eax
	mov		eax,ThreadID
	mov		[ebx].DEBUGTHREAD.threadid,eax
	mov		[ebx].DEBUGTHREAD.lpline,0
	mov		[ebx].DEBUGTHREAD.suspended,FALSE
	mov		eax,ebx
	ret

AddThread endp

RemoveThread proc uses esi edi,ThreadID:DWORD

	invoke FindThread,ThreadID
	mov		edi,eax
	lea		esi,[edi+sizeof DEBUGTHREAD]
	.while [edi].DEBUGTHREAD.htread
		mov		ecx,sizeof DEBUGTHREAD
		rep movsb
	.endw
	ret

RemoveThread endp

SwitchThread proc uses ebx

	mov		ebx,dbg.lpthread
	add		ebx,sizeof DEBUGTHREAD
	.while [ebx].DEBUGTHREAD.htread
		.if [ebx].DEBUGTHREAD.suspended
			jmp		Ex
		.endif
		add		ebx,sizeof DEBUGTHREAD
	.endw
	lea		ebx,dbg.thread
  Ex:
	mov		eax,ebx
	ret

SwitchThread endp

IsInProc proc uses esi,Address:DWORD

	mov		esi,dbg.hMemSymbol
	mov		eax,Address
	.while [esi].DEBUGSYMBOL.szName
		.if [esi].DEBUGSYMBOL.nType=='p'
			mov		edx,[esi].DEBUGSYMBOL.Address
			mov		ecx,[esi].DEBUGSYMBOL.nSize
			lea		ecx,[edx+ecx]
			.if eax>=edx && eax<ecx
				mov		eax,esi
				jmp		Ex
			.endif
		.endif
		lea		esi,[esi+sizeof DEBUGSYMBOL]
	.endw
	xor		eax,eax
  Ex:
	ret

IsInProc endp

IsOnBP proc uses esi,Address:DWORD

	mov		esi,dbg.hMemLine
	mov		eax,Address
	invoke FindLine,Address
	movzx	eax,[eax].DEBUGLINE.BreakPoint
	ret

IsOnBP endp

Debug proc uses ebx esi edi,lpFileName:DWORD
	LOCAL	sinfo:STARTUPINFO
	LOCAL	de:DEBUG_EVENT
	LOCAL	fContinue:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE

	invoke RtlZeroMemory,addr sinfo,sizeof STARTUPINFO
	mov		sinfo.cb,SizeOf STARTUPINFO
	mov		sinfo.dwFlags,STARTF_USESHOWWINDOW
	mov		sinfo.wShowWindow,SW_NORMAL
	;Create the process to be debugged
	invoke CreateProcess,NULL,lpFileName,NULL,NULL,FALSE,NORMAL_PRIORITY_CLASS Or DEBUG_PROCESS Or DEBUG_ONLY_THIS_PROCESS,NULL,NULL,addr sinfo,addr dbg.pinfo
	.if eax
		invoke WaitForSingleObject,dbg.pinfo.hProcess,10
		invoke OpenProcess,PROCESS_ALL_ACCESS,TRUE,dbg.pinfo.dwProcessId
		mov		dbg.hdbghand,eax
		invoke DbgHelp,offset DbgHelpDLL,dbg.pinfo.hProcess,addr szExeName
		.if !dbg.inxline
			invoke PutString,addr szNoDebugInfoMasm
			invoke PutString,addr szExeName
			mov		fNoDebugInfo,TRUE
			invoke EnableMenu
		.else
			invoke wsprintf,addr buffer,addr szFinal,dbg.inxsource,dbg.inxline,dbg.inxsymbol
			invoke PutString,addr buffer
			invoke PutString,addr szDebuggingStarted
			invoke PutString,addr szExeName
			mov		fNoDebugInfo,FALSE
			invoke EnableMenu
			invoke LockFiles,TRUE
			invoke MapNoDebug
			mov		ebx,dbg.hMemLine
			mov		eax,[ebx].DEBUGLINE.Address
			mov		dbg.minadr,eax
			mov		eax,dbg.inxline
			dec		eax
			mov		edx,sizeof DEBUGLINE
			mul		edx
			lea		ebx,[ebx+eax]
			mov		eax,[ebx].DEBUGLINE.Address
			mov		dbg.lastadr,eax
			add		eax,4
			mov		dbg.maxadr,eax
			sub		eax,dbg.minadr
			mov		ebx,eax
			invoke GlobalAlloc,GMEM_FIXED,ebx
			mov		dbg.hMemNoBP,eax
			invoke GlobalAlloc,GMEM_FIXED,ebx
			mov		dbg.hMemBP,eax
			invoke ReadProcessMemory,dbg.hdbghand,dbg.minadr,dbg.hMemNoBP,ebx,0
			invoke ReadProcessMemory,dbg.hdbghand,dbg.minadr,dbg.hMemBP,ebx,0
			mov		ebx,dbg.hMemLine
			mov		ecx,dbg.inxline
			mov		edx,dbg.hMemBP
			.while ecx
				.if ![ebx].DEBUGLINE.NoDebug
					mov		eax,[ebx].DEBUGLINE.Address
					sub		eax,dbg.minadr
					mov		byte ptr [edx+eax],0CCh
				.endif
				lea		ebx,[ebx+sizeof DEBUGLINE]
				dec		ecx
			.endw
			invoke MapBreakPoints
			.if eax
				invoke wsprintf,addr buffer,addr szUnhanfledBreakpoints,eax
				invoke MessageBox,hOut,addr buffer,addr szDebug,MB_OK or MB_ICONEXCLAMATION
			.endif
			invoke SetBreakPoints
			.if dbg.nErrors
				mov		eax,dbg.hMemVar
				mov		dbg.lpvar,eax
				invoke RtlZeroMemory,eax,256*1024
				invoke wsprintf,addr outbuffer,addr szErrorParsing,dbg.nErrors
				invoke PutString,addr outbuffer
			.endif
		.endif
		mov		dbg.prevline,-1
		invoke AddThread,dbg.pinfo.hThread,dbg.pinfo.dwThreadId
		mov		[eax].DEBUGTHREAD.isdebugged,TRUE
		.while TRUE
			invoke WaitForDebugEvent,addr de,INFINITE
			mov		fContinue,DBG_CONTINUE
			mov		eax,de.dwDebugEventCode
			.if eax==EXCEPTION_DEBUG_EVENT
				mov		eax,de.u.Exception.pExceptionRecord.ExceptionCode
				.if eax==EXCEPTION_BREAKPOINT
					.if de.u.Exception.pExceptionRecord.ExceptionAddress<800000h
						invoke FindThread,de.dwThreadId
						mov		ebx,eax
						.if ![ebx].DEBUGTHREAD.isdebugged
							mov		[ebx].DEBUGTHREAD.suspended,TRUE
							mov		[ebx].DEBUGTHREAD.isdebugged,TRUE
							invoke SuspendThread,[ebx].DEBUGTHREAD.htread
							mov		fContinue,DBG_EXCEPTION_NOT_HANDLED
						.else
							mov		dbg.lpthread,ebx
							invoke IsOnBP,de.u.Exception.pExceptionRecord.ExceptionAddress
							push	eax
							invoke IsInProc,de.u.Exception.pExceptionRecord.ExceptionAddress
							pop		edx
							.if dbg.func==FUNC_STEPOVER && eax!=dbg.lpStepOver && !edx
								mov		dbg.context.ContextFlags,CONTEXT_FULL
								invoke GetThreadContext,[ebx].DEBUGTHREAD.htread,addr dbg.context
								mov		eax,de.u.Exception.pExceptionRecord.ExceptionAddress
								mov		dbg.context.regEip,eax
								mov		[ebx].DEBUGTHREAD.address,eax
								invoke SetThreadContext,[ebx].DEBUGTHREAD.htread,addr dbg.context
								invoke RestoreSourceByte,[ebx].DEBUGTHREAD.address
							.else
								.if ![ebx].DEBUGTHREAD.suspended
									mov		[ebx].DEBUGTHREAD.suspended,TRUE
									mov		[ebx].DEBUGTHREAD.isdebugged,TRUE
									invoke SuspendThread,[ebx].DEBUGTHREAD.htread
								.endif
								invoke FindLine,de.u.Exception.pExceptionRecord.ExceptionAddress
								mov		edx,[ebx].DEBUGTHREAD.lpline
								mov		[ebx].DEBUGTHREAD.lpline,eax
								.if eax!=edx
									push	TRUE
								.else
									push	FALSE
								.endif
								.if eax
									invoke SelectLine,eax
								.endif
								mov		dbg.context.ContextFlags,CONTEXT_FULL
								invoke GetThreadContext,[ebx].DEBUGTHREAD.htread,addr dbg.context
								mov		eax,de.u.Exception.pExceptionRecord.ExceptionAddress
								mov		dbg.context.regEip,eax
								mov		[ebx].DEBUGTHREAD.address,eax
								invoke SetThreadContext,[ebx].DEBUGTHREAD.htread,addr dbg.context
								invoke IsInProc,[ebx].DEBUGTHREAD.address
								mov		dbg.lpProc,eax
								pop		eax
								.if eax
									invoke ShowContext
								.endif
								invoke WatchVars
							.endif
							mov		dbg.fHandled,TRUE
						.endif
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
					mov		fContinue,DBG_EXCEPTION_NOT_HANDLED
				.endif
			.elseif eax==CREATE_PROCESS_DEBUG_EVENT
				.if !dbg.hdbgfile
					mov		eax,de.u.CreateProcessInfo.hFile
					mov		dbg.hdbgfile,eax
				.endif
;				invoke wsprintf,addr outbuffer,addr szEventDec,addr szCREATE_PROCESS_DEBUG_EVENT,de.dwProcessId
;				invoke PutString,addr outbuffer
			.elseif eax==EXIT_PROCESS_DEBUG_EVENT
;				invoke wsprintf,addr outbuffer,addr szEventDec,addr szEXIT_PROCESS_DEBUG_EVENT,de.dwProcessId
;				invoke PutString,addr outbuffer
				mov		eax,de.dwProcessId
				.if eax==dbg.pinfo.dwProcessId
					invoke ContinueDebugEvent,de.dwProcessId,de.dwThreadId,DBG_CONTINUE
					.break
				.endif
			.elseif eax==CREATE_THREAD_DEBUG_EVENT
				invoke AddThread,de.u.CreateThread.hThread,de.dwThreadId
;				invoke wsprintf,addr outbuffer,addr szEventDec,addr szCREATE_THREAD_DEBUG_EVENT,de.dwThreadId
;				invoke PutString,addr outbuffer
			.elseif eax==EXIT_THREAD_DEBUG_EVENT
				invoke FindThread,de.dwThreadId
				.if eax
					mov		dbg.lpthread,eax
;					invoke wsprintf,addr outbuffer,addr szEventDec,addr szEXIT_THREAD_DEBUG_EVENT,de.dwThreadId
;					invoke PutString,addr outbuffer
					invoke RemoveThread,de.dwThreadId
					invoke SwitchThread
					mov		ebx,eax
					.if [ebx].DEBUGTHREAD.suspended
						mov		dbg.lpthread,ebx
						mov		[ebx].DEBUGTHREAD.suspended,FALSE
						invoke ResumeThread,[ebx].DEBUGTHREAD.htread
					.endif
				.endif
			.elseif eax==LOAD_DLL_DEBUG_EVENT
;				mov		buffer,0
;				invoke GetModuleFileName,de.u.LoadDll.lpBaseOfDll,addr buffer,sizeof buffer
;				invoke wsprintf,addr outbuffer,addr szEventString,addr szLOAD_DLL_DEBUG_EVENT,addr buffer
;				invoke PutString,addr outbuffer
			.elseif eax==UNLOAD_DLL_DEBUG_EVENT
;				mov		buffer,0
;				invoke GetModuleFileName,de.u.UnloadDll.lpBaseOfDll,addr buffer,sizeof buffer
;				invoke wsprintf,addr outbuffer,addr szEventString,addr szUNLOAD_DLL_DEBUG_EVENT,addr buffer
;				invoke PutString,addr outbuffer
			.elseif eax==OUTPUT_DEBUG_STRING_EVENT
				movzx	eax,de.u.DebugString.nDebugStringiLength
				.if eax>255
					mov		eax,255
				.endif
				invoke ReadProcessMemory,dbg.hdbghand,de.u.DebugString.lpDebugStringData,addr buffer,eax,0
				invoke wsprintf,addr outbuffer,addr szEventString,addr szOUTPUT_DEBUG_STRING_EVENT,addr buffer
				invoke PutString,addr outbuffer
			.elseif eax==RIP_EVENT
;				invoke PutString,addr szRIP_EVENT
			.endif
			invoke ContinueDebugEvent,de.dwProcessId,de.dwThreadId,fContinue
		.endw
		; Close debug handles
		invoke CloseHandle,dbg.hdbgfile
		invoke CloseHandle,dbg.hdbghand
		invoke CloseHandle,dbg.pinfo.hThread
		invoke CloseHandle,dbg.pinfo.hProcess
		; Free debug memory
		.if dbg.hMemLine
			invoke GlobalFree,dbg.hMemLine
			mov		dbg.hMemLine,0
		.endif
		.if dbg.hMemType
			invoke GlobalFree,dbg.hMemType
			mov		dbg.hMemType,0
		.endif
		.if dbg.hMemSymbol
			invoke GlobalFree,dbg.hMemSymbol
			mov		dbg.hMemSymbol,0
		.endif
		.if dbg.hMemSource
			invoke GlobalFree,dbg.hMemSource
			mov		dbg.hMemSource,0
		.endif
		invoke GlobalFree,dbg.hMemNoBP
		invoke GlobalFree,dbg.hMemBP
	.endif
	invoke CloseHandle,dbg.hDbgThread
	mov		dbg.hDbgThread,0
	invoke ResetSelectLine
	mov		fNoDebugInfo,FALSE
	mov		dbg.fHandled,FALSE
	invoke EnableMenu
	invoke LockFiles,FALSE
	invoke SetWindowText,hOut,addr szNULL
	invoke PutString,addr szDebugStopped
	invoke ImmPromptOff
	invoke RtlZeroMemory,addr dbg,sizeof DEBUG
	ret

Debug endp
