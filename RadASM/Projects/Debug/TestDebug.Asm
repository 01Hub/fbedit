.386
.model flat, stdcall  ;32 bit memory model
option casemap :none  ;case sensitive
include windows.inc
include kernel32.inc
include user32.inc
includelib kernel32.lib
includelib user32.lib
include TestMisc.asm
.data
szTest		db 'Test',0
.code
start:
	mov		eax,'ABCD'
	mov		eax,'EFGH'
	invoke ExitProcess,0
end start
