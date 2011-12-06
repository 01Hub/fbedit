.386
.model flat, stdcall
option casemap :none   ; case sensitive

include LCD.inc

.code

InstallLCD proc
	LOCAL	wc:WNDCLASSEX

	mov		wc.cbSize,sizeof WNDCLASSEX
	mov		wc.style,CS_HREDRAW or CS_VREDRAW
	mov		wc.lpfnWndProc,offset DisplayProc
	mov		wc.cbClsExtra,NULL
	mov		wc.cbWndExtra,4
	push	hInstance
	pop		wc.hInstance
	invoke GetStockObject,GRAY_BRUSH
	mov		wc.hbrBackground,eax
	mov		wc.lpszMenuName,NULL
	mov		wc.lpszClassName,offset LCDClass
	mov		wc.hIcon,NULL
	mov		wc.hIconSm,NULL
	invoke LoadCursor,0,IDC_ARROW
	mov		wc.hCursor,eax
	invoke RegisterClassEx,addr wc
	ret

InstallLCD endp

UnInstallLCD proc

	ret

UnInstallLCD endp

DisplayProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_CREATE
	.else
  ExDef:
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
		ret
	.endif
	xor    eax,eax
  Ex:
	ret

DisplayProc endp

LCDProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		push	0
		push	IDC_CBOD0
		push	IDC_CBOD1
		push	IDC_CBOD2
		push	IDC_CBOD3
		push	IDC_CBOD4
		push	IDC_CBOD5
		push	IDC_CBOD6
		push	IDC_CBOD7
		push	IDC_CBORS
		push	IDC_CBORW
		mov		eax,IDC_CBOE
		.while eax
			call	InitCbo
			pop		eax
		.endw
		push	0
		push	0
		push	IDC_CBOD0
		push	0
		push	IDC_CBOD1
		push	0
		push	IDC_CBOD2
		push	0
		push	IDC_CBOD3
		push	0
		push	IDC_CBOD4
		push	19
		push	IDC_CBOD5
		push	20
		push	IDC_CBOD6
		push	21
		push	IDC_CBOD7
		push	22
		push	IDC_CBORS
		push	23
		push	IDC_CBORW
		push	0
		mov		eax,IDC_CBOE
		mov		edx,24
		.while eax
			push	edx
			invoke GetDlgItem,hWin,eax
			pop		edx
			invoke SendMessage,eax,CB_SETCURSEL,edx,0
			pop		edx
			pop		eax
		.endw
	.elseif eax==WM_CLOSE
		invoke DestroyWindow,hWin
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

InitCbo:
	mov		esi,offset szPortBits
	invoke GetDlgItem,hWin,eax
	mov		ebx,eax
	.while byte ptr [esi]
		invoke SendMessage,ebx,CB_ADDSTRING,0,esi
		invoke lstrlen,esi
		lea		esi,[esi+eax+1]
	.endw
	retn

LCDProc endp

AddinProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==AM_INIT
	.elseif eax==AM_SHOW
		invoke CreateDialogParam,hInstance,IDD_DLGLCD,hWin,addr LCDProc,0
	.elseif eax==AM_PORTCHANGED
	.endif
	ret

AddinProc endp

DllEntry proc hInst:HINSTANCE,reason:DWORD,reserved1:DWORD

	.if reason==DLL_PROCESS_ATTACH
		push	hInst
		pop		hInstance
		invoke InstallLCD
	.elseif reason==DLL_PROCESS_DETACH
		invoke UnInstallLCD
	.endif
	mov     eax,TRUE
	ret

DllEntry endp

End DllEntry
