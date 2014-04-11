
IDD_DLGMAG		equ 1100
IDC_BTNMAGXY	equ 1102
IDC_STC13		equ 1105
IDC_STC12		equ 1104
IDC_STC11		equ 1103
IDC_UDCMAGCAL	equ 1107
IDC_STC14		equ 1101

.code

MagnProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	buffer[256]:BYTE
	LOCAL	x:DWORD
	LOCAL	y:DWORD
	LOCAL	z:DWORD

	mov		eax,uMsg
	.if	eax==WM_INITDIALOG
		invoke SendDlgItemMessage,hWin,IDC_STC13,WM_SETFONT,hFont,FALSE
		invoke SendDlgItemMessage,hWin,IDC_STC12,WM_SETFONT,hFont,FALSE
		invoke SendDlgItemMessage,hWin,IDC_STC11,WM_SETFONT,hFont,FALSE
		mov		calinx,0
		mov		countdown,1024+40
		mov		mode,MODE_CALIBRATE
		;Create a timer. The event will read the accelerometer axis
		invoke SetTimer,hWin,1000,100,NULL
	.elseif	eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDC_BTNACLXY
			.elseif eax==IDC_BTNACLZ
			.elseif eax==IDCANCEL
				invoke	SendMessage,hWin,WM_CLOSE,NULL,NULL
			.endif
		.endif
	.elseif	eax==WM_TIMER
		invoke KillTimer,hWin,1000
		mov		compass.flag,MODE_NORMAL
		invoke STLinkWrite,hWnd,STM32_ADDRESS,offset compass,4
		.if eax && eax!=IDIGNORE && eax!=IDABORT
			.while TRUE
				invoke Sleep,10
				;Read 16 bytes from STM32F4 ram and store it in compass.
				invoke STLinkRead,hWnd,STM32_ADDRESS,offset compass,16
				.if eax && eax!=IDIGNORE && eax!=IDABORT
					movsx	eax,compass.x
					invoke wsprintf,addr buffer,addr szFmtAxis,offset magxAxis,eax
					invoke SetDlgItemText,hWin,IDC_STC13,addr buffer
					movsx	eax,compass.y
					invoke wsprintf,addr buffer,addr szFmtAxis,offset magyAxis,eax
					invoke SetDlgItemText,hWin,IDC_STC12,addr buffer
					movsx	eax,compass.z
					invoke wsprintf,addr buffer,addr szFmtAxis,offset magzAxis,eax
					invoke SetDlgItemText,hWin,IDC_STC11,addr buffer

					invoke SetDlgItemInt,hWin,IDC_STC14,countdown,FALSE
					mov		ebx,calinx
					.if ebx<1024
						call	TempComp
						mov		eax,x
						mov		calibration.x[ebx*(2*WORD)],ax
						mov		eax,y
						mov		calibration.y[ebx*(2*WORD)],ax
						inc		calinx
					.endif
					dec		countdown
					.if ZERO?
						;Get min and max x and y
						mov		compass.mminx,2048
						mov		compass.mmaxx,-2048
						mov		compass.mminy,2048
						mov		compass.mmaxy,-2048
						xor		ebx,ebx
						.while ebx<1024
							movsx	eax,calibration.x[ebx*(2*WORD)]
							.if sdword ptr eax<compass.mminx
								mov		compass.mminx,eax
							.endif
							.if sdword ptr eax>compass.mmaxx
								mov		compass.mmaxx,eax
							.endif
							movsx	eax,calibration.y[ebx*(2*WORD)]
							.if sdword ptr eax<compass.mminy
								mov		compass.mminy,eax
							.endif
							.if sdword ptr eax>compass.mmaxy
								mov		compass.mmaxy,eax
							.endif
							inc		ebx
						.endw
						mov		eax,compass.mmaxx
						sub		eax,compass.mminx
						mov		compass.xscale,eax
						mov		eax,compass.mmaxy
						sub		eax,compass.mminy
						mov		compass.yscale,eax
						invoke wsprintf,addr buffer,addr szFmpCalibrate,compass.mminx,compass.mmaxx,compass.xscale,compass.mminy,compass.mmaxy,compass.yscale
						invoke SetDlgItemText,hWin,IDC_EDTRESULT,addr buffer
						invoke GetDlgItem,hWin,IDC_BTNSAVE
						invoke EnableWindow,eax,TRUE
						mov		mode,MODE_NORMAL
					.else
						invoke SetTimer,hWin,1000,100,NULL
					.endif
					.break
				.else
					mov		connected,FALSE
					.break
				.endif
			.endw
		.else
			mov		connected,FALSE
		.endif
	.elseif	eax==WM_CLOSE
		invoke KillTimer,hWin,1000
		invoke EndDialog,hWin,0
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

TempComp:
	;Temprature compensation
	movsx	eax,compass.x
	cdq
	mov		ecx,compass.tcxrt
	imul	ecx
	cdq
	mov		ecx,compass.tcxct
	idiv	ecx
	mov		x,eax
	movsx	eax,compass.y
	cdq
	mov		ecx,compass.tcyrt
	imul	ecx
	cdq
	mov		ecx,compass.tcyct
	idiv	ecx
	mov		y,eax
	movsx	eax,compass.z
	cdq
	mov		ecx,compass.tczrt
	imul	ecx
	cdq
	mov		ecx,compass.tczct
	idiv	ecx
	mov		z,eax
	retn

MagnProc endp

