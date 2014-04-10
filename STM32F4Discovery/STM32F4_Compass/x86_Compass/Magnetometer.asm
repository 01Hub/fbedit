
IDD_DLGMAG		equ 1100
IDC_BTNMAGXY	equ 1102
IDC_STC13		equ 1105
IDC_STC12		equ 1104
IDC_STC11		equ 1103
IDC_UDCMAGCAL	equ 1107

.code

AccelProc	proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	buffer[256]:BYTE
	LOCAL	aclx:DWORD
	LOCAL	acly:DWORD
	LOCAL	aclz:DWORD

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
				;Read 16 bytes from STM32F100 ram and store it in compass.
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
					invoke SetTimer,hWin,1000,100,NULL
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

AccelProc endp

