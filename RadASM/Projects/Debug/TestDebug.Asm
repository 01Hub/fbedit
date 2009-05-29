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

.data

szTest		db 'Test',0

.code

MyProc3 proc uses esi

	mov		eax,'abcd'
	ret

MyProc3 endp

start:

	mov		eax,'ABCD'
	mov		eax,'EFGH'
	invoke MyProc3
	invoke MyProc1
	invoke MyProc2
	invoke MyProc4
	invoke ExitProcess,0

end start
