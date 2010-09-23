.386
.model flat, stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include asm51.inc
include Misc.asm

.code

HexLine proc uses eax ecx edx esi edi,lpLine:DWORD

	mov		esi,lpLine
	mov		edi,offset hexbuff
	mov		ecx,16
	.while ecx
		call	hexbyte
		mov		byte ptr [edi],20h
		inc		edi
		dec		ecx
	.endw
	mov		byte ptr [edi],0
	invoke MessageBox,NULL,addr hexbuff,addr szTitle,MB_OK
	ret

hexbyte:
	movzx	eax,byte ptr [esi]
	inc		esi
	push	eax
	shr		eax,4
	call	hexnib
	pop		eax
hexnib:
	and		eax,0Fh
	.if eax>9
		add		eax,41h-0Ah
	.else
		add		eax,30h
	.endif
	mov		[edi],al
	inc		edi
	retn

HexLine endp

;PASS 0 ******************************************************

;Preparse the line
AsmLinePass0 proc uses ebx esi edi,lpLine:DWORD

	inc		dword ptr Line_number
	mov		esi,lpLine
	mov		edi,offset Text_line
	mov		ebx,offset Pass0_line-1
	xor		cl,cl					;REMARK FLAG
	xor		ch,ch					;TEXT FLAG
  @@:
	mov		al,[esi]
	mov		[edi],al
	inc		esi
	inc		edi
	.if al==0Dh || al==0Ah
		;End of line
		mov		dword ptr [edi],0A0Dh
		inc		ebx
		mov		byte ptr [ebx],00h
		inc		ebx
		mov		byte ptr [ebx],0Dh
		mov		eax,esi
		clc
		ret
	.elseif al==1Ah || al==00h
		;End of file
		mov		dword ptr [edi],0A0Dh
		inc		ebx
		mov		byte ptr [ebx],0Dh
		mov		eax,esi
		stc
		ret
	.elseif cl						;REMARK FLAG
		;Skip all except CRLF or eof
		jmp		@b
	.elseif al==09h && ch==00h
		;Convert tab to space if not in string
		mov		al,' '
	.elseif al=="'"
		xor		ch,0FFh				;TEXT FLAG
	.endif
	.if ch==00h						;TEXT FLAG
		.if al==' '
			;Convert space to 00h, test for previous
			xor		al,al
			cmp		al,[ebx]
			jz		@b
		.elseif al==';'
			mov		al,00h
			inc		cl				;REMARK FLAG
		.endif
	.endif
	inc		ebx
	mov		[ebx],al
	jmp		@b

AsmLinePass0 endp

;PASS 1 ******************************************************

;00 EOL
;01 OP CODE					MOV, EQU etc.
;02 LABEL					PROG_LABLE:
;03 CONSTANT NAME			MYCONST		EQU 2
;04 HEX or DEC NUMBER		04H or 123
;23 #
;24 $
;2B +
;2C ,
;2D -

IsNumber proc uses esi,lpLine:DWORD

	mov		esi,lpLine
	.if byte ptr [esi]>='0' && byte ptr [esi]<='9'
		.while TRUE
			mov		ax,[esi]
			.if (al>='0' && al<='9') || (al>='A' && al<='F') || (al>='a' && al<='f') 
				inc		esi
			.elseif (al=='H' || al=='h' || !al) && (ah=='+' || ah=='-' || ah==',' || ah==0Dh || !ah)
				clc
				ret
			.else
				.break
			.endif
		.endw
	.endif
	stc
	ret

IsNumber endp

GetDecimal proc uses ebx

    xor     eax,eax
  @@:
    cmp     byte ptr [esi],30h
    jb      @f
    cmp     byte ptr [esi],3Ah
    jnb     @f
    mov     ebx,eax
    shl     eax,2
    add     eax,ebx
    shl     eax,1
    xor     ebx,ebx
    mov     bl,[esi]
    sub     bl,30h
    add     eax,ebx
    inc     esi
    jmp     @b
  @@:
	ret

GetDecimal endp

GetHex proc uses ebx

	xor		ebx,ebx
	.while byte ptr [esi]!='H' && byte ptr [esi]!='h'
		mov		al,[esi]
		.if al>='a' && al<='z'
			and		al,5Fh
		.endif
		sub		al,'0'
		cmp		al,0AH
		jb		@f
		sub		al,07H
	  @@:
		shl		ebx,4
		add		bl,al
		inc		esi
		inc		esi
	.endw
	inc		esi
	mov		eax,ebx
	ret

GetHex endp

IsOpcode proc uses ebx,lpLine:DWORD

	mov		ebx,offset Op_codes
	.while byte ptr [ebx]
		invoke strcmpi,esi,addr [ebx+1]
		.if !eax
			;Found
			mov		eax,ebx
			clc
			ret
		.endif
		invoke strlen,addr [ebx+1]
		lea		ebx,[ebx+eax+2]
	.endw
	stc
	ret

IsOpcode endp

SkipZero proc

	.while !byte ptr [esi]
		inc		esi
	.endw
	mov		al,[esi]
	ret

SkipZero endp

AsmLinePass1 proc uses ebx esi edi

	mov		esi,offset Pass0_line
	mov		edi,offset Pass1_line
	mov		dword ptr [edi],0
	.while byte ptr [esi]
		invoke SkipZero
		mov		al,[esi]
		.if al=='-' || al=='+' || al==','
			mov		[edi],al
			inc		esi
			inc		edi
		.elseif al==0Dh
			mov		byte ptr [edi],00h
			clc
			ret
		.else
			invoke IsNumber,esi
			.if !CARRY?
				.if !al
					;Decimal
					invoke GetDecimal
				.else
					;Hex
					invoke GetHex
				.endif
				mov		byte ptr [edi],PASS1_NUMBER
				inc		edi
				mov		[edi],ax
				inc		edi
				inc		edi
			.else
				invoke IsOpcode,esi
				.if !CARRY?
					;Op code
					.if byte ptr [eax]==0FBh
						;@b
						mov		byte ptr [edi],PASS1_LABEL
						inc		edi
						invoke wsprintf,addr tmplbl,addr fmttmplbl,ntmplbl
						invoke lstrcpy,edi,addr tmplbl
						lea		edi,[edi+7]
					.elseif byte ptr [eax]==0FCh
						;@f
						mov		byte ptr [edi],PASS1_LABEL
						inc		edi
						mov		eax,ntmplbl
						invoke wsprintf,addr tmplbl,addr fmttmplbl,addr [eax-1]
						invoke lstrcpy,edi,addr tmplbl
						lea		edi,[edi+7]
					.else
						mov		byte ptr [edi],PASS1_OPCODE
						inc		edi
						mov		al,[eax]
						mov		[edi],al
						inc		edi
					.endif
					invoke strlen,esi
					lea		esi,[esi+eax+1]
				.else
					mov		al,[esi]
					.if (al>='@' && al<='Z') || (al>='a' && al<='z')
						;Label
						invoke strlen,esi
						.if byte ptr [esi+eax-1]==':'
							;Label
							mov		byte ptr [edi],PASS1_LABEL
							inc		edi
							.if dword ptr [esi]==':@@'
								;Auto label
								invoke wsprintf,addr tmplbl,addr fmttmplbl,ntmplbl
								invoke lstrcpy,edi,addr tmplbl
								lea		esi,[esi+4]
								lea		edi,[edi+7]
								inc		ntmplbl
							.else
								;Program label
								invoke lstrcpyn,edi,esi,eax
								invoke strlen,esi
								lea		edi,[edi+eax]
								lea		esi,[esi+eax+1]
							.endif
						.else
							;Const name
							mov		byte ptr [edi],PASS1_CONST
							inc		edi
							invoke lstrcpy,edi,esi
							invoke strlen,esi
							lea		edi,[edi+eax+1]
							lea		esi,[esi+eax+1]
						.endif
					.else
						call Err
						db	'PASS 1 SYNTAX ERROR : ',0
					.endif
				.endif
			.endif
		.endif
	.endw
	stc
	ret

AsmLinePass1 endp

;PASS 2 ******************************************************

AddLabel proc uses ebx esi edi,lpname:DWORD,ntype:DWORD

	ret

AddLabel endp

AsmLinePass2 proc uses ebx esi edi
	LOCAL deflbl:DEFLBL

	mov		esi,offset Pass1_line
	.while byte ptr [esi] && byte ptr [esi]!=0Dh
		movzx	eax,byte ptr [esi]
		inc		esi
		.if eax==PASS1_OPCODE
PrintText "PASS1_OPCODE"
			inc		esi
		.elseif eax==PASS1_LABEL
PrintText "PASS1_LABEL"
			invoke strlen,esi
			lea		esi,[esi+eax+1]
		.elseif eax==PASS1_CONST
PrintText "PASS1_CONST"
			mov		ebx,esi
			invoke strlen,esi
			lea		esi,[esi+eax+1]
			.if byte ptr [esi]==PASS1_OPCODE
				inc		esi
				movzx	eax,byte ptr [esi]
				inc		esi
				.if eax==0F0h
					;EQU
					movzx	eax,byte ptr [esi]
					inc		esi
					.if eax==PASS1_CONST
					.elseif eax==PASS1_NUMBER
					.endif
				.elseif eax==0F1h
					;DB
				.elseif eax==0F2h
					;DW
				.elseif eax==0FAh
					;BIT
				.else
					call Err
					db	'PASS 2 SYNTAX ERROR : ',0
				.endif
			.else
				call Err
				db	'PASS 2 SYNTAX ERROR : ',0
			.endif
		.elseif eax==PASS1_NUMBER
PrintText "PASS1_NUMBER"
			add		esi,2
		.endif
	.endw
	ret

AsmLinePass2 endp

;PASS 3 ******************************************************

;*************************************************************

Err:
	invoke PrintLineNumber,Line_number
	call PrintStringz
	mov		eax,offset Text_line
	.while byte ptr [eax] && (byte ptr [eax]==20h || byte ptr [eax]==09h)
		inc		eax
	.endw
	invoke PrintStringz,eax
	mov		eax,1
	jmp		Exit

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

invoke lstrcpy,offset InpFile,offset szTestFile

	invoke ReadAsmFile,offset InpFile
	.if eax
		mov		hAsmMem,eax
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,1024*64
		mov		hCmdMem,eax
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,1024*128
		mov		hDefMem,eax
		mov		Def_lbl_adr,eax
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,1024*128
		mov		hAskMem,eax
		mov		Ask_lbl_adr,eax
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,1024*128
		mov		hNameMem,eax
		mov		Name_adr,eax
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,1024*128
		mov		hLinMem,eax
		mov		Lst_lin_adr,eax
		mov		eax,hAsmMem
		.while !CARRY?
			invoke AsmLinePass0,eax
			pushfd
			push	eax
;invoke HexLine,addr Pass0_line
			invoke AsmLinePass1
;invoke HexLine,addr Pass1_line
;.break
			invoke AsmLinePass2
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
		invoke GlobalFree,hNameMem
		invoke GlobalFree,hLinMem
		pop		eax
	.endif
	mov		ecx,2000000000
	.while ecx
		.while edx
			dec		edx
		.endw
		dec		ecx
	.endw
;	mov		ecx,2000000000
;	.while ecx
;		.while edx
;			dec		edx
;		.endw
;		dec		ecx
;	.endw
	invoke ExitProcess,eax

end start
