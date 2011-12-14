.386
.model flat, stdcall
option casemap :none   ; case sensitive

include MMIO.inc

.code

UnInstallMMIO proc

	invoke DestroyWindow,hDlg
	ret

UnInstallMMIO endp

EditProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_CHAR
		mov		eax,wParam
		.if (eax>='0' && eax<='9') || (eax>='A' && eax<='F') || (eax>='a' && eax<='f') || eax==VK_BACK
			invoke CallWindowProc,lpOldEditProc,hWin,uMsg,wParam,lParam
		.else
			xor		eax,eax
		.endif
	.else
		invoke CallWindowProc,lpOldEditProc,hWin,uMsg,wParam,lParam
	.endif
	ret

EditProc endp

MMIOProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		eax,hWin
		mov		hDlg,eax
	.elseif eax==WM_CLOSE
		invoke ShowWindow,hWin,SW_HIDE
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

MMIOProc endp

AddinProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	mii:MENUITEMINFO

	mov		eax,uMsg
	.if eax==AM_INIT
		mov		ebx,lParam
		mov		lpAddin,ebx
		mov		mii.cbSize,sizeof MENUITEMINFO
		mov		mii.fMask,MIIM_SUBMENU
		invoke GetMenuItemInfo,[ebx].ADDIN.hMenu,IDM_VIEW,FALSE,addr mii
		invoke AppendMenu,mii.hSubMenu,MF_STRING,[ebx].ADDIN.MenuID,offset szMenuMMIO
		mov		eax,[ebx].ADDIN.MenuID
		mov		IDAddin,eax
		inc		[ebx].ADDIN.MenuID
		invoke CreateDialogParam,hInstance,IDD_DLGMMIO,hWin,addr MMIOProc,0
		push	0
		push	IDC_EDTADDRMMI0
		push	IDC_EDTADDRMMI1
		push	IDC_EDTADDRMMI2
		push	IDC_EDTADDRMMI3
		push	IDC_EDTADDRMMO0
		push	IDC_EDTADDRMMO1
		push	IDC_EDTADDRMMO2
		mov		eax,IDC_EDTADDRMMO3
		.while eax
			invoke GetDlgItem,hDlg,eax
			mov		ebx,eax
			invoke SetWindowLong,ebx,GWL_WNDPROC,offset EditProc
			mov		lpOldEditProc,eax
			invoke SendMessage,ebx,EM_LIMITTEXT,4,0
			pop		eax
		.endw
	.elseif eax==AM_PORTWRITE
	.elseif eax==AM_XRAMWRITE
	.elseif eax==AM_COMMAND
		mov		eax,lParam
		.if eax==IDAddin
			invoke ShowWindow,hDlg,SW_SHOW
		.endif
	.elseif eax==AM_RESET
	.endif
	xor		eax,eax
  Ex:
	ret

AddinProc endp

DllEntry proc hInst:HINSTANCE,reason:DWORD,reserved1:DWORD

	.if reason==DLL_PROCESS_ATTACH
		push	hInst
		pop		hInstance
	.elseif reason==DLL_PROCESS_DETACH
		invoke UnInstallMMIO
	.endif
	mov     eax,TRUE
	ret

DllEntry endp

End DllEntry
