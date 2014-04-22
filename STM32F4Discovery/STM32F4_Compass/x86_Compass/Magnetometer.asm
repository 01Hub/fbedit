
IDD_DLGMAG			equ 1100
IDC_BTNMAGXY		equ 1102
IDC_STC13			equ 1105
IDC_STC12			equ 1104
IDC_STC11			equ 1103
IDC_UDCMAGCAL		equ 1107
IDC_STC14			equ 1101
IDC_BTNMAGZMIN		equ 1106
IDC_BTNMAGZMAX		equ 1108
IDC_BTNMAGUPDATE	equ 1109

.data?

magxmin				DWORD ?
magxmax				DWORD ?
magymin				DWORD ?
magymax				DWORD ?
magzmin				DWORD ?
magzmax				DWORD ?

.code

MagnProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	buffer[256]:BYTE
	LOCAL	rect:RECT

	mov		eax,uMsg
	.if	eax==WM_INITDIALOG
		invoke SendDlgItemMessage,hWin,IDC_STC13,WM_SETFONT,hFont,FALSE
		invoke SendDlgItemMessage,hWin,IDC_STC12,WM_SETFONT,hFont,FALSE
		invoke SendDlgItemMessage,hWin,IDC_STC11,WM_SETFONT,hFont,FALSE
		invoke SendDlgItemMessage,hWin,IDC_STC14,WM_SETFONT,hFont,FALSE
		invoke GetDlgItem,hWin,IDC_UDCMAGCAL
		mov		ebx,eax
		invoke GetClientRect,ebx,addr rect
		invoke SetWindowPos,ebx,NULL,0,0,rect.right,rect.right,SWP_NOMOVE or SWP_NOZORDER
		xor		eax,eax
		mov		calinx,eax
		mov		magxmin,eax
		mov		magxmax,eax
		mov		magymin,eax
		mov		magymax,eax
		mov		magzmin,eax
		mov		magzmax,eax
		mov		countdown,1024
		mov		mode,MODE_CALIBRATE
		;Create a timer. The event will read the magnetometer axis
		invoke SetTimer,hWin,1000,100,NULL
	.elseif	eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDC_BTNMAGXY
				;Get min and max x and y
				mov		magxmin,2048
				mov		magxmax,-2048
				mov		magymin,2048
				mov		magymax,-2048
				xor		ebx,ebx
				.while ebx<1024
					movsx	eax,calibration.x[ebx*(2*WORD)]
					.if sdword ptr eax<magxmin
						mov		magxmin,eax
					.endif
					.if sdword ptr eax>magxmax
						mov		magxmax,eax
					.endif
					movsx	eax,calibration.y[ebx*(2*WORD)]
					.if sdword ptr eax<magymin
						mov		magymin,eax
					.endif
					.if sdword ptr eax>magymax
						mov		magymax,eax
					.endif
					inc		ebx
				.endw
			.elseif eax==IDC_BTNMAGZMIN
				movsx	eax,compass.z
				mov		magzmin,eax
			.elseif eax==IDC_BTNMAGZMAX
				movsx	eax,compass.z
				mov		magzmax,eax
			.elseif eax==IDC_BTNMAGUPDATE
				;Get axis offset
				mov		eax,magxmin
				mov		compass.magxmin,eax
				mov		eax,magxmax
				mov		compass.magxmax,eax

				mov		eax,magymin
				mov		compass.magymin,eax
				mov		eax,magymax
				mov		compass.magymax,eax

				mov		eax,magzmin
				mov		compass.magzmin,eax
				mov		eax,magzmax
				mov		compass.magzmax,eax

				invoke GetDlgItem,hWnd,IDC_BTNSAVE
				invoke EnableWindow,eax,TRUE

PrintDec magxmin
PrintDec magxmax
PrintDec magymin
PrintDec magymax
PrintDec magzmin
PrintDec magzmax
			.elseif eax==IDCANCEL
				mov		mode,MODE_NORMAL
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
					mov		ebx,calinx
					.if ebx<1024
;						call	TempComp
						movsx	eax,compass.x
						mov		calibration.x[ebx*(2*WORD)],ax
						movsx	eax,compass.y
						mov		calibration.y[ebx*(2*WORD)],ax
						inc		calinx
						invoke GetDlgItem,hWin,IDC_UDCMAGCAL
						invoke InvalidateRect,eax,NULL,TRUE
						dec		countdown
						invoke SetDlgItemInt,hWin,IDC_STC14,countdown,FALSE
					.endif
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

TempComp:
	;Temprature compensation
	movsx	eax,compass.x
	mov		ecx,compass.tcxrt
	imul	ecx
	mov		ecx,compass.tcxct
	idiv	ecx
	mov		compass.x,ax
	movsx	eax,compass.y
	mov		ecx,compass.tcyrt
	imul	ecx
	mov		ecx,compass.tcyct
	idiv	ecx
	mov		compass.y,ax
	movsx	eax,compass.z
	mov		ecx,compass.tczrt
	imul	ecx
	mov		ecx,compass.tczct
	idiv	ecx
	mov		compass.z,ax
	retn

MagnProc endp

