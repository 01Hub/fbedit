
.const

szBP			db 0CCh

.data?

hDbgThread		HANDLE ?
dbghand			HANDLE ?
pinfo			PROCESS_INFORMATION <>
threadcontext	HANDLE ?

.code

PrintSourceByte proc Address:DWORD,SourceByte:DWORD
	LOCAL	buffer[256]:BYTE

	invoke wsprintf,addr buffer,addr szSourceByte,Address,SourceByte
	invoke PutString,addr buffer
	ret

PrintSourceByte endp

SetBreakPointsAll proc uses ebx edi

	mov		edi,offset dbgline
	xor		ebx,ebx
	.while ebx<inxline
		invoke ReadProcessMemory,dbghand,[edi].DEBUGLINE.Address,addr [edi].DEBUGLINE.SourceByte,1,0
		movzx		eax,[edi].DEBUGLINE.SourceByte
		invoke PrintSourceByte,[edi].DEBUGLINE.Address,eax
		invoke WriteProcessMemory,dbghand,[edi].DEBUGLINE.Address,addr szBP,1,0
		add		edi,sizeof DEBUGLINE
		inc		ebx
	.endw
	ret

SetBreakPointsAll endp

RestoreSourceByte proc uses ebx edi,Address:DWORD

	mov		edi,offset dbgline
	mov		eax,Address
	xor		ebx,ebx
	.while ebx<inxline
		.if eax==[edi].DEBUGLINE.Address
			movzx		eax,[edi].DEBUGLINE.SourceByte
			invoke PrintSourceByte,[edi].DEBUGLINE.Address,eax
			invoke WriteProcessMemory,dbghand,Address,addr [edi].DEBUGLINE.SourceByte,1,0
			.break
		.endif
		add		edi,sizeof DEBUGLINE
		inc		ebx
	.endw
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

	mov		ebx,lpDEBUGLINE
	mov		eax,[ebx].DEBUGLINE.FileID
	mov		edx,sizeof DEBUGSOURCE
	mul		edx
	lea		esi,[eax+offset dbgsource]
	mov		edx,lpData
	mov		edx,[edx].ADDINDATA.lpFile
	invoke lstrcpy,edx,addr [esi].DEBUGSOURCE.FileName
	mov		eax,lpProc
	mov		eax,[eax].ADDINPROCS.lpOpenProjectFile
	push	TRUE
	call	eax
	ret

SelectLine endp

Debug proc lpFileName:DWORD
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
	invoke CreateProcess,NULL,lpFileName,NULL,NULL,FALSE,NORMAL_PRIORITY_CLASS Or DEBUG_PROCESS Or DEBUG_ONLY_THIS_PROCESS,NULL,NULL,addr sinfo,addr pinfo
	.if eax
		invoke WaitForSingleObject,pinfo.hProcess,10
		invoke OpenProcess,PROCESS_ALL_ACCESS,TRUE,pinfo.dwProcessId
		mov		dbghand,eax
		invoke DbgHelp,pinfo.hProcess,lpFileName
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
		invoke SetBreakPointsAll
		mov		eax,pinfo.hThread
		mov		threadcontext,eax
		.while TRUE
			invoke WaitForDebugEvent,addr de,INFINITE
			mov		fContinue,DBG_CONTINUE
			mov		eax,de.dwDebugEventCode
			.if eax==EXCEPTION_DEBUG_EVENT
				invoke PutString,addr szEXCEPTION_DEBUG_EVENT
				mov		eax,de.u.Exception.pExceptionRecord.ExceptionCode
				.if eax==EXCEPTION_BREAKPOINT
					.if de.u.Exception.pExceptionRecord.ExceptionAddress<800000h
						invoke PutString,addr szEXCEPTION_BREAKPOINT
;						PrintHex de.u.Exception.pExceptionRecord.ExceptionAddress
						invoke RestoreSourceByte,de.u.Exception.pExceptionRecord.ExceptionAddress
						mov		context.ContextFlags,CONTEXT_CONTROL
						invoke GetThreadContext,threadcontext,addr context
						mov		eax,de.u.Exception.pExceptionRecord.ExceptionAddress
						mov		context.regEip,eax
						invoke SetThreadContext,threadcontext,addr context
						invoke SuspendThread,threadcontext
						invoke FindLine,de.u.Exception.pExceptionRecord.ExceptionAddress
						.if eax
							invoke SelectLine,eax
						.endif
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
					invoke ReadProcessMemory,dbghand,de.u.Exception.pExceptionRecord.ExceptionAddress,addr Old,1,0
					movzx		eax,Old
					invoke PrintSourceByte,de.u.Exception.pExceptionRecord.ExceptionAddress,eax
					mov		fContinue,DBG_EXCEPTION_NOT_HANDLED
				.endif
			.elseif eax==CREATE_PROCESS_DEBUG_EVENT
				invoke PutString,addr szCREATE_PROCESS_DEBUG_EVENT
			.elseif eax==CREATE_THREAD_DEBUG_EVENT
				invoke PutString,addr szCREATE_THREAD_DEBUG_EVENT
			.elseif eax==EXIT_THREAD_DEBUG_EVENT
				invoke PutString,addr szEXIT_THREAD_DEBUG_EVENT
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
	.endif
	invoke CloseHandle,pinfo.hThread
	invoke CloseHandle,pinfo.hProcess
	invoke CloseHandle,dbghand
	invoke CloseHandle,hDbgThread
	mov		hDbgThread,0
	ret

Debug endp
