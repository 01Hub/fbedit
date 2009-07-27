;#########################################################################
; Assembler directives

.486
.model flat,stdcall
option casemap:none
option proc:private

;#########################################################################
;		Include file

include LibDebug.inc
include Misc.asm
include Math.asm
include DbgHelp.asm
include Debug.asm
include Immediate.asm
include BreakPoint.asm

.code

;#########################################################################

EnumProc proc uses ebx,hWin:HWND,lParam:LPARAM
	LOCAL	pid:DWORD
	LOCAL	tid:DWORD

	invoke GetWindowThreadProcessId,hWin,addr pid
	mov		tid,eax
	mov		ebx,dbg.lpthread
	.if ebx
		mov		eax,[ebx].DEBUGTHREAD.threadid
		.if eax==tid
			invoke SetForegroundWindow,hWin
			xor		eax,eax
			jmp		Ex
		.endif
	.endif
	mov		eax,TRUE
  Ex:
	ret

EnumProc endp

BringWindowToFront proc

	invoke EnumWindows,offset EnumProc,0
	ret

BringWindowToFront endp

SetDebugInfo proc public lpDEBUGINFO:DWORD

	mov		edx,lpDEBUGINFO
	mov		eax,[edx].DEBUGINFO.hWnd
	mov		hWnd,eax
	mov		eax,[edx].DEBUGINFO.hOut
	mov		hOut,eax
	mov		eax,[edx].DEBUGINFO.hPrp
	mov		hPrp,eax
	mov		eax,[edx].DEBUGINFO.lpCallBack
	mov		lpCallBack,eax
	invoke strcpy,addr szExeName,addr [edx].DEBUGINFO.FileName
	ret

SetDebugInfo endp

DebugCommand proc public uses ebx esi edi,nCmnd:DWORD,wParam:DWORD,lParam:DWORD
	LOCAL	tid:DWORD

	mov		eax,nCmnd
	.if eax==FUNC_BPCLEARALL
		invoke ClearBreakpoints
	.elseif eax==FUNC_BPADDLINE
		invoke AddBreakpoint,wParam,lParam
	.elseif eax==FUNC_RUN
		mov		dbg.func,FUNC_RUN
		.if !dbg.hDbgThread
			invoke CreateThread,NULL,0,addr Debug,addr szExeName,NULL,addr tid
			mov		dbg.hDbgThread,eax
		.else
			mov		dbg.fHandled,FALSE
			invoke ResetSelectLine
			mov		dbg.func,FUNC_RUN
			invoke ClearBreakPointsAll
			invoke MapBreakPoints
			invoke SetBreakPoints
			mov		ebx,dbg.lpthread
			.if [ebx].DEBUGTHREAD.suspended
				invoke RestoreSourceByte,[ebx].DEBUGTHREAD.address
				mov		[ebx].DEBUGTHREAD.suspended,FALSE
				invoke ResumeThread,[ebx].DEBUGTHREAD.htread
				invoke BringWindowToFront
			.endif
		.endif
	.elseif eax==FUNC_STOP
		.if dbg.hDbgThread
			mov		dbg.func,FUNC_STOP
			invoke TerminateProcess,dbg.pinfo.hProcess,0
		.endif
	.elseif eax==FUNC_STEPINTO
		.if dbg.hDbgThread
			.if dbg.fHandled
				mov		dbg.func,FUNC_STEPINTO
				mov		dbg.fHandled,FALSE
				invoke ResetSelectLine
				invoke SetBreakPointsAll
				mov		ebx,dbg.lpthread
				.if ![ebx].DEBUGTHREAD.suspended
					mov		[ebx].DEBUGTHREAD.suspended,TRUE
					invoke SuspendThread,[ebx].DEBUGTHREAD.htread
				.endif
				invoke SwitchThread
				mov		ebx,eax
				mov		dbg.lpthread,ebx
				.if [ebx].DEBUGTHREAD.suspended
					invoke RestoreSourceByte,[ebx].DEBUGTHREAD.address
					mov		[ebx].DEBUGTHREAD.suspended,FALSE
					invoke ResumeThread,[ebx].DEBUGTHREAD.htread
				.endif
			.endif
		.endif
	.elseif eax==FUNC_STEPOVER
		.if dbg.hDbgThread
			.if dbg.fHandled
				mov		dbg.func,FUNC_STEPOVER
				mov		dbg.fHandled,FALSE
				invoke ResetSelectLine
				invoke SetBreakPointsAll
				mov		ebx,dbg.lpthread
				.if [ebx].DEBUGTHREAD.suspended
					mov		eax,dbg.lpProc
					mov		dbg.lpStepOver,eax
					invoke RestoreSourceByte,[ebx].DEBUGTHREAD.address
					mov		[ebx].DEBUGTHREAD.suspended,FALSE
					invoke ResumeThread,[ebx].DEBUGTHREAD.htread
				.endif
			.endif
		.endif
	.elseif eax==FUNC_RUNTOCARET
		.if dbg.hDbgThread
			.if dbg.fHandled
				mov		dbg.func,FUNC_RUNTOCARET
				mov		dbg.fHandled,FALSE
				invoke ResetSelectLine
				invoke ClearBreakPointsAll
				invoke SetBreakPoints
				mov		ebx,dbg.lpthread
				invoke RestoreSourceByte,[ebx].DEBUGTHREAD.address
				invoke SetBreakpointAtCurrentLine,wParam,lParam
				.if [ebx].DEBUGTHREAD.suspended
					mov		[ebx].DEBUGTHREAD.suspended,FALSE
					invoke ResumeThread,[ebx].DEBUGTHREAD.htread
				.endif
			.endif
		.endif
;	.elseif eax==
	.endif
	ret

DebugCommand endp

end
