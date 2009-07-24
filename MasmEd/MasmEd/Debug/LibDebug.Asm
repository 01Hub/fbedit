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

SetDebugInfo proc public lpDEBUGINFO:DWORD

	mov		edx,lpDEBUGINFO
	mov		eax,[edx].DEBUGINFO.hOut
	mov		hOut,eax
	mov		eax,[edx].DEBUGINFO.lpCallBack
	mov		lpCallBack,eax
	invoke strcpy,addr szExeName,addr [edx].DEBUGINFO.FileName
	ret

SetDebugInfo endp

DebugCommand proc public nCmnd:DWORD,wParam:DWORD,lParam:DWORD
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
		.endif
	.elseif eax==FUNC_STOP
		mov		dbg.func,FUNC_STOP
		invoke TerminateProcess,dbg.pinfo.hProcess,0
	.elseif eax==FUNC_STEPINTO
		mov		dbg.func,FUNC_STEPINTO
	.elseif eax==FUNC_STEPOVER
		mov		dbg.func,FUNC_STEPOVER
	.elseif eax==FUNC_RUNTOCARET
		mov		dbg.func,FUNC_RUNTOCARET
;	.elseif eax==
	.endif
	ret

DebugCommand endp

end
