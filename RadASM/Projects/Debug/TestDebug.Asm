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
	aaaaa	DWORD ?
	bbbbb	DWORD ?
MYSTRUCT ends

.data

szTest		db 'Test',0
szBuff		db MAX_PATH dup(?)
tid			dd   ?
rect		RECT <>
mystruct	MYSTRUCT 4 dup(<>)
valdd		DWORD 4
valdw		WORD 2
valdbabcdefgh		BYTE 1
hInstance	HINSTANCE 8 dup(?)

.code

MyProc2 proc var:DWORD,var1:DWORD,var2:PTR DWORD;ebp+8,ebp+12,ebp+16
	LOCAL	aa:BYTE
	LOCAL	bb:WORD
	LOCAL	cc:BYTE
	LOCAL	ddd:DWORD
	LOCAL	eee:BYTE
	LOCAL	s[256]:BYTE
	LOCAL	fff:BYTE
	LOCAL	rc:RECT
	LOCAL	ggg:WORD

	mov		rc.left,123
	mov		ggg,999
	mov		aa,1
	mov		bb,2
	mov		cc,3
	mov		ddd,4
	mov		eee,5
	mov		fff,6
	mov		rc.left,99
	mov		eax,ebp
	lea		eax,aa
	lea		ecx,bb
	lea		edx,cc
	lea		eax,ddd
	mov		dword ptr s,'ABCD'
	lea		eax,s
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

MyProc1 proc uses esi edi,var:DWORD
	LOCAL	aa:SDWORD
	LOCAL	bb:SWORD

	mov		eax,'abcd'
	ret

MyProc1 endp

MyProc3 proc uses esi,Param:DWORD
	LOCAL	tst[4]:sdword

	mov		eax,'abcd'
	mov		eax,'abcd'
	mov		eax,'abcd'
	mov		eax,'abcd'
	invoke OutputDebugString,addr szTest
	ret

MyProc3 endp

ThreadProc1 proc uses esi,Param:DWORD
	LOCAL	tst[4]:sdword

	mov		eax,'abcd'
	mov		eax,'abcd'
	mov		eax,'abcd'
	mov		eax,'abcd'
	invoke OutputDebugString,addr szTest
	ret

ThreadProc1 endp

ThreadProc2 proc uses esi,Param:DWORD
	LOCAL	tst[4]:sdword

	mov		eax,'abcd'
	mov		eax,'abcd'
	mov		eax,'abcd'
	mov		eax,'abcd'
	invoke OutputDebugString,addr szTest
	ret

ThreadProc2 endp

start:
	mov		hInstance[0],1
	mov		hInstance[4],2
	mov		hInstance[8],3
	mov		eax,'ABCD'
	mov		eax,tid
	mov		tid,1234
	invoke CreateThread,NULL,0,addr ThreadProc1,0,NULL,addr tid
	invoke CloseHandle,eax
	invoke CreateThread,NULL,0,addr ThreadProc2,0,NULL,addr tid
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
	invoke MyProc1,1234
	invoke MyProc2,123,456,789
;	invoke MyProc3,987
	invoke MyProc4
	jmp		Ex
Ex:
	invoke ExitProcess,0

end start
