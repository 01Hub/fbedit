
IDD_BUILDOPTION					equ 3400
IDC_EDTRES						equ 1001
IDC_EDTASM						equ 1002
IDC_EDTLNK						equ 1003
IDC_BTNRESTORE					equ 1004

.code

BuildOptionDialogProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke SendDlgItemMessage,hWin,IDC_EDTRES,EM_LIMITTEXT,240,0
		invoke SendDlgItemMessage,hWin,IDC_EDTASM,EM_LIMITTEXT,240,0
		invoke SendDlgItemMessage,hWin,IDC_EDTLNK,EM_LIMITTEXT,240,0
		invoke SetDlgItemText,hWin,IDC_EDTRES,addr CompileRC
		invoke SetDlgItemText,hWin,IDC_EDTASM,addr Assemble
		invoke SetDlgItemText,hWin,IDC_EDTLNK,addr Link
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDOK
				invoke GetDlgItemText,hWin,IDC_EDTRES,addr CompileRC,240
				invoke lstrlen,addr CompileRC
				inc		eax
				invoke RegSetValueEx,hReg,addr szCompileRC,0,REG_SZ,addr CompileRC,eax
				invoke GetDlgItemText,hWin,IDC_EDTASM,addr Assemble,240
				invoke lstrlen,addr Assemble
				inc		eax
				invoke RegSetValueEx,hReg,addr szAssemble,0,REG_SZ,addr Assemble,eax
				invoke GetDlgItemText,hWin,IDC_EDTLNK,addr Link,240
				invoke lstrlen,addr Link
				inc		eax
				invoke RegSetValueEx,hReg,addr szLink,0,REG_SZ,addr Link,eax
				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
			.elseif eax==IDCANCEL
				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
			.elseif eax==IDC_BTNRESTORE
				invoke SetDlgItemText,hWin,IDC_EDTRES,addr defCompileRC
				invoke SetDlgItemText,hWin,IDC_EDTASM,addr defAssemble
				invoke SetDlgItemText,hWin,IDC_EDTLNK,addr defLink
			.endif
		.endif
	.elseif eax==WM_CLOSE
		invoke EndDialog,hWin,NULL
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

BuildOptionDialogProc endp
