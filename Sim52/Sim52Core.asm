
SendAddinMessage		PROTO :HWND,:DWORD,:DWORD,:DWORD

STATE_STOP				equ 0
STATE_RUN				equ 1
STATE_PAUSE				equ 2
STATE_STEP_INTO			equ 4
STATE_STEP_OVER			equ 8
STATE_RUN_TO_CURSOR		equ 16
SIM52_BREAKPOINT		equ 32

STATE_THREAD			equ 128

.data

JmpTab					dd NOP_,AJMP_$cad,LJMP_$cad,RR_A,INC_A,INC_dir,INC_@R0,INC_@R1,INC_R0,INC_R1,INC_R2,INC_R3,INC_R4,INC_R5,INC_R6,INC_R7
						dd JBC_bit_$cad,ACALL_$cad,LCALL_$cad,RRC_A,DEC_A,DEC_dir,DEC_@R0,DEC_@R1,DEC_R0,DEC_R1,DEC_R2,DEC_R3,DEC_R4,DEC_R5,DEC_R6,DEC_R7
						dd JB_bit_$cad,AJMP_$cad,RET_,RL_A,ADD_A_imm,ADD_A_dir,ADD_A_@R0,ADD_A_@R1,ADD_A_R0,ADD_A_R1,ADD_A_R2,ADD_A_R3,ADD_A_R4,ADD_A_R5,ADD_A_R6,ADD_A_R7
						dd JNB_bit_$cad,ACALL_$cad,RETI_,RLC_A,ADDC_A_imm,ADDC_A_dir,ADDC_A_@R0,ADDC_A_@R1,ADDC_A_R0,ADDC_A_R1,ADDC_A_R2,ADDC_A_R3,ADDC_A_R4,ADDC_A_R5,ADDC_A_R6,ADDC_A_R7

						dd JC_$cad,AJMP_$cad,ORL_dir_A,ORL_dir_imm,ORL_A_imm,ORL_A_dir,ORL_A_@R0,ORL_A_@R1,ORL_A_R0,ORL_A_R1,ORL_A_R2,ORL_A_R3,ORL_A_R4,ORL_A_R5,ORL_A_R6,ORL_A_R7
						dd JNC_$cad,ACALL_$cad,ANL_dir_A,ANL_dir_imm,ANL_A_imm,ANL_A_dir,ANL_A_@R0,ANL_A_@R1,ANL_A_R0,ANL_A_R1,ANL_A_R2,ANL_A_R3,ANL_A_R4,ANL_A_R5,ANL_A_R6,ANL_A_R7
						dd JZ_$cad,AJMP_$cad,XRL_dir_A,XRL_dir_imm,XRL_A_imm,XRL_A_dir,XRL_A_@R0,XRL_A_@R1,XRL_A_R0,XRL_A_R1,XRL_A_R2,XRL_A_R3,XRL_A_R4,XRL_A_R5,XRL_A_R6,XRL_A_R7
						dd JNZ_$cad,ACALL_$cad,ORL_C_bit,JMP_@A_DPTR,MOV_A_imm,MOV_dir_imm,MOV_@R0_imm,MOV_@R1_imm,MOV_R0_imm,MOV_R1_imm,MOV_R2_imm,MOV_R3_imm,MOV_R4_imm,MOV_R5_imm,MOV_R6_imm,MOV_R7_imm

						dd SJMP_$cad,AJMP_$cad,ANL_C_bit,MOVC_A_@A_PC,DIV_AB,MOV_dir_dir,MOV_dir_@R0,MOV_dir_@R1,MOV_dir_R0,MOV_dir_R1,MOV_dir_R2,MOV_dir_R3,MOV_dir_R4,MOV_dir_R5,MOV_dir_R6,MOV_dir_R7
						dd MOV_DPTR_dw,ACALL_$cad,MOV_bit_C,MOVC_A_@A_DPTR,SUBB_A_imm,SUBB_A_dir,SUBB_A_@R0,SUBB_A_@R1,SUBB_A_R0,SUBB_A_R1,SUBB_A_R2,SUBB_A_R3,SUBB_A_R4,SUBB_A_R5,SUBB_A_R6,SUBB_A_R7
						dd ORL_C_nbit,AJMP_$cad,MOV_C_bit,INC_DPTR,MUL_AB,reserved,MOV_@R0_dir,MOV_@R1_dir,MOV_R0_dir,MOV_R1_dir,MOV_R2_dir,MOV_R3_dir,MOV_R4_dir,MOV_R5_dir,MOV_R6_dir,MOV_R7_dir
						dd ANL_C_nbit,ACALL_$cad,CPL_bit,CPL_C,CJNE_A_imm_$cad,CJNE_A_dir_$cad,CJNE_@R0_imm_$cad,CJNE_@R1_imm_$cad,CJNE_R0_imm_$cad,CJNE_R1_imm_$cad,CJNE_R2_imm_$cad,CJNE_R3_imm_$cad,CJNE_R4_imm_$cad,CJNE_R5_imm_$cad,CJNE_R6_imm_$cad,CJNE_R7_imm_$cad

						dd PUSH_dir,AJMP_$cad,CLR_bit,CLR_C,SWAP_A,XCH_A_dir,XCH_A_@R0,XCH_A_@R1,XCH_A_R0,XCH_A_R1,XCH_A_R2,XCH_A_R3,XCH_A_R4,XCH_A_R5,XCH_A_R6,XCH_A_R7
						dd POP_dir,ACALL_$cad,SETB_bit,SETB_C,DA_A,DJNZ_dir_$cad,XCHD_A_@R0,XCHD_A_@R1,DJNZ_R0_$cad,DJNZ_R1_$cad,DJNZ_R2_$cad,DJNZ_R3_$cad,DJNZ_R4_$cad,DJNZ_R5_$cad,DJNZ_R6_$cad,DJNZ_R7_$cad
						dd MOVX_A_@DPTR,AJMP_$cad,MOVX_A_@R0,MOVX_A_@R1,CLR_A,MOV_A_dir,MOV_A_@R0,MOV_A_@R1,MOV_A_R0,MOV_A_R1,MOV_A_R2,MOV_A_R3,MOV_A_R4,MOV_A_R5,MOV_A_R6,MOV_A_R7
						dd MOVX_@DPTR_A,ACALL_$cad,MOVX_@R0_A,MOVX_@R1_A,CPL_A,MOV_dir_A,MOV_@R0_A,MOV_@R1_A,MOV_R0_A,MOV_R1_A,MOV_R2_A,MOV_R3_A,MOV_R4_A,MOV_R5_A,MOV_R6_A,MOV_R7_A

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

.code

LoadMCUTypes proc uses ebx esi edi
	LOCAL	buffer[8]:BYTE

	mov		edi,offset szMCUTypes
	xor		ebx,ebx
	.while ebx<16
		invoke wsprintf,addr buffer,addr szFmtDec,ebx
		invoke GetPrivateProfileString,addr szIniMCU,addr buffer,addr szNULL,edi,16,addr szIniFile
		.break .if !eax
		inc		ebx
		lea		edi,[edi+16]
	.endw
	ret

LoadMCUTypes endp

LoadSFRFile proc uses ebx esi edi,lpMCU:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE

	invoke lstrcpy,addr szSfrFile,addr szPath
	invoke lstrcat,addr szSfrFile,lpMCU
	invoke lstrcat,addr szSfrFile,addr szSfrFileExt
	mov		edi,offset addin.SfrData
	mov		ecx,sizeof addin.SfrData
	xor		eax,eax
	rep		stosb
	xor		ebx,ebx
	mov		edi,offset addin.SfrData
	.while TRUE
		invoke wsprintf,addr buffer,addr szFmtDec,ebx
		invoke GetPrivateProfileString,addr szIniSFRMAP,addr buffer,addr szNULL,addr buffer,sizeof buffer,addr szSfrFile
		.break .if !eax
		invoke GetItemHex,addr buffer,0
		mov		[edi].SFRMAP.ad,eax
		invoke GetItemHex,addr buffer,0
		mov		[edi].SFRMAP.rst,eax
		invoke GetItemStr,addr buffer,addr szNULL,addr [edi].SFRMAP.nme,8
		invoke GetItemStr,addr buffer,addr szNULL,addr [edi].SFRMAP.d7,8
		invoke GetItemStr,addr buffer,addr szNULL,addr [edi].SFRMAP.d6,8
		invoke GetItemStr,addr buffer,addr szNULL,addr [edi].SFRMAP.d5,8
		invoke GetItemStr,addr buffer,addr szNULL,addr [edi].SFRMAP.d4,8
		invoke GetItemStr,addr buffer,addr szNULL,addr [edi].SFRMAP.d3,8
		invoke GetItemStr,addr buffer,addr szNULL,addr [edi].SFRMAP.d2,8
		invoke GetItemStr,addr buffer,addr szNULL,addr [edi].SFRMAP.d1,8
		invoke GetItemStr,addr buffer,addr szNULL,addr [edi].SFRMAP.d0,8
		inc		ebx
		lea		edi,[edi+sizeof SFRMAP]
	.endw
	ret

LoadSFRFile endp

Reset proc uses edi

	mov		State,STATE_STOP
	mov		addin.PC,0
	mov		PCDONE,0
	mov		edi,offset addin.Sfr
	mov		ecx,sizeof addin.Sfr
	xor		eax,eax
	rep		stosb
	mov		edi,offset addin.SfrData
	.while [edi].SFRMAP.ad
		mov		edx,[edi].SFRMAP.ad
		mov		eax,[edi].SFRMAP.rst
		mov		addin.Sfr[edx],al
		lea		edi,[edi+sizeof SFRMAP]
	.endw
	invoke SendAddinMessage,addin.hWnd,AM_RESET,0,0
	mov		eax,addin.hBmpGreenLed
	mov		StatusLed,eax
	invoke SendDlgItemMessage,addin.hWnd,IDC_IMGSTATUS,STM_SETIMAGE,IMAGE_BITMAP,StatusLed
	invoke ScreenCls
	mov		addin.Refresh,1
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

	mov		esi,offset addin.SfrData
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
				invoke SendDlgItemMessage,hWin,addr [ebx+ecx],STM_SETIMAGE,IMAGE_BITMAP,addin.hBmpRedLed
			.else
				invoke SendDlgItemMessage,hWin,addr [ebx+ecx],STM_SETIMAGE,IMAGE_BITMAP,addin.hBmpGrayLed
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
	invoke SetDlgItemText,addin.hTabDlgStatus,IDC_EDTPC,addr buffer
	movzx	eax,word ptr addin.Sfr[SFR_DPL]
	invoke wsprintf,addr buffer,addr szFmtHexWord,eax
	invoke SetDlgItemText,addin.hTabDlgStatus,IDC_EDTDPTR,addr buffer
	movzx	eax,word ptr addin.Sfr[SFR_DP1L]
	invoke wsprintf,addr buffer,addr szFmtHexWord,eax
	invoke SetDlgItemText,addin.hTabDlgStatus,IDC_EDTDPTR1,addr buffer
	movzx	eax,addin.Sfr[SFR_ACC]
	invoke wsprintf,addr buffer,addr szFmtHexByte,eax
	invoke SetDlgItemText,addin.hTabDlgStatus,IDC_EDTACC,addr buffer
	movzx	eax,addin.Sfr[SFR_B]
	invoke wsprintf,addr buffer,addr szFmtHexByte,eax
	invoke SetDlgItemText,addin.hTabDlgStatus,IDC_EDTB,addr buffer
	movzx	eax,addin.Sfr[SFR_SP]
	invoke wsprintf,addr buffer,addr szFmtHexByte,eax
	invoke SetDlgItemText,addin.hTabDlgStatus,IDC_EDTSP,addr buffer
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
			invoke SendDlgItemMessage,addin.hTabDlgStatus,eax,STM_SETIMAGE,IMAGE_BITMAP,addin.hBmpRedLed
		.else
			invoke SendDlgItemMessage,addin.hTabDlgStatus,eax,STM_SETIMAGE,IMAGE_BITMAP,addin.hBmpGrayLed
		.endif
		pop		eax
	.endw
	invoke FindMcuAddr,PCDONE
	.if eax
		movzx	eax,[eax].MCUADDR.lbinx
		invoke SendMessage,addin.hGrd,GM_SETCURROW,eax,0
	.endif
	invoke SetDlgItemInt,addin.hTabDlgStatus,IDC_STCCYCLES,TotalCycles,FALSE
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
			invoke SendDlgItemMessage,addin.hTabDlgStatus,eax,STM_SETIMAGE,IMAGE_BITMAP,addin.hBmpGreenLed
		.else
			invoke SendDlgItemMessage,addin.hTabDlgStatus,eax,STM_SETIMAGE,IMAGE_BITMAP,addin.hBmpGrayLed
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
			invoke SendDlgItemMessage,addin.hTabDlgStatus,eax,STM_SETIMAGE,IMAGE_BITMAP,addin.hBmpGreenLed
		.else
			invoke SendDlgItemMessage,addin.hTabDlgStatus,eax,STM_SETIMAGE,IMAGE_BITMAP,addin.hBmpGrayLed
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
			invoke SendDlgItemMessage,addin.hTabDlgStatus,eax,STM_SETIMAGE,IMAGE_BITMAP,addin.hBmpGreenLed
		.else
			invoke SendDlgItemMessage,addin.hTabDlgStatus,eax,STM_SETIMAGE,IMAGE_BITMAP,addin.hBmpGrayLed
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
			invoke SendDlgItemMessage,addin.hTabDlgStatus,eax,STM_SETIMAGE,IMAGE_BITMAP,addin.hBmpGreenLed
		.else
			invoke SendDlgItemMessage,addin.hTabDlgStatus,eax,STM_SETIMAGE,IMAGE_BITMAP,addin.hBmpGrayLed
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
		invoke SetDlgItemText,addin.hTabDlgStatus,ebx,addr buffer
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
				invoke SendDlgItemMessage,addin.hTabDlg[4],edi,STM_SETIMAGE,IMAGE_BITMAP,addin.hBmpRedLed
			.else
				invoke SendDlgItemMessage,addin.hTabDlg[4],edi,STM_SETIMAGE,IMAGE_BITMAP,addin.hBmpGrayLed
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
		invoke SendMessage,addin.hGrd,GM_SETCELLDATA,ecx,addr dwbp
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
				invoke SendMessage,addin.hGrd,GM_SETCELLDATA,edx,addr dwbp
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
	invoke SendAddinMessage,addin.hWnd,AM_PORTWRITE,eax,nValue
	ret

WritePort endp

WaitHalfCycle proc

	push	eax
	push	edx
	mov		eax,CpuCycles
	add		dword ptr PerformanceCount,eax
	adc		dword ptr PerformanceCount+4,0
	.while TRUE
		rdtsc
		sub		eax,dword ptr PerformanceCount
		sbb		edx,dword ptr PerformanceCount+4
		.break .if !CARRY?
	.endw
	pop		edx
	pop		eax
	ret

WaitHalfCycle endp

ReadXRam proc uses ebx,nAddr:DWORD

	movzx	ebx,addin.Sfr[SFR_P3]
	mov		eax,ebx
	and		eax,7Fh
	mov		addin.Sfr[SFR_P3],al
	;Set RD low
	invoke WritePort,addr addin.Sfr[SFR_P3],eax
	invoke SendAddinMessage,addin.hWnd,AM_XRAMREAD,nAddr,0
	mov		edx,nAddr
	movzx	eax,addin.XRam[edx]
	push	eax
	invoke WaitHalfCycle
	mov		addin.Sfr[SFR_P3],bl
	;Set RD high
	invoke WritePort,addr addin.Sfr[SFR_P3],ebx
	pop		eax
	ret

ReadXRam endp

WriteXRam proc uses ebx esi edi,nAddr:DWORD,nValue:DWORD

	movzx	ebx,addin.Sfr[SFR_P3]
	mov		eax,ebx
	and		eax,0BFh
	mov		addin.Sfr[SFR_P3],al
	;Set WR low
	invoke WritePort,addr addin.Sfr[SFR_P3],eax
	xor		edi,edi
	xor		esi,esi
	.while edi<4
		mov		eax,nAddr
		.if eax==addin.mmoutport[edi*4]
			;There is a memory mapped output at this address, update port
			mov		edx,nValue
			mov		addin.mmoutportdata[edi*4],edx
			;invoke SendAddinMessage,addin.hWnd,AM_MMOWRITE,nAddr,nValue
			lea		esi,[esi+1]
		.endif
		lea		edi,[edi+1]
	.endw
	.if !esi
		;No memory mapped output at this address, update XRam
		mov		edx,nAddr
		mov		eax,nValue
		mov		addin.XRam[edx],al
	.endif
	invoke WaitHalfCycle
	mov		addin.Sfr[SFR_P3],bl
	;Set WR high
	invoke WritePort,addr addin.Sfr[SFR_P3],ebx
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
	ret

AJMP_$cad:
	mov		ah,dl
	xchg	al,ah
	shr		ah,5
	and		ebx,0F800h
	lea		ebx,[ebx+eax]
	mov		addin.PC,ebx
	ret

LJMP_$cad:
	mov		ebx,edx
	xchg	bl,bh
	mov		addin.PC,ebx
	ret

RR_A:
	ror		addin.Sfr[SFR_ACC],1
	ret

INC_A:
	inc		addin.Sfr[SFR_ACC]
	invoke SetParity
	ret

INC_dir:
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
	ret

INC_@R0:
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	movzx	eax,addin.Ram[eax]
	inc		addin.Ram[eax]
	ret

INC_@R1:
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	movzx	eax,addin.Ram[eax]
	inc		addin.Ram[eax]
	ret

INC_R0:
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	inc		addin.Ram[eax]
	ret

INC_R1:
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	inc		addin.Ram[eax]
	ret

INC_R2:
	mov		eax,addin.Bank
	lea		eax,[eax*8+2]
	inc		addin.Ram[eax]
	ret

INC_R3:
	mov		eax,addin.Bank
	lea		eax,[eax*8+3]
	inc		addin.Ram[eax]
	ret

INC_R4:
	mov		eax,addin.Bank
	lea		eax,[eax*8+4]
	inc		addin.Ram[eax]
	ret

INC_R5:
	mov		eax,addin.Bank
	lea		eax,[eax*8+5]
	inc		addin.Ram[eax]
	ret

INC_R6:
	mov		eax,addin.Bank
	lea		eax,[eax*8+6]
	inc		addin.Ram[eax]
	ret

INC_R7:
	mov		eax,addin.Bank
	lea		eax,[eax*8+7]
	inc		addin.Ram[eax]
	ret

;------------------------------------------------------------------------------
JBC_bit_$cad:
	movzx	ecx,dx
	movzx	eax,cl
	and		cl,07h
	mov		edx,1
	shl		edx,cl
	.if al<80h
		shr		eax,3
		lea		eax,[eax+20h]
		test	addin.Ram[eax],dl
		.if !ZERO?
			xor		addin.Ram[eax],dl
			movsx	ecx,ch
			lea		ebx,[ebx+ecx]
			mov		addin.PC,ebx
		.endif
	.else
		and		eax,0F8h
		test	addin.Sfr[eax],dl
		.if !ZERO?
			xor		addin.Sfr[eax],dl
			movsx	ecx,ch
			lea		ebx,[ebx+ecx]
			mov		addin.PC,ebx
		.endif
	.endif
	ret

ACALL_$cad:
	mov		ah,dl
	xchg	al,ah
	movzx	edx,addin.Sfr[SFR_SP]
	inc		dl
	mov		addin.Ram[edx],bl
	inc		dl
	mov		addin.Ram[edx],bh
	mov		addin.Sfr[SFR_SP],dl
	shr		ah,5
	and		ebx,0F800h
	lea		ebx,[ebx+eax]
	mov		addin.PC,ebx
	ret

LCALL_$cad:
	mov		eax,edx
	xchg	al,ah
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
	ret

DEC_A:
	dec		addin.Sfr[SFR_ACC]
	invoke SetParity
	ret

DEC_dir:
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
	ret

DEC_@R0:
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	movzx	eax,addin.Ram[eax]
	dec		addin.Ram[eax]
	ret

DEC_@R1:
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	movzx	eax,addin.Ram[eax]
	dec		addin.Ram[eax]
	ret

DEC_R0:
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	dec		addin.Ram[eax]
	ret

DEC_R1:
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	dec		addin.Ram[eax]
	ret

DEC_R2:
	mov		eax,addin.Bank
	lea		eax,[eax*8+2]
	dec		addin.Ram[eax]
	ret

DEC_R3:
	mov		eax,addin.Bank
	lea		eax,[eax*8+3]
	dec		addin.Ram[eax]
	ret

DEC_R4:
	mov		eax,addin.Bank
	lea		eax,[eax*8+4]
	dec		addin.Ram[eax]
	ret

DEC_R5:
	mov		eax,addin.Bank
	lea		eax,[eax*8+5]
	dec		addin.Ram[eax]
	ret

DEC_R6:
	mov		eax,addin.Bank
	lea		eax,[eax*8+6]
	dec		addin.Ram[eax]
	ret

DEC_R7:
	mov		eax,addin.Bank
	lea		eax,[eax*8+7]
	dec		addin.Ram[eax]
	ret

;------------------------------------------------------------------------------
JB_bit_$cad:
	mov		ecx,edx
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
		mov		addin.PC,ebx
	.endif
	ret

RET_:
	movzx	edx,addin.Sfr[SFR_SP]
	mov		bh,addin.Ram[edx]
	dec		dl
	mov		bl,addin.Ram[edx]
	dec		dl
	mov		addin.Sfr[SFR_SP],dl
	mov		addin.PC,ebx
	ret

RL_A:
	rol		addin.Sfr[SFR_ACC],1
	ret

ADD_A_imm:
	add		addin.Sfr[SFR_ACC],dl
	invoke SetFlags
	ret

ADD_A_dir:
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
	ret

ADD_A_@R1:
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	movzx	eax,addin.Ram[eax]
	movzx	eax,addin.Ram[eax]
	add		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ADD_A_R0:
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	movzx	eax,addin.Ram[eax]
	add		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ADD_A_R1:
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	movzx	eax,addin.Ram[eax]
	add		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ADD_A_R2:
	mov		eax,addin.Bank
	lea		eax,[eax*8+2]
	movzx	eax,addin.Ram[eax]
	add		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ADD_A_R3:
	mov		eax,addin.Bank
	lea		eax,[eax*8+3]
	movzx	eax,addin.Ram[eax]
	add		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ADD_A_R4:
	mov		eax,addin.Bank
	lea		eax,[eax*8+4]
	movzx	eax,addin.Ram[eax]
	add		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ADD_A_R5:
	mov		eax,addin.Bank
	lea		eax,[eax*8+5]
	movzx	eax,addin.Ram[eax]
	add		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ADD_A_R6:
	mov		eax,addin.Bank
	lea		eax,[eax*8+6]
	movzx	eax,addin.Ram[eax]
	add		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ADD_A_R7:
	mov		eax,addin.Bank
	lea		eax,[eax*8+7]
	movzx	eax,addin.Ram[eax]
	add		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

;------------------------------------------------------------------------------
JNB_bit_$cad:
	mov		ecx,edx
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
		mov		addin.PC,ebx
	.endif
	ret

RETI_:
	movzx	edx,addin.Sfr[SFR_SP]
	mov		bh,addin.Ram[edx]
	dec		dl
	mov		bl,addin.Ram[edx]
	dec		dl
	mov		addin.Sfr[SFR_SP],dl
	mov		addin.PC,ebx
	ret

RLC_A:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	rcl		addin.Sfr[SFR_ACC],1
	ret

ADDC_A_imm:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,edx
	adc		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ADDC_A_dir:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
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
	ret

ADDC_A_R0:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	movzx	eax,addin.Ram[eax]
	adc		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ADDC_A_R1:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	movzx	eax,addin.Ram[eax]
	adc		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ADDC_A_R2:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+2]
	movzx	eax,addin.Ram[eax]
	adc		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ADDC_A_R3:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+3]
	movzx	eax,addin.Ram[eax]
	adc		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ADDC_A_R4:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+4]
	movzx	eax,addin.Ram[eax]
	adc		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ADDC_A_R5:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+5]
	movzx	eax,addin.Ram[eax]
	adc		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ADDC_A_R6:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+6]
	movzx	eax,addin.Ram[eax]
	adc		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ADDC_A_R7:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+7]
	movzx	eax,addin.Ram[eax]
	adc		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

;------------------------------------------------------------------------------
JC_$cad:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	.if CARRY?
		movsx	edx,dl
		lea		ebx,[ebx+edx]
		mov		addin.PC,ebx
	.endif
	ret

ORL_dir_A:
	movzx	eax,addin.Sfr[SFR_ACC]
	or		addin.Ram[edx],al
	invoke SetFlags
	ret

ORL_dir_imm:
	movzx	eax,dh
	movzx	edx,dl
	or		addin.Ram[edx],al
	invoke SetFlags
	ret

ORL_A_imm:
	or		addin.Sfr[SFR_ACC],dl
	invoke SetFlags
	ret

ORL_A_dir:
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
	ret

ORL_A_@R1:
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	movzx	eax,addin.Ram[eax]
	movzx	eax,addin.Ram[eax]
	or		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ORL_A_R0:
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	movzx	eax,addin.Ram[eax]
	or		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ORL_A_R1:
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	movzx	eax,addin.Ram[eax]
	or		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ORL_A_R2:
	mov		eax,addin.Bank
	lea		eax,[eax*8+2]
	movzx	eax,addin.Ram[eax]
	or		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ORL_A_R3:
	mov		eax,addin.Bank
	lea		eax,[eax*8+3]
	movzx	eax,addin.Ram[eax]
	or		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ORL_A_R4:
	mov		eax,addin.Bank
	lea		eax,[eax*8+4]
	movzx	eax,addin.Ram[eax]
	or		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ORL_A_R5:
	mov		eax,addin.Bank
	lea		eax,[eax*8+5]
	movzx	eax,addin.Ram[eax]
	or		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ORL_A_R6:
	mov		eax,addin.Bank
	lea		eax,[eax*8+6]
	movzx	eax,addin.Ram[eax]
	or		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ORL_A_R7:
	mov		eax,addin.Bank
	lea		eax,[eax*8+7]
	movzx	eax,addin.Ram[eax]
	or		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

;------------------------------------------------------------------------------
JNC_$cad:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	.if !CARRY?
		movsx	edx,dl
		lea		ebx,[ebx+edx]
		mov		addin.PC,ebx
	.endif
	ret

ANL_dir_A:
	movzx	eax,addin.Sfr[SFR_ACC]
	and		addin.Ram[edx],al
	invoke SetFlags
	ret

ANL_dir_imm:
	movzx	eax,dh
	movzx	edx,dl
	and		addin.Ram[edx],al
	invoke SetFlags
	ret

ANL_A_imm:
	and		addin.Sfr[SFR_ACC],dl
	invoke SetFlags
	ret

ANL_A_dir:
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
	ret

ANL_A_@R1:
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	movzx	eax,addin.Ram[eax]
	movzx	eax,addin.Ram[eax]
	and		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ANL_A_R0:
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	movzx	eax,addin.Ram[eax]
	and		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ANL_A_R1:
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	movzx	eax,addin.Ram[eax]
	and		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ANL_A_R2:
	mov		eax,addin.Bank
	lea		eax,[eax*8+2]
	movzx	eax,addin.Ram[eax]
	and		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ANL_A_R3:
	mov		eax,addin.Bank
	lea		eax,[eax*8+3]
	movzx	eax,addin.Ram[eax]
	and		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ANL_A_R4:
	mov		eax,addin.Bank
	lea		eax,[eax*8+4]
	movzx	eax,addin.Ram[eax]
	and		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ANL_A_R5:
	mov		eax,addin.Bank
	lea		eax,[eax*8+5]
	movzx	eax,addin.Ram[eax]
	and		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ANL_A_R6:
	mov		eax,addin.Bank
	lea		eax,[eax*8+6]
	movzx	eax,addin.Ram[eax]
	and		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

ANL_A_R7:
	mov		eax,addin.Bank
	lea		eax,[eax*8+7]
	movzx	eax,addin.Ram[eax]
	and		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

;------------------------------------------------------------------------------
JZ_$cad:
	movzx	eax,addin.Sfr[SFR_ACC]
	or		eax,eax
	.if ZERO?
		movsx	edx,dl
		lea		ebx,[ebx+edx]
		mov		addin.PC,ebx
	.endif
	ret

XRL_dir_A:
	movzx	eax,addin.Sfr[SFR_ACC]
	xor		addin.Ram[edx],al
	invoke SetFlags
	ret

XRL_dir_imm:
	movzx	eax,dh
	movzx	edx,dl
	xor		addin.Ram[edx],al
	invoke SetFlags
	ret

XRL_A_imm:
	xor		addin.Sfr[SFR_ACC],dl
	invoke SetFlags
	ret

XRL_A_dir:
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
	ret

XRL_A_@R1:
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	movzx	eax,addin.Ram[eax]
	movzx	eax,addin.Ram[eax]
	xor		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

XRL_A_R0:
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	movzx	eax,addin.Ram[eax]
	xor		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

XRL_A_R1:
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	movzx	eax,addin.Ram[eax]
	xor		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

XRL_A_R2:
	mov		eax,addin.Bank
	lea		eax,[eax*8+2]
	movzx	eax,addin.Ram[eax]
	xor		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

XRL_A_R3:
	mov		eax,addin.Bank
	lea		eax,[eax*8+3]
	movzx	eax,addin.Ram[eax]
	xor		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

XRL_A_R4:
	mov		eax,addin.Bank
	lea		eax,[eax*8+4]
	movzx	eax,addin.Ram[eax]
	xor		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

XRL_A_R5:
	mov		eax,addin.Bank
	lea		eax,[eax*8+5]
	movzx	eax,addin.Ram[eax]
	xor		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

XRL_A_R6:
	mov		eax,addin.Bank
	lea		eax,[eax*8+6]
	movzx	eax,addin.Ram[eax]
	xor		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

XRL_A_R7:
	mov		eax,addin.Bank
	lea		eax,[eax*8+7]
	movzx	eax,addin.Ram[eax]
	xor		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

;------------------------------------------------------------------------------
JNZ_$cad:
	movzx	eax,addin.Sfr[SFR_ACC]
	or		eax,eax
	.if !ZERO?
		movsx	edx,dl
		lea		ebx,[ebx+edx]
		mov		addin.PC,ebx
	.endif
	ret

ORL_C_bit:
	mov		ecx,edx
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
	mov		addin.PC,ebx
	ret

MOV_A_imm:
	mov		addin.Sfr[SFR_ACC],dl
	ret

MOV_dir_imm:
	movzx	eax,dh
	movzx	edx,dl
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
	ret
	
MOV_@R0_imm:
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	movzx	ecx,addin.Ram[eax]
	mov		addin.Ram[ecx],dl
	ret

MOV_@R1_imm:
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	movzx	ecx,addin.Ram[eax]
	mov		addin.Ram[edx],dl
	ret

MOV_R0_imm:
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	mov		addin.Ram[eax],dl
	ret

MOV_R1_imm:
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	mov		addin.Ram[eax],dl
	ret

MOV_R2_imm:
	mov		eax,addin.Bank
	lea		eax,[eax*8+2]
	mov		addin.Ram[eax],dl
	ret

MOV_R3_imm:
	mov		eax,addin.Bank
	lea		eax,[eax*8+3]
	mov		addin.Ram[eax],dl
	ret

MOV_R4_imm:
	mov		eax,addin.Bank
	lea		eax,[eax*8+4]
	mov		addin.Ram[eax],dl
	ret

MOV_R5_imm:
	mov		eax,addin.Bank
	lea		eax,[eax*8+5]
	mov		addin.Ram[eax],dl
	ret

MOV_R6_imm:
	mov		eax,addin.Bank
	lea		eax,[eax*8+6]
	mov		addin.Ram[eax],dl
	ret

MOV_R7_imm:
	mov		eax,addin.Bank
	lea		eax,[eax*8+7]
	mov		addin.Ram[eax],dl
	ret

;------------------------------------------------------------------------------
SJMP_$cad:
	movsx	edx,dl
	lea		ebx,[ebx+edx]
	mov		addin.PC,ebx
	ret

ANL_C_bit:
	mov		ecx,edx
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
	ret

MOV_dir_dir:
	movzx	ecx,dh
	.if ecx<80h
		movzx	eax,addin.Ram[ecx]
	.else
		movzx	eax,addin.Sfr[ecx]
	.endif
	movzx	edx,dl
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
	ret

MOV_dir_@R0:
	mov		ecx,addin.Bank
	lea		ecx,[ecx*8+0]
	movzx	ecx,addin.Ram[ecx]
	movzx	eax,addin.Ram[ecx]
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
	ret

MOV_dir_@R1:
	mov		ecx,addin.Bank
	lea		ecx,[ecx*8+1]
	movzx	ecx,addin.Ram[ecx]
	movzx	eax,addin.Ram[ecx]
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
	ret

MOV_dir_R0:
	mov		ecx,addin.Bank
	lea		ecx,[ecx*8+0]
	movzx	eax,addin.Ram[ecx]
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
	ret

MOV_dir_R1:
	mov		ecx,addin.Bank
	lea		ecx,[ecx*8+1]
	movzx	eax,addin.Ram[ecx]
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
	ret

MOV_dir_R2:
	mov		ecx,addin.Bank
	lea		ecx,[ecx*8+2]
	movzx	eax,addin.Ram[ecx]
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
	ret

MOV_dir_R3:
	mov		ecx,addin.Bank
	lea		ecx,[ecx*8+3]
	movzx	eax,addin.Ram[ecx]
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
	ret

MOV_dir_R4:
	mov		ecx,addin.Bank
	lea		ecx,[ecx*8+4]
	movzx	eax,addin.Ram[ecx]
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
	ret

MOV_dir_R5:
	mov		ecx,addin.Bank
	lea		ecx,[ecx*8+5]
	movzx	eax,addin.Ram[ecx]
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
	ret

MOV_dir_R6:
	mov		ecx,addin.Bank
	lea		ecx,[ecx*8+6]
	movzx	eax,addin.Ram[ecx]
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
	ret

MOV_dir_R7:
	mov		ecx,addin.Bank
	lea		ecx,[ecx*8+7]
	movzx	eax,addin.Ram[ecx]
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
	ret

;------------------------------------------------------------------------------
MOV_DPTR_dw:
	xchg	dl,dh
	test	addin.Sfr[SFR_AUXR1],1
	.if ZERO?
		mov		word ptr addin.Sfr[SFR_DPL],dx
	.else
		mov		word ptr addin.Sfr[SFR_DP1L],dx
	.endif
	ret

MOV_bit_C:
	mov		ecx,edx
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
		.if eax==SFR_SBUF
			test	addin.Sfr[SFR_PSW],80h
			.if ZERO?
				xor		edx,0FFh
				and		SBUFWR,edx
			.else
				or		SBUFWR,edx
			.endif
			invoke ScreenChar,SBUFWR
		.else
			test	addin.Sfr[SFR_PSW],80h
			.if ZERO?
				xor		edx,0FFh
				and		addin.Sfr[eax],dl
			.else
				or		addin.Sfr[eax],dl
			.endif
			.if eax==SFR_P0 || eax==SFR_P1 || eax==SFR_P2 || eax==SFR_P3
				movzx	edx,addin.Sfr[eax]
				invoke WritePort,eax,edx
			.endif
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
	ret

SUBB_A_imm:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	sbb		addin.Sfr[SFR_ACC],dl
	invoke SetFlags
	ret

SUBB_A_dir:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
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
	ret

SUBB_A_R0:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	movzx	eax,addin.Ram[eax]
	sbb		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

SUBB_A_R1:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	movzx	eax,addin.Ram[eax]
	sbb		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

SUBB_A_R2:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+2]
	movzx	eax,addin.Ram[eax]
	sbb		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

SUBB_A_R3:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+3]
	movzx	eax,addin.Ram[eax]
	sbb		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

SUBB_A_R4:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+4]
	movzx	eax,addin.Ram[eax]
	sbb		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

SUBB_A_R5:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+5]
	movzx	eax,addin.Ram[eax]
	sbb		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

SUBB_A_R6:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+6]
	movzx	eax,addin.Ram[eax]
	sbb		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

SUBB_A_R7:
	movzx	eax,addin.Sfr[SFR_PSW]
	rcl		al,1
	mov		eax,addin.Bank
	lea		eax,[eax*8+7]
	movzx	eax,addin.Ram[eax]
	sbb		addin.Sfr[SFR_ACC],al
	invoke SetFlags
	ret

;------------------------------------------------------------------------------
ORL_C_nbit:
	mov		ecx,edx
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

MOV_C_bit:
	mov		ecx,edx
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
	ret

reserved:
	;#########
	ret

MOV_@R0_dir:
	mov		ecx,addin.Bank
	lea		ecx,[ecx*8+0]
	movzx	ecx,addin.Ram[ecx]
	.if ecx<80h
		movzx	eax,addin.Ram[edx]
	.else
		movzx	eax,addin.Sfr[edx]
	.endif
	mov		addin.Ram[ecx],al
	ret

MOV_@R1_dir:
	mov		ecx,addin.Bank
	lea		ecx,[ecx*8+1]
	movzx	ecx,addin.Ram[ecx]
	.if edx<80h
		movzx	eax,addin.Ram[edx]
	.else
		movzx	eax,addin.Sfr[edx]
	.endif
	mov		addin.Ram[ecx],al
	ret

MOV_R0_dir:
	mov		ecx,addin.Bank
	lea		ecx,[ecx*8+0]
	.if edx<80h
		movzx	eax,addin.Ram[edx]
	.else
		movzx	eax,addin.Sfr[edx]
	.endif
	mov		addin.Ram[ecx],al
	ret

MOV_R1_dir:
	mov		ecx,addin.Bank
	lea		ecx,[ecx*8+1]
	.if edx<80h
		movzx	eax,addin.Ram[edx]
	.else
		movzx	eax,addin.Sfr[edx]
	.endif
	mov		addin.Ram[ecx],al
	ret

MOV_R2_dir:
	mov		ecx,addin.Bank
	lea		ecx,[ecx*8+2]
	.if edx<80h
		movzx	eax,addin.Ram[edx]
	.else
		movzx	eax,addin.Sfr[edx]
	.endif
	mov		addin.Ram[ecx],al
	ret

MOV_R3_dir:
	mov		ecx,addin.Bank
	lea		ecx,[ecx*8+3]
	.if edx<80h
		movzx	eax,addin.Ram[edx]
	.else
		movzx	eax,addin.Sfr[edx]
	.endif
	mov		addin.Ram[ecx],al
	ret

MOV_R4_dir:
	mov		ecx,addin.Bank
	lea		ecx,[ecx*8+4]
	.if edx<80h
		movzx	eax,addin.Ram[edx]
	.else
		movzx	eax,addin.Sfr[edx]
	.endif
	mov		addin.Ram[ecx],al
	ret

MOV_R5_dir:
	mov		ecx,addin.Bank
	lea		ecx,[ecx*8+5]
	.if edx<80h
		movzx	eax,addin.Ram[edx]
	.else
		movzx	eax,addin.Sfr[edx]
	.endif
	mov		addin.Ram[ecx],al
	ret

MOV_R6_dir:
	mov		ecx,addin.Bank
	lea		ecx,[ecx*8+6]
	.if edx<80h
		movzx	eax,addin.Ram[edx]
	.else
		movzx	eax,addin.Sfr[edx]
	.endif
	mov		addin.Ram[ecx],al
	ret

MOV_R7_dir:
	mov		ecx,addin.Bank
	lea		ecx,[ecx*8+7]
	.if edx<80h
		movzx	eax,addin.Ram[edx]
	.else
		movzx	eax,addin.Sfr[edx]
	.endif
	mov		addin.Ram[ecx],al
	ret

;------------------------------------------------------------------------------
ANL_C_nbit:
	mov		ecx,edx
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

CPL_bit:
	mov		ecx,edx
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
	ret

CJNE_A_imm_$cad:
	movsx	ecx,dh
	cmp		addin.Sfr[SFR_ACC],dl
	.if !ZERO?
		lea		ebx,[ebx+ecx]
		mov		addin.PC,ebx
	.endif
	invoke SetFlags
	ret

CJNE_A_dir_$cad:
	movsx	ecx,dh
	movzx	edx,dl
	.if edx<80h
		movzx	eax,addin.Ram[edx]
	.else
		movzx	eax,addin.Sfr[edx]
	.endif
	cmp		addin.Sfr[SFR_ACC],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
		mov		addin.PC,ebx
	.endif
	invoke SetFlags
	ret

CJNE_@R0_imm_$cad:
	movsx	ecx,dh
	movzx	eax,dl
	mov		edx,addin.Bank
	lea		edx,[edx*8+0]
	movzx	edx,addin.Ram[edx]
	cmp		addin.Ram[edx],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
		mov		addin.PC,ebx
	.endif
	invoke SetFlags
	ret

CJNE_@R1_imm_$cad:
	movsx	ecx,dh
	movzx	eax,dl
	mov		edx,addin.Bank
	lea		edx,[edx*8+1]
	movzx	edx,addin.Ram[edx]
	cmp		addin.Ram[edx],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
		mov		addin.PC,ebx
	.endif
	invoke SetFlags
	ret

CJNE_R0_imm_$cad:
	movzx	eax,dl
	movsx	ecx,dh
	mov		edx,addin.Bank
	lea		edx,[edx*8+0]
	cmp		addin.Ram[edx],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
		mov		addin.PC,ebx
	.endif
	invoke SetFlags
	ret

CJNE_R1_imm_$cad:
	movzx	eax,dl
	movsx	ecx,dh
	mov		edx,addin.Bank
	lea		edx,[edx*8+1]
	cmp		addin.Ram[edx],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
		mov		addin.PC,ebx
	.endif
	invoke SetFlags
	ret

CJNE_R2_imm_$cad:
	movzx	eax,dl
	movsx	ecx,dh
	mov		edx,addin.Bank
	lea		edx,[edx*8+2]
	cmp		addin.Ram[edx],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
		mov		addin.PC,ebx
	.endif
	invoke SetFlags
	ret

CJNE_R3_imm_$cad:
	movzx	eax,dl
	movsx	ecx,dh
	mov		edx,addin.Bank
	lea		edx,[edx*8+3]
	cmp		addin.Ram[edx],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
		mov		addin.PC,ebx
	.endif
	invoke SetFlags
	ret

CJNE_R4_imm_$cad:
	movzx	eax,dl
	movsx	ecx,dh
	mov		edx,addin.Bank
	lea		edx,[edx*8+4]
	cmp		addin.Ram[edx],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
		mov		addin.PC,ebx
	.endif
	invoke SetFlags
	ret

CJNE_R5_imm_$cad:
	movzx	eax,dl
	movsx	ecx,dh
	mov		edx,addin.Bank
	lea		edx,[edx*8+5]
	cmp		addin.Ram[edx],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
		mov		addin.PC,ebx
	.endif
	invoke SetFlags
	ret

CJNE_R6_imm_$cad:
	movzx	eax,dl
	movsx	ecx,dh
	mov		edx,addin.Bank
	lea		edx,[edx*8+6]
	cmp		addin.Ram[edx],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
		mov		addin.PC,ebx
	.endif
	invoke SetFlags
	ret

CJNE_R7_imm_$cad:
	movzx	eax,dl
	movsx	ecx,dh
	mov		edx,addin.Bank
	lea		edx,[edx*8+7]
	cmp		addin.Ram[edx],al
	.if !ZERO?
		lea		ebx,[ebx+ecx]
		mov		addin.PC,ebx
	.endif
	invoke SetFlags
	ret

;------------------------------------------------------------------------------
PUSH_dir:
	inc		addin.Sfr[SFR_SP]
	movzx	ecx,addin.Sfr[SFR_SP]
	.if edx<80h
		movzx	eax,addin.Ram[edx]
	.else
		movzx	eax,addin.Sfr[edx]
	.endif
	mov		addin.Ram[ecx],al
	ret

CLR_bit:
	mov		ecx,edx
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
		.if eax==SFR_SBUF
			and		SBUFWR,edx
			invoke ScreenChar,SBUFWR
		.else
			and		addin.Sfr[eax],dl
			.if eax==SFR_P0 || eax==SFR_P1 || eax==SFR_P2 || eax==SFR_P3
				movzx	edx,addin.Sfr[eax]
				invoke WritePort,eax,edx
			.endif
		.endif
	.endif
	ret

CLR_C:
	and		addin.Sfr[SFR_PSW],7Fh
	ret

SWAP_A:
	movzx	eax,addin.Sfr[SFR_ACC]
	mov		ah,al
	shr		al,4
	shl		ah,4
	or		al,ah
	mov		addin.Sfr[SFR_ACC],al
	ret

XCH_A_dir:
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
	ret

XCH_A_@R0:
	mov		edx,addin.Bank
	lea		edx,[edx*8+0]
	movzx	edx,addin.Ram[edx]
	movzx	eax,addin.Sfr[SFR_ACC]
	xchg	al,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	ret

XCH_A_@R1:
	mov		edx,addin.Bank
	lea		edx,[edx*8+1]
	movzx	edx,addin.Ram[edx]
	movzx	eax,addin.Sfr[SFR_ACC]
	xchg	al,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	ret

XCH_A_R0:
	mov		edx,addin.Bank
	lea		edx,[edx*8+0]
	movzx	eax,addin.Sfr[SFR_ACC]
	xchg	al,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	ret

XCH_A_R1:
	mov		edx,addin.Bank
	lea		edx,[edx*8+1]
	movzx	eax,addin.Sfr[SFR_ACC]
	xchg	al,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	ret

XCH_A_R2:
	mov		edx,addin.Bank
	lea		edx,[edx*8+2]
	movzx	eax,addin.Sfr[SFR_ACC]
	xchg	al,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	ret

XCH_A_R3:
	mov		edx,addin.Bank
	lea		edx,[edx*8+3]
	movzx	eax,addin.Sfr[SFR_ACC]
	xchg	al,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	ret

XCH_A_R4:
	mov		edx,addin.Bank
	lea		edx,[edx*8+4]
	movzx	eax,addin.Sfr[SFR_ACC]
	xchg	al,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	ret

XCH_A_R5:
	mov		edx,addin.Bank
	lea		edx,[edx*8+5]
	movzx	eax,addin.Sfr[SFR_ACC]
	xchg	al,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	ret

XCH_A_R6:
	mov		edx,addin.Bank
	lea		edx,[edx*8+6]
	movzx	eax,addin.Sfr[SFR_ACC]
	xchg	al,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	ret

XCH_A_R7:
	mov		edx,addin.Bank
	lea		edx,[edx*8+7]
	movzx	eax,addin.Sfr[SFR_ACC]
	xchg	al,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	ret

;------------------------------------------------------------------------------
POP_dir:
	movzx	ecx,addin.Sfr[SFR_SP]
	movzx	eax,addin.Ram[ecx]
	dec		addin.Sfr[SFR_SP]
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
	ret

SETB_bit:
	mov		ecx,edx
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
		.if eax==SFR_SBUF
			or		SBUFWR,edx
			invoke ScreenChar,SBUFWR
		.else
			or		addin.Sfr[eax],dl
			.if eax==SFR_P0 || eax==SFR_P1 || eax==SFR_P2 || eax==SFR_P3
				movzx	edx,addin.Sfr[eax]
				invoke WritePort,eax,edx
			.endif
		.endif
	.endif
	ret

SETB_C:
	or		addin.Sfr[SFR_PSW],80h
	ret

DA_A:
	movzx	eax,addin.Sfr[SFR_ACC]
	add		eax,0
	daa
	mov		addin.Sfr[SFR_ACC],al
	ret

DJNZ_dir_$cad:
	movsx	ecx,dh
	movzx	edx,dl
	.if edx<80h
		dec		addin.Ram[edx]
	.else
		dec		addin.Sfr[edx]
	.endif
	.if !ZERO?
		lea		ebx,[ebx+ecx]
		mov		addin.PC,ebx
	.endif
	ret

XCHD_A_@R0:
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	movzx	edx,addin.Ram[eax]
	movzx	eax,addin.Ram[edx]
	xchg	addin.Sfr[SFR_ACC],al
	mov		addin.Ram[edx],al
	ret

XCHD_A_@R1:
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	movzx	edx,addin.Ram[eax]
	movzx	eax,addin.Ram[edx]
	xchg	addin.Sfr[SFR_ACC],al
	mov		addin.Ram[edx],al
	ret

DJNZ_R0_$cad:
	movsx	edx,dl
	mov		eax,addin.Bank
	lea		eax,[eax*8+0]
	dec		addin.Ram[eax]
	.if !ZERO?
		lea		ebx,[ebx+edx]
		mov		addin.PC,ebx
	.endif
	ret

DJNZ_R1_$cad:
	movsx	edx,dl
	mov		eax,addin.Bank
	lea		eax,[eax*8+1]
	dec		addin.Ram[eax]
	.if !ZERO?
		lea		ebx,[ebx+edx]
		mov		addin.PC,ebx
	.endif
	ret

DJNZ_R2_$cad:
	movsx	edx,dl
	mov		eax,addin.Bank
	lea		eax,[eax*8+2]
	dec		addin.Ram[eax]
	.if !ZERO?
		lea		ebx,[ebx+edx]
		mov		addin.PC,ebx
	.endif
	ret

DJNZ_R3_$cad:
	movsx	edx,dl
	mov		eax,addin.Bank
	lea		eax,[eax*8+3]
	dec		addin.Ram[eax]
	.if !ZERO?
		lea		ebx,[ebx+edx]
		mov		addin.PC,ebx
	.endif
	ret

DJNZ_R4_$cad:
	movsx	edx,dl
	mov		eax,addin.Bank
	lea		eax,[eax*8+4]
	dec		addin.Ram[eax]
	.if !ZERO?
		lea		ebx,[ebx+edx]
		mov		addin.PC,ebx
	.endif
	ret

DJNZ_R5_$cad:
	movsx	edx,dl
	mov		eax,addin.Bank
	lea		eax,[eax*8+5]
	dec		addin.Ram[eax]
	.if !ZERO?
		lea		ebx,[ebx+edx]
		mov		addin.PC,ebx
	.endif
	ret

DJNZ_R6_$cad:
	movsx	edx,dl
	mov		eax,addin.Bank
	lea		eax,[eax*8+6]
	dec		addin.Ram[eax]
	.if !ZERO?
		lea		ebx,[ebx+edx]
		mov		addin.PC,ebx
	.endif
	ret

DJNZ_R7_$cad:
	movsx	edx,dl
	mov		eax,addin.Bank
	lea		eax,[eax*8+7]
	dec		addin.Ram[eax]
	.if !ZERO?
		lea		ebx,[ebx+edx]
		mov		addin.PC,ebx
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
	invoke ReadXRam,edx
	mov		addin.Sfr[SFR_ACC],al
	ret

MOVX_A_@R0:
	mov		edx,addin.Bank
	lea		edx,[edx*8+0]
	movzx	edx,addin.Ram[edx]
	mov		dh,addin.Sfr[SFR_P2]
	invoke ReadXRam,edx
	mov		addin.Sfr[SFR_ACC],al
	ret

MOVX_A_@R1:
	mov		edx,addin.Bank
	lea		edx,[edx*8+1]
	movzx	edx,addin.Ram[edx]
	mov		dh,addin.Sfr[SFR_P2]
	invoke ReadXRam,edx
	mov		addin.Sfr[SFR_ACC],al
	ret

CLR_A:
	mov		addin.Sfr[SFR_ACC],0
	ret

MOV_A_dir:
	.if edx<80h
		movzx	eax,addin.Ram[edx]
	.else
		movzx	eax,addin.Sfr[edx]
	.endif
	mov		addin.Sfr[SFR_ACC],al
	ret

MOV_A_@R0:
	mov		edx,addin.Bank
	lea		edx,[edx*8+0]
	movzx	edx,addin.Ram[edx]
	movzx	eax,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	ret

MOV_A_@R1:
	mov		edx,addin.Bank
	lea		edx,[edx*8+1]
	movzx	edx,addin.Ram[edx]
	movzx	eax,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	ret

MOV_A_R0:
	mov		edx,addin.Bank
	lea		edx,[edx*8+0]
	movzx	eax,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	ret

MOV_A_R1:
	mov		edx,addin.Bank
	lea		edx,[edx*8+1]
	movzx	eax,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	ret

MOV_A_R2:
	mov		edx,addin.Bank
	lea		edx,[edx*8+2]
	movzx	eax,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	ret

MOV_A_R3:
	mov		edx,addin.Bank
	lea		edx,[edx*8+3]
	movzx	eax,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	ret

MOV_A_R4:
	mov		edx,addin.Bank
	lea		edx,[edx*8+4]
	movzx	eax,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	ret

MOV_A_R5:
	mov		edx,addin.Bank
	lea		edx,[edx*8+5]
	movzx	eax,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	ret

MOV_A_R6:
	mov		edx,addin.Bank
	lea		edx,[edx*8+6]
	movzx	eax,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
	ret

MOV_A_R7:
	mov		edx,addin.Bank
	lea		edx,[edx*8+7]
	movzx	eax,addin.Ram[edx]
	mov		addin.Sfr[SFR_ACC],al
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
	ret

MOVX_@R0_A:
	mov		edx,addin.Bank
	lea		edx,[edx*8+0]
	movzx	edx,addin.Ram[edx]
	mov		dh,addin.Sfr[SFR_P2]
	movzx	eax,addin.Sfr[SFR_ACC]
	invoke WriteXRam,edx,eax
	ret

MOVX_@R1_A:
	mov		edx,addin.Bank
	lea		edx,[edx*8+1]
	movzx	edx,addin.Ram[edx]
	mov		dh,addin.Sfr[SFR_P2]
	movzx	eax,addin.Sfr[SFR_ACC]
	invoke WriteXRam,edx,eax
	ret

CPL_A:
	xor		addin.Sfr[SFR_ACC],0FFh
	ret

MOV_dir_A:
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
	ret

MOV_@R0_A:
	mov		edx,addin.Bank
	lea		edx,[edx*8+0]
	movzx	edx,addin.Ram[edx]
	movzx	eax,addin.Sfr[SFR_ACC]
	mov		addin.Ram[edx],al
	ret

MOV_@R1_A:
	mov		edx,addin.Bank
	lea		edx,[edx*8+1]
	movzx	edx,addin.Ram[edx]
	movzx	eax,addin.Sfr[SFR_ACC]
	mov		addin.Ram[edx],al
	ret

MOV_R0_A:
	movzx	eax,addin.Sfr[SFR_ACC]
	mov		edx,addin.Bank
	lea		edx,[edx*8+0]
	mov		addin.Ram[edx],al
	ret

MOV_R1_A:
	movzx	eax,addin.Sfr[SFR_ACC]
	mov		edx,addin.Bank
	lea		edx,[edx*8+1]
	mov		addin.Ram[edx],al
	ret

MOV_R2_A:
	movzx	eax,addin.Sfr[SFR_ACC]
	mov		edx,addin.Bank
	lea		edx,[edx*8+2]
	mov		addin.Ram[edx],al
	ret

MOV_R3_A:
	movzx	eax,addin.Sfr[SFR_ACC]
	mov		edx,addin.Bank
	lea		edx,[edx*8+3]
	mov		addin.Ram[edx],al
	ret

MOV_R4_A:
	movzx	eax,addin.Sfr[SFR_ACC]
	mov		edx,addin.Bank
	lea		edx,[edx*8+4]
	mov		addin.Ram[edx],al
	ret

MOV_R5_A:
	movzx	eax,addin.Sfr[SFR_ACC]
	mov		edx,addin.Bank
	lea		edx,[edx*8+5]
	mov		addin.Ram[edx],al
	ret

MOV_R6_A:
	movzx	eax,addin.Sfr[SFR_ACC]
	mov		edx,addin.Bank
	lea		edx,[edx*8+6]
	mov		addin.Ram[edx],al
	ret

MOV_R7_A:
	movzx	eax,addin.Sfr[SFR_ACC]
	mov		edx,addin.Bank
	lea		edx,[edx*8+7]
	mov		addin.Ram[edx],al
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
				mov		addin.Refresh,1
			.elseif State & STATE_STEP_INTO
				call	Execute
				xor		State,STATE_STEP_INTO
				mov		addin.Refresh,1
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
				mov		addin.Refresh,1
			.else
				mov		eax,addin.hBmpGreenLed
				call	SetStatusLed
			.endif
		.else
			mov		eax,addin.hBmpGreenLed
			call	SetStatusLed
		.endif
	.endw
	invoke Reset
	xor		eax,eax
	ret

Fetch:
	push	eax
	push	edx
	invoke SendAddinMessage,addin.hWnd,AM_ALECHANGED,0,0
	pop		edx
	pop		eax
	invoke WaitHalfCycle
	movzx	ecx,byte ptr [esi+ebx]
	inc		ebx
	mov		addin.PC,ebx
	retn

Execute:
	mov		eax,addin.hBmpRedLed
	call	SetStatusLed
	call	Fetch
	mov		eax,ecx
	movzx	ecx,Bytes[ecx]
	movzx	edi,Cycles[ecx]
	add		TotalCycles,edi
	lea		edi,[edi*2-1]
	.if ecx==1
		.while edi>1
			push	eax
			push	edx
			invoke SendAddinMessage,addin.hWnd,AM_ALECHANGED,0,0
			pop		edx
			pop		eax
			invoke WaitHalfCycle
			dec		edi
		.endw
		call	JmpTab[eax*4]
	.elseif ecx==2
		call	Fetch
		mov		edx,ecx
		.while edi>1
			push	eax
			push	edx
			invoke SendAddinMessage,addin.hWnd,AM_ALECHANGED,0,0
			pop		edx
			pop		eax
			invoke WaitHalfCycle
			dec		edi
		.endw
		call	JmpTab[eax*4]
	.elseif ecx==3
		call	Fetch
		mov		edx,ecx
		call	Fetch
		mov		dh,cl
		.while edi>1
			push	eax
			push	edx
			invoke SendAddinMessage,addin.hWnd,AM_ALECHANGED,0,0
			pop		edx
			pop		eax
			invoke WaitHalfCycle
			dec		edi
		.endw
		call	JmpTab[eax*4]
	.endif
	mov		PCDONE,ebx
	invoke FindMcuAddr,ebx
	.if eax
		.if [eax].MCUADDR.fbp
			or		State,SIM52_BREAKPOINT
		.endif
	.endif
	.while edi
		invoke SendAddinMessage,addin.hWnd,AM_ALECHANGED,0,0
		invoke WaitHalfCycle
		dec		edi
	.endw
	retn

SetStatusLed:
	.if eax!=StatusLed
		mov		StatusLed,eax
		invoke SendDlgItemMessage,addin.hWnd,IDC_IMGSTATUS,STM_SETIMAGE,IMAGE_BITMAP,eax
	.endif
	retn

CoreThread endp
