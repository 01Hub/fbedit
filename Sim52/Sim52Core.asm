
SendAddinMessage		PROTO :HWND,:DWORD,:DWORD,:DWORD

STATE_STOP				equ 0
STATE_RUN				equ 1
STATE_PAUSE				equ 2
STATE_STEP_INTO			equ 4
STATE_STEP_OVER			equ 8
STATE_RUN_TO_CURSOR		equ 16
SIM52_BREAKPOINT		equ 32

STATE_THREAD			equ 128

SFRMAP struct
	ad					dd ?
	nme					db 8 dup(?)
	d7					db 8 dup(?)
	d6					db 8 dup(?)
	d5					db 8 dup(?)
	d4					db 8 dup(?)
	d3					db 8 dup(?)
	d2					db 8 dup(?)
	d1					db 8 dup(?)
	d0					db 8 dup(?)
SFRMAP ends

.data

JmpTab					dd NOP_,AJMP_$cad,LJMP_$cad,RR_A,INC_A,INC_$dad,INC_@R0,INC_@R1,INC_R0,INC_R1,INC_R2,INC_R3,INC_R4,INC_R5,INC_R6,INC_R7
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

Cycles					db 1,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1
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
                    	
Bytes					db 1,2,3,1,1,2,1,1,1,1,1,1,1,1,1,1
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

SfrData					SFRMAP <080h,'P0','P0.7','P0.6','P0.5','P0.4','P0.3','P0.2','P0.1','P0.0'>
						SFRMAP <081h,'SP','D7','D6','D5','D4','D3','D2','D1','D0'>
						SFRMAP <082h,'DPL','D7','D6','D5','D4','D3','D2','D1','D0'>
						SFRMAP <083h,'DPH','D7','D6','D5','D4','D3','D2','D1','D0'>
						SFRMAP <084h,'DP1L','D7','D6','D5','D4','D3','D2','D1','D0'>
						SFRMAP <085h,'DP1H','D7','D6','D5','D4','D3','D2','D1','D0'>
						SFRMAP <087h,'PCON','SMOD','-','-','-','GF1','GF0','PD','IDL'>

						SFRMAP <088h,'TCON','TF1','TR1','TF0','TR0','IE1','IT1','IE0','IT0'>
						SFRMAP <089h,'TMOD','GTE1','C/T1','M1.1','M0.1','GTE0','C/T0','M1.0','M0.1'>
						SFRMAP <08Ah,'TL0','D7','D6','D5','D4','D3','D2','D1','D0'>
						SFRMAP <08Bh,'TL1','D7','D6','D5','D4','D3','D2','D1','D0'>
						SFRMAP <08Ch,'TH0','D7','D6','D5','D4','D3','D2','D1','D0'>
						SFRMAP <08Dh,'TH1','D7','D6','D5','D4','D3','D2','D1','D0'>
						SFRMAP <08Eh,'AUXR','-','-','-','WDIDLE','DISRTO','-','-','DISALE'>

						SFRMAP <090h,'P1','P1.7','P1.6','P1.5','P1.4','P1.3','P1.2','P1.1','P1.0'>

						SFRMAP <098h,'SCON','SM0','SM1','SM2','REN','TB8','RB8','TI','RI'>
						SFRMAP <099h,'SBUF','D7','D6','D5','D4','D3','D2','D1','D0'>

						SFRMAP <0A0h,'P2','P2.7','P2.6','P2.5','P2.4','P2.3','P2.2','P2.1','P2.0'>
						SFRMAP <0A2h,'AUXR1','-','-','-','-','-','-','-','DPS'>
						SFRMAP <0A6h,'WDTRST','-','-','-','-','-','-','-','-'>

						SFRMAP <0A8h,'IE','EA','-','-','ES','ET1','EX1','ET0','EX0'>

						SFRMAP <0B0h,'P3','P3.7','P3.6','P3.5','P3.4','P3.3','P3.2','P3.1','P3.0'>

						SFRMAP <0B8h,'IP','-','-','-','PS','PT1','PX1','PT0','RX0'>

						SFRMAP <0C8h,'T2CON','TF2','EXF2','RCLK','TCLK','EXEN2','TR2','C/T2','CP/RL2'>
						SFRMAP <0C9h,'T2MOD','-','-','-','-','-','-','T2OE','DCEN'>
						SFRMAP <0CAh,'RCAP2L','D7','D6','D5','D4','D3','D2','D1','D0'>
						SFRMAP <0CBh,'RCAP2H','D7','D6','D5','D4','D3','D2','D1','D0'>
						SFRMAP <0CCh,'TL2','D7','D6','D5','D4','D3','D2','D1','D0'>
						SFRMAP <0CDh,'TH2','D7','D6','D5','D4','D3','D2','D1','D0'>

						SFRMAP <0D0h,'PSW','CY','AC','F0','RS1','RS0','OV','FL','P'>

						SFRMAP <0E0h,'ACC','ACC.7','ACC.6','ACC.5','ACC.4','ACC.3','ACC.2','ACC.1','ACC.0'>

						SFRMAP <0F0h,'B','B.7','B.6','B.5','B.4','B.3','B.2','B.1','B.0'>

						SFRMAP <0>

.data?

hMemFile				HGLOBAL ?
hMemAddr				HGLOBAL ?

StatusLed				DWORD ?

ViewBank				DWORD ?
Refresh					DWORD ?
State					DWORD ?
CursorAddr				DWORD ?
TotalCycles				DWORD ?
SBUFWR					DWORD ?
ComputerClock			DWORD ?
MCUClock				DWORD ?
CpuCycles				DWORD ?
PerformanceCount		QWORD ?
RefreshRate				DWORD ?

.code

;Get number of computer clock cycles for each 8052 instruction cycle. ComputerClock/(MCUClock/12)
SetTiming proc

	mov		eax,MCUClock			;8052 Clock in Hz
	.if eax<12
		mov		eax,12
	.endif
	xor		edx,edx
	mov		ecx,12
	div		ecx						;Divide by 12 to get instruction cycle
	mov		ecx,eax
	mov		eax,ComputerClock		;Computer clock in MHz
	mov		edx,1000000
	mul		edx						;Multiply by 1000000 to convert to Hz
	div		ecx
	mov		CpuCycles,eax
	invoke KillTimer,addin.hWnd,1000
	invoke SetTimer,addin.hWnd,1000,RefreshRate,NULL
	ret

SetTiming endp

Reset proc

	mov		State,STATE_STOP
	mov		addin.PC,0
	mov		addin.Sfr[SFR_P0],0FFh
	mov		addin.Sfr[SFR_SP],07h
	mov		addin.Sfr[SFR_DPL],00h
	mov		addin.Sfr[SFR_DPH],00h
	mov		addin.Sfr[SFR_DP1L],00h
	mov		addin.Sfr[SFR_DP1H],00h
	mov		addin.Sfr[SFR_PCON],00h
	mov		addin.Sfr[SFR_TCON],00h
	mov		addin.Sfr[SFR_TMOD],00h
	mov		addin.Sfr[SFR_TL0],00h
	mov		addin.Sfr[SFR_TL1],00h
	mov		addin.Sfr[SFR_TH0],00h
	mov		addin.Sfr[SFR_TH1],00h
	mov		addin.Sfr[SFR_AUXR],00h
	mov		addin.Sfr[SFR_P1],0FFh
	mov		addin.Sfr[SFR_SCON],00h
	mov		addin.Sfr[SFR_SBUF],00h
	mov		addin.Sfr[SFR_P2],0FFh
	mov		addin.Sfr[SFR_AUXR1],00h
	mov		addin.Sfr[SFR_WDTRST],00h
	mov		addin.Sfr[SFR_IE],00h
	mov		addin.Sfr[SFR_P3],0FFh
	mov		addin.Sfr[SFR_IP],00h
	mov		addin.Sfr[SFR_T2CON],00h
	mov		addin.Sfr[SFR_T2MOD],00h
	mov		addin.Sfr[SFR_RCAP2L],00h
	mov		addin.Sfr[SFR_RCAP2H],00h
	mov		addin.Sfr[SFR_TL2],00h
	mov		addin.Sfr[SFR_TH2],00h
	mov		addin.Sfr[SFR_PSW],00h
	mov		addin.Sfr[SFR_ACC],00h
	mov		addin.Sfr[SFR_B],00h
	invoke SendAddinMessage,addin.hWnd,AM_RESET,0,0
	mov		eax,hBmpGreenLed
	mov		StatusLed,eax
	invoke SendDlgItemMessage,addin.hWnd,IDC_IMGSTATUS,STM_SETIMAGE,IMAGE_BITMAP,StatusLed
	mov		Refresh,1
	ret

Reset endp

FindMcuAddr proc uses ebx esi edi,Address:DWORD
	LOCAL	lower:DWORD
	LOCAL	upper:DWORD

	mov		esi,hMemAddr
	xor		eax,eax
	.if esi
		mov		lower,eax
		mov		ecx,eax
		mov		eax,addin.nAddr
		mov		upper,eax
		mov		ebx,Address
		.while TRUE
			mov		eax,upper
			sub		eax,lower
			.break .if !eax
			shr		eax,1
			add		eax,lower
			mov		ecx,eax
			mov		edx,sizeof MCUADDR
			mul		edx
			movzx	edx,[esi+eax].MCUADDR.mcuaddr
			mov		eax,ebx
			sub		eax,edx
			.if !eax
				; Found
				.break
			.elseif sdword ptr eax<0
				; Smaller
				mov		upper,ecx
			.elseif sdword ptr eax>0
				; Larger
				mov		lower,ecx
			.endif
		.endw
		mov		eax,sizeof MCUADDR
		mul		ecx
		lea		eax,[esi+eax]
	.endif
	ret

FindMcuAddr endp

FindGrdInx proc uses esi,GrdInx:DWORD

	mov		esi,hMemAddr
	xor		eax,eax
	.if esi
		mov		edx,GrdInx
		xor		ecx,ecx
		.while dx!=[esi].MCUADDR.lbinx && ecx<addin.nAddr
			inc		ecx
			lea		esi,[esi+sizeof MCUADDR]
		.endw
		.if dx==[esi].MCUADDR.lbinx
			mov		eax,esi
		.endif
	.endif
	ret

FindGrdInx endp

GetSfrPtr proc uses esi,hWin:HWND

	mov		esi,offset SfrData
	invoke SendDlgItemMessage,hWin,IDC_CBOSFR,CB_GETCURSEL,0,0
	invoke SendDlgItemMessage,hWin,IDC_CBOSFR,CB_GETITEMDATA,eax,0
	mov		ebx,eax
	xor		eax,eax
	.while [esi].SFRMAP.ad
		.if ebx==[esi].SFRMAP.ad
			mov		eax,esi
			.break
		.endif
		lea		esi,[esi+sizeof SFRMAP]
	.endw
	ret

GetSfrPtr endp

UpdateSelSfr proc uses ebx esi,hWin:HWND
	LOCAL	buffer[16]:BYTE

	invoke GetSfrPtr,hWin
	.if eax
		mov		esi,eax
		mov		ebx,[esi].SFRMAP.ad
		invoke wsprintf,addr buffer,addr szFmtHexByteh,ebx
		invoke SetDlgItemText,hWin,IDC_STCSFRADDR,addr buffer
		invoke SetDlgItemText,hWin,IDC_STCSFRBIT7,addr [esi].SFRMAP.d7
		invoke SetDlgItemText,hWin,IDC_STCSFRBIT6,addr [esi].SFRMAP.d6
		invoke SetDlgItemText,hWin,IDC_STCSFRBIT5,addr [esi].SFRMAP.d5
		invoke SetDlgItemText,hWin,IDC_STCSFRBIT4,addr [esi].SFRMAP.d4
		invoke SetDlgItemText,hWin,IDC_STCSFRBIT3,addr [esi].SFRMAP.d3
		invoke SetDlgItemText,hWin,IDC_STCSFRBIT2,addr [esi].SFRMAP.d2
		invoke SetDlgItemText,hWin,IDC_STCSFRBIT1,addr [esi].SFRMAP.d1
		invoke SetDlgItemText,hWin,IDC_STCSFRBIT0,addr [esi].SFRMAP.d0
		mov		al,addin.Sfr[ebx]
		xor		ecx,ecx
		mov		ebx,1100
		.while ecx<8
			push	ecx
			shr		eax,1
			push	eax
			.if CARRY?
				invoke SendDlgItemMessage,hWin,addr [ebx+ecx],STM_SETIMAGE,IMAGE_BITMAP,hBmpRedLed
			.else
				invoke SendDlgItemMessage,hWin,addr [ebx+ecx],STM_SETIMAGE,IMAGE_BITMAP,hBmpGrayLed
			.endif
			pop		eax
			pop		ecx
			inc		ecx
		.endw
	.endif
	ret

UpdateSelSfr endp

UpdateStatus proc uses ebx
	LOCAL	buffer[16]:BYTE

	mov		eax,addin.PC
	invoke wsprintf,addr buffer,addr szFmtHexWord,eax
	invoke SetDlgItemText,hTabDlgStatus,IDC_EDTPC,addr buffer
	movzx	eax,word ptr addin.Sfr[SFR_DPL]
	invoke wsprintf,addr buffer,addr szFmtHexWord,eax
	invoke SetDlgItemText,hTabDlgStatus,IDC_EDTDPTR,addr buffer
	movzx	eax,word ptr addin.Sfr[SFR_DP1L]
	invoke wsprintf,addr buffer,addr szFmtHexWord,eax
	invoke SetDlgItemText,hTabDlgStatus,IDC_EDTDPTR1,addr buffer
	movzx	eax,addin.Sfr[SFR_ACC]
	invoke wsprintf,addr buffer,addr szFmtHexByte,eax
	invoke SetDlgItemText,hTabDlgStatus,IDC_EDTACC,addr buffer
	movzx	eax,addin.Sfr[SFR_B]
	invoke wsprintf,addr buffer,addr szFmtHexByte,eax
	invoke SetDlgItemText,hTabDlgStatus,IDC_EDTB,addr buffer
	movzx	eax,addin.Sfr[SFR_SP]
	invoke wsprintf,addr buffer,addr szFmtHexByte,eax
	invoke SetDlgItemText,hTabDlgStatus,IDC_EDTSP,addr buffer
	push	0
	push	IDC_IMGCY
	push	IDC_IMGAC
	push	IDC_IMGF0
	push	IDC_IMGRS1
	push	IDC_IMGRS0
	push	IDC_IMGOV
	push	IDC_IMGFL
	push	IDC_IMGP
	movzx	ebx,addin.Sfr[SFR_PSW]
	pop		eax
	.while eax
		shr		ebx,1
		.if CARRY?
			invoke SendDlgItemMessage,hTabDlgStatus,eax,STM_SETIMAGE,IMAGE_BITMAP,hBmpRedLed
		.else
			invoke SendDlgItemMessage,hTabDlgStatus,eax,STM_SETIMAGE,IMAGE_BITMAP,hBmpGrayLed
		.endif
		pop		eax
	.endw
	invoke FindMcuAddr,addin.PC
	.if eax
		movzx	eax,[eax].MCUADDR.lbinx
		invoke SendMessage,hGrd,GM_SETCURROW,eax,0
	.endif
	invoke SetDlgItemInt,hTabDlgStatus,IDC_STCCYCLES,TotalCycles,FALSE
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
	movzx	ebx,addin.Sfr[SFR_P0]
	pop		eax
	.while eax
		shl		bl,1
		.if CARRY?
			invoke SendDlgItemMessage,hTabDlgStatus,eax,STM_SETIMAGE,IMAGE_BITMAP,hBmpGreenLed
		.else
			invoke SendDlgItemMessage,hTabDlgStatus,eax,STM_SETIMAGE,IMAGE_BITMAP,hBmpGrayLed
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
	movzx	ebx,addin.Sfr[SFR_P1]
	pop		eax
	.while eax
		shl		bl,1
		.if CARRY?
			invoke SendDlgItemMessage,hTabDlgStatus,eax,STM_SETIMAGE,IMAGE_BITMAP,hBmpGreenLed
		.else
			invoke SendDlgItemMessage,hTabDlgStatus,eax,STM_SETIMAGE,IMAGE_BITMAP,hBmpGrayLed
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
	movzx	ebx,addin.Sfr[SFR_P2]
	pop		eax
	.while eax
		shl		bl,1
		.if CARRY?
			invoke SendDlgItemMessage,hTabDlgStatus,eax,STM_SETIMAGE,IMAGE_BITMAP,hBmpGreenLed
		.else
			invoke SendDlgItemMessage,hTabDlgStatus,eax,STM_SETIMAGE,IMAGE_BITMAP,hBmpGrayLed
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
	movzx	ebx,addin.Sfr[SFR_P3]
	pop		eax
	.while eax
		shl		bl,1
		.if CARRY?
			invoke SendDlgItemMessage,hTabDlgStatus,eax,STM_SETIMAGE,IMAGE_BITMAP,hBmpGreenLed
		.else
			invoke SendDlgItemMessage,hTabDlgStatus,eax,STM_SETIMAGE,IMAGE_BITMAP,hBmpGrayLed
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
	mov		esi,offset addin.Ram
	mov		eax,ViewBank
	lea		esi,[esi+eax*8]
	pop		ebx
	.while ebx
		movzx	eax,byte ptr [esi]
		invoke wsprintf,addr buffer,addr szFmtHexByte,eax
		invoke SetDlgItemText,hTabDlgStatus,ebx,addr buffer
		inc		esi
		pop		ebx
	.endw
	ret

UpdateRegisters endp

UpdateBits proc uses ebx edi

	mov		edi,1000
	xor		ebx,ebx
	.while ebx<16
		xor		ecx,ecx
		mov		al,addin.Ram[ebx+20h]
		.while ecx<8
			push	ecx
			ror		eax,1
			push	eax
			.if CARRY?
				invoke SendDlgItemMessage,hTabDlg[4],edi,STM_SETIMAGE,IMAGE_BITMAP,hBmpRedLed
			.else
				invoke SendDlgItemMessage,hTabDlg[4],edi,STM_SETIMAGE,IMAGE_BITMAP,hBmpGrayLed
			.endif
			pop		eax
			pop		ecx
			inc		ecx
			inc		edi
		.endw
		inc		ebx
	.endw
	ret

UpdateBits endp

ToggleBreakPoint proc grdinx:DWORD
	LOCAL	dwbp:DWORD

	invoke FindGrdInx,grdinx
	.if eax
		xor		[eax].MCUADDR.fbp,TRUE
		movzx	eax,[eax].MCUADDR.fbp
		xor		eax,1
		mov		dwbp,eax
		mov		ecx,grdinx
		shl		ecx,16
		invoke SendMessage,hGrd,GM_SETCELLDATA,ecx,addr dwbp
	.endif
	ret

ToggleBreakPoint endp

ClearBreakPoints proc
	LOCAL	dwbp:DWORD

	mov		dwbp,1
	mov		edx,hMemAddr
	.if edx
		xor		ecx,ecx
		.while ecx<addin.nAddr
			.if [edx].MCUADDR.fbp
				push	ecx
				push	edx
				movzx	edx,[edx].MCUADDR.lbinx
				shl		edx,16
				invoke SendMessage,hGrd,GM_SETCELLDATA,edx,addr dwbp
				pop		edx
				pop		ecx
			.endif
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

WritePort proc lpSfr:DWORD,nValue:DWORD

	mov		eax,lpSfr
	sub		eax,SFR_P0
	shr		eax,4
	invoke SendAddinMessage,addin.hWnd,AM_PORTCHANGED,eax,nValue
	ret

WritePort endp

WriteXRam proc nAddr:DWORD,nValue:DWORD

	invoke SendAddinMessage,addin.hWnd,AM_XRAMCHANGED,nAddr,nValue
	.if !eax
		;No memory mapped outputs at this address, update XRam
		mov		edx,nAddr
		mov		eax,nValue
		mov		addin.XRam[edx],al
	.endif
	ret

WriteXRam endp

SetParity proc

	ret

SetParity endp

SetFlags proc

	pushfd
	pop		eax
	;Carry
	test	eax,1
	.if ZERO?
		and		addin.Sfr[SFR_PSW],7Fh
	.else
		or		addin.Sfr[SFR_PSW],80h
	.endif
	;Parity
	test	eax,4
	.if ZERO?
		and		addin.Sfr[SFR_PSW],0FEh
	.else
		or		addin.Sfr[SFR_PSW],01h
	.endif
	;Auxiliary Flag
	test	eax,16
	.if ZERO?
		and		addin.Sfr[SFR_PSW],0BFh
	.else
		or		addin.Sfr[SFR_PSW],40h
	.endif
	;Overflow flag
	test	eax,2048
	.if ZERO?
		and		addin.Sfr[SFR_PSW],0FBh
	.else
		or		addin.Sfr[SFR_PSW],04h
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
	ror		addin.Sfr[SFR_ACC],1
	lea		ebx,[ebx+1]
	ret

INC_A:
	inc		addin.Sfr[SFR_ACC]
	invoke SetParity
	lea		ebx,[ebx+1]
	ret

INC_$dad:
	movzx	edx,byte ptr [esi+ebx+1]
	.if edx<80h
		inc		addin.Ram[edx]
	.else
		.if edx==SFR_SBUF
			inc		SBUFWR
			invoke ScreenChar,SBUFWR
		.else
			inc		addin.Sfr[edx]
			.if edx==SFR_P0 || edx==SFR_P1 || edx==SFR_P2 || edx==SFR_P3
				movzx	eax,addin.Sfr[edx]
				invoke WritePort,edx,eax
			.endif
		.endif
	.endif
	lea		ebx,[ebx+2]
	ret

INC_@R0:
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	movzx	eax,addin.Ram[eax]
	inc		addin.Ram[eax]
	lea		ebx,[ebx+1]
	ret

INC_@R1:
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	movzx	eax,addin.Ram[eax]
	inc		addin.Ram[eax]
	lea		ebx,[ebx+1]
	ret

INC_R0:
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	inc		addin.Ram[eax]
	lea		ebx,[ebx+1]
	ret

INC_R1:
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	inc		addin.Ram[eax]
	lea		ebx,[ebx+1]
	ret

INC_R2:
	mov		eax,addin.Bank
	lea		eax,[eax*8+2]
	inc		addin.Ram[eax]
	lea		ebx,[ebx+1]
	ret

INC_R3:
	mov		eax,addin.Bank
	lea		eax,[eax*8+3]
	inc		addin.Ram[eax]
	lea		ebx,[ebx+1]
	ret

INC_R4:
	mov		eax,addin.Bank
	lea		eax,[eax*8+4]
	inc		addin.Ram[eax]
	lea		ebx,[ebx+1]
	ret

INC_R5:
	mov		eax,addin.Bank
	lea		eax,[eax*8+5]
	inc		addin.Ram[eax]
	lea		ebx,[ebx+1]
	ret

INC_R6:
	mov		eax,addin.Bank
	lea		eax,[eax*8+6]
	inc		addin.Ram[eax]
	lea		ebx,[ebx+1]
	ret

INC_R7:
	mov		eax,addin.Bank
	lea		eax,[eax*8+7]
	inc		addin.Ram[eax]
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
	test	addin.Ram[eax],dl
	.if !ZERO?
		xor		addin.Ram[eax],dl
		movsx	ecx,ch
		lea		ebx,[ebx+ecx]
	.endif
	ret

ACALL_$cad:
	movzx	eax,word ptr [esi+ebx]
	xchg	al,ah
	lea		ebx,[ebx+2]
	movzx	edx,addin.Sfr[SFR_SP]
	inc		dl
	mov		addin.Ram[edx],bl
	inc		dl
	mov		addin.Ram[edx],bh
	mov		addin.Sfr[SFR_SP],dl
	shr		ah,5
	and		ebx,0F800h
	lea		ebx,[ebx+eax]
	ret

LCALL_$cad:
	movzx	eax,word ptr [esi+ebx+1]
	xchg	al,ah
	lea		ebx,[ebx+3]
	movzx	edx,addin.Sfr[SFR_SP]
	inc		dl
	mov		addin.Ram[edx],bl
	inc		dl
	mov		addin.Ram[edx],bh
	mov		addin.Sfr[SFR_SP],dl
	mov		ebx,eax
	ret

RRC_A:
	test	addin.Sfr[SFR_PSW],80h
	clc
	.if !ZERO?
		stc
	.endif
	rcr		addin.Sfr[SFR_ACC],1
	.if CARRY?
		or		addin.Sfr[SFR_PSW],80h
	.else
		and		addin.Sfr[SFR_PSW],7Fh
	.endif
	lea		ebx,[ebx+1]
	ret

DEC_A:
	dec		addin.Sfr[SFR_ACC]
	invoke SetParity
	lea		ebx,[ebx+1]
	ret

DEC_$dad:
	movzx	edx,byte ptr [esi+ebx+1]
	.if edx<80h
		dec		addin.Ram[edx]
	.else
		.if edx==SFR_SBUF
			dec		SBUFWR
			invoke ScreenChar,SBUFWR
		.else
			dec		addin.Sfr[edx]
			.if edx==SFR_P0 || edx==SFR_P1 || edx==SFR_P2 || edx==SFR_P3
				movzx	eax,addin.Sfr[edx]
				invoke WritePort,edx,eax
			.endif
		.endif
	.endif
	lea		ebx,[ebx+2]
	ret

DEC_@R0:
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	movzx	eax,addin.Ram[eax]
	dec		addin.Ram[eax]
	lea		ebx,[ebx+1]
	ret

DEC_@R1:
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	movzx	eax,addin.Ram[eax]
	dec		addin.Ram[eax]
	lea		ebx,[ebx+1]
	ret

DEC_R0:
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	dec		addin.Ram[eax]
	lea		ebx,[ebx+1]
	ret

DEC_R1:
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	dec		addin.Ram[eax]
	lea		ebx,[ebx+1]
	ret

DEC_R2:
	mov		eax,addin.Bank
	lea		eax,[eax*8+2]
	dec		addin.Ram[eax]
	lea		ebx,[ebx+1]
	ret

DEC_R3:
	mov		eax,addin.Bank
	lea		eax,[eax*8+3]
	dec		addin.Ram[eax]
	lea		ebx,[ebx+1]
	ret

DEC_R4:
	mov		eax,addin.Bank
	lea		eax,[eax*8+4]
	dec		addin.Ram[eax]
	lea		ebx,[ebx+1]
	ret

DEC_R5:
	mov		eax,addin.Bank
	lea		eax,[eax*8+5]
	dec		addin.Ram[eax]
	lea		ebx,[ebx+1]
	ret

DEC_R6:
	mov		eax,addin.Bank
	lea		eax,[eax*8+6]
	dec		addin.Ram[eax]
	lea		ebx,[ebx+1]
	ret

DEC_R7:
	mov		eax,addin.Bank
	lea		eax,[eax*8+7]
	dec		addin.Ram[eax]
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
		test	addin.Ram[eax],dl
	.else
		and		eax,0F8h
		test	addin.Sfr[eax],dl
	.endif
	.if !ZERO?
		movsx	ecx,ch
		lea		ebx,[ebx+ecx]
	.endif
	ret

RET_:
	movzx	edx,addin.Sfr[SFR_SP]
	mov		bh,addin.Ram[edx]
	dec		dl
	mov		bl,addin.Ram[edx]
	dec		dl
	mov		addin.Sfr[SFR_SP],dl
	ret

RL_A:
	rol		addin.Sfr[SFR_ACC],1
	lea		ebx,[ebx+1]
	ret

ADD_A_imm:
	movzx	eax,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	add		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ADD_A_$dad:
	movzx	edx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	.if edx<80h
		movzx	eax,addin.Ram[edx]
	.else
		movzx	eax,addin.Sfr[edx]
	.endif
	add		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ADD_A_@R0:
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	movzx	eax,addin.Ram[eax]
	movzx	eax,addin.Ram[eax]
	add		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADD_A_@R1:
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	movzx	eax,addin.Ram[eax]
	movzx	eax,addin.Ram[eax]
	add		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADD_A_R0:
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	movzx	eax,addin.Ram[eax]
	add		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADD_A_R1:
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	movzx	eax,addin.Ram[eax]
	add		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADD_A_R2:
	mov		eax,addin.Bank
	lea		eax,[eax*8+2]
	movzx	eax,addin.Ram[eax]
	add		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADD_A_R3:
	mov		eax,addin.Bank
	lea		eax,[eax*8+3]
	movzx	eax,addin.Ram[eax]
	add		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADD_A_R4:
	mov		eax,addin.Bank
	lea		eax,[eax*8+4]
	movzx	eax,addin.Ram[eax]
	add		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADD_A_R5:
	mov		eax,addin.Bank
	lea		eax,[eax*8+5]
	movzx	eax,addin.Ram[eax]
	add		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADD_A_R6:
	mov		eax,addin.Bank
	lea		eax,[eax*8+6]
	movzx	eax,addin.Ram[eax]
	add		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADD_A_R7:
	mov		eax,addin.Bank
	lea		eax,[eax*8+7]
	movzx	eax,addin.Ram[eax]
	add		addin.Sfr[SFR_ACC],al
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
		test	addin.Ram[eax],dl
	.else
		and		eax,0F8h
		test	addin.Sfr[eax],dl
	.endif
	.if ZERO?
		movsx	ecx,ch
		lea		ebx,[ebx+ecx]
	.endif
	ret

RETI_:
	movzx	edx,addin.Sfr[SFR_SP]
	mov		bh,addin.Ram[edx]
	dec		dl
	mov		bl,addin.Ram[edx]
	dec		dl
	mov		addin.Sfr[SFR_SP],dl
	ret

RLC_A:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	rcl		addin.Sfr[SFR_ACC],1
	lea		ebx,[ebx+1]
	ret

ADDC_A_imm:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	movzx	eax,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	adc		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ADDC_A_$dad:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	movzx	edx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	.if edx<80h
		movzx	eax,addin.Ram[edx]
	.else
		movzx	eax,addin.Sfr[edx]
	.endif
	adc		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ADDC_A_@R0:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	movzx	eax,addin.Ram[eax]
	movzx	eax,addin.Ram[eax]
	adc		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADDC_A_@R1:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	movzx	eax,addin.Ram[eax]
	movzx	eax,addin.Ram[eax]
	adc		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADDC_A_R0:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	movzx	eax,addin.Ram[eax]
	adc		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADDC_A_R1:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	movzx	eax,addin.Ram[eax]
	adc		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADDC_A_R2:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+2]
	movzx	eax,addin.Ram[eax]
	adc		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADDC_A_R3:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+3]
	movzx	eax,addin.Ram[eax]
	adc		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADDC_A_R4:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+4]
	movzx	eax,addin.Ram[eax]
	adc		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADDC_A_R5:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+5]
	movzx	eax,addin.Ram[eax]
	adc		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADDC_A_R6:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+6]
	movzx	eax,addin.Ram[eax]
	adc		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ADDC_A_R7:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+7]
	movzx	eax,addin.Ram[eax]
	adc		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

;------------------------------------------------------------------------------
JC_$cad:
	movsx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	.if CARRY?
		lea		ebx,[ebx+ecx]
	.endif
	ret

ORL_$dad_A:
	movzx	edx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	movzx	eax,addin.Sfr[SFR_ACC]
	or		addin.Ram[edx],al
	invoke SetFlags
	ret

ORL_$dad_imm:
	movzx	edx,byte ptr [esi+ebx+1]
	movzx	eax,byte ptr [esi+ebx+2]
	lea		ebx,[ebx+3]
	or		addin.Ram[edx],al
	invoke SetFlags
	ret

ORL_A_imm:
	movzx	eax,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	or		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ORL_A_$dad:
	movzx	edx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	.if edx<80h
		movzx	eax,addin.Ram[edx]
	.else
		movzx	eax,addin.Sfr[edx]
	.endif
	or		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ORL_A_@R0:
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	movzx	eax,addin.Ram[eax]
	movzx	eax,addin.Ram[eax]
	or		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ORL_A_@R1:
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	movzx	eax,addin.Ram[eax]
	movzx	eax,addin.Ram[eax]
	or		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ORL_A_R0:
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	movzx	eax,addin.Ram[eax]
	or		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ORL_A_R1:
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	movzx	eax,addin.Ram[eax]
	or		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ORL_A_R2:
	mov		eax,addin.Bank
	lea		eax,[eax*8+2]
	movzx	eax,addin.Ram[eax]
	or		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ORL_A_R3:
	mov		eax,addin.Bank
	lea		eax,[eax*8+3]
	movzx	eax,addin.Ram[eax]
	or		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ORL_A_R4:
	mov		eax,addin.Bank
	lea		eax,[eax*8+4]
	movzx	eax,addin.Ram[eax]
	or		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ORL_A_R5:
	mov		eax,addin.Bank
	lea		eax,[eax*8+5]
	movzx	eax,addin.Ram[eax]
	or		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ORL_A_R6:
	mov		eax,addin.Bank
	lea		eax,[eax*8+6]
	movzx	eax,addin.Ram[eax]
	or		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ORL_A_R7:
	mov		eax,addin.Bank
	lea		eax,[eax*8+7]
	movzx	eax,addin.Ram[eax]
	or		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

;------------------------------------------------------------------------------
JNC_$cad:
	movsx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	.if !CARRY?
		lea		ebx,[ebx+ecx]
	.endif
	ret

ANL_$dad_A:
	movzx	edx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	movzx	eax,addin.Sfr[SFR_ACC]
	and		addin.Ram[edx],al
	invoke SetFlags
	ret

ANL_$dad_imm:
	movzx	edx,byte ptr [esi+ebx+1]
	movzx	eax,byte ptr [esi+ebx+2]
	lea		ebx,[ebx+3]
	and		addin.Ram[edx],al
	invoke SetFlags
	ret

ANL_A_imm:
	movzx	eax,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	and		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ANL_A_$dad:
	movzx	edx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	.if edx<80h
		movzx	eax,addin.Ram[edx]
	.else
		movzx	eax,addin.Sfr[edx]
	.endif
	and		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ANL_A_@R0:
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	movzx	eax,addin.Ram[eax]
	movzx	eax,addin.Ram[eax]
	and		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ANL_A_@R1:
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	movzx	eax,addin.Ram[eax]
	movzx	eax,addin.Ram[eax]
	and		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ANL_A_R0:
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	movzx	eax,addin.Ram[eax]
	and		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ANL_A_R1:
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	movzx	eax,addin.Ram[eax]
	and		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ANL_A_R2:
	mov		eax,addin.Bank
	lea		eax,[eax*8+2]
	movzx	eax,addin.Ram[eax]
	and		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ANL_A_R3:
	mov		eax,addin.Bank
	lea		eax,[eax*8+3]
	movzx	eax,addin.Ram[eax]
	and		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ANL_A_R4:
	mov		eax,addin.Bank
	lea		eax,[eax*8+4]
	movzx	eax,addin.Ram[eax]
	and		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ANL_A_R5:
	mov		eax,addin.Bank
	lea		eax,[eax*8+5]
	movzx	eax,addin.Ram[eax]
	and		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ANL_A_R6:
	mov		eax,addin.Bank
	lea		eax,[eax*8+6]
	movzx	eax,addin.Ram[eax]
	and		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

ANL_A_R7:
	mov		eax,addin.Bank
	lea		eax,[eax*8+7]
	movzx	eax,addin.Ram[eax]
	and		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

;------------------------------------------------------------------------------
JZ_$cad:
	movsx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	movzx	eax,addin.Sfr[SFR_ACC]
	or		eax,eax
	.if ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	ret

XRL_$dad_A:
	movzx	edx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	movzx	eax,addin.Sfr[SFR_ACC]
	xor		addin.Ram[edx],al
	invoke SetFlags
	ret

XRL_$dad_imm:
	movzx	edx,byte ptr [esi+ebx+1]
	movzx	eax,byte ptr [esi+ebx+2]
	lea		ebx,[ebx+3]
	xor		addin.Ram[edx],al
	invoke SetFlags
	ret

XRL_A_imm:
	movzx	eax,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	xor		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

XRL_A_$dad:
	movzx	edx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	.if edx<80h
		movzx	eax,addin.Ram[edx]
	.else
		movzx	eax,addin.Sfr[edx]
	.endif
	xor		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

XRL_A_@R0:
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	movzx	eax,addin.Ram[eax]
	movzx	eax,addin.Ram[eax]
	xor		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

XRL_A_@R1:
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	movzx	eax,addin.Ram[eax]
	movzx	eax,addin.Ram[eax]
	xor		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

XRL_A_R0:
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	movzx	eax,addin.Ram[eax]
	xor		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

XRL_A_R1:
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	movzx	eax,addin.Ram[eax]
	xor		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

XRL_A_R2:
	mov		eax,addin.Bank
	lea		eax,[eax*8+2]
	movzx	eax,addin.Ram[eax]
	xor		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

XRL_A_R3:
	mov		eax,addin.Bank
	lea		eax,[eax*8+3]
	movzx	eax,addin.Ram[eax]
	xor		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

XRL_A_R4:
	mov		eax,addin.Bank
	lea		eax,[eax*8+4]
	movzx	eax,addin.Ram[eax]
	xor		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

XRL_A_R5:
	mov		eax,addin.Bank
	lea		eax,[eax*8+5]
	movzx	eax,addin.Ram[eax]
	xor		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

XRL_A_R6:
	mov		eax,addin.Bank
	lea		eax,[eax*8+6]
	movzx	eax,addin.Ram[eax]
	xor		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

XRL_A_R7:
	mov		eax,addin.Bank
	lea		eax,[eax*8+7]
	movzx	eax,addin.Ram[eax]
	xor		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

;------------------------------------------------------------------------------
JNZ_$cad:
	movsx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	movzx	eax,addin.Sfr[SFR_ACC]
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
		and		dl,addin.Ram[eax]
	.else
		and		eax,0F8h
		and		dl,addin.Sfr[eax]
	.endif
	.if dl
		or		addin.Sfr[SFR_PSW],80h
	.endif
	ret

JMP_@A_DPTR:
	movzx	eax,addin.Sfr[SFR_AUXR1]
	and		eax,1
	.if ZERO?
		movzx	dx,addin.Sfr[SFR_DPL]
	.else
		movzx	dx,addin.Sfr[SFR_DP1L]
	.endif
	movzx	eax,addin.Sfr[SFR_ACC]
	lea		ebx,[edx+eax]
	ret

MOV_A_imm:
	movzx	eax,byte ptr [esi+ebx+1]
	mov		addin.Sfr[SFR_ACC],al
	lea		ebx,[ebx+2]
	ret

MOV_$dad_imm:
	movzx	edx,byte ptr [esi+ebx+1]
	movzx	eax,byte ptr [esi+ebx+2]
	.if edx<80h
		mov		addin.Ram[edx],al
	.else
		.if edx==SFR_SBUF
			mov		SBUFWR,eax
			invoke ScreenChar,SBUFWR
		.else
			mov		addin.Sfr[edx],al
			.if edx==SFR_P0 || edx==SFR_P1 || edx==SFR_P2 || edx==SFR_P3
				movzx	eax,addin.Sfr[edx]
				invoke WritePort,edx,eax
			.endif
		.endif
	.endif
	lea		ebx,[ebx+3]
	ret
	
MOV_@R0_imm:
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	movzx	edx,addin.Ram[eax]
	movzx	eax,byte ptr [esi+ebx+1]
	mov		addin.Ram[edx],al
	lea		ebx,[ebx+2]
	ret

MOV_@R1_imm:
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	movzx	edx,addin.Ram[eax]
	movzx	eax,byte ptr [esi+ebx+1]
	mov		addin.Ram[edx],al
	lea		ebx,[ebx+2]
	ret

MOV_R0_imm:
	movzx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	mov		addin.Ram[eax],cl
	ret

MOV_R1_imm:
	movzx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	mov		addin.Ram[eax],cl
	ret

MOV_R2_imm:
	movzx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	mov		eax,addin.Bank
	lea		eax,[eax*8+2]
	mov		addin.Ram[eax],cl
	ret

MOV_R3_imm:
	movzx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	mov		eax,addin.Bank
	lea		eax,[eax*8+3]
	mov		addin.Ram[eax],cl
	ret

MOV_R4_imm:
	movzx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	mov		eax,addin.Bank
	lea		eax,[eax*8+4]
	mov		addin.Ram[eax],cl
	ret

MOV_R5_imm:
	movzx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	mov		eax,addin.Bank
	lea		eax,[eax*8+5]
	mov		addin.Ram[eax],cl
	ret

MOV_R6_imm:
	movzx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	mov		eax,addin.Bank
	lea		eax,[eax*8+6]
	mov		addin.Ram[eax],cl
	ret

MOV_R7_imm:
	movzx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	mov		eax,addin.Bank
	lea		eax,[eax*8+7]
	mov		addin.Ram[eax],cl
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
		and		dl,addin.Ram[eax]
	.else
		and		eax,0F8h
		and		dl,addin.Sfr[eax]
	.endif
	.if !dl
		and		addin.Sfr[SFR_PSW],7Fh
	.endif
	ret

MOVC_A_@A_PC:
	movzx	eax,addin.Sfr[SFR_ACC]
	lea		edx,[ebx+eax]
	movzx	eax,byte ptr [esi+edx]
	mov		addin.Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

DIV_AB:
	movzx	eax,addin.Sfr[SFR_ACC]
	movzx	ecx,addin.Sfr[SFR_B]
	.if !ecx
		;Set OV flag
		or		addin.Sfr[SFR_PSW],04h
	.else
		xor		edx,edx
		div		cl
		mov		addin.Sfr[SFR_ACC],al
		mov		addin.Sfr[SFR_B],dl
		;Clear OV flag
		and		addin.Sfr[SFR_PSW],0FBh
	.endif
	;Clear CY flag
	and		addin.Sfr[SFR_PSW],7Fh
	lea		ebx,[ebx+1]
	ret

MOV_$dad_$dad:
	movzx	edx,byte ptr [esi+ebx+2]
	.if edx<80h
		movzx	eax,addin.Ram[edx]
	.else
		movzx	eax,addin.Sfr[edx]
	.endif
	movzx	edx,byte ptr [esi+ebx+1]
	.if edx<80h
		mov		addin.Ram[edx],al
	.else
		.if edx==SFR_SBUF
			mov		SBUFWR,eax
			invoke ScreenChar,SBUFWR
		.else
			mov		addin.Sfr[edx],al
			.if edx==SFR_P0 || edx==SFR_P1 || edx==SFR_P2 || edx==SFR_P3
				movzx	eax,addin.Sfr[edx]
				invoke WritePort,edx,eax
			.endif
		.endif
	.endif
	lea		ebx,[ebx+3]
	ret

MOV_$dad_@R0:
	mov		edx,addin.Bank
	lea		edx,[edx*8+0]
	movzx	edx,addin.Ram[edx]
	movzx	eax,addin.Ram[edx]
	movzx	edx,byte ptr [esi+ebx+1]
	.if edx<80h
		mov		addin.Ram[edx],al
	.else
		.if edx==SFR_SBUF
			mov		SBUFWR,eax
			invoke ScreenChar,SBUFWR
		.else
			mov		addin.Sfr[edx],al
			.if edx==SFR_P0 || edx==SFR_P1 || edx==SFR_P2 || edx==SFR_P3
				movzx	eax,addin.Sfr[edx]
				invoke WritePort,edx,eax
			.endif
		.endif
	.endif
	lea		ebx,[ebx+2]
	ret

MOV_$dad_@R1:
	mov		edx,addin.Bank
	lea		edx,[edx*8+1]
	movzx	edx,addin.Ram[edx]
	movzx	eax,addin.Ram[edx]
	movzx	edx,byte ptr [esi+ebx+1]
	.if edx<80h
		mov		addin.Ram[edx],al
	.else
		.if edx==SFR_SBUF
			mov		SBUFWR,eax
			invoke ScreenChar,SBUFWR
		.else
			mov		addin.Sfr[edx],al
			.if edx==SFR_P0 || edx==SFR_P1 || edx==SFR_P2 || edx==SFR_P3
				movzx	eax,addin.Sfr[edx]
				invoke WritePort,edx,eax
			.endif
		.endif
	.endif
	lea		ebx,[ebx+2]
	ret

MOV_$dad_R0:
	mov		edx,addin.Bank
	lea		edx,[edx*8+0]
	movzx	eax,addin.Ram[edx]
	movzx	edx,byte ptr [esi+ebx+1]
	.if edx<80h
		mov		addin.Ram[edx],al
	.else
		.if edx==SFR_SBUF
			mov		SBUFWR,eax
			invoke ScreenChar,SBUFWR
		.else
			mov		addin.Sfr[edx],al
			.if edx==SFR_P0 || edx==SFR_P1 || edx==SFR_P2 || edx==SFR_P3
				movzx	eax,addin.Sfr[edx]
				invoke WritePort,edx,eax
			.endif
		.endif
	.endif
	lea		ebx,[ebx+2]
	ret

MOV_$dad_R1:
	mov		edx,addin.Bank
	lea		edx,[edx*8+1]
	movzx	eax,addin.Ram[edx]
	movzx	edx,byte ptr [esi+ebx+1]
	.if edx<80h
		mov		addin.Ram[edx],al
	.else
		.if edx==SFR_SBUF
			mov		SBUFWR,eax
			invoke ScreenChar,SBUFWR
		.else
			mov		addin.Sfr[edx],al
			.if edx==SFR_P0 || edx==SFR_P1 || edx==SFR_P2 || edx==SFR_P3
				movzx	eax,addin.Sfr[edx]
				invoke WritePort,edx,eax
			.endif
		.endif
	.endif
	lea		ebx,[ebx+2]
	ret

MOV_$dad_R2:
	mov		edx,addin.Bank
	lea		edx,[edx*8+2]
	movzx	eax,addin.Ram[edx]
	movzx	edx,byte ptr [esi+ebx+1]
	.if edx<80h
		mov		addin.Ram[edx],al
	.else
		.if edx==SFR_SBUF
			mov		SBUFWR,eax
			invoke ScreenChar,SBUFWR
		.else
			mov		addin.Sfr[edx],al
			.if edx==SFR_P0 || edx==SFR_P1 || edx==SFR_P2 || edx==SFR_P3
				movzx	eax,addin.Sfr[edx]
				invoke WritePort,edx,eax
			.endif
		.endif
	.endif
	lea		ebx,[ebx+2]
	ret

MOV_$dad_R3:
	mov		edx,addin.Bank
	lea		edx,[edx*8+3]
	movzx	eax,addin.Ram[edx]
	movzx	edx,byte ptr [esi+ebx+1]
	.if edx<80h
		mov		addin.Ram[edx],al
	.else
		.if edx==SFR_SBUF
			mov		SBUFWR,eax
			invoke ScreenChar,SBUFWR
		.else
			mov		addin.Sfr[edx],al
			.if edx==SFR_P0 || edx==SFR_P1 || edx==SFR_P2 || edx==SFR_P3
				movzx	eax,addin.Sfr[edx]
				invoke WritePort,edx,eax
			.endif
		.endif
	.endif
	lea		ebx,[ebx+2]
	ret

MOV_$dad_R4:
	mov		edx,addin.Bank
	lea		edx,[edx*8+4]
	movzx	eax,addin.Ram[edx]
	movzx	edx,byte ptr [esi+ebx+1]
	.if edx<80h
		mov		addin.Ram[edx],al
	.else
		.if edx==SFR_SBUF
			mov		SBUFWR,eax
			invoke ScreenChar,SBUFWR
		.else
			mov		addin.Sfr[edx],al
			.if edx==SFR_P0 || edx==SFR_P1 || edx==SFR_P2 || edx==SFR_P3
				movzx	eax,addin.Sfr[edx]
				invoke WritePort,edx,eax
			.endif
		.endif
	.endif
	lea		ebx,[ebx+2]
	ret

MOV_$dad_R5:
	mov		edx,addin.Bank
	lea		edx,[edx*8+5]
	movzx	eax,addin.Ram[edx]
	movzx	edx,byte ptr [esi+ebx+1]
	.if edx<80h
		mov		addin.Ram[edx],al
	.else
		.if edx==SFR_SBUF
			mov		SBUFWR,eax
			invoke ScreenChar,SBUFWR
		.else
			mov		addin.Sfr[edx],al
			.if edx==SFR_P0 || edx==SFR_P1 || edx==SFR_P2 || edx==SFR_P3
				movzx	eax,addin.Sfr[edx]
				invoke WritePort,edx,eax
			.endif
		.endif
	.endif
	lea		ebx,[ebx+2]
	ret

MOV_$dad_R6:
	mov		edx,addin.Bank
	lea		edx,[edx*8+6]
	movzx	eax,addin.Ram[edx]
	movzx	edx,byte ptr [esi+ebx+1]
	.if edx<80h
		mov		addin.Ram[edx],al
	.else
		.if edx==SFR_SBUF
			mov		SBUFWR,eax
			invoke ScreenChar,SBUFWR
		.else
			mov		addin.Sfr[edx],al
			.if edx==SFR_P0 || edx==SFR_P1 || edx==SFR_P2 || edx==SFR_P3
				movzx	eax,addin.Sfr[edx]
				invoke WritePort,edx,eax
			.endif
		.endif
	.endif
	lea		ebx,[ebx+2]
	ret

MOV_$dad_R7:
	mov		edx,addin.Bank
	lea		edx,[edx*8+7]
	movzx	eax,addin.Ram[edx]
	movzx	edx,byte ptr [esi+ebx+1]
	.if edx<80h
		mov		addin.Ram[edx],al
	.else
		.if edx==SFR_SBUF
			mov		SBUFWR,eax
			invoke ScreenChar,SBUFWR
		.else
			mov		addin.Sfr[edx],al
			.if edx==SFR_P0 || edx==SFR_P1 || edx==SFR_P2 || edx==SFR_P3
				movzx	eax,addin.Sfr[edx]
				invoke WritePort,edx,eax
			.endif
		.endif
	.endif
	lea		ebx,[ebx+2]
	ret

;------------------------------------------------------------------------------
MOV_DPTR_dw:
	mov		ah,byte ptr [esi+ebx+1]
	mov		al,byte ptr [esi+ebx+2]
	test	addin.Sfr[SFR_AUXR1],1
	.if ZERO?
		mov		word ptr addin.Sfr[SFR_DPL],ax
	.else
		mov		word ptr addin.Sfr[SFR_DP1L],ax
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
		test	addin.Sfr[SFR_PSW],80h
		.if ZERO?
			xor		edx,0FFh
			and		addin.Ram[eax],dl
		.else
			or		addin.Ram[eax],dl
		.endif
	.else
		and		eax,0F8h
		test	addin.Sfr[SFR_PSW],80h
		.if ZERO?
			xor		edx,0FFh
			and		addin.Sfr[eax],dl
		.else
			or		addin.Sfr[eax],dl
		.endif
	.endif
	ret

MOVC_A_@A_DPTR:
	test	addin.Sfr[SFR_AUXR1],1
	.if ZERO?
		movzx	edx,word ptr addin.Sfr[SFR_DPL]
	.else
		movzx	edx,word ptr addin.Sfr[SFR_DP1L]
	.endif
	movzx	eax,addin.Sfr[SFR_ACC]
	lea		edx,[edx+eax]
	movzx	eax,byte ptr [esi+edx]
	mov		addin.Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

SUBB_A_imm:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	movzx	eax,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	sbb		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

SUBB_A_$dad:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	movzx	edx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	.if edx<80h
		movzx	eax,addin.Ram[edx]
	.else
		movzx	eax,addin.Sfr[edx]
	.endif
	sbb		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

SUBB_A_@R0:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	movzx	eax,addin.Ram[eax]
	movzx	eax,addin.Ram[eax]
	sbb		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

SUBB_A_@R1:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	movzx	eax,addin.Ram[eax]
	movzx	eax,addin.Ram[eax]
	sbb		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

SUBB_A_R0:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	movzx	eax,addin.Ram[eax]
	sbb		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

SUBB_A_R1:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	movzx	eax,addin.Ram[eax]
	sbb		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

SUBB_A_R2:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+2]
	movzx	eax,addin.Ram[eax]
	sbb		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

SUBB_A_R3:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+3]
	movzx	eax,addin.Ram[eax]
	sbb		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

SUBB_A_R4:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+4]
	movzx	eax,addin.Ram[eax]
	sbb		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

SUBB_A_R5:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+5]
	movzx	eax,addin.Ram[eax]
	sbb		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

SUBB_A_R6:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+6]
	movzx	eax,addin.Ram[eax]
	sbb		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	lea		ebx,[ebx+1]
	ret

SUBB_A_R7:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+7]
	movzx	eax,addin.Ram[eax]
	sbb		addin.Sfr[SFR_ACC],al
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
		and		dl,addin.Ram[eax]
	.else
		and		eax,0F8h
		and		dl,addin.Sfr[eax]
	.endif
	.if !dl
		or		addin.Sfr[SFR_PSW],80h
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
		and		dl,addin.Ram[eax]
	.else
		and		eax,0F8h
		and		dl,addin.Sfr[eax]
	.endif
	.if dl
		or		addin.Sfr[SFR_PSW],80h
	.else
		and		addin.Sfr[SFR_PSW],7Fh
	.endif
	ret

INC_DPTR:
	movzx	eax,addin.Sfr[SFR_AUXR1]
	and		eax,1
	.if ZERO?
		inc		word ptr addin.Sfr[SFR_DPL]
	.else
		inc		word ptr addin.Sfr[SFR_DP1L]
	.endif
	lea		ebx,[ebx+1]
	ret

MUL_AB:
	mov		al,addin.Sfr[SFR_ACC]
	mov		ah,addin.Sfr[SFR_B]
	mul		ah
	mov		addin.Sfr[SFR_ACC],al
	mov		addin.Sfr[SFR_B],ah
	.if ah
		;Set OV flag
		or		addin.Sfr[SFR_PSW],04h
	.else
		;Clear OV flag
		and		addin.Sfr[SFR_PSW],0FBh
	.endif
	;Clear CY flag
	and		addin.Sfr[SFR_PSW],7Fh
	lea		ebx,[ebx+1]
	ret

reserved:
	;#########
	lea		ebx,[ebx+1]
	ret

MOV_@R0_$dad:
	mov		edx,addin.Bank
	lea		edx,[edx*8+0]
	movzx	edx,addin.Ram[edx]
	movzx	eax,byte ptr [esi+ebx+1]
	.if eax<80h
		movzx	eax,addin.Ram[eax]
	.else
		movzx	eax,addin.Sfr[eax]
	.endif
	mov		addin.Ram[edx],al
	lea		ebx,[ebx+2]
	ret

MOV_@R1_$dad:
	mov		edx,addin.Bank
	lea		edx,[edx*8+1]
	movzx	edx,addin.Ram[edx]
	movzx	eax,byte ptr [esi+ebx+1]
	.if eax<80h
		movzx	eax,addin.Ram[eax]
	.else
		movzx	eax,addin.Sfr[eax]
	.endif
	mov		addin.Ram[edx],al
	lea		ebx,[ebx+2]
	ret

MOV_R0_$dad:
	mov		edx,addin.Bank
	lea		edx,[edx*8+0]
	movzx	eax,byte ptr [esi+ebx+1]
	.if eax<80h
		movzx	eax,addin.Ram[eax]
	.else
		movzx	eax,addin.Sfr[eax]
	.endif
	mov		addin.Ram[edx],al
	lea		ebx,[ebx+2]
	ret

MOV_R1_$dad:
	mov		edx,addin.Bank
	lea		edx,[edx*8+1]
	movzx	eax,byte ptr [esi+ebx+1]
	.if eax<80h
		movzx	eax,addin.Ram[eax]
	.else
		movzx	eax,addin.Sfr[eax]
	.endif
	mov		addin.Ram[edx],al
	lea		ebx,[ebx+2]
	ret

MOV_R2_$dad:
	mov		edx,addin.Bank
	lea		edx,[edx*8+2]
	movzx	eax,byte ptr [esi+ebx+1]
	.if eax<80h
		movzx	eax,addin.Ram[eax]
	.else
		movzx	eax,addin.Sfr[eax]
	.endif
	mov		addin.Ram[edx],al
	lea		ebx,[ebx+2]
	ret

MOV_R3_$dad:
	mov		edx,addin.Bank
	lea		edx,[edx*8+3]
	movzx	eax,byte ptr [esi+ebx+1]
	.if eax<80h
		movzx	eax,addin.Ram[eax]
	.else
		movzx	eax,addin.Sfr[eax]
	.endif
	mov		addin.Ram[edx],al
	lea		ebx,[ebx+2]
	ret

MOV_R4_$dad:
	mov		edx,addin.Bank
	lea		edx,[edx*8+4]
	movzx	eax,byte ptr [esi+ebx+1]
	.if eax<80h
		movzx	eax,addin.Ram[eax]
	.else
		movzx	eax,addin.Sfr[eax]
	.endif
	mov		addin.Ram[edx],al
	lea		ebx,[ebx+2]
	ret

MOV_R5_$dad:
	mov		edx,addin.Bank
	lea		edx,[edx*8+5]
	movzx	eax,byte ptr [esi+ebx+1]
	.if eax<80h
		movzx	eax,addin.Ram[eax]
	.else
		movzx	eax,addin.Sfr[eax]
	.endif
	mov		addin.Ram[edx],al
	lea		ebx,[ebx+2]
	ret

MOV_R6_$dad:
	mov		edx,addin.Bank
	lea		edx,[edx*8+6]
	movzx	eax,byte ptr [esi+ebx+1]
	.if eax<80h
		movzx	eax,addin.Ram[eax]
	.else
		movzx	eax,addin.Sfr[eax]
	.endif
	mov		addin.Ram[edx],al
	lea		ebx,[ebx+2]
	ret

MOV_R7_$dad:
	mov		edx,addin.Bank
	lea		edx,[edx*8+7]
	movzx	eax,byte ptr [esi+ebx+1]
	.if eax<80h
		movzx	eax,addin.Ram[eax]
	.else
		movzx	eax,addin.Sfr[eax]
	.endif
	mov		addin.Ram[edx],al
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
		and		dl,addin.Ram[eax]
	.else
		and		eax,0F8h
		and		dl,addin.Sfr[eax]
	.endif
	.if dl
		and		addin.Sfr[SFR_PSW],7Fh
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
		xor		addin.Ram[eax],dl
	.else
		and		eax,0F8h
		xor		addin.Sfr[eax],dl
	.endif
	ret

CPL_C:
	xor		addin.Sfr[SFR_PSW],80h
	lea		ebx,[ebx+1]
	ret

CJNE_A_imm_$cad:
	movzx	eax,byte ptr [esi+ebx+1]
	movsx	ecx,byte ptr [esi+ebx+2]
	lea		ebx,[ebx+3]
	cmp		addin.Sfr[SFR_ACC],al
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
		movzx	eax,addin.Ram[edx]
	.else
		movzx	eax,addin.Sfr[edx]
	.endif
	cmp		addin.Sfr[SFR_ACC],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	invoke SetFlags
	ret

CJNE_@R0_imm_$cad:
	movzx	eax,byte ptr [esi+ebx+1]
	movsx	ecx,byte ptr [esi+ebx+2]
	lea		ebx,[ebx+3]
	mov		edx,addin.Bank
	lea		edx,[edx*8+0]
	movzx	edx,addin.Ram[edx]
	cmp		addin.Ram[edx],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	invoke SetFlags
	ret

CJNE_@R1_imm_$cad:
	movzx	eax,byte ptr [esi+ebx+1]
	movsx	ecx,byte ptr [esi+ebx+2]
	lea		ebx,[ebx+3]
	mov		edx,addin.Bank
	lea		edx,[edx*8+1]
	movzx	edx,addin.Ram[edx]
	cmp		addin.Ram[edx],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	invoke SetFlags
	ret

CJNE_R0_imm_$cad:
	movzx	eax,byte ptr [esi+ebx+1]
	movsx	ecx,byte ptr [esi+ebx+2]
	lea		ebx,[ebx+3]
	mov		edx,addin.Bank
	lea		edx,[edx*8+0]
	cmp		addin.Ram[edx],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	invoke SetFlags
	ret

CJNE_R1_imm_$cad:
	movzx	eax,byte ptr [esi+ebx+1]
	movsx	ecx,byte ptr [esi+ebx+2]
	lea		ebx,[ebx+3]
	mov		edx,addin.Bank
	lea		edx,[edx*8+1]
	cmp		addin.Ram[edx],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	invoke SetFlags
	ret

CJNE_R2_imm_$cad:
	movzx	eax,byte ptr [esi+ebx+1]
	movsx	ecx,byte ptr [esi+ebx+2]
	lea		ebx,[ebx+3]
	mov		edx,addin.Bank
	lea		edx,[edx*8+2]
	cmp		addin.Ram[edx],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	invoke SetFlags
	ret

CJNE_R3_imm_$cad:
	movzx	eax,byte ptr [esi+ebx+1]
	movsx	ecx,byte ptr [esi+ebx+2]
	lea		ebx,[ebx+3]
	mov		edx,addin.Bank
	lea		edx,[edx*8+3]
	cmp		addin.Ram[edx],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	invoke SetFlags
	ret

CJNE_R4_imm_$cad:
	movzx	eax,byte ptr [esi+ebx+1]
	movsx	ecx,byte ptr [esi+ebx+2]
	lea		ebx,[ebx+3]
	mov		edx,addin.Bank
	lea		edx,[edx*8+4]
	cmp		addin.Ram[edx],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	invoke SetFlags
	ret

CJNE_R5_imm_$cad:
	movzx	eax,byte ptr [esi+ebx+1]
	movsx	ecx,byte ptr [esi+ebx+2]
	lea		ebx,[ebx+3]
	mov		edx,addin.Bank
	lea		edx,[edx*8+5]
	cmp		addin.Ram[edx],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	invoke SetFlags
	ret

CJNE_R6_imm_$cad:
	movzx	eax,byte ptr [esi+ebx+1]
	movsx	ecx,byte ptr [esi+ebx+2]
	lea		ebx,[ebx+3]
	mov		edx,addin.Bank
	lea		edx,[edx*8+6]
	cmp		addin.Ram[edx],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	invoke SetFlags
	ret

CJNE_R7_imm_$cad:
	movzx	eax,byte ptr [esi+ebx+1]
	movsx	ecx,byte ptr [esi+ebx+2]
	lea		ebx,[ebx+3]
	mov		edx,addin.Bank
	lea		edx,[edx*8+7]
	cmp		addin.Ram[edx],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	invoke SetFlags
	ret

;------------------------------------------------------------------------------
PUSH_$dad:
	inc		addin.Sfr[SFR_SP]
	movzx	edx,addin.Sfr[SFR_SP]
	movzx	eax,byte ptr [esi+ebx+1]
	.if eax<80h
		movzx	eax,addin.Ram[eax]
	.else
		movzx	eax,addin.Sfr[eax]
	.endif
	mov		addin.Ram[edx],al
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
		and		addin.Ram[eax],dl
	.else
		and		eax,0F8h
		and		addin.Sfr[eax],dl
		.if eax==SFR_P0 || eax==SFR_P1 || eax==SFR_P2 || eax==SFR_P3
			movzx	edx,addin.Sfr[eax]
			invoke WritePort,eax,edx
		.endif
	.endif
	lea		ebx,[ebx+2]
	ret

CLR_C:
	and		addin.Sfr[SFR_PSW],7Fh
	lea		ebx,[ebx+1]
	ret

SWAP_A:
	movzx	eax,addin.Sfr[SFR_ACC]
	mov		ah,al
	shr		al,4
	shl		ah,4
	or		al,ah
	mov		addin.Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

XCH_A_$dad:
	movzx	edx,byte ptr [esi+ebx+1]
	movzx	eax,addin.Sfr[SFR_ACC]
	.if edx<80h
		xchg	al,addin.Ram[edx]
		mov		addin.Sfr[SFR_ACC],al
	.else
		.if edx==SFR_SBUF
			xchg	eax,SBUFWR
			mov		addin.Sfr[SFR_ACC],al
			invoke ScreenChar,SBUFWR
		.else
			xchg	al,addin.Sfr[edx]
			mov		addin.Sfr[SFR_ACC],al
			.if edx==SFR_P0 || edx==SFR_P1 || edx==SFR_P2 || edx==SFR_P3
				movzx	eax,addin.Sfr[edx]
				invoke WritePort,edx,eax
			.endif
		.endif
	.endif
	lea		ebx,[ebx+2]
	ret

XCH_A_@R0:
	mov		edx,addin.Bank
	lea		edx,[edx*8+0]
	movzx	edx,addin.Ram[edx]
	movzx	eax,addin.Sfr[SFR_ACC]
	xchg	al,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

XCH_A_@R1:
	mov		edx,addin.Bank
	lea		edx,[edx*8+1]
	movzx	edx,addin.Ram[edx]
	movzx	eax,addin.Sfr[SFR_ACC]
	xchg	al,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

XCH_A_R0:
	mov		edx,addin.Bank
	lea		edx,[edx*8+0]
	movzx	eax,addin.Sfr[SFR_ACC]
	xchg	al,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

XCH_A_R1:
	mov		edx,addin.Bank
	lea		edx,[edx*8+1]
	movzx	eax,addin.Sfr[SFR_ACC]
	xchg	al,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

XCH_A_R2:
	mov		edx,addin.Bank
	lea		edx,[edx*8+2]
	movzx	eax,addin.Sfr[SFR_ACC]
	xchg	al,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

XCH_A_R3:
	mov		edx,addin.Bank
	lea		edx,[edx*8+3]
	movzx	eax,addin.Sfr[SFR_ACC]
	xchg	al,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

XCH_A_R4:
	mov		edx,addin.Bank
	lea		edx,[edx*8+4]
	movzx	eax,addin.Sfr[SFR_ACC]
	xchg	al,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

XCH_A_R5:
	mov		edx,addin.Bank
	lea		edx,[edx*8+5]
	movzx	eax,addin.Sfr[SFR_ACC]
	xchg	al,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

XCH_A_R6:
	mov		edx,addin.Bank
	lea		edx,[edx*8+6]
	movzx	eax,addin.Sfr[SFR_ACC]
	xchg	al,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

XCH_A_R7:
	mov		edx,addin.Bank
	lea		edx,[edx*8+7]
	movzx	eax,addin.Sfr[SFR_ACC]
	xchg	al,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

;------------------------------------------------------------------------------
POP_$dad:
	movzx	edx,addin.Sfr[SFR_SP]
	movzx	eax,addin.Ram[edx]
	dec		addin.Sfr[SFR_SP]
	movzx	edx,byte ptr [esi+ebx+1]
	.if edx<80h
		mov		addin.Ram[edx],al
	.else
		.if edx==SFR_SBUF
			mov		SBUFWR,eax
			invoke ScreenChar,SBUFWR
		.else
			mov		addin.Sfr[edx],al
			.if edx==SFR_P0 || edx==SFR_P1 || edx==SFR_P2 || edx==SFR_P3
				movzx	eax,addin.Sfr[edx]
				invoke WritePort,edx,eax
			.endif
		.endif
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
		or		addin.Ram[eax],dl
	.else
		and		eax,0F8h
		or		addin.Sfr[eax],dl
		.if eax==SFR_P0 || eax==SFR_P1 || eax==SFR_P2 || eax==SFR_P3
			movzx	edx,addin.Sfr[eax]
			invoke WritePort,eax,edx
		.endif
	.endif
	lea		ebx,[ebx+2]
	ret

SETB_C:
	or		addin.Sfr[SFR_PSW],80h
	lea		ebx,[ebx+1]
	ret

DA_A:
	movzx	eax,addin.Sfr[SFR_ACC]
	add		eax,0
	daa
	mov		addin.Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

DJNZ_$dad_$cad:
	movzx	edx,byte ptr [esi+ebx+1]
	movsx	ecx,byte ptr [esi+ebx+2]
	lea		ebx,[ebx+3]
	.if edx<80h
		dec		addin.Ram[edx]
	.else
		dec		addin.Sfr[edx]
	.endif
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	ret

XCHD_A_@R0:
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	movzx	edx,addin.Ram[eax]
	movzx	eax,addin.Ram[edx]
	xchg	addin.Sfr[SFR_ACC],al
	mov		addin.Ram[edx],al
	lea		ebx,[ebx+1]
	ret

XCHD_A_@R1:
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	movzx	edx,addin.Ram[eax]
	movzx	eax,addin.Ram[edx]
	xchg	addin.Sfr[SFR_ACC],al
	mov		addin.Ram[edx],al
	lea		ebx,[ebx+1]
	ret

DJNZ_R0_$cad:
	movsx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	dec		addin.Ram[eax]
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	ret

DJNZ_R1_$cad:
	movsx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	dec		addin.Ram[eax]
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	ret

DJNZ_R2_$cad:
	movsx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	mov		eax,addin.Bank
	lea		eax,[eax*8+2]
	dec		addin.Ram[eax]
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	ret

DJNZ_R3_$cad:
	movsx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	mov		eax,addin.Bank
	lea		eax,[eax*8+3]
	dec		addin.Ram[eax]
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	ret

DJNZ_R4_$cad:
	movsx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	mov		eax,addin.Bank
	lea		eax,[eax*8+4]
	dec		addin.Ram[eax]
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	ret

DJNZ_R5_$cad:
	movsx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	mov		eax,addin.Bank
	lea		eax,[eax*8+5]
	dec		addin.Ram[eax]
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	ret

DJNZ_R6_$cad:
	movsx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	mov		eax,addin.Bank
	lea		eax,[eax*8+6]
	dec		addin.Ram[eax]
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	ret

DJNZ_R7_$cad:
	movsx	ecx,byte ptr [esi+ebx+1]
	lea		ebx,[ebx+2]
	mov		eax,addin.Bank
	lea		eax,[eax*8+7]
	dec		addin.Ram[eax]
	.if !ZERO?
		lea		ebx,[ebx+ecx]
	.endif
	ret

;------------------------------------------------------------------------------
MOVX_A_@DPTR:
	movzx	eax,addin.Sfr[SFR_AUXR1]
	and		eax,1
	.if ZERO?
		movzx	edx,word ptr addin.Sfr[SFR_DPL]
	.else
		movzx	edx,word ptr addin.Sfr[SFR_DP1L]
	.endif
	movzx	eax,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

MOVX_A_@R0:
	mov		edx,addin.Bank
	lea		edx,[edx*8+0]
	movzx	edx,addin.Ram[edx]
	mov		dh,addin.Sfr[SFR_P2]
	movzx	eax,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

MOVX_A_@R1:
	mov		edx,addin.Bank
	lea		edx,[edx*8+1]
	movzx	edx,addin.Ram[edx]
	mov		dh,addin.Sfr[SFR_P2]
	movzx	eax,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

CLR_A:
	mov		addin.Sfr[SFR_ACC],0
	lea		ebx,[ebx+1]
	ret

MOV_A_$dad:
	movzx	edx,byte ptr [esi+ebx+1]
	.if edx<80h
		movzx	eax,addin.Ram[edx]
	.else
		movzx	eax,addin.Sfr[edx]
	.endif
	mov		addin.Sfr[SFR_ACC],al
	lea		ebx,[ebx+2]
	ret

MOV_A_@R0:
	mov		edx,addin.Bank
	lea		edx,[edx*8+0]
	movzx	edx,addin.Ram[edx]
	movzx	eax,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

MOV_A_@R1:
	mov		edx,addin.Bank
	lea		edx,[edx*8+1]
	movzx	edx,addin.Ram[edx]
	movzx	eax,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

MOV_A_R0:
	mov		edx,addin.Bank
	lea		edx,[edx*8+0]
	movzx	eax,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

MOV_A_R1:
	mov		edx,addin.Bank
	lea		edx,[edx*8+1]
	movzx	eax,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

MOV_A_R2:
	mov		edx,addin.Bank
	lea		edx,[edx*8+2]
	movzx	eax,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

MOV_A_R3:
	mov		edx,addin.Bank
	lea		edx,[edx*8+3]
	movzx	eax,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

MOV_A_R4:
	mov		edx,addin.Bank
	lea		edx,[edx*8+4]
	movzx	eax,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

MOV_A_R5:
	mov		edx,addin.Bank
	lea		edx,[edx*8+5]
	movzx	eax,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

MOV_A_R6:
	mov		edx,addin.Bank
	lea		edx,[edx*8+6]
	movzx	eax,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

MOV_A_R7:
	mov		edx,addin.Bank
	lea		edx,[edx*8+7]
	movzx	eax,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	lea		ebx,[ebx+1]
	ret

;------------------------------------------------------------------------------
MOVX_@DPTR_A:
	movzx	eax,addin.Sfr[SFR_AUXR1]
	and		eax,1
	.if ZERO?
		movzx	edx,word ptr addin.Sfr[SFR_DPL]
	.else
		movzx	edx,word ptr addin.Sfr[SFR_DP1L]
	.endif
	movzx	eax,addin.Sfr[SFR_ACC]
	invoke WriteXRam,edx,eax
	lea		ebx,[ebx+1]
	ret

MOVX_@R0_A:
	mov		edx,addin.Bank
	lea		edx,[edx*8+0]
	movzx	edx,addin.Ram[edx]
	mov		dh,addin.Sfr[SFR_P2]
	movzx	eax,addin.Sfr[SFR_ACC]
	invoke WriteXRam,edx,eax
	lea		ebx,[ebx+1]
	ret

MOVX_@R1_A:
	mov		edx,addin.Bank
	lea		edx,[edx*8+1]
	movzx	edx,addin.Ram[edx]
	mov		dh,addin.Sfr[SFR_P2]
	movzx	eax,addin.Sfr[SFR_ACC]
	invoke WriteXRam,edx,eax
	lea		ebx,[ebx+1]
	ret

CPL_A:
	xor		addin.Sfr[SFR_ACC],0FFh
	lea		ebx,[ebx+1]
	ret

MOV_$dad_A:
	movzx	edx,byte ptr [esi+ebx+1]
	movzx	eax,addin.Sfr[SFR_ACC]
	.if edx<80h
		mov		addin.Ram[edx],al
	.else
		.if edx==SFR_SBUF
			mov		SBUFWR,eax
			invoke ScreenChar,SBUFWR
		.else
			mov		addin.Sfr[edx],al
			.if edx==SFR_P0 || edx==SFR_P1 || edx==SFR_P2 || edx==SFR_P3
				movzx	eax,addin.Sfr[edx]
				invoke WritePort,edx,eax
			.endif
		.endif
	.endif
	lea		ebx,[ebx+2]
	ret

MOV_@R0_A:
	mov		edx,addin.Bank
	lea		edx,[edx*8+0]
	movzx	edx,addin.Ram[edx]
	movzx	eax,addin.Sfr[SFR_ACC]
	mov		addin.Ram[edx],al
	lea		ebx,[ebx+1]
	ret

MOV_@R1_A:
	mov		edx,addin.Bank
	lea		edx,[edx*8+1]
	movzx	edx,addin.Ram[edx]
	movzx	eax,addin.Sfr[SFR_ACC]
	mov		addin.Ram[edx],al
	lea		ebx,[ebx+1]
	ret

MOV_R0_A:
	movzx	eax,addin.Sfr[SFR_ACC]
	mov		edx,addin.Bank
	lea		edx,[edx*8+0]
	mov		addin.Ram[edx],al
	lea		ebx,[ebx+1]
	ret

MOV_R1_A:
	movzx	eax,addin.Sfr[SFR_ACC]
	mov		edx,addin.Bank
	lea		edx,[edx*8+1]
	mov		addin.Ram[edx],al
	lea		ebx,[ebx+1]
	ret

MOV_R2_A:
	movzx	eax,addin.Sfr[SFR_ACC]
	mov		edx,addin.Bank
	lea		edx,[edx*8+2]
	mov		addin.Ram[edx],al
	lea		ebx,[ebx+1]
	ret

MOV_R3_A:
	movzx	eax,addin.Sfr[SFR_ACC]
	mov		edx,addin.Bank
	lea		edx,[edx*8+3]
	mov		addin.Ram[edx],al
	lea		ebx,[ebx+1]
	ret

MOV_R4_A:
	movzx	eax,addin.Sfr[SFR_ACC]
	mov		edx,addin.Bank
	lea		edx,[edx*8+4]
	mov		addin.Ram[edx],al
	lea		ebx,[ebx+1]
	ret

MOV_R5_A:
	movzx	eax,addin.Sfr[SFR_ACC]
	mov		edx,addin.Bank
	lea		edx,[edx*8+5]
	mov		addin.Ram[edx],al
	lea		ebx,[ebx+1]
	ret

MOV_R6_A:
	movzx	eax,addin.Sfr[SFR_ACC]
	mov		edx,addin.Bank
	lea		edx,[edx*8+6]
	mov		addin.Ram[edx],al
	lea		ebx,[ebx+1]
	ret

MOV_R7_A:
	movzx	eax,addin.Sfr[SFR_ACC]
	mov		edx,addin.Bank
	lea		edx,[edx*8+7]
	mov		addin.Ram[edx],al
	lea		ebx,[ebx+1]
	ret

;------------------------------------------------------------------------------

CoreThread proc lParam:DWORD
	LOCAL	InstCycles:DWORD

	mov		esi,offset addin.Code
	mov		ebx,addin.PC
	mov		InstCycles,0
	.while State!=STATE_STOP
		.if (State & STATE_RUN) && !(State & SIM52_BREAKPOINT)
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
		.else
			mov		eax,hBmpGreenLed
			call	SetStatusLed
		.endif
		mov		eax,InstCycles
		mov		edx,CpuCycles
		mul		edx
		add		dword ptr PerformanceCount,eax
		adc		dword ptr PerformanceCount+4,edx
		.while TRUE
			rdtsc
			sub		eax,dword ptr PerformanceCount
			sbb		edx,dword ptr PerformanceCount+4
			.break .if !CARRY?
		.endw
	.endw
	invoke Reset
	xor		eax,eax
	ret

Execute:
	mov		eax,hBmpRedLed
	call	SetStatusLed
	movzx	eax,byte ptr [esi+ebx]
	push	eax
	call	JmpTab[eax*4]
	pop		eax
	movzx	edx,Cycles[eax]
	mov		InstCycles,edx
	add		TotalCycles,edx
	mov		addin.PC,ebx
	invoke FindMcuAddr,ebx
	.if eax
		.if [eax].MCUADDR.fbp
			or		State,SIM52_BREAKPOINT
		.endif
	.endif
	retn

SetStatusLed:
	.if eax!=StatusLed
		mov		StatusLed,eax
		invoke SendDlgItemMessage,addin.hWnd,IDC_IMGSTATUS,STM_SETIMAGE,IMAGE_BITMAP,eax
	.endif
	retn

CoreThread endp
