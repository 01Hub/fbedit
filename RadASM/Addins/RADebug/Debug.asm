
EnableMenu						PROTO
LockFiles						PROTO	:DWORD

.const

szBP							db 0CCh
szDump							db 'Reg     Hex       Dec',0Dh,'-------------------------------',0Dh,0
szDec							db '  %u',0Dh,0
szRegs							db 'EAX     ',0,'ECX     ',0,'EDX     ',0,'EBX     ',0,'ESP     ',0,'EBP     ',0,'ESI     ',0,'EDI     ',0,'EIP     ',0,'EFL     ',0

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
	mov		eax,dbg.inxsource
	mov		CountSource,eax
	mov		ebx,dbg.hMemSource
	.while CountSource
		invoke lstrcmpi,edi,addr [ebx].DEBUGSOURCE.FileName
		.if !eax
			mov		dx,[ebx].DEBUGSOURCE.FileID
			mov		eax,[esi].BREAKPOINT.LineNumber
			inc		eax		;LineNumber
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

	mov		edi,dbg.hMemSymbol
	mov		ebx,dbg.inxsymbol
	xor		eax,eax
	.while ebx
		mov		[edi].DEBUGSYMBOL.NoDebug,ax
		dec		ebx
		add		edi,sizeof DEBUGSYMBOL
	.endw
	mov		ecx,dbg.inxline
	mov		esi,dbg.hMemLine
	.while ecx
		mov		[esi].DEBUGLINE.NoDebug,ax
		dec		ecx
		add		esi,sizeof DEBUGLINE
	.endw
	mov		nInx,0
	.while TRUE
		invoke wsprintf,addr buffer1,addr szCommaBP[1],nInx
		mov		eax,lpData
		invoke GetPrivateProfileString,addr szNoDebug,addr buffer1,addr szNULL,addr buffer,sizeof buffer,[eax].ADDINDATA.lpProject
		.break .if !eax
		mov		edi,dbg.hMemSymbol
		mov		ebx,dbg.inxsymbol
		.while ebx
			invoke lstrcmp,addr buffer,addr [edi].DEBUGSYMBOL.szName
			.if !eax
				mov		[edi].DEBUGSYMBOL.NoDebug,1
				mov		edx,[edi].DEBUGSYMBOL.Address
				mov		eax,edx
				add		edx,[edi].DEBUGSYMBOL.nSize
				mov		ecx,dbg.inxline
				mov		esi,dbg.hMemLine
				.while ecx
					.if [esi].DEBUGLINE.Address>=eax
						.if [esi].DEBUGLINE.Address<edx
							mov		[esi].DEBUGLINE.NoDebug,1
						.endif
					.endif
					dec		ecx
					add		esi,sizeof DEBUGLINE
				.endw
				.break
			.endif
			dec		ebx
			add		edi,sizeof DEBUGSYMBOL
		.endw
		inc		nInx
	.endw
	ret

MapNoDebug endp

SetBreakPointsAll proc uses ebx esi edi,fNoProc:DWORD

	mov		edi,dbg.hMemLine
	xor		ebx,ebx
	.if fNoProc
		;Step Over
		.while ebx<dbg.inxline
			.if [edi].DEBUGLINE.SourceByte==-1 && [edi].DEBUGLINE.NoDebug==0
				call	IsAddressProc
				.if !eax
					mov		[edi].DEBUGLINE.SourceByte,0
					invoke ReadProcessMemory,dbg.hdbghand,[edi].DEBUGLINE.Address,addr [edi].DEBUGLINE.SourceByte,1,0
					invoke WriteProcessMemory,dbg.hdbghand,[edi].DEBUGLINE.Address,addr szBP,1,0
				.else
					.while [edi+sizeof DEBUGLINE].DEBUGLINE.Address<eax
						.if [edi].DEBUGLINE.SourceByte!=-1
							push	eax
							invoke WriteProcessMemory,dbg.hdbghand,[edi].DEBUGLINE.Address,addr [edi].DEBUGLINE.SourceByte,1,0
							mov		[edi].DEBUGLINE.SourceByte,-1
							pop		eax
						.endif
						lea		edi,[edi+sizeof DEBUGLINE]
						inc		ebx
					.endw
				.endif
			.endif
			lea		edi,[edi+sizeof DEBUGLINE]
			inc		ebx
		.endw
	.else
		;Step Into
		.while ebx<dbg.inxline
			.if [edi].DEBUGLINE.SourceByte==-1 && [edi].DEBUGLINE.NoDebug==0
				mov		[edi].DEBUGLINE.SourceByte,0
				invoke ReadProcessMemory,dbg.hdbghand,[edi].DEBUGLINE.Address,addr [edi].DEBUGLINE.SourceByte,1,0
				invoke WriteProcessMemory,dbg.hdbghand,[edi].DEBUGLINE.Address,addr szBP,1,0
			.endif
			add		edi,sizeof DEBUGLINE
			inc		ebx
		.endw
	.endif
	ret

IsAddressProc:
	mov		esi,dbg.hMemSymbol
	mov		eax,[edi].DEBUGLINE.Address
	mov		ecx,dbg.inxsymbol
	.while ecx
		.if eax==[esi].DEBUGSYMBOL.Address
			add		eax,[esi].DEBUGSYMBOL.nSize
			retn
		.endif
		lea		esi,[esi+sizeof DEBUGSYMBOL]
		dec		ecx
	.endw
	xor		eax,eax
	retn

SetBreakPointsAll endp

SetBreakPoints proc uses ebx edi

	mov		edi,dbg.hMemLine
	mov		ebx,dbg.inxline
	.while ebx
		.if [edi].DEBUGLINE.SourceByte==-1 && [edi].DEBUGLINE.BreakPoint==TRUE && [edi].DEBUGLINE.NoDebug==FALSE
			mov		[edi].DEBUGLINE.SourceByte,0
			invoke ReadProcessMemory,dbg.hdbghand,[edi].DEBUGLINE.Address,addr [edi].DEBUGLINE.SourceByte,1,0
			invoke WriteProcessMemory,dbg.hdbghand,[edi].DEBUGLINE.Address,addr szBP,1,0
		.endif
		lea		edi,[edi+sizeof DEBUGLINE]
		dec		ebx
	.endw
	ret

SetBreakPoints endp

SetBreakpointAtCurrentLine proc uses ebx esi edi,nLine:DWORD
	LOCAL	chrg:CHARRANGE
	LOCAL	CountSource:DWORD

	mov		ebx,lpHandles
	.if !nLine
		; Get current line
		invoke SendMessage,[ebx].ADDINHANDLES.hEdit,EM_EXGETSEL,0,addr chrg
		invoke SendMessage,[ebx].ADDINHANDLES.hEdit,EM_LINEFROMCHAR,chrg.cpMin,0
		inc		eax
		mov		nLine,eax
	.endif
	; Get project file ID
	invoke GetWindowLong,[ebx].ADDINHANDLES.hMdiCld,16
	push	eax
	mov		eax,lpProc
	call	[eax].ADDINPROCS.lpGetFileNameFromID
	mov		edi,eax
	mov		eax,dbg.inxsource
	mov		CountSource,eax
	mov		ebx,dbg.hMemSource
	.while CountSource
		invoke lstrcmpi,edi,addr [ebx].DEBUGSOURCE.FileName
		.if !eax
			mov		dx,[ebx].DEBUGSOURCE.FileID
			mov		eax,nLine		;LineNumber
			mov		esi,dbg.hMemLine
			xor		ecx,ecx
			.while ecx<dbg.inxline
				.if eax==[esi].DEBUGLINE.LineNumber
					.if dx==[esi].DEBUGLINE.FileID
						.if [esi].DEBUGLINE.SourceByte==-1
							mov		[esi].DEBUGLINE.SourceByte,0
							invoke ReadProcessMemory,dbg.hdbghand,[esi].DEBUGLINE.Address,addr [esi].DEBUGLINE.SourceByte,1,0
							invoke WriteProcessMemory,dbg.hdbghand,[esi].DEBUGLINE.Address,addr szBP,1,0
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

	mov		edi,dbg.hMemLine
	mov		ebx,dbg.inxline
	.while ebx
		.if [edi].DEBUGLINE.SourceByte!=-1
			invoke WriteProcessMemory,dbg.hdbghand,[edi].DEBUGLINE.Address,addr [edi].DEBUGLINE.SourceByte,1,0
			mov		[edi].DEBUGLINE.SourceByte,-1
		.endif
		lea		edi,[edi+sizeof DEBUGLINE]
		dec		ebx
	.endw
	ret

ClearBreakPointsAll endp

RestoreSourceByte proc uses ebx edi,lpLine:DWORD

	mov		edi,lpLine
	.if edi
		.if [edi].DEBUGLINE.SourceByte!=-1
			invoke WriteProcessMemory,dbg.hdbghand,[edi].DEBUGLINE.Address,addr [edi].DEBUGLINE.SourceByte,1,0
			mov		[edi].DEBUGLINE.SourceByte,-1
		.endif
	.endif
	ret

RestoreSourceByte endp

FindLine proc uses ebx esi edi,Address:DWORD
	LOCAL	inx:DWORD
	LOCAL	half:DWORD
	LOCAL	lower:DWORD
	LOCAL	upper:DWORD

	mov		eax,dbg.inxline
	.if eax<32
		mov		ebx,dbg.inxline
		mov		edi,dbg.hMemLine
		call	Linear
	.else
		mov		lower,0
		mov		upper,eax
		shr		eax,1
		mov		half,eax
		mov		inx,eax
		call	TestIt
		.if sdword ptr eax<0
			; Lower half
			mov		ebx,inx
			mov		edi,dbg.hMemLine
			call	Linear
		.elseif sdword ptr eax>0
			; Upper half
			mov		ebx,dbg.inxline
			sub		ebx,inx
			call	Linear
		.else
			; Found
			jmp		Ex
		.endif
	.endif
  Ex:
	mov		eax,edi
	ret

TestIt:
	call	GetPointerFromInx
	mov		eax,Address
	sub		eax,[edi].DEBUGLINE.Address
	retn

GetPointerFromInx:
	mov		eax,inx
	mov		edx,sizeof DEBUGLINE
	mul		edx
	mov		edi,dbg.hMemLine
	lea		edi,[edi+eax]
	retn

Linear:
	mov		eax,Address
	.while ebx
		.if eax==[edi].DEBUGLINE.Address
			retn
		.endif
		lea		edi,[edi+sizeof DEBUGLINE]
		dec		ebx
	.endw
	xor		edi,edi
	retn

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
	movzx	eax,[ebx].DEBUGLINE.FileID
	mov		edx,sizeof DEBUGSOURCE
	mul		edx
	mov		esi,dbg.hMemSource
	lea		esi,[esi+eax]
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
	mov		word ptr dbg.szprevline,255
	invoke SendMessage,dbg.prevhwnd,EM_GETLINE,dbg.prevline,addr dbg.szprevline
	mov		dbg.szprevline[eax],0
	invoke SendMessage,dbg.prevhwnd,EM_SCROLLCARET,0,0
	invoke SendMessage,dbg.prevhwnd,EM_GETFIRSTVISIBLELINE,0,0
	.if eax==dbg.prevline
		invoke SendMessage,dbg.prevhwnd,EM_LINESCROLL,0,-1
		invoke SendMessage,dbg.prevhwnd,EM_EXSETSEL,0,addr chrg
		invoke SendMessage,dbg.prevhwnd,EM_SCROLLCARET,0,0
	.endif
	invoke SetForegroundWindow,[edi].ADDINHANDLES.hWnd
	invoke SetFocus,dbg.prevhwnd
	invoke SendMessage,dbg.prevhwnd,REM_SETHILITELINE,dbg.prevline,1
	ret

SelectLine endp

IsLineCall proc uses esi edi

	mov		esi,offset szCall
	lea		edi,dbg.szprevline
	.while byte ptr [edi] && (byte ptr [edi]==VK_TAB || byte ptr [edi]==VK_SPACE)
		inc		edi
	.endw
	push	edi
	.while byte ptr [edi] && ((byte ptr [edi]>='A' && byte ptr [edi]<='Z') || (byte ptr [edi]>='a' && byte ptr [edi]<='z'))
		inc		edi
	.endw
	mov		byte ptr [edi],0
	pop		edi
	.while byte ptr [esi]
		invoke lstrcmpi,esi,edi
		.if !eax
			inc		eax
			jmp		Ex
		.endif
		invoke lstrlen,esi
		lea		esi,[esi+eax+1]
	.endw
	xor		eax,eax
  Ex:
	ret

IsLineCall endp

ResumeAllThreads proc uses ebx

	lea		ebx,dbg.thread
	.while [ebx].DEBUGTHREAD.htread && [ebx].DEBUGTHREAD.suspended
		mov		[ebx].DEBUGTHREAD.suspended,FALSE
		invoke ResumeThread,[ebx].DEBUGTHREAD.htread
		add		ebx,sizeof DEBUGTHREAD
	.endw
	ret

ResumeAllThreads endp

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

Debug proc uses ebx,lpFileName:DWORD
	LOCAL	sinfo:STARTUPINFO
	LOCAL	de:DEBUG_EVENT
	LOCAL	fContinue:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	Old:BYTE

	invoke RtlZeroMemory,addr sinfo,sizeof STARTUPINFO
	mov		sinfo.cb,SizeOf STARTUPINFO
	mov		sinfo.dwFlags,STARTF_USESHOWWINDOW
	mov		sinfo.wShowWindow,SW_NORMAL
	;Create the process to be debugged
	invoke CreateProcess,NULL,lpFileName,NULL,NULL,FALSE,NORMAL_PRIORITY_CLASS Or DEBUG_PROCESS Or DEBUG_ONLY_THIS_PROCESS,NULL,NULL,addr sinfo,addr dbg.pinfo
	.if eax
		; Allocate memory for DEBUGLINE, max 128K lines
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,128*1024*sizeof DEBUGLINE
		mov		dbg.hMemLine,eax
		; Allocate memory for DEBUGSYMBOL, max 16K symbols
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,16*1024*sizeof DEBUGSYMBOL
		mov		dbg.hMemSymbol,eax
		; Allocate memory for DEBUGSOURCE, max 512 sources
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,512*sizeof DEBUGSOURCE
		mov		dbg.hMemSource,eax
		; Zero the indexes
		mov		dbg.inxsource,0
		mov		dbg.inxline,0
		mov		dbg.inxsymbol,0
		invoke WaitForSingleObject,dbg.pinfo.hProcess,10
		invoke OpenProcess,PROCESS_ALL_ACCESS,TRUE,dbg.pinfo.dwProcessId
		mov		dbg.hdbghand,eax
		invoke DbgHelp,dbg.pinfo.hProcess,lpFileName
		.if !dbg.inxline
			invoke PutString,addr szNoDebugInfo
		.endif
		mov		dbg.prevline,-1
		invoke MapNoDebug
		invoke MapBreakPoints
		.if eax
			invoke wsprintf,addr buffer,addr szUnhanfledBreakpoints,eax
			mov		edx,lpHandles
			invoke MessageBox,[edx].ADDINHANDLES.hWnd,addr buffer,addr szDebug,MB_OK or MB_ICONEXCLAMATION
		.endif
		invoke SetBreakPoints
		invoke AddThread,dbg.pinfo.hThread,dbg.pinfo.dwThreadId
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
						mov		dbg.lpthread,ebx
						.if ![ebx].DEBUGTHREAD.suspended
							mov		[ebx].DEBUGTHREAD.suspended,TRUE
							invoke SuspendThread,[ebx].DEBUGTHREAD.htread
						.endif
						invoke FindLine,de.u.Exception.pExceptionRecord.ExceptionAddress
						mov		[ebx].DEBUGTHREAD.lpline,eax
						.if eax
							invoke SelectLine,eax
						.endif
						mov		dbg.context.ContextFlags,CONTEXT_FULL;CONTEXT_CONTROL
						invoke GetThreadContext,[ebx].DEBUGTHREAD.htread,addr dbg.context
						mov		eax,de.u.Exception.pExceptionRecord.ExceptionAddress
						mov		dbg.context.regEip,eax
						invoke SetThreadContext,[ebx].DEBUGTHREAD.htread,addr dbg.context
						invoke ShowContext
					.else
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
					mov		fContinue,DBG_EXCEPTION_NOT_HANDLED
				.endif
			.elseif eax==CREATE_PROCESS_DEBUG_EVENT
				invoke PutString,addr szCREATE_PROCESS_DEBUG_EVENT
				mov		eax,de.u.CreateProcessInfo.hFile
				mov		dbg.hdbgfile,eax
			.elseif eax==CREATE_THREAD_DEBUG_EVENT
				mov		eax,dbg.inxline
				dec		eax
				mov		edx,sizeof DEBUGLINE
				mul		edx
				add		eax,dbg.hMemLine
				mov		eax,[eax].DEBUGLINE.Address
				.if eax>de.u.CreateThread.lpStartAddress
					mov		ebx,dbg.lpthread
					.if ![ebx].DEBUGTHREAD.suspended
						mov		[ebx].DEBUGTHREAD.suspended,TRUE
						invoke SuspendThread,[ebx].DEBUGTHREAD.htread
					.endif
					invoke AddThread,de.u.CreateThread.hThread,de.dwThreadId
					invoke PutString,addr szCREATE_THREAD_DEBUG_EVENT
				.endif
			.elseif eax==EXIT_THREAD_DEBUG_EVENT
				invoke FindThread,de.dwThreadId
				.if eax
					invoke PutString,addr szEXIT_THREAD_DEBUG_EVENT
					invoke RemoveThread,de.dwThreadId
					lea		ebx,dbg.thread
					.if [ebx].DEBUGTHREAD.suspended
						invoke RestoreSourceByte,[ebx].DEBUGTHREAD.lpline
						mov		[ebx].DEBUGTHREAD.suspended,FALSE
						invoke ResumeThread,[ebx].DEBUGTHREAD.htread
						mov		dbg.lpthread,ebx
					.endif
				.endif
			.elseif eax==EXIT_PROCESS_DEBUG_EVENT
				invoke PutString,addr szEXIT_PROCESS_DEBUG_EVENT
				invoke ContinueDebugEvent,de.dwProcessId,de.dwThreadId,DBG_CONTINUE
				.break
			.elseif eax==LOAD_DLL_DEBUG_EVENT
				mov		buffer,0
				invoke GetModuleFileName,de.u.LoadDll.lpBaseOfDll,addr buffer,sizeof buffer
				invoke PutString,addr szLOAD_DLL_DEBUG_EVENT
				invoke PutString,addr buffer
			.elseif eax==UNLOAD_DLL_DEBUG_EVENT
				mov		buffer,0
				invoke GetModuleFileName,de.u.UnloadDll.lpBaseOfDll,addr buffer,sizeof buffer
				invoke PutString,addr szUNLOAD_DLL_DEBUG_EVENT
				invoke PutString,addr buffer
			.elseif eax==OUTPUT_DEBUG_STRING_EVENT
				invoke PutString,addr szOUTPUT_DEBUG_STRING_EVENT
				movzx	eax,de.u.DebugString.nDebugStringiLength
				invoke ReadProcessMemory,dbg.hdbghand,de.u.DebugString.lpDebugStringData,addr buffer,eax,0
				invoke PutString,addr buffer
			.elseif eax==RIP_EVENT
				invoke PutString,addr szRIP_EVENT
			.endif
			invoke ContinueDebugEvent,de.dwProcessId,de.dwThreadId,fContinue
		.endw
		; Close debug handles
		invoke CloseHandle,dbg.hdbgfile
		invoke CloseHandle,dbg.hdbghand
		invoke CloseHandle,dbg.pinfo.hThread
		invoke CloseHandle,dbg.pinfo.hProcess
		; Free debug memory
		invoke GlobalFree,dbg.hMemLine
		invoke GlobalFree,dbg.hMemSymbol
		invoke GlobalFree,dbg.hMemSource
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
