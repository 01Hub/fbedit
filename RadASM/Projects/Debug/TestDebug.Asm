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
tid			dd   ?
rect		RECT <>
mystruct	MYSTRUCT <>
valdd		DWORD 4
valdw		WORD 2
valdb		BYTE 1
hInstance	HINSTANCE ?

.code

MyProc1 proc

	mov		eax,'abcd'
	ret

MyProc1 endp

MyProc2 proc uses esi edi,var:DWORD,var1:PTR DWORD,var2:DWORD;ebp+8,ebp+12,ebp+16
	LOCAL	aa:WORD; ebp-4
	LOCAL	bb:WORD; ebp-8
	LOCAL	cc:WORD; ebp-12
	LOCAL	s[256]:BYTE

	mov		aa,1
	mov		bb,2
	mov		cc,3
	mov		s,'A'
	mov		eax,ebp
	lea		eax,var
	sub		eax,ebp
	lea		ecx,var1
	sub		ecx,ebp
	lea		edx,var2
	sub		edx,ebp
	lea		eax,aa
	lea		ecx,bb
	lea		edx,cc
	invoke MyProc4
	ret

MyProc2 endp

MyProc3 proc uses esi

	mov		eax,'abcd'
	mov		eax,'abcd'
	mov		eax,'abcd'
	mov		eax,'abcd'
	invoke OutputDebugString,addr szTest
	ret

MyProc3 endp

start:

	mov		eax,'ABCD'
	mov		eax,tid
	mov		tid,1234
	invoke CreateThread,NULL,0,addr MyProc3,0,NULL,addr tid
	invoke CloseHandle,eax
	invoke CreateThread,NULL,0,addr MyProc3,0,NULL,addr tid
	invoke CloseHandle,eax
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
	mov		al,'B'
	mov		ah,'C'
	mov		ax,'DE'
	invoke MyProc1
	invoke MyProc2,123,456,789
;	invoke MyProc3
	invoke MyProc4
	jmp		Ex
Ex:
	invoke ExitProcess,0

end start
