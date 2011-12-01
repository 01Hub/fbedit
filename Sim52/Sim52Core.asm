
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

STATE_THREAD		equ 128

.data

JmpTab				dd NOP_,AJMP_$cad,LJMP_$cad,RR_A,INC_A,INC_$dad,INC_@R0,INC_@R1,INC_R0,INC_R1,INC_R2,INC_R3,INC_R4,INC_R5,INC_R6,INC_R7
					dd JBC$bad_$cad,ACALL_$cad,LCALL_$cad,RRC_A,DEC_A,DEC_$dad,DEC_@R0,DEC_@R1,DEC_R0,DEC_R1,DEC_R2,DEC_R3,DEC_R4,DEC_R5,DEC_R6,DEC_R7
					dd JB_$bad_$cad,AJMP_$cad,RET_,RL_A,ADD_A_dd,ADD_A_$dad,ADD_A_@R0,ADD_A_@R1,ADD_A_R0,ADD_A_R1,ADD_A_R2,ADD_A_R3,ADD_A_R4,ADD_A_R5,ADD_A_R6,ADD_A_R7
					dd JNB_$bad_$cad,ACALL_$cad,RETI_,RLC_A,ADDC_A_dd,ADDC_A_$dad,ADDC_A_@R0,ADDC_A_@R1,ADDC_A_R0,ADDC_A_R1,ADDC_A_R2,ADDC_A_R3,ADDC_A_R4,ADDC_A_R5,ADDC_A_R6,ADDC_A_R7

					dd JC_$cad,AJMP_$cad,ORL_$dad_A,ORL_$dad_dd,ORL_A_dd,ORL_A_$dad,ORL_A_@R0,ORL_A_@R1,ORL_A_R0,ORL_A_R1,ORL_A_R2,ORL_A_R3,ORL_A_R4,ORL_A_R5,ORL_A_R6,ORL_A_R7
					dd JNC_$cad,ACALL_$cad,ANL_$dad_A,ANL_$dad_dd,ANL_A_dd,ANL_A_$dad,ANL_A_@R0,ANL_A_@R1,ANL_A_R0,ANL_A_R1,ANL_A_R2,ANL_A_R3,ANL_A_R4,ANL_A_R5,ANL_A_R6,ANL_A_R7
					dd JZ_$cad,AJMP_$cad,XRL_$dad_A,XRL_$dad_dd,XRL_A_dd,XRL_A_$dad,XRL_A_@R0,XRL_A_@R1,XRL_A_R0,XRL_A_R1,XRL_A_R2,XRL_A_R3,XRL_A_R4,XRL_A_R5,XRL_A_R6,XRL_A_R7
					dd JNZ_$cad,ACALL_$cad,ORL_C_$bad,JMP_@A_DPTR,MOV_A_dd,MOV_$dad_dd,MOV_@R0_dd,MOV_@R1_dd,MOV_R0_dd,MOV_R1_dd,MOV_R2_dd,MOV_R3_dd,MOV_R4_dd,MOV_R5_dd,MOV_R6_dd,MOV_R7_dd

					dd SJMP_$cad,AJMP_$cad,ANL_C_$bad,MOVC_A_@A_PC,DIV_AB,MOV_$dad_$dad,MOV_$dad_@R0,MOV_$dad_@R1,MOV_$dad_R0,MOV_$dad_R1,MOV_$dad_R2,MOV_$dad_R3,MOV_$dad_R4,MOV_$dad_R5,MOV_$dad_R6,MOV_$dad_R7
					dd MOV_DPTR_dw,ACALL_$cad,MOV_$bad_C,MOVC_A_@A_DPTR,SUBB_A_dd,SUBB_A_$dad,SUBB_A_@R0,SUBB_A_@R1,SUBB_A_R0,SUBB_A_R1,SUBB_A_R2,SUBB_A_R3,SUBB_A_R4,SUBB_A_R5,SUBB_A_R6,SUBB_A_R7
					dd ORL_C_n$bad,AJMP_$cad,MOV_C_$bad,INC_DPTR,MUL_AB,reserved,MOV_@R0_$dad,MOV_@R1_$dad,MOV_R0_$dad,MOV_R1_$dad,MOV_R2_$dad,MOV_R3_$dad,MOV_R4_$dad,MOV_R5_$dad,MOV_R6_$dad,MOV_R7_$dad
					dd ANL_C_n$bad,ACALL_$cad,CPL_$bad,CPL_C,CJNE_A_dd_$cad,CJNE_A_$dad_$cad,CJNE_@R0_dd_$cad,CJNE_@R1_dd_$cad,CJNE_R0_dd_$cad,CJNE_R1_dd_$cad,CJNE_R2_dd_$cad,CJNE_R3_dd_$cad,CJNE_R4_dd_$cad,CJNE_R5_dd_$cad,CJNE_R6_dd_$cad,CJNE_R7_dd_$cad

					dd PUSH_$dad,AJMP_$cad,CLR_$bad,CLR_C,SWAP_A,XCH_A_$dad,XCH_A_@R0,XCH_A_@R1,XCH_A_R0,XCH_A_R1,XCH_A_R2,XCH_A_R3,XCH_A_R4,XCH_A_R5,XCH_A_R6,XCH_A_R7
					dd POP_$dad,ACALL_$cad,SETB_$bad,SETB_C,DA_A,DJNZ_$dad_$cad,XCHD_A_@R0,XCHD_A_@R1,DJNZ_R0_$cad,DJNZ_R1_$cad,DJNZ_R2_$cad,DJNZ_R3_$cad,DJNZ_R4_$cad,DJNZ_R5_$cad,DJNZ_R6_$cad,DJNZ_R7_$cad
					dd MOVX_A_@DPTR,AJMP_$cad,MOVX_A_@R0,MOVX_A_@R1,CLR_A,MOV_A_$dad,MOV_A_@R0,MOV_A_@R1,MOV_A_R0,MOV_A_R1,MOV_A_R2,MOV_A_R3,MOV_A_R4,MOV_A_R5,MOV_A_R6,MOV_A_R7
					dd MOVX_@DPTR_A,ACALL_$cad,MOVX_@R0_A,MOVX_@R1_A,CPL_A,MOV_$dad_A,MOV_@R0_A,MOV_@R1_A,MOV_R0_A,MOV_R1_A,MOV_R2_A,MOV_R3_A,MOV_R4_A,MOV_R5_A,MOV_R6_A,MOV_R7_A

.data?

hMemFile			HGLOBAL ?
hMemCode			HGLOBAL ?

Sfr					db 256 dup(?)
Ram					db 256 dup(?)
Bank				dd ?
PC					dd ?
State				dd ?

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
	ret

Reset endp

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
	xor		ebx,ebx
	.while TRUE
		invoke SendDlgItemMessage,hWnd,IDC_LSTCODE,LB_GETITEMDATA,ebx,0
		.if eax==PC
			invoke SendDlgItemMessage,hWnd,IDC_LSTCODE,LB_SETCURSEL,ebx,0
			.break
		.elseif eax==LB_ERR
			.break
		.endif
		inc		ebx
	.endw
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
	mov		eax,Bank
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

SetParity proc

	ret

SetParity endp

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
	movzx	eax,Ram[esi+ebx+1]
	inc		Ram[eax]
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
	movzx	ecx,word ptr Ram[esi+ebx+1]
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
	inc		al
	mov		Ram[edx],bl
	inc		dl
	mov		Ram[edx],bh
	mov		Sfr[SFR_SP],dl
	shr		ah,5
	and		ebx,0F800h
	lea		ebx,[ebx+eax]
	ret

LCALL_$cad:
	movzx	eax,word ptr Ram[esi+ebx+1]
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
	movzx	eax,Ram[esi+ebx+1]
	dec		Ram[eax]
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
;AJMP_$cadP1:
RET_:
RL_A:
ADD_A_dd:
ADD_A_$dad:
ADD_A_@R0:
ADD_A_@R1:
ADD_A_R0:
ADD_A_R1:
ADD_A_R2:
ADD_A_R3:
ADD_A_R4:
ADD_A_R5:
ADD_A_R6:
ADD_A_R7:

;------------------------------------------------------------------------------
JNB_$bad_$cad:
;ACALL_$cadP1:
RETI_:
RLC_A:
ADDC_A_dd:
ADDC_A_$dad:
ADDC_A_@R0:
ADDC_A_@R1:
ADDC_A_R0:
ADDC_A_R1:
ADDC_A_R2:
ADDC_A_R3:
ADDC_A_R4:
ADDC_A_R5:
ADDC_A_R6:
ADDC_A_R7:

;------------------------------------------------------------------------------
JC_$cad:
;AJMP_$cadP2:
ORL_$dad_A:
ORL_$dad_dd:
ORL_A_dd:
ORL_A_$dad:
ORL_A_@R0:
ORL_A_@R1:
ORL_A_R0:
ORL_A_R1:
ORL_A_R2:
ORL_A_R3:
ORL_A_R4:
ORL_A_R5:
ORL_A_R6:
ORL_A_R7:

;------------------------------------------------------------------------------
JNC_$cad:
;ACALL_$cadP2:
ANL_$dad_A:
ANL_$dad_dd:
ANL_A_dd:
ANL_A_$dad:
ANL_A_@R0:
ANL_A_@R1:
ANL_A_R0:
ANL_A_R1:
ANL_A_R2:
ANL_A_R3:
ANL_A_R4:
ANL_A_R5:
ANL_A_R6:
ANL_A_R7:

;------------------------------------------------------------------------------
JZ_$cad:
;AJMP_$cadP3:
XRL_$dad_A:
XRL_$dad_dd:
XRL_A_dd:
XRL_A_$dad:
XRL_A_@R0:
XRL_A_@R1:
XRL_A_R0:
XRL_A_R1:
XRL_A_R2:
XRL_A_R3:
XRL_A_R4:
XRL_A_R5:
XRL_A_R6:
XRL_A_R7:

;------------------------------------------------------------------------------
JNZ_$cad:
;ACALL_$cadP3:
ORL_C_$bad:
JMP_@A_DPTR:
MOV_A_dd:
MOV_$dad_dd:
MOV_@R0_dd:
MOV_@R1_dd:
MOV_R0_dd:
MOV_R1_dd:
MOV_R2_dd:
MOV_R3_dd:
MOV_R4_dd:
MOV_R5_dd:
MOV_R6_dd:
MOV_R7_dd:

;------------------------------------------------------------------------------
SJMP_$cad:
;AJMP_$cadP4:
ANL_C_$bad:
MOVC_A_@A_PC:
DIV_AB:
MOV_$dad_$dad:
MOV_$dad_@R0:
MOV_$dad_@R1:
MOV_$dad_R0:
MOV_$dad_R1:
MOV_$dad_R2:
MOV_$dad_R3:
MOV_$dad_R4:
MOV_$dad_R5:
MOV_$dad_R6:
MOV_$dad_R7:

;------------------------------------------------------------------------------
MOV_DPTR_dw:
;ACALL_$cadP4:
MOV_$bad_C:
MOVC_A_@A_DPTR:
SUBB_A_dd:
SUBB_A_$dad:
SUBB_A_@R0:
SUBB_A_@R1:
SUBB_A_R0:
SUBB_A_R1:
SUBB_A_R2:
SUBB_A_R3:
SUBB_A_R4:
SUBB_A_R5:
SUBB_A_R6:
SUBB_A_R7:

;------------------------------------------------------------------------------
ORL_C_n$bad:
;AJMP_$cadP5:
MOV_C_$bad:
INC_DPTR:
MUL_AB:
reserved:
MOV_@R0_$dad:
MOV_@R1_$dad:
MOV_R0_$dad:
MOV_R1_$dad:
MOV_R2_$dad:
MOV_R3_$dad:
MOV_R4_$dad:
MOV_R5_$dad:
MOV_R6_$dad:
MOV_R7_$dad:

;------------------------------------------------------------------------------
ANL_C_n$bad:
;ACALL_$cadP5:
CPL_$bad:
CPL_C:
CJNE_A_dd_$cad:
CJNE_A_$dad_$cad:
CJNE_@R0_dd_$cad:
CJNE_@R1_dd_$cad:
CJNE_R0_dd_$cad:
CJNE_R1_dd_$cad:
CJNE_R2_dd_$cad:
CJNE_R3_dd_$cad:
CJNE_R4_dd_$cad:
CJNE_R5_dd_$cad:
CJNE_R6_dd_$cad:
CJNE_R7_dd_$cad:

;------------------------------------------------------------------------------
PUSH_$dad:
;AJMP_$cadP6:
CLR_$bad:
CLR_C:
SWAP_A:
XCH_A_$dad:
XCH_A_@R0:
XCH_A_@R1:
XCH_A_R0:
XCH_A_R1:
XCH_A_R2:
XCH_A_R3:
XCH_A_R4:
XCH_A_R5:
XCH_A_R6:
XCH_A_R7:

;------------------------------------------------------------------------------
POP_$dad:
;ACALL_$cadP6:
SETB_$bad:
SETB_C:
DA_A:
DJNZ_$dad_$cad:
XCHD_A_@R0:
XCHD_A_@R1:
DJNZ_R0_$cad:
DJNZ_R1_$cad:
DJNZ_R2_$cad:
DJNZ_R3_$cad:
DJNZ_R4_$cad:
DJNZ_R5_$cad:
DJNZ_R6_$cad:
DJNZ_R7_$cad:

;------------------------------------------------------------------------------
MOVX_A_@DPTR:
;AJMP_$cadP7:
MOVX_A_@R0:
MOVX_A_@R1:
CLR_A:
	mov		Sfr[SFR_ACC],0
	lea		ebx,[ebx+1]
	ret

MOV_A_$dad:
MOV_A_@R0:
MOV_A_@R1:
MOV_A_R0:
MOV_A_R1:
MOV_A_R2:
MOV_A_R3:
MOV_A_R4:
MOV_A_R5:
MOV_A_R6:
MOV_A_R7:

;------------------------------------------------------------------------------
MOVX_@DPTR_A:
;ACALL_$cadP7:
MOVX_@R0_A:
MOVX_@R1_A:
CPL_A:
MOV_$dad_A:
MOV_@R0_A:
MOV_@R1_A:
MOV_R0_A:
MOV_R1_A:
MOV_R2_A:
MOV_R3_A:
MOV_R4_A:
MOV_R5_A:
MOV_R6_A:
MOV_R7_A:
	ret

;------------------------------------------------------------------------------

CoreThread proc lParam:DWORD

	mov		esi,hMemCode
	mov		ebx,PC
	.while State!=STATE_STOP
		.if State & STATE_RUN
			.if !(State & STATE_PAUSE)
				call	Execute
			.elseif State & STATE_STEP_INTO
				call	Execute
				xor		State,STATE_STEP_INTO
			.elseif State & STATE_STEP_OVER
				call	Execute
				xor		State,STATE_STEP_OVER
			.endif
		.endif
	.endw
	xor		eax,eax
	ret

Execute:
	movzx	eax,byte ptr [esi+ebx]
	call	JmpTab[eax*4]
	mov		PC,ebx
	retn

CoreThread endp
