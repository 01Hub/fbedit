
IDD_DLGACCEL		equ 1000
IDC_BTNACLMIN		equ 1004
IDC_BTNACLMAX		equ 1005
IDC_BTNACLUPDATE	equ 1009
IDC_STC10			equ 1003
IDC_STC9			equ 1002
IDC_STC8			equ 1001

IDC_RBNACLX			equ 1006
IDC_RBNACLY			equ 1007
IDC_RBNACLZ			equ 1008

.data?

aclsel				DWORD ?
aclxmin				DWORD ?
aclxmax				DWORD ?
aclymin				DWORD ?
aclymax				DWORD ?
aclzmin				DWORD ?
aclzmax				DWORD ?

.code

AccelProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	buffer[256]:BYTE
	LOCAL	aclx:DWORD
	LOCAL	acly:DWORD
	LOCAL	aclz:DWORD

	mov		eax,uMsg
	.if	eax==WM_INITDIALOG
		invoke SendDlgItemMessage,hWin,IDC_STC10,WM_SETFONT,hFont,FALSE
		invoke SendDlgItemMessage,hWin,IDC_STC9,WM_SETFONT,hFont,FALSE
		invoke SendDlgItemMessage,hWin,IDC_STC8,WM_SETFONT,hFont,FALSE
		invoke CheckDlgButton,hWin,IDC_RBNACLX,BST_CHECKED
		mov		aclsel,0
		;Create a timer. The event will read the accelerometer axis
		invoke SetTimer,hWin,1000,100,NULL
	.elseif	eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDC_BTNACLMIN
				mov		ecx,aclsel
				.if ecx==0
					movsx	eax,compass.buffer[0]
					mov		aclxmin,eax
				.elseif	ecx==1
					movsx	eax,compass.buffer[2]
					mov		aclymin,eax
				.elseif ecx==2
					movsx	eax,compass.buffer[4]
					mov		aclzmin,eax
				.endif
			.elseif eax==IDC_BTNACLMAX
				mov		ecx,aclsel
				.if ecx==0
					movsx	eax,compass.buffer[0]
					mov		aclxmax,eax
				.elseif	ecx==1
					movsx	eax,compass.buffer[2]
					mov		aclymax,eax
				.elseif ecx==2
					movsx	eax,compass.buffer[4]
					mov		aclzmax,eax
				.endif
			.elseif eax==IDC_BTNACLUPDATE
				;Get axis offset
				mov		eax,aclxmin
				mov		compass.aclxmin,eax
				mov		eax,aclxmax
				mov		compass.aclxmax,eax

				mov		eax,aclymin
				mov		compass.aclymin,eax
				mov		eax,aclymax
				mov		compass.aclymax,eax

				mov		eax,aclzmin
				mov		compass.aclzmin,eax
				mov		eax,aclzmax
				mov		compass.aclzmax,eax

				invoke GetDlgItem,hWnd,IDC_BTNSAVE
				invoke EnableWindow,eax,TRUE
PrintDec aclxmin
PrintDec aclxmax
PrintDec aclymin
PrintDec aclymax
PrintDec aclzmin
PrintDec aclzmax
			.elseif eax==IDCANCEL
				invoke	SendMessage,hWin,WM_CLOSE,NULL,NULL
			.elseif eax>=IDC_RBNACLX && eax<=IDC_RBNACLZ
				sub		eax,IDC_RBNACLX
				mov		aclsel,eax
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
					movsx	eax,compass.buffer[0]
					invoke wsprintf,addr buffer,addr szFmtAxis,offset aclxAxis,eax
					invoke SetDlgItemText,hWin,IDC_STC10,addr buffer
					movsx	eax,compass.buffer[2]
					invoke wsprintf,addr buffer,addr szFmtAxis,offset aclyAxis,eax
					invoke SetDlgItemText,hWin,IDC_STC9,addr buffer
					movsx	eax,compass.buffer[4]
					invoke wsprintf,addr buffer,addr szFmtAxis,offset aclzAxis,eax
					invoke SetDlgItemText,hWin,IDC_STC8,addr buffer
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

