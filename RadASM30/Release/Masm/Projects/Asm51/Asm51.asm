.386
.model flat, stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include asm51.inc
include Misc.asm

.code

;PASS 0 ******************************************************

;Preparse the line
AsmLinePass0 proc uses ebx esi edi,lpLine:DWORD

	inc		dword ptr LINE_NUMBER
	mov		esi,lpLine
	mov		edi,offset TEXT_LINE
	mov		ebx,offset PASS0_LINE-1
	xor		cl,cl					;REMARK FLAG
	xor		ch,ch					;TEXT FLAG
  @@:
	mov		al,[esi]
	mov		[edi],al
	inc		esi
	inc		edi
	.if al==0Ah
		;End of line
		mov		byte ptr [edi],00H
		inc		ebx
		mov		byte ptr [ebx],00H
		mov		eax,esi
		clc
		ret
	.elseif al==1Ah || al==00h
		;End of file
		dec		edi
		mov		dword ptr [edi],0A0Dh
		inc		ebx
		mov		word ptr [ebx],000Dh
		mov		eax,esi
		stc
		ret
	.elseif cl						;REMARK FLAG
		;Skip all except linefeed or eof
		jmp		@b
	.elseif al==09h && ch==00h
		;Convert tab to space
		mov		al,' '
	.elseif al=="'"
		xor		ch,0FFH				;TEXT FLAG
	.endif
	.if ch==00h						;TEXT FLAG
		.if al==' '
			;Convert space to 00h, test for previous
			xor		al,al
			cmp		al,[ebx]
			jz		@b
		.elseif al==';'
			mov		al,0DH
			inc		cl				;REMARK FLAG
		.endif
	.endif
	inc		ebx
	mov		[ebx],al
	jmp		@b

AsmLinePass0 endp

;PASS 1 ******************************************************

;00 EOL
;01 OP CODE
;02 DEF PROG LABEL			PROG_LABLE:
;03 DEF AUTO PROG LABEL		@@:
;04 DEF CONSTANT			CR			EQU	0DH
;							SCRN_ADR	EQU	0C000H
;							SCRN_ADR1	EQU	SCRN_ADR+CR+1
;05 DEF BYTE CONSTANTS		PRINT_DATA	DB 'ABCDEFGH',0DH,0AH,0
;06 DEF WORD CONSTANTS		ADR_DATA	DW 0C000H,0D000H,123

;08 DEF IMMEDIATE BYTE DATA	DB 0DH,CR
;09 DEF IMMEDIATE WORD DATA	DW 0C000H

;10 ASK PROG LABEL			JNZ	PROG_LABLE
;11							JNZ	$-2
;12							JNZ	@f
;							JNZ	@b
;13 ASK BYTE LABEL			MOV	A,#CR
;14 ASK WORD LABEL			MOV	DPTR,#SCRN_ADR+1
;2B +
;2C ,
;2D -

start:

	invoke GetStdHandle,STD_OUTPUT_HANDLE
	mov		hOut,eax
	invoke GetModuleHandle,NULL
	mov		hInstance,eax
	invoke GetCommandLine
	mov		CommandLine,eax
	;Get command line filename
	invoke PathGetArgs,CommandLine
	mov		CommandLine,eax
	mov		dl,[eax]
	.if dl!=0
		.if dl==34
			invoke PathUnquoteSpaces,eax
		.endif
	.endif
	mov		eax,CommandLine
	invoke lstrcpy,offset InpFile,eax
	invoke PrintStringz,offset szTitle
	invoke ReadAsmFile,offset InpFile
	.if eax
		mov		hAsmMem,eax
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,1024*64
		mov		hCmdMem,eax
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,1024*128
		mov		hDefMem,eax
		mov		DEF_LBL_ADR,eax
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,1024*128
		mov		hAskMem,eax
		mov		ASK_LBL_ADR,eax
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,1024*128
		mov		hLinMem,eax
		mov		LST_LIN_ADR,eax
		mov		eax,hAsmMem
		.while !CARRY?
			invoke AsmLinePass0,eax
			pushfd
			push	eax
PrintStringByAddr offset PASS0_LINE
;			invoke AsmLinePass1,eax
;			invoke AsmLinePass2,eax
			pop		eax
			popfd
		.endw
;		call	PASS2_PUT_LST
;		invoke AsmPass3
;		invoke SaveCmdFile
;		invoke AsmListFile
;		invoke AsmHexFile
	.endif
	xor		eax,eax
Exit:
	.if hAsmMem
		push	eax
		invoke GlobalFree,hAsmMem
		invoke GlobalFree,hCmdMem
		invoke GlobalFree,hDefMem
		invoke GlobalFree,hAskMem
		invoke GlobalFree,hLinMem
		pop		eax
	.endif
	invoke ExitProcess,eax

end start
