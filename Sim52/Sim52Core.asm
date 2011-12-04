
SFR_P0      		equ 080h
SFR_SP      		equ 081h
SFR_DPL     		equ 082h
SFR_DPH     		equ 083h
SFR_DP1L     		equ 084h
SFR_DP1H     		equ 085h
SFR_PCON    		equ 087h
SFR_TCON    		equ 088h
SFR_TMOD    		equ 089h
SFR_TL0     		equ 08Ah
SFR_TL1     		equ 08Bh
SFR_TH0     		equ 08Ch
SFR_TH1     		equ 08Dh
SFR_AUXR    		equ 08Eh
SFR_P1      		equ 090h
SFR_SCON    		equ 098h
SFR_SBUF    		equ 099h
SFR_P2      		equ 0A0h
SFR_AUXR1   		equ 0A2h
SFR_WDTRST  		equ 0A6h
SFR_IE      		equ 0A8h
SFR_P3      		equ 0B0h
SFR_IP      		equ 0B8h
SFR_T2CON   		equ 0C8h
SFR_T2MOD   		equ 0C9h
SFR_RCAP2L  		equ 0CAh
SFR_RCAP2H  		equ 0CBh
SFR_TL2     		equ 0CCh
SFR_TH2     		equ 0CDh
SFR_PSW     		equ 0D0h
SFR_ACC     		equ 0E0h
SFR_B       		equ 0F0h

STATE_STOP			equ 0
STATE_RUN			equ 1
STATE_PAUSE			equ 2
STATE_STEP_INTO		equ 4
STATE_STEP_OVER		equ 8
STATE_RUN_TO_CURSOR	equ 16
STATE_BREAKPOINT	equ 32

STATE_THREAD		equ 128

.data

JmpTab				dd NOP_,AJMP_$cad,LJMP_$cad,RR_A,INC_A,INC_$dad,INC_@R0,INC_@R1,INC_R0,INC_R1,INC_R2,INC_R3,INC_R4,INC_R5,INC_R6,INC_R7
					dd JBC$bad_$cad,ACALL_$cad,LCALL_$cad,RRC_A,DEC_A,DEC_$dad,DEC_@R0,DEC_@R1,DEC_R0,DEC_R1,DEC_R2,DEC_R3,DEC_R4,DEC_R5,DEC_R6,DEC_R7
					dd JB_$bad_$cad,AJMP_$cad,RET_,RL_A,ADD_A_imm,ADD_A_$dad,ADD_A_@R0,ADD_A_@R1,ADD_A_R0,ADD_A_R1,ADD_A_R2,ADD_A_R3,ADD_A_R4,ADD_A_R5,ADD_A_R6,ADD_A_R7
					dd JNB_$bad_$cad,ACALL_$cad,RETI_,RLC_A,ADDC_A_imm,ADDC_A_$dad,ADDC_A_@R0,ADDC_A_@R1,ADDC_A_R0,ADDC_A_R1,ADDC_A_R2,ADDC_A_R3,ADDC_A_R4,ADDC_A_R5,ADDC_A_R6,ADDC_A_R7

					dd JC_$cad,AJMP_$cad,ORL_$dad_A,ORL_$dad_imm,ORL_A_imm,ORL_A_$dad,ORL_A_@R0,ORL_A_@R1,ORL_A_R0,ORL_A_R1,ORL_A_R2,ORL_A_R3,ORL_A_R4,ORL_A_R5,ORL_A_R6,ORL_A_R7
					dd JNC_$cad,ACALL_$cad,ANL_$dad_A,ANL_$dad_imm,ANL_A_imm,ANL_A_$dad,ANL_A_@R0,ANL_A_@R1,ANL_A_R0,ANL_A_R1,ANL_A_R2,ANL_A_R3,ANL_A_R4,ANL_A_R5,ANL_A_R6,ANL_A_R7
					dd JZ_$cad,AJMP_$cad,XRL_$dad_A,XRL_$dad_imm,XRL_A_imm,XRL_A_$dad,XRL_A_@R0,XRL_A_@R1,XRL_A_R0,XRL_A_R1,XRL_A_R2,XRL_A_R3,XRL_A_R4,XRL_A_R5,XRL_A_R6,XRL_A_R7
					dd JNZ_$cad,ACALL_$cad,ORL_C_$bad,JMP_@A_DPTR,MOV_A_imm,MOV_$dad_imm,MOV_@R0_imm,MOV_@R1_imm,MOV_R0_imm,MOV_R1_imm,MOV_R2_imm,MOV_R3_imm,MOV_R4_imm,MOV_R5_imm,MOV_R6_imm,MOV_R7_imm

					dd SJMP_$cad,AJMP_$cad,ANL_C_$bad,MOVC_A_@A_PC,DIV_AB,MOV_$dad_$dad,MOV_$dad_@R0,MOV_$dad_@R1,MOV_$dad_R0,MOV_$dad_R1,MOV_$dad_R2,MOV_$dad_R3,MOV_$dad_R4,MOV_$dad_R5,MOV_$dad_R6,MOV_$dad_R7
					dd MOV_DPTR_dw,ACALL_$cad,MOV_$bad_C,MOVC_A_@A_DPTR,SUBB_A_imm,SUBB_A_$dad,SUBB_A_@R0,SUBB_A_@R1,SUBB_A_R0,SUBB_A_R1,SUBB_A_R2,SUBB_A_R3,SUBB_A_R4,SUBB_A_R5,SUBB_A_R6,SUBB_A_R7
					dd ORL_C_n$bad,AJMP_$cad,MOV_C_$bad,INC_DPTR,MUL_AB,reserved,MOV_@R0_$dad,MOV_@R1_$dad,MOV_R0_$dad,MOV_R1_$dad,MOV_R2_$dad,MOV_R3_$dad,MOV_R4_$dad,MOV_R5_$dad,MOV_R6_$dad,MOV_R7_$dad
					dd ANL_C_n$bad,ACALL_$cad,CPL_$bad,CPL_C,CJNE_A_imm_$cad,CJNE_A_$dad_$cad,CJNE_@R0_imm_$cad,CJNE_@R1_imm_$cad,CJNE_R0_imm_$cad,CJNE_R1_imm_$cad,CJNE_R2_imm_$cad,CJNE_R3_imm_$cad,CJNE_R4_imm_$cad,CJNE_R5_imm_$cad,CJNE_R6_imm_$cad,CJNE_R7_imm_$cad

					dd PUSH_$dad,AJMP_$cad,CLR_$bad,CLR_C,SWAP_A,XCH_A_$dad,XCH_A_@R0,XCH_A_@R1,XCH_A_R0,XCH_A_R1,XCH_A_R2,XCH_A_R3,XCH_A_R4,XCH_A_R5,XCH_A_R6,XCH_A_R7
					dd POP_$dad,ACALL_$cad,SETB_$bad,SETB_C,DA_A,DJNZ_$dad_$cad,XCHD_A_@R0,XCHD_A_@R1,DJNZ_R0_$cad,DJNZ_R1_$cad,DJNZ_R2_$cad,DJNZ_R3_$cad,DJNZ_R4_$cad,DJNZ_R5_$cad,DJNZ_R6_$cad,DJNZ_R7_$cad
					dd MOVX_A_@DPTR,AJMP_$cad,MOVX_A_@R0,MOVX_A_@R1,CLR_A,MOV_A_$dad,MOV_A_@R0,MOV_A_@R1,MOV_A_R0,MOV_A_R1,MOV_A_R2,MOV_A_R3,MOV_A_R4,MOV_A_R5,MOV_A_R6,MOV_A_R7
					dd MOVX_@DPTR_A,ACALL_$cad,MOVX_@R0_A,MOVX_@R1_A,CPL_A,MOV_$dad_A,MOV_@R0_A,MOV_@R1_A,MOV_R0_A,MOV_R1_A,MOV_R2_A,MOV_R3_A,MOV_R4_A,MOV_R5_A,MOV_R6_A,MOV_R7_A

Cycles				db 1,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1
					db 2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1
					db 2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1
					db 2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1
					db 2,2,1,2,1,1,1,1,1,1,1,1,1,1,1,1
					db 2,2,1,2,1,1,1,1,1,1,1,1,1,1,1,1
					db 2,2,1,2,1,1,1,1,1,1,1,1,1,1,1,1
					db 2,2,2,2,1,2,1,1,1,1,1,1,1,1,1,1
					db 2,2,2,2,4,2,2,2,2,2,2,2,2,2,2,2
					db 2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1
					db 2,2,1,2,4,0,2,2,2,2,2,2,2,2,2,2
					db 2,2,1,1,2,2,2,2,2,2,2,2,2,2,2,2
					db 2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1
					db 2,2,1,1,1,2,1,1,2,2,2,2,2,2,2,2
					db 2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1
					db 2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1

Bytes				db 1,2,3,1,1,2,1,1,1,1,1,1,1,1,1,1
					db 3,2,3,1,1,2,1,1,1,1,1,1,1,1,1,1
					db 3,2,1,1,2,2,1,1,1,1,1,1,1,1,1,1
					db 3,2,1,1,2,2,1,1,1,1,1,1,1,1,1,1
					db 2,2,2,3,2,2,1,1,1,1,1,1,1,1,1,1
					db 2,2,2,3,2,2,1,1,1,1,1,1,1,1,1,1
					db 2,2,2,3,2,2,1,1,1,1,1,1,1,1,1,1
					db 2,2,2,1,2,3,2,2,2,2,2,2,2,2,2,2
					db 2,2,2,1,1,3,2,2,2,2,2,2,2,2,2,2
					db 3,2,2,1,2,2,1,1,1,1,1,1,1,1,1,1
					db 2,2,2,1,1,0,2,2,2,2,2,2,2,2,2,2
					db 2,2,2,1,3,3,3,3,3,3,3,3,3,3,3,3
					db 2,2,2,1,1,2,1,1,1,1,1,1,1,1,1,1
					db 2,2,2,1,1,3,1,1,2,2,2,2,2,2,2,2
					db 1,2,1,1,1,2,1,1,1,1,1,1,1,1,1,1
					db 1,2,1,1,1,2,1,1,1,1,1,1,1,1,1,1

.data?

hMemFile			HGLOBAL ?
hMemAddr			HGLOBAL ?

Sfr					db 256 dup(?)
Ram					db 256 dup(?)
XRam				db 65536 dup(?)
Code				db 65536 dup(?)
Bank				dd ?
PC					dd ?
nAddr				dd ?

ViewBank			DD ?
Refresh				dd ?
State				dd ?
CursorAddr			dd ?
TotalCycles			dd ?
PerformanceCount		dq ?
PerformanceFrequency	dq ?

.code

Reset proc

	mov		State,STATE_STOP
	mov		PC,0
	mov		Sfr[SFR_P0],0FFh
	mov		Sfr[SFR_SP],07h
	mov		Sfr[SFR_DPL],00h
	mov		Sfr[SFR_DPH],00h
	mov		Sfr[SFR_DP1L],00h
	mov		Sfr[SFR_DP1H],00h
	mov		Sfr[SFR_PCON],00h
	mov		Sfr[SFR_TCON],00h
	mov		Sfr[SFR_TMOD],00h
	mov		Sfr[SFR_TL0],00h
	mov		Sfr[SFR_TL1],00h
	mov		Sfr[SFR_TH0],00h
	mov		Sfr[SFR_TH1],00h
	mov		Sfr[SFR_AUXR],00h
	mov		Sfr[SFR_P1],0FFh
	mov		Sfr[SFR_SCON],00h
	mov		Sfr[SFR_SBUF],00h
	mov		Sfr[SFR_P2],0FFh
	mov		Sfr[SFR_AUXR1],00h
	mov		Sfr[SFR_WDTRST],00h
	mov		Sfr[SFR_IE],00h
	mov		Sfr[SFR_P3],0FFh
	mov		Sfr[SFR_IP],00h
	mov		Sfr[SFR_T2CON],00h
	mov		Sfr[SFR_T2MOD],00h
	mov		Sfr[SFR_RCAP2L],00h
	mov		Sfr[SFR_RCAP2H],00h
	mov		Sfr[SFR_TL2],00h
	mov		Sfr[SFR_TH2],00h
	mov		Sfr[SFR_PSW],00h
	mov		Sfr[SFR_ACC],00h
	mov		Sfr[SFR_B],00h
	mov		Refresh,1
	ret

Reset endp

;FindMcuAddr proc uses esi,McuAddr:DWORD
;
;	mov		esi,hMemAddr
;	xor		eax,eax
;	.if esi
;		mov		edx,McuAddr
;		xor		ecx,ecx
;		.while dx!=[esi].MCUADDR.mcuaddr && ecx<nAddr
;			inc		ecx
;			lea		esi,[esi+sizeof MCUADDR]
;		.endw
;		.if dx==[esi].MCUADDR.mcuaddr
;			mov		eax,esi
;		.endif
;	.endif
;	ret
;
;FindMcuAddr endp

FindMcuAddr proc uses ebx esi edi,Address:DWORD
	LOCAL	inx:DWORD
	LOCAL	lower:DWORD
	LOCAL	upper:DWORD

	mov		esi,hMemAddr
	xor		eax,eax
	.if esi
		mov		lower,0
		mov		eax,nAddr
		mov		upper,eax
		xor		ebx,ebx
		.while TRUE
			mov		eax,upper
			sub		eax,lower
			.break .if !eax
			shr		eax,1
			add		eax,lower
			mov		inx,eax
			mov		edx,sizeof MCUADDR
			mul		edx
			movzx	edx,[esi+eax].MCUADDR.mcuaddr
			mov		eax,Address
			sub		eax,edx
			.if !eax || ebx>30
				; Found
				jmp		Ex
			.elseif sdword ptr eax<0
				; Smaller
				mov		eax,inx
				mov		upper,eax
			.elseif sdword ptr eax>0
				; Larger
				mov		eax,inx
				mov		lower,eax
			.endif
			inc		ebx
		.endw
		; Not found, should never happend
PrintHex ebx
	  Ex:
		mov		eax,inx
		mov		edx,sizeof MCUADDR
		mul		edx
		lea		eax,[esi+eax]
	.endif
	ret

FindMcuAddr endp

FindLbInx proc uses esi,LbInx:DWORD

	mov		esi,hMemAddr
	xor		eax,eax
	.if esi
		mov		edx,LbInx
		xor		ecx,ecx
		.while dx!=[esi].MCUADDR.lbinx && ecx<nAddr
			inc		ecx
			lea		esi,[esi+sizeof MCUADDR]
		.endw
		.if dx==[esi].MCUADDR.lbinx
			mov		eax,esi
		.endif
	.endif
	ret

FindLbInx endp

UpdateStatus proc uses ebx
	LOCAL	buffer[16]:BYTE

	mov		eax,PC
	invoke wsprintf,addr buffer,addr szFmtHexWord,eax
	invoke SetDlgItemText,hWnd,IDC_EDTPC,addr buffer
	movzx	eax,word ptr Sfr(SFR_DPL)
	invoke wsprintf,addr buffer,addr szFmtHexWord,eax
	invoke SetDlgItemText,hWnd,IDC_EDTDPTR,addr buffer
	movzx	eax,Sfr(SFR_ACC)
	invoke wsprintf,addr buffer,addr szFmtHexByte,eax
	invoke SetDlgItemText,hWnd,IDC_EDTACC,addr buffer
	movzx	eax,Sfr(SFR_B)
	invoke wsprintf,addr buffer,addr szFmtHexByte,eax
	invoke SetDlgItemText,hWnd,IDC_EDTB,addr buffer
	movzx	eax,Sfr(SFR_SP)
	invoke wsprintf,addr buffer,addr szFmtHexByte,eax
	invoke SetDlgItemText,hWnd,IDC_EDTSP,addr buffer
	push	0
	push	IDC_IMGCY
	push	IDC_IMGAC
	push	IDC_IMGF0
	push	IDC_IMGRS1
	push	IDC_IMGRS0
	push	IDC_IMGOV
	push	IDC_IMGFL
	push	IDC_IMGP
	movzx	ebx,Sfr(SFR_PSW)
	pop		eax
	.while eax
		shr		ebx,1
		.if CARRY?
			invoke SendDlgItemMessage,hWnd,eax,STM_SETIMAGE,IMAGE_BITMAP,hBmpRedLed
		.else
			invoke SendDlgItemMessage,hWnd,eax,STM_SETIMAGE,IMAGE_BITMAP,hBmpGrayLed
		.endif
		pop		eax
	.endw

	invoke SendDlgItemMessage,hWnd,IDC_LSTCODE,LB_GETCOUNT,0,0
	mov		ebx,eax
	mov		edx,hMemAddr
	invoke FindMcuAddr,PC
	.if eax
		movzx	eax,[eax].MCUADDR.lbinx
		invoke SendDlgItemMessage,hWnd,IDC_LSTCODE,LB_SETCURSEL,eax,0
	.endif
	ret

UpdateStatus endp

UpdatePorts proc uses ebx

	push	0
	push	IDC_IMGP0_0
	push	IDC_IMGP0_1
	push	IDC_IMGP0_2
	push	IDC_IMGP0_3
	push	IDC_IMGP0_4
	push	IDC_IMGP0_5
	push	IDC_IMGP0_6
	push	IDC_IMGP0_7
	movzx	ebx,Sfr(SFR_P0)
	pop		eax
	.while eax
		shl		bl,1
		.if CARRY?
			invoke SendDlgItemMessage,hWnd,eax,STM_SETIMAGE,IMAGE_BITMAP,hBmpGreenLed
		.else
			invoke SendDlgItemMessage,hWnd,eax,STM_SETIMAGE,IMAGE_BITMAP,hBmpGrayLed
		.endif
		pop		eax
	.endw
	push	0
	push	IDC_IMGP1_0
	push	IDC_IMGP1_1
	push	IDC_IMGP1_2
	push	IDC_IMGP1_3
	push	IDC_IMGP1_4
	push	IDC_IMGP1_5
	push	IDC_IMGP1_6
	push	IDC_IMGP1_7
	movzx	ebx,Sfr(SFR_P1)
	pop		eax
	.while eax
		shl		bl,1
		.if CARRY?
			invoke SendDlgItemMessage,hWnd,eax,STM_SETIMAGE,IMAGE_BITMAP,hBmpGreenLed
		.else
			invoke SendDlgItemMessage,hWnd,eax,STM_SETIMAGE,IMAGE_BITMAP,hBmpGrayLed
		.endif
		pop		eax
	.endw
	push	0
	push	IDC_IMGP2_0
	push	IDC_IMGP2_1
	push	IDC_IMGP2_2
	push	IDC_IMGP2_3
	push	IDC_IMGP2_4
	push	IDC_IMGP2_5
	push	IDC_IMGP2_6
	push	IDC_IMGP2_7
	movzx	ebx,Sfr(SFR_P2)
	pop		eax
	.while eax
		shl		bl,1
		.if CARRY?
			invoke SendDlgItemMessage,hWnd,eax,STM_SETIMAGE,IMAGE_BITMAP,hBmpGreenLed
		.else
			invoke SendDlgItemMessage,hWnd,eax,STM_SETIMAGE,IMAGE_BITMAP,hBmpGrayLed
		.endif
		pop		eax
	.endw
	push	0
	push	IDC_IMGP3_0
	push	IDC_IMGP3_1
	push	IDC_IMGP3_2
	push	IDC_IMGP3_3
	push	IDC_IMGP3_4
	push	IDC_IMGP3_5
	push	IDC_IMGP3_6
	push	IDC_IMGP3_7
	movzx	ebx,Sfr(SFR_P3)
	pop		eax
	.while eax
		shl		bl,1
		.if CARRY?
			invoke SendDlgItemMessage,hWnd,eax,STM_SETIMAGE,IMAGE_BITMAP,hBmpGreenLed
		.else
			invoke SendDlgItemMessage,hWnd,eax,STM_SETIMAGE,IMAGE_BITMAP,hBmpGrayLed
		.endif
		pop		eax
	.endw
	ret

UpdatePorts endp

UpdateRegisters proc uses ebx esi
	LOCAL	buffer[16]:BYTE

	push	0
	push	IDC_EDTR7
	push	IDC_EDTR6
	push	IDC_EDTR5
	push	IDC_EDTR4
	push	IDC_EDTR3
	push	IDC_EDTR2
	push	IDC_EDTR1
	push	IDC_EDTR0
	mov		esi,offset Ram
	mov		eax,ViewBank
	lea		esi,[esi+eax*8]
	pop		ebx
	.while ebx
		movzx	eax,byte ptr [esi]
		invoke wsprintf,addr buffer,addr szFmtHexByte,eax
		invoke SetDlgItemText,hWnd,ebx,addr buffer
		inc		esi
		pop		ebx
	.endw
	ret

UpdateRegisters endp

ToggleBreakPoint proc lbinx:DWORD

	invoke FindLbInx,lbinx
	.if eax
		xor		[eax].MCUADDR.fbp,TRUE
	.endif
	ret

ToggleBreakPoint endp

ClearBreakPoints proc

	mov		edx,hMemAddr
	.if edx
		xor		ecx,ecx
		.while ecx<nAddr
			mov		[edx].MCUADDR.fbp,0
			inc		ecx
			lea		edx,[edx+sizeof MCUADDR]
		.endw
	.endif
	ret

ClearBreakPoints endp

IsAddrBreakPoint proc uses esi,mcuaddr:DWORD

	invoke FindMcuAddr,mcuaddr
	.if eax
		movzx	eax,[eax].MCUADDR.fbp
	.else
		dec		eax
	.endif
	ret

IsAddrBreakPoint endp

SetParity proc

	ret

SetParity endp

SetFlags proc

	pushfd
	pop		eax
	;Carry
	test	eax,1
	.if ZERO?
		and		Sfr[SFR_PSW],7Fh
	.else
		or		Sfr[SFR_PSW],80h
	.endif
	;Parity
	test	eax,4
	.if ZERO?
		and		Sfr[SFR_PSW],0FEh
	.else
		or		Sfr[SFR_PSW],01h
	.endif
	;Auxiliary Flag
	test	eax,16
	.if ZERO?
		and		Sfr[SFR_PSW],0BFh
	.else
		or		Sfr[SFR_PSW],40h
	.endif
	;Overflow flag
	test	eax,2048
	.if ZERO?
		and		Sfr[SFR_PSW],0FBh
	.else
		or		Sfr[SFR_PSW],04h
	.endif
	ret

SetFlags endp

;------------------------------------------------------------------------------
NOP_:
	lea		ebx,[ebx+1]
	ret

AJMP_$cad:
	movzx	eax,word ptr [esi+ebx]
	xchg	al,ah
	shr		ah,5
	lea		ebx,[ebx+2]
	and		ebx,0F800h
	lea		ebx,[ebx+eax]
	ret

LJMP_$cad:
	movzx	ebx,word ptr [esi+ebx+1]
	xchg	bl,bh
	ret

RR_A:
	ror		Sfr[SFR_ACC],1
	lea		ebx,[ebx+1]
	ret

INC_A:
	inc		Sfr[SFR_ACC]
	invoke SetParity
	lea		ebx,[ebx+1]
	ret

INC_$dad:
	movzx	edx,byte ptr [esi+ebx+1]
	.if edx<80h
		inc		Ram[edx]
	.else
		inc		Sfr[edx]
	.endif
	lea		ebx,[ebx+2]
	ret

INC_@R0:
	mov		eax,Bank
	lea		eax,[eax*8+0]
	movzx	eax,Ram[eax]
	inc		Ram[eax]
	lea		ebx,[ebx+1]
	ret

INC_@R1:
	mov		eax,Bank
	lea		eax,[eax*8+1]
	movzx	eax,Ram[eax]
	inc		Ram[eax]
	lea		ebx,[ebx+1]
	ret

INC_R0:
	mov		eax,Bank
	lea		eax,[eax*8+0]
	inc		Ram[eax]
	lea		ebx,[ebx+1]
	ret

INC_R1:
	mov		eax,Bank
	lea		eax,[eax*8+1]
	inc		Ram[eax]
	lea		ebx,[ebx+1]
	ret

INC_R2:
	mov		eax,Bank
	lea		eax,[eax*8+2]
	inc		Ram[eax]
	lea		ebx,[ebx+1]
	ret

INC_R3:
	mov		eax,Bank
	lea		eax,[eax*8+3]
	inc		Ram[eax]
	lea		ebx,[ebx+1]
	ret

INC_R4:
	mov		eax,Bank
	lea		eax,[eax*8+4]
	inc		Ram[eax]
	lea		ebx,[ebx+1]
	ret

INC_R5:
	mov		eax,Bank
	lea		eax,[eax*8+5]
	inc		Ram[eax]
	lea		ebx,[ebx+1]
	ret

INC_R6:
	mov		eax,Bank
	lea		eax,[eax*8+6]
	inc		Ram[eax]
	lea		ebx,[ebx+1]
	ret

INC_R7:
	mov		eax,Bank
	lea		eax,[eax*8+7]
	inc		Ram[eax]
	lea		ebx,[ebx+1]
	ret

;------------------------------------------------------------------------------
JBC$bad_$cad:
	movzx	ecx,word ptr [esi+ebx+1]
	lea		ebx,[ebx+3]
	movzx	eax,cl
	and		cl,07h
	mov		edx,1
	shl		edx,cl
	.if al<80h
		shr		eax,3
		lea		eax,[eax+20h]
	.else
		and		eax,0F8h
	.endif
	test	Ram[eax],dl
	.if !ZERO?
		xor		Ram[eax],dl
		movsx	ecx,ch
		lea		ebx,[ebx+ecx]
	.endif
	ret

ACALL_$cad:
	movzx	eax,word ptr [esi+ebx]
	xchg	al,ah
	lea		ebx,[ebx+2]
	movzx	edx,Sfr[SFR_SP]
	inc		dl
	mov		Ram[edx],bl
	inc		dl
	mov		Ram[edx],bh
	mov		Sfr[SFR_SP],dl
	shr		ah,5
	and		ebx,0F800h
	lea		ebx,[ebx+eax]
	ret

LCALL_$cad:
	movzx	eax,word ptr [esi+ebx+1]
	xchg	al,ah
	lea		ebx,[ebx+3]
	movzx	edx,Sfr[SFR_SP]
	inc		dl
	mov		Ram[edx],bl
	inc		dl
	mov		Ram[edx],bh
	mov		Sfr[SFR_SP],dl
	mov		ebx,eax
	ret

RRC_A:
	test	Sfr[SFR_PSW],80h
	clc
	.if !ZERO?
		stc
	.endif
	rcr		Sfr[SFR_ACC],1
	.if CARRY?
		or		Sfr[SFR_PSW],80h
	.else
		and		Sfr[SFR_PSW],7Fh
	.endif
	lea		ebx,[ebx+1]
	ret

DEC_A:
	dec		Sfr[SFR_ACC]
	invoke SetParity
	lea		ebx,[ebx+1]
	ret

DEC_$dad:
	movzx	edx,byte ptr [esi+ebx+1]
	.if edx<80h
		dec		Ram[edx]
	.else
		dec		Sfr[edx]
	.endif
	lea		ebx,[ebx+2]
	ret

DEC_@R0:
	mov		eax,Bank
	lea		eax,[eax*8+0]
	movzx	eax,Ram[eax]
	dec		Ram[eax]
	lea		ebx,[ebx+1]
	ret

DEC_@R1:
	mov		eax,Bank
	lea		eax,[eax*8+1]
	movzx	eax,Ram[eax]
	dec		Ram[eax]
	lea		ebx,[ebx+1]
	ret

DEC_R0:
	mov		eax,Bank
	lea		eax,[eax*8+0]
	dec		Ram[eax]
	lea		ebx,[ebx+1]
	ret

DEC_R1:
	mov		eax,Bank
	lea		eax,[eax*8+1]
	dec		Ram[eax]
	lea		ebx,[ebx+1]
	ret

DEC_R2:
	mov		eax,Bank
	lea		eax,[eax*8+2]
	dec		Ram[eax]
	lea		ebx,[ebx+1]
	ret

DEC_R3:
	mov		eax,Bank
	lea		eax,[eax*8+3]
	dec		Ram[eax]
	lea		ebx,[ebx+1]
	ret

DEC_R4:
	mov		eax,Bank
	lea		eax,[eax*8+4]
	dec		Ram[eax]
	lea		ebx,[ebx+1]
	ret

DEC_R5:
	mov		eax,Bank
	lea		eax,[eax*8+5]
	dec		Ram[eax]
	lea		ebx,[ebx+1]
	ret

DEC_R6:
	mov		eax,Bank
	lea		eax,[eax*8+6]
	dec		Ram[eax]
	lea		ebx,[ebx+1]
	ret

DEC_R7:
	mov		eax,Bank
	lea		eax,[eax*8+7]
	dec		Ram[eax]
	lea		ebx,[ebx+1]
	ret

;------------------------------------------------------------------------------
JB_$bad_$cad:
	movzx	ecx,word ptr [esi+ebx+1]
	lea		ebx,[ebx+3]
	movzx	eax,cl
	and		cl,07h
	mov		edx,1
	shl		edx,cl
	.if al<80h
		shr		eax,3
		lea		eax,[eax+20h]
	.else
		and		eax,0F8h
	.endif
	test	Ram[eax],dl
	.if !ZERO?
		movsx	ecx,ch
		lea		ebx,[ebx+ecx]
	.endif
	ret

RET_:
	movzx	edx,Sfr[SFR_SP]
	mov		bh,Ram[edx]
	dec		dl
	mov		bl,Ram[edx]
	dec		dl
	mov		Sfr[SFR_SP],dl
	ret

RL_A:
	rol		Sfr[SFR_ACC],1
	lea		ebx,[ebx+1]
	ret

ADD_A_imm:
	movzx	eax,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	add		Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ADD_A_$dad:
	movzx	edx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	.if edx<80h
		movzx	eax,Ram[edx]
	.else
		movzx	eax,Sfr[edx]
	.endif
	add		Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ADD_A_@R0:
	mov		eax,Bank
	lea		eax,[eax*8+0]
	movzx	eax,Ram[eax]
	movzx	eax,Ram[eax]
	add		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADD_A_@R1:
	mov		eax,Bank
	lea		eax,[eax*8+1]
	movzx	eax,Ram[eax]
	movzx	eax,Ram[eax]
	add		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADD_A_R0:
	mov		eax,Bank
	lea		eax,[eax*8+0]
	movzx	eax,Ram[eax]
	add		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADD_A_R1:
	mov		eax,Bank
	lea		eax,[eax*8+1]
	movzx	eax,Ram[eax]
	add		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADD_A_R2:
	mov		eax,Bank
	lea		eax,[eax*8+2]
	movzx	eax,Ram[eax]
	add		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADD_A_R3:
	mov		eax,Bank
	lea		eax,[eax*8+3]
	movzx	eax,Ram[eax]
	add		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADD_A_R4:
	mov		eax,Bank
	lea		eax,[eax*8+4]
	movzx	eax,Ram[eax]
	add		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADD_A_R5:
	mov		eax,Bank
	lea		eax,[eax*8+5]
	movzx	eax,Ram[eax]
	add		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADD_A_R6:
	mov		eax,Bank
	lea		eax,[eax*8+6]
	movzx	eax,Ram[eax]
	add		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADD_A_R7:
	mov		eax,Bank
	lea		eax,[eax*8+7]
	movzx	eax,Ram[eax]
	add		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

;------------------------------------------------------------------------------
JNB_$bad_$cad:
	movzx	ecx,word ptr [esi+ebx+1]
	lea		ebx,[ebx+3]
	movzx	eax,cl
	and		cl,07h
	mov		edx,1
	shl		edx,cl
	.if al<80h
		shr		eax,3
		lea		eax,[eax+20h]
	.else
		and		eax,0F8h
	.endif
	test	Ram[eax],dl
	.if ZERO?
		movsx	ecx,ch
		lea		ebx,[ebx+ecx]
	.endif
	ret

RETI_:
	movzx	edx,Sfr[SFR_SP]
	mov		bh,Ram[edx]
	dec		dl
	mov		bl,Ram[edx]
	dec		dl
	mov		Sfr[SFR_SP],dl
	ret

RLC_A:
	movzx	eax,Sfr[SFR_PSW]
	rcl		al,1
	rcl		Sfr[SFR_ACC],1
	lea		ebx,[ebx+1]
	ret

ADDC_A_imm:
	movzx	eax,Sfr[SFR_PSW]
	rcl		al,1
	movzx	eax,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	adc		Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ADDC_A_$dad:
	movzx	eax,Sfr[SFR_PSW]
	rcl		al,1
	movzx	edx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	.if edx<80h
		movzx	eax,Ram[edx]
	.else
		movzx	eax,Sfr[edx]
	.endif
	adc		Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ADDC_A_@R0:
	movzx	eax,Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,Bank
	lea		eax,[eax*8+0]
	movzx	eax,Ram[eax]
	movzx	eax,Ram[eax]
	adc		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADDC_A_@R1:
	movzx	eax,Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,Bank
	lea		eax,[eax*8+1]
	movzx	eax,Ram[eax]
	movzx	eax,Ram[eax]
	adc		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADDC_A_R0:
	movzx	eax,Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,Bank
	lea		eax,[eax*8+0]
	movzx	eax,Ram[eax]
	adc		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADDC_A_R1:
	movzx	eax,Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,Bank
	lea		eax,[eax*8+1]
	movzx	eax,Ram[eax]
	adc		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADDC_A_R2:
	movzx	eax,Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,Bank
	lea		eax,[eax*8+2]
	movzx	eax,Ram[eax]
	adc		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADDC_A_R3:
	movzx	eax,Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,Bank
	lea		eax,[eax*8+3]
	movzx	eax,Ram[eax]
	adc		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADDC_A_R4:
	movzx	eax,Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,Bank
	lea		eax,[eax*8+4]
	movzx	eax,Ram[eax]
	adc		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADDC_A_R5:
	movzx	eax,Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,Bank
	lea		eax,[eax*8+5]
	movzx	eax,Ram[eax]
	adc		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADDC_A_R6:
	movzx	eax,Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,Bank
	lea		eax,[eax*8+6]
	movzx	eax,Ram[eax]
	adc		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADDC_A_R7:
	movzx	eax,Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,Bank
	lea		eax,[eax*8+7]
	movzx	eax,Ram[eax]
	adc		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

;------------------------------------------------------------------------------
JC_$cad:
	movsx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	movzx	eax,Sfr[SFR_PSW]
	rcl		al,1
	.if CARRY?
		lea		ebx,[ebx+ecx]
	.endif
	ret

ORL_$dad_A:
	movzx	edx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	movzx	eax,Sfr[SFR_ACC]
	or		Ram[edx],al
	invoke SetFlags
	ret

ORL_$dad_imm:
	movzx	edx,byte ptr [esi+ebx+1]
	movzx	eax,byte ptr [esi+ebx+2]
	lea		ebx,[ebx+3]
	or		Ram[edx],al
	invoke SetFlags
	ret

ORL_A_imm:
	movzx	eax,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	or		Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ORL_A_$dad:
	movzx	edx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	.if edx<80h
		movzx	eax,Ram[edx]
	.else
		movzx	eax,Sfr[edx]
	.endif
	or		Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ORL_A_@R0:
	mov		eax,Bank
	lea		eax,[eax*8+0]
	movzx	eax,Ram[eax]
	movzx	eax,Ram[eax]
	or		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ORL_A_@R1:
	mov		eax,Bank
	lea		eax,[eax*8+1]
	movzx	eax,Ram[eax]
	movzx	eax,Ram[eax]
	or		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ORL_A_R0:
	mov		eax,Bank
	lea		eax,[eax*8+0]
	movzx	eax,Ram[eax]
	or		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ORL_A_R1:
	mov		eax,Bank
	lea		eax,[eax*8+1]
	movzx	eax,Ram[eax]
	or		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ORL_A_R2:
	mov		eax,Bank
	lea		eax,[eax*8+2]
	movzx	eax,Ram[eax]
	or		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ORL_A_R3:
	mov		eax,Bank
	lea		eax,[eax*8+3]
	movzx	eax,Ram[eax]
	or		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ORL_A_R4:
	mov		eax,Bank
	lea		eax,[eax*8+4]
	movzx	eax,Ram[eax]
	or		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ORL_A_R5:
	mov		eax,Bank
	lea		eax,[eax*8+5]
	movzx	eax,Ram[eax]
	or		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ORL_A_R6:
	mov		eax,Bank
	lea		eax,[eax*8+6]
	movzx	eax,Ram[eax]
	or		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ORL_A_R7:
	mov		eax,Bank
	lea		eax,[eax*8+7]
	movzx	eax,Ram[eax]
	or		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

;------------------------------------------------------------------------------
JNC_$cad:
	movsx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	movzx	eax,Sfr[SFR_PSW]
	rcl		al,1
	.if !CARRY?
		lea		ebx,[ebx+ecx]
	.endif
	ret

ANL_$dad_A:
	movzx	edx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	movzx	eax,Sfr[SFR_ACC]
	and		Ram[edx],al
	invoke SetFlags
	ret

ANL_$dad_imm:
	movzx	edx,byte ptr [esi+ebx+1]
	movzx	eax,byte ptr [esi+ebx+2]
	lea		ebx,[ebx+3]
	and		Ram[edx],al
	invoke SetFlags
	ret

ANL_A_imm:
	movzx	eax,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	and		Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ANL_A_$dad:
	movzx	edx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	.if edx<80h
		movzx	eax,Ram[edx]
	.else
		movzx	eax,Sfr[edx]
	.endif
	and		Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ANL_A_@R0:
	mov		eax,Bank
	lea		eax,[eax*8+0]
	movzx	eax,Ram[eax]
	movzx	eax,Ram[eax]
	and		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ANL_A_@R1:
	mov		eax,Bank
	lea		eax,[eax*8+1]
	movzx	eax,Ram[eax]
	movzx	eax,Ram[eax]
	and		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ANL_A_R0:
	mov		eax,Bank
	lea		eax,[eax*8+0]
	movzx	eax,Ram[eax]
	and		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ANL_A_R1:
	mov		eax,Bank
	lea		eax,[eax*8+1]
	movzx	eax,Ram[eax]
	and		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ANL_A_R2:
	mov		eax,Bank
	lea		eax,[eax*8+2]
	movzx	eax,Ram[eax]
	and		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ANL_A_R3:
	mov		eax,Bank
	lea		eax,[eax*8+3]
	movzx	eax,Ram[eax]
	and		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ANL_A_R4:
	mov		eax,Bank
	lea		eax,[eax*8+4]
	movzx	eax,Ram[eax]
	and		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ANL_A_R5:
	mov		eax,Bank
	lea		eax,[eax*8+5]
	movzx	eax,Ram[eax]
	and		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ANL_A_R6:
	mov		eax,Bank
	lea		eax,[eax*8+6]
	movzx	eax,Ram[eax]
	and		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ANL_A_R7:
	mov		eax,Bank
	lea		eax,[eax*8+7]
	movzx	eax,Ram[eax]
	and		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

;------------------------------------------------------------------------------
JZ_$cad:
	movsx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	movzx	eax,Sfr[SFR_ACC]
	or		eax,eax
	.if ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	ret

XRL_$dad_A:
	movzx	edx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	movzx	eax,Sfr[SFR_ACC]
	xor		Ram[edx],al
	invoke SetFlags
	ret

XRL_$dad_imm:
	movzx	edx,byte ptr [esi+ebx+1]
	movzx	eax,byte ptr [esi+ebx+2]
	lea		ebx,[ebx+3]
	xor		Ram[edx],al
	invoke SetFlags
	ret

XRL_A_imm:
	movzx	eax,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	xor		Sfr[SFR_ACC],al
	invoke SetFlags
	ret

XRL_A_$dad:
	movzx	edx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	.if edx<80h
		movzx	eax,Ram[edx]
	.else
		movzx	eax,Sfr[edx]
	.endif
	xor		Sfr[SFR_ACC],al
	invoke SetFlags
	ret

XRL_A_@R0:
	mov		eax,Bank
	lea		eax,[eax*8+0]
	movzx	eax,Ram[eax]
	movzx	eax,Ram[eax]
	xor		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

XRL_A_@R1:
	mov		eax,Bank
	lea		eax,[eax*8+1]
	movzx	eax,Ram[eax]
	movzx	eax,Ram[eax]
	xor		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

XRL_A_R0:
	mov		eax,Bank
	lea		eax,[eax*8+0]
	movzx	eax,Ram[eax]
	xor		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

XRL_A_R1:
	mov		eax,Bank
	lea		eax,[eax*8+1]
	movzx	eax,Ram[eax]
	xor		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

XRL_A_R2:
	mov		eax,Bank
	lea		eax,[eax*8+2]
	movzx	eax,Ram[eax]
	xor		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

XRL_A_R3:
	mov		eax,Bank
	lea		eax,[eax*8+3]
	movzx	eax,Ram[eax]
	xor		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

XRL_A_R4:
	mov		eax,Bank
	lea		eax,[eax*8+4]
	movzx	eax,Ram[eax]
	xor		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

XRL_A_R5:
	mov		eax,Bank
	lea		eax,[eax*8+5]
	movzx	eax,Ram[eax]
	xor		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

XRL_A_R6:
	mov		eax,Bank
	lea		eax,[eax*8+6]
	movzx	eax,Ram[eax]
	xor		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

XRL_A_R7:
	mov		eax,Bank
	lea		eax,[eax*8+7]
	movzx	eax,Ram[eax]
	xor		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

;------------------------------------------------------------------------------
JNZ_$cad:
	movsx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	movzx	eax,Sfr[SFR_ACC]
	or		eax,eax
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	ret

ORL_C_$bad:
	movzx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	movzx	eax,cl
	and		cl,07h
	mov		edx,1
	shl		edx,cl
	.if al<80h
		shr		eax,3
		lea		eax,[eax+20h]
		and		dl,Ram[eax]
	.else
		and		eax,0F8h
		and		dl,Sfr[eax]
	.endif
	.if dl
		or		Sfr[SFR_PSW],80h
	.endif
	ret

JMP_@A_DPTR:
	movzx	eax,Sfr[SFR_AUXR1]
	and		eax,1
	.if ZERO?
		movzx	dx,Sfr[SFR_DPL]
	.else
		movzx	dx,Sfr[SFR_DP1L]
	.endif
	movzx	eax,Sfr[SFR_ACC]
	lea		ebx,[edx+eax]
	ret

MOV_A_imm:
	movzx	eax,byte ptr [esi+ebx+1]
	mov		Sfr[SFR_ACC],al
	lea		ebx,[ebx+2]
	ret

MOV_$dad_imm:
	movzx	edx,byte ptr [esi+ebx+1]
	movzx	eax,byte ptr [esi+ebx+2]
	.if edx<80h
		mov		Ram[edx],al
	.else
		mov		Sfr[edx],al
	.endif
	lea		ebx,[ebx+3]
	ret
	
MOV_@R0_imm:
	mov		eax,Bank
	lea		eax,[eax*8+0]
	movzx	edx,Ram[eax]
	movzx	eax,byte ptr [esi+ebx+1]
	mov		Ram[edx],al
	lea		ebx,[ebx+2]
	ret

MOV_@R1_imm:
	mov		eax,Bank
	lea		eax,[eax*8+1]
	movzx	edx,Ram[eax]
	movzx	eax,byte ptr [esi+ebx+1]
	mov		Ram[edx],al
	lea		ebx,[ebx+2]
	ret

MOV_R0_imm:
	movzx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	mov		eax,Bank
	lea		eax,[eax*8+0]
	mov		Ram[eax],cl
	ret

MOV_R1_imm:
	movzx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	mov		eax,Bank
	lea		eax,[eax*8+1]
	mov		Ram[eax],cl
	ret

MOV_R2_imm:
	movzx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	mov		eax,Bank
	lea		eax,[eax*8+2]
	mov		Ram[eax],cl
	ret

MOV_R3_imm:
	movzx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	mov		eax,Bank
	lea		eax,[eax*8+3]
	mov		Ram[eax],cl
	ret

MOV_R4_imm:
	movzx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	mov		eax,Bank
	lea		eax,[eax*8+4]
	mov		Ram[eax],cl
	ret

MOV_R5_imm:
	movzx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	mov		eax,Bank
	lea		eax,[eax*8+5]
	mov		Ram[eax],cl
	ret

MOV_R6_imm:
	movzx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	mov		eax,Bank
	lea		eax,[eax*8+6]
	mov		Ram[eax],cl
	ret

MOV_R7_imm:
	movzx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	mov		eax,Bank
	lea		eax,[eax*8+7]
	mov		Ram[eax],cl
	ret

;------------------------------------------------------------------------------
SJMP_$cad:
	movsx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	lea		ebx,[ebx+ecx]
	ret

ANL_C_$bad:
	movzx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	movzx	eax,cl
	and		cl,07h
	mov		edx,1
	shl		edx,cl
	.if al<80h
		shr		eax,3
		lea		eax,[eax+20h]
		and		dl,Ram[eax]
	.else
		and		eax,0F8h
		and		dl,Sfr[eax]
	.endif
	.if !dl
		and		Sfr[SFR_PSW],7Fh
	.endif
	ret

MOVC_A_@A_PC:
	movzx	eax,Sfr[SFR_ACC]
	lea		edx,[ebx+eax]
	movzx	eax,byte ptr [esi+edx]
	mov		Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

DIV_AB:
	movzx	eax,Sfr[SFR_ACC]
	movzx	ecx,Sfr[SFR_B]
	.if !ecx
		;Set OV flag
		or		Sfr[SFR_PSW],04h
	.else
		xor		edx,edx
		div		cl
		mov		Sfr[SFR_ACC],al
		mov		Sfr[SFR_B],dl
		;Clear OV flag
		and		Sfr[SFR_PSW],0FBh
	.endif
	;Clear CY flag
	and		Sfr[SFR_PSW],7Fh
	lea		ebx,[ebx+1]
	ret

MOV_$dad_$dad:
	movzx	edx,byte ptr [esi+ebx+2]
	.if edx<80h
		movzx	eax,Ram[edx]
	.else
		movzx	eax,Sfr[edx]
	.endif
	movzx	edx,byte ptr [esi+ebx+1]
	.if edx<80h
		mov		Ram[edx],al
	.else
		mov		Sfr[edx],al
	.endif
	lea		ebx,[ebx+3]
	ret

MOV_$dad_@R0:
	mov		edx,Bank
	lea		edx,[edx*8+0]
	movzx	edx,Ram[edx]
	movzx	eax,Ram[edx]
	movzx	edx,byte ptr [esi+ebx+1]
	.if edx<80h
		mov		Ram[edx],al
	.else
		mov		Sfr[edx],al
	.endif
	lea		ebx,[ebx+2]
	ret

MOV_$dad_@R1:
	mov		edx,Bank
	lea		edx,[edx*8+1]
	movzx	edx,Ram[edx]
	movzx	eax,Ram[edx]
	movzx	edx,byte ptr [esi+ebx+1]
	.if edx<80h
		mov		Ram[edx],al
	.else
		mov		Sfr[edx],al
	.endif
	lea		ebx,[ebx+2]
	ret

MOV_$dad_R0:
	mov		edx,Bank
	lea		edx,[edx*8+0]
	movzx	eax,Ram[edx]
	movzx	edx,byte ptr [esi+ebx+1]
	.if edx<80h
		mov		Ram[edx],al
	.else
		mov		Sfr[edx],al
	.endif
	lea		ebx,[ebx+2]
	ret

MOV_$dad_R1:
	mov		edx,Bank
	lea		edx,[edx*8+1]
	movzx	eax,Ram[edx]
	movzx	edx,byte ptr [esi+ebx+1]
	.if edx<80h
		mov		Ram[edx],al
	.else
		mov		Sfr[edx],al
	.endif
	lea		ebx,[ebx+2]
	ret

MOV_$dad_R2:
	mov		edx,Bank
	lea		edx,[edx*8+2]
	movzx	eax,Ram[edx]
	movzx	edx,byte ptr [esi+ebx+1]
	.if edx<80h
		mov		Ram[edx],al
	.else
		mov		Sfr[edx],al
	.endif
	lea		ebx,[ebx+2]
	ret

MOV_$dad_R3:
	mov		edx,Bank
	lea		edx,[edx*8+3]
	movzx	eax,Ram[edx]
	movzx	edx,byte ptr [esi+ebx+1]
	.if edx<80h
		mov		Ram[edx],al
	.else
		mov		Sfr[edx],al
	.endif
	lea		ebx,[ebx+2]
	ret

MOV_$dad_R4:
	mov		edx,Bank
	lea		edx,[edx*8+4]
	movzx	eax,Ram[edx]
	movzx	edx,byte ptr [esi+ebx+1]
	.if edx<80h
		mov		Ram[edx],al
	.else
		mov		Sfr[edx],al
	.endif
	lea		ebx,[ebx+2]
	ret

MOV_$dad_R5:
	mov		edx,Bank
	lea		edx,[edx*8+5]
	movzx	eax,Ram[edx]
	movzx	edx,byte ptr [esi+ebx+1]
	.if edx<80h
		mov		Ram[edx],al
	.else
		mov		Sfr[edx],al
	.endif
	lea		ebx,[ebx+2]
	ret

MOV_$dad_R6:
	mov		edx,Bank
	lea		edx,[edx*8+6]
	movzx	eax,Ram[edx]
	movzx	edx,byte ptr [esi+ebx+1]
	.if edx<80h
		mov		Ram[edx],al
	.else
		mov		Sfr[edx],al
	.endif
	lea		ebx,[ebx+2]
	ret

MOV_$dad_R7:
	mov		edx,Bank
	lea		edx,[edx*8+7]
	movzx	eax,Ram[edx]
	movzx	edx,byte ptr [esi+ebx+1]
	.if edx<80h
		mov		Ram[edx],al
	.else
		mov		Sfr[edx],al
	.endif
	lea		ebx,[ebx+2]
	ret

;------------------------------------------------------------------------------
MOV_DPTR_dw:
	mov		ah,byte ptr [esi+ebx+1]
	mov		al,byte ptr [esi+ebx+2]
	test	Sfr[SFR_AUXR1],1
	.if ZERO?
		mov		word ptr Sfr[SFR_DPL],ax
	.else
		mov		word ptr Sfr[SFR_DP1L],ax
	.endif
	lea		ebx,[ebx+3]
	ret

MOV_$bad_C:
	movzx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	movzx	eax,cl
	and		cl,07h
	mov		edx,1
	shl		edx,cl
	.if al<80h
		shr		eax,3
		lea		eax,[eax+20h]
		test	Sfr[SFR_PSW],80h
		.if ZERO?
			xor		edx,0FFh
			and		Ram[eax],dl
		.else
			or		Ram[eax],dl
		.endif
	.else
		and		eax,0F8h
		test	Sfr[SFR_PSW],80h
		.if ZERO?
			xor		edx,0FFh
			and		Sfr[eax],dl
		.else
			or		Sfr[eax],dl
		.endif
	.endif
	ret

MOVC_A_@A_DPTR:
	test	Sfr[SFR_AUXR1],1
	.if ZERO?
		movzx	edx,word ptr Sfr[SFR_DPL]
	.else
		movzx	edx,word ptr Sfr[SFR_DP1L]
	.endif
	movzx	eax,Sfr[SFR_ACC]
	lea		edx,[edx+eax]
	movzx	eax,byte ptr [esi+edx]
	mov		Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

SUBB_A_imm:
	movzx	eax,Sfr[SFR_PSW]
	rcl		al,1
	movzx	eax,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	sbb		Sfr[SFR_ACC],al
	invoke SetFlags
	ret

SUBB_A_$dad:
	movzx	eax,Sfr[SFR_PSW]
	rcl		al,1
	movzx	edx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	.if edx<80h
		movzx	eax,Ram[edx]
	.else
		movzx	eax,Sfr[edx]
	.endif
	sbb		Sfr[SFR_ACC],al
	invoke SetFlags
	ret

SUBB_A_@R0:
	movzx	eax,Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,Bank
	lea		eax,[eax*8+0]
	movzx	eax,Ram[eax]
	movzx	eax,Ram[eax]
	sbb		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

SUBB_A_@R1:
	movzx	eax,Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,Bank
	lea		eax,[eax*8+1]
	movzx	eax,Ram[eax]
	movzx	eax,Ram[eax]
	sbb		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

SUBB_A_R0:
	movzx	eax,Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,Bank
	lea		eax,[eax*8+0]
	movzx	eax,Ram[eax]
	sbb		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

SUBB_A_R1:
	movzx	eax,Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,Bank
	lea		eax,[eax*8+1]
	movzx	eax,Ram[eax]
	sbb		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

SUBB_A_R2:
	movzx	eax,Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,Bank
	lea		eax,[eax*8+2]
	movzx	eax,Ram[eax]
	sbb		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

SUBB_A_R3:
	movzx	eax,Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,Bank
	lea		eax,[eax*8+3]
	movzx	eax,Ram[eax]
	sbb		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

SUBB_A_R4:
	movzx	eax,Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,Bank
	lea		eax,[eax*8+4]
	movzx	eax,Ram[eax]
	sbb		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

SUBB_A_R5:
	movzx	eax,Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,Bank
	lea		eax,[eax*8+5]
	movzx	eax,Ram[eax]
	sbb		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

SUBB_A_R6:
	movzx	eax,Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,Bank
	lea		eax,[eax*8+6]
	movzx	eax,Ram[eax]
	sbb		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

SUBB_A_R7:
	movzx	eax,Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,Bank
	lea		eax,[eax*8+7]
	movzx	eax,Ram[eax]
	sbb		Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

;------------------------------------------------------------------------------
ORL_C_n$bad:
	movzx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	movzx	eax,cl
	and		cl,07h
	mov		edx,1
	shl		edx,cl
	.if al<80h
		shr		eax,3
		lea		eax,[eax+20h]
		and		dl,Ram[eax]
	.else
		and		eax,0F8h
		and		dl,Sfr[eax]
	.endif
	.if !dl
		or		Sfr[SFR_PSW],80h
	.endif
	ret

MOV_C_$bad:
	movzx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	movzx	eax,cl
	and		cl,07h
	mov		edx,1
	shl		edx,cl
	.if al<80h
		shr		eax,3
		lea		eax,[eax+20h]
		and		dl,Ram[eax]
	.else
		and		eax,0F8h
		and		dl,Sfr[eax]
	.endif
	.if dl
		or		Sfr[SFR_PSW],80h
	.else
		and		Sfr[SFR_PSW],7Fh
	.endif
	ret

INC_DPTR:
	movzx	eax,Sfr[SFR_AUXR1]
	and		eax,1
	.if ZERO?
		inc		word ptr Sfr[SFR_DPL]
	.else
		inc		word ptr Sfr[SFR_DP1L]
	.endif
	lea		ebx,[ebx+1]
	ret

MUL_AB:
	mov		al,Sfr[SFR_ACC]
	mov		ah,Sfr[SFR_B]
	mul		ah
	mov		Sfr[SFR_ACC],al
	mov		Sfr[SFR_B],ah
	.if ah
		;Set OV flag
		or		Sfr[SFR_PSW],04h
	.else
		;Clear OV flag
		and		Sfr[SFR_PSW],0FBh
	.endif
	;Clear CY flag
	and		Sfr[SFR_PSW],7Fh
	lea		ebx,[ebx+1]
	ret

reserved:
	;#########
	lea		ebx,[ebx+1]
	ret

MOV_@R0_$dad:
	mov		edx,Bank
	lea		edx,[edx*8+0]
	movzx	edx,Ram[edx]
	movzx	eax,byte ptr [esi+ebx+1]
	.if eax<80h
		movzx	eax,Ram[eax]
	.else
		movzx	eax,Sfr[eax]
	.endif
	mov		Ram[edx],al
	lea		ebx,[ebx+2]
	ret

MOV_@R1_$dad:
	mov		edx,Bank
	lea		edx,[edx*8+1]
	movzx	edx,Ram[edx]
	movzx	eax,byte ptr [esi+ebx+1]
	.if eax<80h
		movzx	eax,Ram[eax]
	.else
		movzx	eax,Sfr[eax]
	.endif
	mov		Ram[edx],al
	lea		ebx,[ebx+2]
	ret

MOV_R0_$dad:
	mov		edx,Bank
	lea		edx,[edx*8+0]
	movzx	eax,byte ptr [esi+ebx+1]
	.if eax<80h
		movzx	eax,Ram[eax]
	.else
		movzx	eax,Sfr[eax]
	.endif
	mov		Ram[edx],al
	lea		ebx,[ebx+2]
	ret

MOV_R1_$dad:
	mov		edx,Bank
	lea		edx,[edx*8+1]
	movzx	eax,byte ptr [esi+ebx+1]
	.if eax<80h
		movzx	eax,Ram[eax]
	.else
		movzx	eax,Sfr[eax]
	.endif
	mov		Ram[edx],al
	lea		ebx,[ebx+2]
	ret

MOV_R2_$dad:
	mov		edx,Bank
	lea		edx,[edx*8+2]
	movzx	eax,byte ptr [esi+ebx+1]
	.if eax<80h
		movzx	eax,Ram[eax]
	.else
		movzx	eax,Sfr[eax]
	.endif
	mov		Ram[edx],al
	lea		ebx,[ebx+2]
	ret

MOV_R3_$dad:
	mov		edx,Bank
	lea		edx,[edx*8+3]
	movzx	eax,byte ptr [esi+ebx+1]
	.if eax<80h
		movzx	eax,Ram[eax]
	.else
		movzx	eax,Sfr[eax]
	.endif
	mov		Ram[edx],al
	lea		ebx,[ebx+2]
	ret

MOV_R4_$dad:
	mov		edx,Bank
	lea		edx,[edx*8+4]
	movzx	eax,byte ptr [esi+ebx+1]
	.if eax<80h
		movzx	eax,Ram[eax]
	.else
		movzx	eax,Sfr[eax]
	.endif
	mov		Ram[edx],al
	lea		ebx,[ebx+2]
	ret

MOV_R5_$dad:
	mov		edx,Bank
	lea		edx,[edx*8+5]
	movzx	eax,byte ptr [esi+ebx+1]
	.if eax<80h
		movzx	eax,Ram[eax]
	.else
		movzx	eax,Sfr[eax]
	.endif
	mov		Ram[edx],al
	lea		ebx,[ebx+2]
	ret

MOV_R6_$dad:
	mov		edx,Bank
	lea		edx,[edx*8+6]
	movzx	eax,byte ptr [esi+ebx+1]
	.if eax<80h
		movzx	eax,Ram[eax]
	.else
		movzx	eax,Sfr[eax]
	.endif
	mov		Ram[edx],al
	lea		ebx,[ebx+2]
	ret

MOV_R7_$dad:
	mov		edx,Bank
	lea		edx,[edx*8+7]
	movzx	eax,byte ptr [esi+ebx+1]
	.if eax<80h
		movzx	eax,Ram[eax]
	.else
		movzx	eax,Sfr[eax]
	.endif
	mov		Ram[edx],al
	lea		ebx,[ebx+2]
	ret

;------------------------------------------------------------------------------
ANL_C_n$bad:
	movzx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	movzx	eax,cl
	and		cl,07h
	mov		edx,1
	shl		edx,cl
	.if al<80h
		shr		eax,3
		lea		eax,[eax+20h]
		and		dl,Ram[eax]
	.else
		and		eax,0F8h
		and		dl,Sfr[eax]
	.endif
	.if dl
		and		Sfr[SFR_PSW],7Fh
	.endif
	ret

CPL_$bad:
	movzx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	movzx	eax,cl
	and		cl,07h
	mov		edx,1
	shl		edx,cl
	.if al<80h
		shr		eax,3
		lea		eax,[eax+20h]
		xor		Ram[eax],dl
	.else
		and		eax,0F8h
		xor		Sfr[eax],dl
	.endif
	ret

CPL_C:
	xor		Sfr[SFR_PSW],80h
	lea		ebx,[ebx+1]
	ret

CJNE_A_imm_$cad:
	movzx	eax,byte ptr [esi+ebx+1]
	movsx	ecx,byte ptr [esi+ebx+2]
	lea		ebx,[ebx+3]
	cmp		Sfr[SFR_ACC],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	invoke SetFlags
	ret

CJNE_A_$dad_$cad:
	movzx	edx,byte ptr [esi+ebx+1]
	movsx	ecx,byte ptr [esi+ebx+2]
	lea		ebx,[ebx+3]
	.if edx<80h
		movzx	eax,Ram[edx]
	.else
		movzx	eax,Sfr[edx]
	.endif
	cmp		Sfr[SFR_ACC],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	invoke SetFlags
	ret

CJNE_@R0_imm_$cad:
	movzx	eax,byte ptr [esi+ebx+1]
	movsx	ecx,byte ptr [esi+ebx+2]
	lea		ebx,[ebx+3]
	mov		edx,Bank
	lea		edx,[edx*8+0]
	movzx	edx,Ram[edx]
	cmp		Ram[edx],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	invoke SetFlags
	ret

CJNE_@R1_imm_$cad:
	movzx	eax,byte ptr [esi+ebx+1]
	movsx	ecx,byte ptr [esi+ebx+2]
	lea		ebx,[ebx+3]
	mov		edx,Bank
	lea		edx,[edx*8+1]
	movzx	edx,Ram[edx]
	cmp		Ram[edx],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	invoke SetFlags
	ret

CJNE_R0_imm_$cad:
	movzx	eax,byte ptr [esi+ebx+1]
	movsx	ecx,byte ptr [esi+ebx+2]
	lea		ebx,[ebx+3]
	mov		edx,Bank
	lea		edx,[edx*8+0]
	cmp		Ram[edx],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	invoke SetFlags
	ret

CJNE_R1_imm_$cad:
	movzx	eax,byte ptr [esi+ebx+1]
	movsx	ecx,byte ptr [esi+ebx+2]
	lea		ebx,[ebx+3]
	mov		edx,Bank
	lea		edx,[edx*8+1]
	cmp		Ram[edx],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	invoke SetFlags
	ret

CJNE_R2_imm_$cad:
	movzx	eax,byte ptr [esi+ebx+1]
	movsx	ecx,byte ptr [esi+ebx+2]
	lea		ebx,[ebx+3]
	mov		edx,Bank
	lea		edx,[edx*8+2]
	cmp		Ram[edx],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	invoke SetFlags
	ret

CJNE_R3_imm_$cad:
	movzx	eax,byte ptr [esi+ebx+1]
	movsx	ecx,byte ptr [esi+ebx+2]
	lea		ebx,[ebx+3]
	mov		edx,Bank
	lea		edx,[edx*8+3]
	cmp		Ram[edx],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	invoke SetFlags
	ret

CJNE_R4_imm_$cad:
	movzx	eax,byte ptr [esi+ebx+1]
	movsx	ecx,byte ptr [esi+ebx+2]
	lea		ebx,[ebx+3]
	mov		edx,Bank
	lea		edx,[edx*8+4]
	cmp		Ram[edx],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	invoke SetFlags
	ret

CJNE_R5_imm_$cad:
	movzx	eax,byte ptr [esi+ebx+1]
	movsx	ecx,byte ptr [esi+ebx+2]
	lea		ebx,[ebx+3]
	mov		edx,Bank
	lea		edx,[edx*8+5]
	cmp		Ram[edx],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	invoke SetFlags
	ret

CJNE_R6_imm_$cad:
	movzx	eax,byte ptr [esi+ebx+1]
	movsx	ecx,byte ptr [esi+ebx+2]
	lea		ebx,[ebx+3]
	mov		edx,Bank
	lea		edx,[edx*8+6]
	cmp		Ram[edx],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	invoke SetFlags
	ret

CJNE_R7_imm_$cad:
	movzx	eax,byte ptr [esi+ebx+1]
	movsx	ecx,byte ptr [esi+ebx+2]
	lea		ebx,[ebx+3]
	mov		edx,Bank
	lea		edx,[edx*8+7]
	cmp		Ram[edx],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	invoke SetFlags
	ret

;------------------------------------------------------------------------------
PUSH_$dad:
	inc		Sfr[SFR_SP]
	movzx	edx,Sfr[SFR_SP]
	movzx	eax,byte ptr [esi+ebx+1]
	.if eax<80h
		movzx	eax,Ram[eax]
	.else
		movzx	eax,Sfr[eax]
	.endif
	mov		Ram[edx],al
	lea		ebx,[ebx+2]
	ret

CLR_$bad:
	movzx	ecx,byte ptr [esi+ebx+1]
	movzx	eax,cl
	and		cl,07h
	mov		edx,1
	shl		edx,cl
	xor		edx,0FFh
	.if al<80h
		shr		eax,3
		lea		eax,[eax+20h]
		and		Ram[eax],dl
	.else
		and		eax,0F8h
		and		Sfr[eax],dl
	.endif
	lea		ebx,[ebx+2]
	ret

CLR_C:
	and		Sfr[SFR_PSW],7Fh
	lea		ebx,[ebx+1]
	ret

SWAP_A:
	movzx	eax,Sfr[SFR_ACC]
	mov		ah,al
	shr		al,4
	shl		ah,4
	or		al,ah
	mov		Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

XCH_A_$dad:
	movzx	edx,byte ptr [esi+ebx+1]
	movzx	eax,Sfr[SFR_ACC]
	.if edx<80h
		xchg	al,Ram[edx]
	.else
		xchg	al,Sfr[edx]
	.endif
	mov		Sfr[SFR_ACC],al
	lea		ebx,[ebx+2]
	ret

XCH_A_@R0:
	mov		edx,Bank
	lea		edx,[edx*8+0]
	movzx	edx,Ram[edx]
	movzx	eax,Sfr[SFR_ACC]
	xchg	al,Ram[edx]
	mov		Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

XCH_A_@R1:
	mov		edx,Bank
	lea		edx,[edx*8+1]
	movzx	edx,Ram[edx]
	movzx	eax,Sfr[SFR_ACC]
	xchg	al,Ram[edx]
	mov		Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

XCH_A_R0:
	mov		edx,Bank
	lea		edx,[edx*8+0]
	movzx	eax,Sfr[SFR_ACC]
	xchg	al,Ram[edx]
	mov		Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

XCH_A_R1:
	mov		edx,Bank
	lea		edx,[edx*8+1]
	movzx	eax,Sfr[SFR_ACC]
	xchg	al,Ram[edx]
	mov		Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

XCH_A_R2:
	mov		edx,Bank
	lea		edx,[edx*8+2]
	movzx	eax,Sfr[SFR_ACC]
	xchg	al,Ram[edx]
	mov		Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

XCH_A_R3:
	mov		edx,Bank
	lea		edx,[edx*8+3]
	movzx	eax,Sfr[SFR_ACC]
	xchg	al,Ram[edx]
	mov		Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

XCH_A_R4:
	mov		edx,Bank
	lea		edx,[edx*8+4]
	movzx	eax,Sfr[SFR_ACC]
	xchg	al,Ram[edx]
	mov		Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

XCH_A_R5:
	mov		edx,Bank
	lea		edx,[edx*8+5]
	movzx	eax,Sfr[SFR_ACC]
	xchg	al,Ram[edx]
	mov		Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

XCH_A_R6:
	mov		edx,Bank
	lea		edx,[edx*8+6]
	movzx	eax,Sfr[SFR_ACC]
	xchg	al,Ram[edx]
	mov		Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

XCH_A_R7:
	mov		edx,Bank
	lea		edx,[edx*8+7]
	movzx	eax,Sfr[SFR_ACC]
	xchg	al,Ram[edx]
	mov		Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

;------------------------------------------------------------------------------
POP_$dad:
	movzx	edx,Sfr[SFR_SP]
	movzx	eax,Ram[edx]
	dec		Sfr[SFR_SP]
	movzx	edx,byte ptr [esi+ebx+1]
	.if edx<80h
		mov		Ram[edx],al
	.else
		mov		Sfr[edx],al
	.endif
	lea		ebx,[ebx+2]
	ret

SETB_$bad:
	movzx	ecx,byte ptr [esi+ebx+1]
	movzx	eax,cl
	and		cl,07h
	mov		edx,1
	shl		edx,cl
	.if al<80h
		shr		eax,3
		lea		eax,[eax+20h]
		or		Ram[eax],dl
	.else
		and		eax,0F8h
		or		Sfr[eax],dl
	.endif
	lea		ebx,[ebx+2]
	ret

SETB_C:
	or		Sfr[SFR_PSW],80h
	lea		ebx,[ebx+1]
	ret

DA_A:
	movzx	eax,Sfr[SFR_ACC]
	add		eax,0
	daa
	mov		Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

DJNZ_$dad_$cad:
	movzx	edx,byte ptr [esi+ebx+1]
	movsx	ecx,byte ptr [esi+ebx+2]
	lea		ebx,[ebx+3]
	.if edx<80h
		dec		Ram[edx]
	.else
		dec		Sfr[edx]
	.endif
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	ret

XCHD_A_@R0:
	mov		eax,Bank
	lea		eax,[eax*8+0]
	movzx	edx,Ram[eax]
	movzx	eax,Ram[edx]
	xchg	Sfr[SFR_ACC],al
	mov		Ram[edx],al
	lea		ebx,[ebx+1]
	ret

XCHD_A_@R1:
	mov		eax,Bank
	lea		eax,[eax*8+1]
	movzx	edx,Ram[eax]
	movzx	eax,Ram[edx]
	xchg	Sfr[SFR_ACC],al
	mov		Ram[edx],al
	lea		ebx,[ebx+1]
	ret

DJNZ_R0_$cad:
	movsx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	mov		eax,Bank
	lea		eax,[eax*8+0]
	dec		Ram[eax]
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	ret

DJNZ_R1_$cad:
	movsx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	mov		eax,Bank
	lea		eax,[eax*8+1]
	dec		Ram[eax]
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	ret

DJNZ_R2_$cad:
	movsx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	mov		eax,Bank
	lea		eax,[eax*8+2]
	dec		Ram[eax]
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	ret

DJNZ_R3_$cad:
	movsx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	mov		eax,Bank
	lea		eax,[eax*8+3]
	dec		Ram[eax]
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	ret

DJNZ_R4_$cad:
	movsx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	mov		eax,Bank
	lea		eax,[eax*8+4]
	dec		Ram[eax]
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	ret

DJNZ_R5_$cad:
	movsx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	mov		eax,Bank
	lea		eax,[eax*8+5]
	dec		Ram[eax]
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	ret

DJNZ_R6_$cad:
	movsx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	mov		eax,Bank
	lea		eax,[eax*8+6]
	dec		Ram[eax]
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	ret

DJNZ_R7_$cad:
	movsx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	mov		eax,Bank
	lea		eax,[eax*8+7]
	dec		Ram[eax]
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	ret

;------------------------------------------------------------------------------
MOVX_A_@DPTR:
	movzx	eax,Sfr[SFR_AUXR1]
	and		eax,1
	.if ZERO?
		movzx	edx,word ptr Sfr[SFR_DPL]
	.else
		movzx	edx,word ptr Sfr[SFR_DP1L]
	.endif
	movzx	eax,XRam[edx]
	mov		Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

MOVX_A_@R0:
	mov		edx,Bank
	lea		edx,[edx*8+0]
	movzx	edx,Ram[edx]
	mov		dh,Sfr[SFR_P2]
	movzx	eax,XRam[edx]
	mov		Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

MOVX_A_@R1:
	mov		edx,Bank
	lea		edx,[edx*8+1]
	movzx	edx,Ram[edx]
	mov		dh,Sfr[SFR_P2]
	movzx	eax,XRam[edx]
	mov		Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

CLR_A:
	mov		Sfr[SFR_ACC],0
	lea		ebx,[ebx+1]
	ret

MOV_A_$dad:
	movzx	edx,byte ptr [esi+ebx+1]
	.if edx<80h
		movzx	eax,Ram[edx]
	.else
		movzx	eax,Sfr[edx]
	.endif
	mov		Sfr[SFR_ACC],al
	lea		ebx,[ebx+2]
	ret

MOV_A_@R0:
	mov		edx,Bank
	lea		edx,[edx*8+0]
	movzx	edx,Ram[edx]
	movzx	eax,Ram[edx]
	mov		Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

MOV_A_@R1:
	mov		edx,Bank
	lea		edx,[edx*8+1]
	movzx	edx,Ram[edx]
	movzx	eax,Ram[edx]
	mov		Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

MOV_A_R0:
	mov		edx,Bank
	lea		edx,[edx*8+0]
	movzx	eax,Ram[edx]
	mov		Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

MOV_A_R1:
	mov		edx,Bank
	lea		edx,[edx*8+1]
	movzx	eax,Ram[edx]
	mov		Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

MOV_A_R2:
	mov		edx,Bank
	lea		edx,[edx*8+2]
	movzx	eax,Ram[edx]
	mov		Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

MOV_A_R3:
	mov		edx,Bank
	lea		edx,[edx*8+3]
	movzx	eax,Ram[edx]
	mov		Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

MOV_A_R4:
	mov		edx,Bank
	lea		edx,[edx*8+4]
	movzx	eax,Ram[edx]
	mov		Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

MOV_A_R5:
	mov		edx,Bank
	lea		edx,[edx*8+5]
	movzx	eax,Ram[edx]
	mov		Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

MOV_A_R6:
	mov		edx,Bank
	lea		edx,[edx*8+6]
	movzx	eax,Ram[edx]
	mov		Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

MOV_A_R7:
	mov		edx,Bank
	lea		edx,[edx*8+7]
	movzx	eax,Ram[edx]
	mov		Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

;------------------------------------------------------------------------------
MOVX_@DPTR_A:
	movzx	eax,Sfr[SFR_AUXR1]
	and		eax,1
	.if ZERO?
		movzx	edx,word ptr Sfr[SFR_DPL]
	.else
		movzx	edx,word ptr Sfr[SFR_DP1L]
	.endif
	movzx	eax,Sfr[SFR_ACC]
	mov		XRam[edx],al
	lea		ebx,[ebx+1]
	ret

MOVX_@R0_A:
	mov		edx,Bank
	lea		edx,[edx*8+0]
	movzx	edx,Ram[edx]
	mov		dh,Sfr[SFR_P2]
	movzx	eax,Sfr[SFR_ACC]
	mov		XRam[edx],al
	lea		ebx,[ebx+1]
	ret

MOVX_@R1_A:
	mov		edx,Bank
	lea		edx,[edx*8+1]
	movzx	edx,Ram[edx]
	mov		dh,Sfr[SFR_P2]
	movzx	eax,Sfr[SFR_ACC]
	mov		XRam[edx],al
	lea		ebx,[ebx+1]
	ret

CPL_A:
	xor		Sfr[SFR_ACC],0FFh
	lea		ebx,[ebx+1]
	ret

MOV_$dad_A:
	movzx	edx,byte ptr [esi+ebx+1]
	movzx	eax,Sfr[SFR_ACC]
	.if edx<80h
		mov		Ram[edx],al
	.else
		mov		Sfr[edx],al
	.endif
	lea		ebx,[ebx+2]
	ret

MOV_@R0_A:
	mov		edx,Bank
	lea		edx,[edx*8+0]
	movzx	edx,Ram[edx]
	movzx	eax,Sfr[SFR_ACC]
	mov		Ram[edx],al
	lea		ebx,[ebx+1]
	ret

MOV_@R1_A:
	mov		edx,Bank
	lea		edx,[edx*8+1]
	movzx	edx,Ram[edx]
	movzx	eax,Sfr[SFR_ACC]
	mov		Ram[edx],al
	lea		ebx,[ebx+1]
	ret

MOV_R0_A:
	movzx	eax,Sfr[SFR_ACC]
	mov		edx,Bank
	lea		edx,[edx*8+0]
	mov		Ram[edx],al
	lea		ebx,[ebx+1]
	ret

MOV_R1_A:
	movzx	eax,Sfr[SFR_ACC]
	mov		edx,Bank
	lea		edx,[edx*8+1]
	mov		Ram[edx],al
	lea		ebx,[ebx+1]
	ret

MOV_R2_A:
	movzx	eax,Sfr[SFR_ACC]
	mov		edx,Bank
	lea		edx,[edx*8+2]
	mov		Ram[edx],al
	lea		ebx,[ebx+1]
	ret

MOV_R3_A:
	movzx	eax,Sfr[SFR_ACC]
	mov		edx,Bank
	lea		edx,[edx*8+3]
	mov		Ram[edx],al
	lea		ebx,[ebx+1]
	ret

MOV_R4_A:
	movzx	eax,Sfr[SFR_ACC]
	mov		edx,Bank
	lea		edx,[edx*8+4]
	mov		Ram[edx],al
	lea		ebx,[ebx+1]
	ret

MOV_R5_A:
	movzx	eax,Sfr[SFR_ACC]
	mov		edx,Bank
	lea		edx,[edx*8+5]
	mov		Ram[edx],al
	lea		ebx,[ebx+1]
	ret

MOV_R6_A:
	movzx	eax,Sfr[SFR_ACC]
	mov		edx,Bank
	lea		edx,[edx*8+6]
	mov		Ram[edx],al
	lea		ebx,[ebx+1]
	ret

MOV_R7_A:
	movzx	eax,Sfr[SFR_ACC]
	mov		edx,Bank
	lea		edx,[edx*8+7]
	mov		Ram[edx],al
	lea		ebx,[ebx+1]
	ret

;------------------------------------------------------------------------------

CoreThread proc lParam:DWORD
	LOCAL	StatusLed:DWORD

	mov		esi,offset Code
	mov		ebx,PC
	.while State!=STATE_STOP
		.if (State & STATE_RUN) && !(State & STATE_BREAKPOINT)
			.if !(State & STATE_PAUSE)
				call	Execute
				mov		Refresh,1
			.elseif State & STATE_STEP_INTO
				call	Execute
				xor		State,STATE_STEP_INTO
				mov		Refresh,1
			.elseif State & STATE_STEP_OVER
				xor		State,STATE_STEP_OVER
				movzx	eax,byte ptr [esi+ebx]
				.if eax==12h || eax==11h || eax==31h || eax==51h || eax==71h || eax==91h || eax==0B1h || eax==0D1h || eax==0F1h
					invoke FindMcuAddr,ebx
					.if eax
						movzx	eax,[eax].MCUADDR.mcuaddr[sizeof MCUADDR]
						mov		CursorAddr,eax
						or		State,STATE_RUN_TO_CURSOR or STATE_PAUSE
					.endif
				.else
					xor		State,STATE_STEP_INTO
				.endif
			.elseif State & STATE_RUN_TO_CURSOR
				call	Execute
				.if ebx==CursorAddr
					xor		State,STATE_RUN_TO_CURSOR
				.endif
				mov		Refresh,1
			.else
			mov		eax,hBmpGreenLed
			call	SetStatusLed
			.endif
			.if Refresh
				mov		eax,hBmpRedLed
				call	SetStatusLed
				invoke FindMcuAddr,ebx
				.if eax
					.if [eax].MCUADDR.fbp
						or		State,STATE_BREAKPOINT
					.endif
				.endif
			.endif
		.else
			mov		eax,hBmpGreenLed
			call	SetStatusLed
		.endif
	.endw
	invoke Reset
	xor		eax,eax
	ret

Execute:
	movzx	eax,byte ptr [esi+ebx]
	movzx	edx,Cycles[eax]
	add		TotalCycles,edx
	call	JmpTab[eax*4]
	mov		PC,ebx
	invoke QueryPerformanceFrequency,addr PerformanceFrequency
	invoke QueryPerformanceCounter,addr PerformanceCount
	retn

SetStatusLed:
	.if eax!=StatusLed
		mov		StatusLed,eax
		invoke SendDlgItemMessage,hWnd,IDC_IMGSTATUS,STM_SETIMAGE,IMAGE_BITMAP,eax
	.endif
	retn

CoreThread endp
