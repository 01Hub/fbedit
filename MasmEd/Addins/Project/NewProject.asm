
;NewProject.dlg
IDD_DLGNEWPROJECT				equ 1000
IDC_EDTNAME						equ 1001
IDC_CHKSUB						equ 1002
IDC_CHKBAK						equ 1003
IDC_CHKMOD						equ 1004
IDC_CHKINC						equ 1005
IDC_CHKRES						equ 1006
IDC_EDTPATH						equ 1007
IDC_BTNPATH						equ 1008
IDC_TAB1						equ 1009

IDD_DLGTAB1						equ 1100
IDD_DLGTAB2						equ 1200

.code

Tab1Proc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
;
;	.elseif eax==WM_COMMAND
;		mov		edx,wParam
;		movzx	eax,dx
;		shr		edx,16
;		.if edx==BN_CLICKED
;			.if eax==IDOK
;
;			.elseif eax==IDCANCEL
;				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
;			.endif
;		.endif
;	.elseif eax==WM_CLOSE
;		invoke EndDialog,hWin,NULL
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

Tab1Proc endp

Tab2Proc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
;
;	.elseif eax==WM_COMMAND
;		mov		edx,wParam
;		movzx	eax,dx
;		shr		edx,16
;		.if edx==BN_CLICKED
;			.if eax==IDOK
;
;			.elseif eax==IDCANCEL
;				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
;			.endif
;		.endif
;	.elseif eax==WM_CLOSE
;		invoke EndDialog,hWin,NULL
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

Tab2Proc endp

NewProjectDialogProc proc uses ebx,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	hTab:HWND
	LOCAL	tci:TCITEM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		; Get handle of tabstrip
		invoke GetDlgItem,hWin,IDC_TAB1
		mov		hTab,eax
		mov		tci.imask,TCIF_TEXT Or TCIF_PARAM
		mov		tci.pszText,offset szFiles
		; Create Tab1 child dialog
		invoke CreateDialogParam,hInstance,IDD_DLGTAB1,hTab,addr Tab1Proc,0
		mov		tci.lParam,eax
		invoke SendMessage,hTab,TCM_INSERTITEM,0,addr tci
		mov		tci.pszText,offset szTemplate
		; Create Tab2 child dialog
		invoke CreateDialogParam,hInstance,IDD_DLGTAB2,hTab,addr Tab2Proc,0
		mov		tci.lParam,eax
		invoke SendMessage,hTab,TCM_INSERTITEM,1,addr tci
	.elseif eax==WM_NOTIFY
		mov		ebx,lParam
		.if [ebx].NMHDR.code==TCN_SELCHANGING
			; Hide the currently selected dialog
			mov		tci.imask,TCIF_PARAM
			invoke SendMessage,[ebx].NMHDR.hwndFrom,TCM_GETCURSEL,0,0
			mov		edx,eax
			invoke SendMessage,[ebx].NMHDR.hwndFrom,TCM_GETITEM,edx,addr tci
			invoke ShowWindow,tci.lParam,SW_HIDE
		.elseif [ebx].NMHDR.code==TCN_SELCHANGE
			; Show the currently selected dialog
			mov		tci.imask,TCIF_PARAM
			invoke SendMessage,[ebx].NMHDR.hwndFrom,TCM_GETCURSEL,0,0
			mov		edx,eax
			invoke SendMessage,[ebx].NMHDR.hwndFrom,TCM_GETITEM,edx,addr tci
			invoke ShowWindow,tci.lParam,SW_SHOW
		.endif
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDOK

			.elseif eax==IDCANCEL
				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
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

NewProjectDialogProc endp
