.386
.model flat, stdcall
option casemap :none   ; case sensitive

include PushButton.inc

.code

UnInstallPB proc uses ebx

	mov		ebx,IDC_BTNPB0
	.while ebx<=IDC_BTNPB7
		invoke SendDlgItemMessage,hDlg,ebx,BM_SETIMAGE,IMAGE_BITMAP,NULL
		inc		ebx
	.endw
	mov		ebx,IDC_IMGPB0
	.while ebx<=IDC_IMGPB7
		invoke SendDlgItemMessage,hDlg,ebx,STM_SETIMAGE,IMAGE_BITMAP,NULL
		inc		ebx
	.endw
	invoke DestroyWindow,hDlg
	invoke DeleteObject,hBmpPushButton
	invoke DeleteObject,hBmpSwitchOpen
	invoke DeleteObject,hBmpSwitchClosed
	ret

UnInstallPB endp

;GetCBOBits proc uses ebx edi
;
;	mov		P0Bits,0
;	mov		P1Bits,0
;	mov		P2Bits,0
;	mov		P3Bits,0
;	mov		MMI0Bits,0
;	mov		MMI1Bits,0
;	mov		MMI2Bits,0
;	mov		MMI3Bits,0
;	push	0
;	push	IDC_CBOTPB0
;	push	IDC_CBOTPB1
;	push	IDC_CBOTPB2
;	push	IDC_CBOTPB3
;	push	IDC_CBOTPB4
;	push	IDC_CBOTPB5
;	push	IDC_CBOTPB6
;	mov		ebx,IDC_CBOTPB7
;	.while ebx
;		lea		eax,[ebx-IDC_CBOTPB0+IDC_CBOBPB0]
;		invoke SendDlgItemMessage,hDlg,eax,CB_GETCURSEL,0,0
;		.if eax
;			lea		eax,[ebx-IDC_CBOTPB0+IDC_CHKPB0]
;			invoke IsDlgButtonChecked,hDlg,eax
;			.if eax
;				invoke SendDlgItemMessage,hDlg,ebx,CB_GETCURSEL,0,0
;				.if eax==NC
;					mov		edx,-1
;				.elseif eax>=P0_0 && eax<=P0_7
;					sub		eax,P0_0
;					mov		ecx,eax
;					mov		eax,01h
;					shl		eax,cl
;					or		P0Bits,eax
;					mov		edx,0
;				.elseif eax>=P1_0 && eax<=P1_7
;					sub		eax,P1_0
;					mov		ecx,eax
;					mov		eax,01h
;					shl		eax,cl
;					or		P1Bits,eax
;					mov		edx,1
;				.elseif eax>=P2_0 && eax<=P2_7
;					sub		eax,P2_0
;					mov		ecx,eax
;					mov		eax,01h
;					shl		eax,cl
;					or		P2Bits,eax
;					mov		edx,2
;				.elseif eax>=P3_0 && eax<=P3_7
;					sub		eax,P3_0
;					mov		ecx,eax
;					mov		eax,01h
;					shl		eax,cl
;					or		P3Bits,eax
;					mov		edx,3
;				.elseif eax>=MMI0_0 && eax<=MMI0_7
;					sub		eax,MMI0_0
;					mov		ecx,eax
;					mov		eax,01h
;					shl		eax,cl
;					or		MMI0Bits,eax
;					mov		edx,4
;				.elseif eax>=MMI1_0 && eax<=MMI1_7
;					sub		eax,MMI1_0
;					mov		ecx,eax
;					mov		eax,01h
;					shl		eax,cl
;					or		MMI1Bits,eax
;					mov		edx,5
;				.elseif eax>=MMI2_0 && eax<=MMI2_7
;					sub		eax,MMI2_0
;					mov		ecx,eax
;					mov		eax,01h
;					shl		eax,cl
;					or		MMI2Bits,eax
;					mov		edx,6
;				.elseif eax>=MMI3_0 && eax<=MMI3_7
;					sub		eax,MMI3_0
;					mov		ecx,eax
;					mov		eax,01h
;					shl		eax,cl
;					or		MMI3Bits,eax
;					mov		edx,7
;				.endif
;			.endif
;		.endif
;		pop		ebx
;	.endw
;	ret
;
;GetCBOBits endp
;
PBProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	rect:RECT
	LOCAL	buffer[32]:BYTE

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		eax,hWin
		mov		hDlg,eax
		invoke LoadBitmap,hInstance,IDB_PUSHBUTTON
		mov		hBmpPushButton,eax
		invoke LoadBitmap,hInstance,IDB_SWITCHOPEN
		mov		hBmpSwitchOpen,eax
		invoke LoadBitmap,hInstance,IDB_SWITCHCLOSED
		mov		hBmpSwitchClosed,eax
		mov		ebx,IDC_BTNPB0
		.while ebx<=IDC_BTNPB7
			invoke SendDlgItemMessage,hWin,ebx,BM_SETIMAGE,IMAGE_BITMAP,hBmpPushButton
			inc		ebx
		.endw
		invoke GetWindowRect,hWin,addr rect
		mov		eax,rect.left
		sub		rect.right,eax
		invoke MoveWindow,hWin,rect.left,rect.top,rect.right,137,FALSE
		mov		ebx,IDC_CBOBPB0
		.while ebx<=IDC_CBOBPB7
			mov		esi,offset szPBLow
			.while byte ptr [esi]
				invoke SendDlgItemMessage,hWin,ebx,CB_ADDSTRING,0,esi
				invoke lstrlen,esi
				lea		esi,[esi+eax+1]
			.endw
			invoke SendDlgItemMessage,hWin,ebx,CB_SETCURSEL,0,0
			inc		ebx
		.endw
		mov		ebx,IDC_CBOTPB0
		.while ebx<=IDC_CBOTPB7
			mov		esi,offset szPBHigh
			.while byte ptr [esi]
				invoke SendDlgItemMessage,hWin,ebx,CB_ADDSTRING,0,esi
				invoke lstrlen,esi
				lea		esi,[esi+eax+1]
			.endw
			invoke SendDlgItemMessage,hWin,ebx,CB_SETCURSEL,0,0
			inc		ebx
		.endw
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax>=IDC_CHKPB0 && eax<=IDC_CHKPB7
				mov		ebx,eax
				invoke IsDlgButtonChecked,hWin,ebx
				push	eax
				lea		ebx,[ebx-IDC_CHKPB0+IDC_BTNPB0]
				invoke GetDlgItem,hWin,ebx
				pop		edx
				invoke EnableWindow,eax,edx
			.elseif eax>=IDC_BTNPB0 && eax<=IDC_BTNPB7
				mov		ebx,eax
				invoke IsDlgButtonChecked,hWin,ebx
				xor		edi,edi
				.if eax
					lea		edi,[edi+1]
					mov		eax,hBmpSwitchClosed
				.else
					mov		eax,hBmpSwitchOpen
				.endif
				lea		edx,[ebx-IDC_BTNPB0+IDC_IMGPB0]
				invoke SendDlgItemMessage,hDlg,edx,STM_SETIMAGE,IMAGE_BITMAP,eax
				lea		edx,[ebx-IDC_BTNPB0+IDC_CHKPB0]
				invoke IsDlgButtonChecked,hWin,edx
				.if eax
					lea		eax,[ebx-IDC_BTNPB0+IDC_CBOBPB0]
					invoke SendDlgItemMessage,hWin,eax,CB_GETCURSEL,0,0
					.if eax
						lea		eax,[ebx-IDC_BTNPB0+IDC_CBOTPB0]
						invoke SendDlgItemMessage,hWin,eax,CB_GETCURSEL,0,0
						.if eax
							.if eax>=P0_0 && eax<=P0_7
								lea		ecx,[eax-P0_0]
								mov		ebx,1
								shl		ebx,cl
								.if edi
									xor		ebx,0FFh
									mov		edi,lpAddin
									and		[edi].ADDIN.Sfr[SFR_P0],bl
								.else
									mov		edi,lpAddin
									or		[edi].ADDIN.Sfr[SFR_P0],bl
								.endif
								movzx	ebx,[edi].ADDIN.Sfr[SFR_P0]
								push	ebx
								push	0
								push	AM_PORTWRITE
								push	[edi].ADDIN.hWnd
								mov		eax,[edi].ADDIN.lpSendAddinMessage
								call	eax
								mov		[edi].ADDIN.Refresh,1
							.elseif eax>=P1_0 && eax<=P1_7
								lea		ecx,[eax-P1_0]
								mov		ebx,1
								shl		ebx,cl
								.if edi
									xor		ebx,0FFh
									mov		edi,lpAddin
									and		[edi].ADDIN.Sfr[SFR_P1],bl
								.else
									mov		edi,lpAddin
									or		[edi].ADDIN.Sfr[SFR_P1],bl
								.endif
								movzx	ebx,[edi].ADDIN.Sfr[SFR_P1]
								push	ebx
								push	1
								push	AM_PORTWRITE
								push	[edi].ADDIN.hWnd
								mov		eax,[edi].ADDIN.lpSendAddinMessage
								call	eax
								mov		[edi].ADDIN.Refresh,1
							.elseif eax>=P2_0 && eax<=P2_7
								lea		ecx,[eax-P2_0]
								mov		ebx,1
								shl		ebx,cl
								.if edi
									xor		ebx,0FFh
									mov		edi,lpAddin
									and		[edi].ADDIN.Sfr[SFR_P2],bl
								.else
									mov		edi,lpAddin
									or		[edi].ADDIN.Sfr[SFR_P2],bl
								.endif
								movzx	ebx,[edi].ADDIN.Sfr[SFR_P2]
								push	ebx
								push	2
								push	AM_PORTWRITE
								push	[edi].ADDIN.hWnd
								mov		eax,[edi].ADDIN.lpSendAddinMessage
								call	eax
								mov		[edi].ADDIN.Refresh,1
							.elseif eax>=P3_0 && eax<=P3_7
								lea		ecx,[eax-P3_0]
								mov		ebx,1
								shl		ebx,cl
								.if edi
									xor		ebx,0FFh
									mov		edi,lpAddin
									and		[edi].ADDIN.Sfr[SFR_P3],bl
								.else
									mov		edi,lpAddin
									or		[edi].ADDIN.Sfr[SFR_P3],bl
								.endif
								movzx	ebx,[edi].ADDIN.Sfr[SFR_P3]
								push	ebx
								push	3
								push	AM_PORTWRITE
								push	[edi].ADDIN.hWnd
								mov		eax,[edi].ADDIN.lpSendAddinMessage
								call	eax
								mov		[edi].ADDIN.Refresh,1
							.endif
						.endif
					.endif
				.endif
			.elseif eax==IDC_BTNCONFIG
				invoke GetWindowRect,hWin,addr rect
				mov		eax,rect.left
				sub		rect.right,eax
				mov		eax,rect.bottom
				sub		eax,rect.top
				.if eax==137
					invoke SetDlgItemText,hWin,IDC_BTNCONFIG,addr szShrink
					mov		eax,300
				.else
					invoke SetDlgItemText,hWin,IDC_BTNCONFIG,addr szExpand
					mov		eax,137
				.endif
				invoke MoveWindow,hWin,rect.left,rect.top,rect.right,eax,TRUE
			.endif
;		.elseif edx==CBN_SELCHANGE
;			.if (eax>=IDC_CBOTPB0 && eax<=IDC_CBOTPB7) || (eax>=IDC_CBOBPB0 && eax<=IDC_CBOBPB7)
;				invoke GetCBOBits
;			.endif
		.elseif edx==EN_CHANGE
			mov		ebx,eax
			invoke GetDlgItemText,hWin,ebx,addr buffer,sizeof buffer
			lea		ebx,[ebx-IDC_EDTPB0+IDC_STCPB0]
			invoke SetDlgItemText,hWin,ebx,addr buffer
		.endif
	.elseif eax==WM_ACTIVATE
		.if wParam!=WA_INACTIVE
			mov		eax,hWin
			mov		ebx,lpAddin
			mov		[ebx].ADDIN.hActive,eax
		.endif
	.elseif eax==WM_CLOSE
		invoke ShowWindow,hWin,SW_HIDE
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

PBProc endp


AddinProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	mii:MENUITEMINFO

	mov		eax,uMsg
	.if eax==AM_INIT
		mov		ebx,lParam
		mov		lpAddin,ebx
		mov		mii.cbSize,sizeof MENUITEMINFO
		mov		mii.fMask,MIIM_SUBMENU
		invoke GetMenuItemInfo,[ebx].ADDIN.hMenu,IDM_VIEW,FALSE,addr mii
		invoke AppendMenu,mii.hSubMenu,MF_STRING,[ebx].ADDIN.MenuID,offset szMenuPB
		mov		eax,[ebx].ADDIN.MenuID
		mov		IDAddin,eax
		inc		[ebx].ADDIN.MenuID
		invoke CreateDialogParam,hInstance,IDD_DLGPB,hWin,addr PBProc,0
	.elseif eax==AM_PORTWRITE
	.elseif eax==AM_XRAMWRITE
	.elseif eax==AM_COMMAND
		mov		eax,lParam
		.if eax==IDAddin
			invoke IsWindowVisible,hDlg
			.if eax
				invoke ShowWindow,hDlg,SW_HIDE
			.else
				invoke ShowWindow,hDlg,SW_SHOW
			.endif
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
		invoke UnInstallPB
	.endif
	mov     eax,TRUE
	ret

DllEntry endp

End DllEntry
