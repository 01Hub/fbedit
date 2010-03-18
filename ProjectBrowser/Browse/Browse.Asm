.386
.model flat, stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include Browse.inc

.code

start:

	invoke GetModuleHandle,NULL
	mov		hInstance,eax
	invoke LoadLibrary,addr szRAProject
	mov		hLib,eax
    invoke InitCommonControls
	invoke DialogBoxParam,hInstance,IDD_DIALOG1,NULL,addr DlgProc,NULL
	invoke FreeLibrary,hLib
	invoke ExitProcess,0

;########################################################################

DlgProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	rect:RECT

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke GetDlgItem,hWin,IDC_RAP
		mov		hPbr,eax
		invoke SendMessage,hPbr,RPBM_SETFILEEXT,FALSE,addr pbfileext
		invoke SendMessage,hPbr,RPBM_SETITEMS,FALSE,addr pbitems
	.elseif eax==WM_COMMAND

	.elseif eax==WM_SIZE
		invoke GetClientRect,hWin,addr rect
		invoke MoveWindow,hPbr,0,0,rect.right,rect.bottom,TRUE
	.elseif eax==WM_CLOSE
		invoke EndDialog,hWin,0
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

DlgProc endp

end start
