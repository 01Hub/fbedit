;#########################################################################
;Assembler directives

.486
.model flat,stdcall
option casemap:none

;#########################################################################
;Include file

include RAEdirAddin.inc

.code

;#########################################################################
;Common AddIn Procedures

DllEntry proc hInst:HINSTANCE,reason:DWORD,reserved1:DWORD

	mov		eax,hInst
	mov		hInstance,eax
	mov		eax,TRUE
	ret

DllEntry Endp

UpdateMenu proc hMnu:HMENU
	LOCAL	mii:MENUITEMINFO

	mov		mii.cbSize,sizeof MENUITEMINFO
	mov		mii.fMask,MIIM_SUBMENU
	mov		edx,lpHandles
	invoke GetMenuItemInfo,[edx].ADDINHANDLES.hMenu,IDM_TOOLS,FALSE,addr mii
	invoke AppendMenu,mii.hSubMenu,MF_STRING,[IDAddIn],offset szMenuName
	ret

UpdateMenu endp

DlgProc proc uses ebx,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	
	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		ebx,lpHandles
		invoke SendDlgItemMessage,hWin,IDC_RAEDIT,REM_SETFONT,0,addr [ebx].ADDINHANDLES.racf
		mov		ebx,lpData
		invoke SendDlgItemMessage,hWin,IDC_RAEDIT,REM_SETCOLOR,0,addr [ebx].ADDINDATA.radcolor.racol
	.elseif eax==WM_CLOSE
		invoke DestroyWindow,hWin
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

DlgProc endp

InstallAddin proc uses ebx hWin:DWORD

	mov		ebx,hWin
	;Get pointer to handles struct
	invoke SendMessage,ebx,AIM_GETHANDLES,0,0;	
	mov		lpHandles,eax
	;Get pointer to proc struct
	invoke SendMessage,ebx,AIM_GETPROCS,0,0
	mov		lpProc,eax
	;Get pointer to data struct
	invoke SendMessage,ebx,AIM_GETDATA,0,0	
	mov		lpData,eax
	; Allocate a new menu id
	invoke SendMessage,ebx,AIM_GETMENUID,0,0
	mov		IDAddIn,eax
	mov		hook.hook1,HOOK_COMMAND or HOOK_MENUUPDATE
	xor		eax,eax
	mov		hook.hook2,eax
	mov		hook.hook3,eax
	mov		hook.hook4,eax
	mov		eax,offset hook
	ret 

InstallAddin Endp

AddinProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	
	mov		eax,uMsg
	.if eax==AIM_COMMAND
		mov 	eax,wParam
		movzx	edx,ax
		shr		eax, 16
		.IF edx==IDAddIn && eax==BN_CLICKED
			mov		eax,lpHandles
			mov		eax,[eax].ADDINHANDLES.hWnd
			invoke CreateDialogParam,hInstance,IDD_DLGRAEDIT,eax,offset DlgProc,NULL
			mov		hWnd,eax
			mov		eax,FALSE
			ret
		.ENDIF
	.elseif eax==AIM_MENUUPDATE
		invoke UpdateMenu,wParam
	.endif
	xor		eax,eax
	ret

AddinProc endp

;#########################################################################

End DllEntry
