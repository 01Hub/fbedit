
.386
.model flat, stdcall  ;32 bit memory model eax
option casemap :none  ;case sensitive eax

include About.inc

.code

start:
	invoke	GetModuleHandle,NULL
	mov	hInstance,eax
	invoke	InitCommonControls
	invoke	DialogBoxParam,hInstance,IDD_MAIN,NULL,addr DlgProc,NULL
	invoke	ExitProcess,0

;########################################################################

DlgProc	proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.IF	eax==WM_INITDIALOG
		;initialization here
	.ELSEIF	eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.IF edx==BN_CLICKED
			.IF eax==IDOK

			.ELSEIF eax==IDCANCEL
				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
			.ENDIF
		.ENDIF
	.ELSEIF	eax==WM_CLOSE
		invoke EndDialog,hWin,0
	.ELSE
		mov		eax,FALSE
		ret
	.ENDIF
	mov		eax,TRUE
	ret

DlgProc endp

end start

