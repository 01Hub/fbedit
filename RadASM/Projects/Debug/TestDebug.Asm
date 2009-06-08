.386
.model flat, stdcall  ;32 bit memory model

option casemap :none  ;case sensitive

include windows.inc
include kernel32.inc
include user32.inc
includelib kernel32.lib
includelib user32.lib
include Src\TestMisc.asm
include TestMisc.asm

MYSTRUCT struct
	a	DWORD ?
	b	DWORD ?
MYSTRUCT ends

.data

szTest		db 'Test',0
tid			dd ?
rect		RECT <>
mystruct	MYSTRUCT <>

.code

;MyProc1 proc uses esi
;
;	mov		eax,'abcd'
;	ret
;
;MyProc1 endp
;
;MyProc2 proc uses esi
;
;	mov		eax,'abcd'
;	invoke MyProc4
;	ret
;
;MyProc2 endp
;
;MyProc3 proc uses esi
;
;	mov		eax,'abcd'
;	mov		eax,'abcd'
;	mov		eax,'abcd'
;	mov		eax,'abcd'
;	invoke OutputDebugString,addr szTest
;	ret
;
;MyProc3 endp
;
start:

	mov		eax,'ABCD'
	mov		eax,'EFGH'
;	invoke CreateThread,NULL,0,addr MyProc3,0,NULL,addr tid
;	invoke CloseHandle,eax
;	invoke CreateThread,NULL,0,addr MyProc3,0,NULL,addr tid
;	invoke CloseHandle,eax
	mov		eax,'ABCD'
	mov		ecx,'EFGH'
	mov		edx,'ABCD'
	mov		eax,'EFGH'
	mov		eax,'ABCD'
	mov		eax,'EFGH'
	mov		eax,'ABCD'
	mov		eax,'EFGH'
	mov		eax,'ABCD'
	mov		eax,'EFGH'
	mov		eax,'ABCD'
	mov		eax,'EFGH'
	mov		eax,'ABCD'
	mov		eax,'EFGH'
;	invoke MyProc1
;	invoke MyProc2
;;	invoke MyProc3
;	invoke MyProc4
	jmp		Ex
Ex:
	invoke ExitProcess,0

end start
