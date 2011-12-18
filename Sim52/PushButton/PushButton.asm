.386
.model flat, stdcall
option casemap :none   ; case sensitive

include PushButton.inc

.code

DecToBin proc uses ebx esi,lpStr:DWORD
	LOCAL	fNeg:DWORD

    mov     esi,lpStr
    mov		fNeg,FALSE
    mov		al,[esi]
    .if al=='-'
		inc		esi
		mov		fNeg,TRUE
    .endif
    xor     eax,eax
  @@:
    cmp     byte ptr [esi],30h
    jb      @f
    cmp     byte ptr [esi],3Ah
    jnb     @f
    mov     ebx,eax
    shl     eax,2
    add     eax,ebx
    shl     eax,1
    xor     ebx,ebx
    mov     bl,[esi]
    sub     bl,30h
    add     eax,ebx
    inc     esi
    jmp     @b
  @@:
	.if fNeg
		neg		eax
	.endif
    ret

DecToBin endp

BinToDec proc dwVal:DWORD,lpAscii:DWORD
	LOCAL	buffer[8]:BYTE

	mov		dword ptr buffer,'d%'
	invoke wsprintf,lpAscii,addr buffer,dwVal
	ret

BinToDec endp

GetItemInt proc uses esi edi,lpBuff:DWORD,nDefVal:DWORD

	mov		esi,lpBuff
	.if byte ptr [esi]
		mov		edi,esi
		invoke DecToBin,edi
		.while byte ptr [esi] && byte ptr [esi]!=','
			inc		esi
		.endw
		.if byte ptr [esi]==','
			inc		esi
		.endif
		push	eax
		invoke lstrcpy,edi,esi
		pop		eax
	.else
		mov		eax,nDefVal
	.endif
	ret

GetItemInt endp

PutItemInt proc uses esi edi,lpBuff:DWORD,nVal:DWORD

	mov		esi,lpBuff
	invoke lstrlen,esi
	mov		byte ptr [esi+eax],','
	invoke BinToDec,nVal,addr [esi+eax+1]
	ret

PutItemInt endp

GetItemStr proc uses esi edi,lpBuff:DWORD,lpDefVal:DWORD,lpResult:DWORD,ccMax:DWORD

	mov		esi,lpBuff
	.if byte ptr [esi]
		mov		edi,esi
		.while byte ptr [esi] && byte ptr [esi]!=','
			inc		esi
		.endw
		lea		eax,[esi+1]
		sub		eax,edi
		.if eax>ccMax
			mov		eax,ccMax
		.endif
		invoke lstrcpyn,lpResult,edi,eax
		.if byte ptr [esi]
			inc		esi
		.endif
		invoke lstrcpy,edi,esi
	.else
		invoke lstrcpyn,lpResult,lpDefVal,ccMax
	.endif
	ret

GetItemStr endp

;'"Str,Str","Str",1,2','Str',1
GetItemQuotedStr proc uses esi edi,lpBuff:DWORD,lpDefVal:DWORD,lpResult:DWORD,ccMax:DWORD

	mov		esi,lpBuff
	.if byte ptr [esi]=="'"
		mov		edi,esi
		inc		esi
		.while byte ptr [esi] && byte ptr [esi]!="'"
			inc		esi
		.endw
		.if byte ptr [esi]=="'"
			inc		esi
		.endif
		lea		eax,[esi+1]
		sub		eax,edi
		.if eax>ccMax
			mov		eax,ccMax
			lea		eax,[eax+2]
		.endif
		invoke lstrcpyn,lpResult,addr [edi+1],addr [eax-2]
		.if byte ptr [esi]
			inc		esi
		.endif
		invoke lstrcpy,edi,esi
	.elseif byte ptr [esi]
		invoke GetItemStr,lpBuff,lpDefVal,lpResult,ccMax
	.else
		invoke lstrcpyn,lpResult,lpDefVal,ccMax
	.endif
	ret

GetItemQuotedStr endp

PutItemQuotedStr proc uses esi,lpBuff:DWORD,lpStr:DWORD

	mov		esi,lpBuff
	invoke lstrlen,esi
	lea		esi,[esi+eax]
	mov		word ptr [esi],"',"
	invoke lstrcpy,addr [esi+2],lpStr
	invoke lstrlen,esi
	mov		word ptr [esi+eax],"'"
	ret

PutItemQuotedStr endp

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

BtnProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_LBUTTONDOWN
		invoke CallWindowProc,lpOldBtnProc,hWin,WM_LBUTTONUP,wParam,lParam
		invoke GetWindowLong,hWin,GWL_ID
		push	eax
		invoke GetParent,hWin
		pop		edx
		invoke SendMessage,eax,WM_PBDOWN,hWin,edx
	.elseif eax==WM_LBUTTONUP || eax==WM_LBUTTONDBLCLK
		invoke GetWindowLong,hWin,GWL_ID
		push	eax
		invoke GetParent,hWin
		pop		edx
		invoke SendMessage,eax,WM_PBUP,hWin,edx
	.else
		invoke CallWindowProc,lpOldBtnProc,hWin,uMsg,wParam,lParam
		ret
	.endif
	xor		eax,eax
	ret

BtnProc endp

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
		push	0
		push	IDC_BTNPB0
		push	IDC_BTNPB1
		push	IDC_BTNPB2
		push	IDC_BTNPB3
		push	IDC_BTNPB4
		push	IDC_BTNPB5
		push	IDC_BTNPB6
		mov		eax,IDC_BTNPB7
		.while eax
			invoke GetDlgItem,hWin,eax
			invoke SetWindowLong,eax,GWL_WNDPROC,offset BtnProc
			mov		lpOldBtnProc,eax
			pop		eax
		.endw
	.elseif eax==WM_PBDOWN
		invoke CheckDlgButton,hWin,lParam,BST_CHECKED
		invoke SendMessage,hWin,WM_COMMAND,lParam,wParam
	.elseif eax==WM_PBUP
		invoke CheckDlgButton,hWin,lParam,BST_UNCHECKED
		invoke SendMessage,hWin,WM_COMMAND,lParam,wParam
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
							mov		esi,lpAddin
							.if eax>=P0_0 && eax<=P0_7
								lea		ecx,[eax-P0_0]
								mov		ebx,1
								shl		ebx,cl
								.if edi
									xor		ebx,0FFh
									and		[esi].ADDIN.Sfr[SFR_P0],bl
								.else
									or		[esi].ADDIN.Sfr[SFR_P0],bl
								.endif
								movzx	ebx,[esi].ADDIN.Sfr[SFR_P0]
								push	ebx
								push	0
								push	AM_PORTWRITE
								push	[esi].ADDIN.hWnd
								mov		eax,[esi].ADDIN.lpSendAddinMessage
								call	eax
								mov		[esi].ADDIN.Refresh,1
							.elseif eax>=P1_0 && eax<=P1_7
								lea		ecx,[eax-P1_0]
								mov		ebx,1
								shl		ebx,cl
								.if edi
									xor		ebx,0FFh
									and		[esi].ADDIN.Sfr[SFR_P1],bl
								.else
									or		[esi].ADDIN.Sfr[SFR_P1],bl
								.endif
								movzx	ebx,[esi].ADDIN.Sfr[SFR_P1]
								push	ebx
								push	1
								push	AM_PORTWRITE
								push	[esi].ADDIN.hWnd
								mov		eax,[esi].ADDIN.lpSendAddinMessage
								call	eax
								mov		[esi].ADDIN.Refresh,1
							.elseif eax>=P2_0 && eax<=P2_7
								lea		ecx,[eax-P2_0]
								mov		ebx,1
								shl		ebx,cl
								.if edi
									xor		ebx,0FFh
									and		[esi].ADDIN.Sfr[SFR_P2],bl
								.else
									or		[esi].ADDIN.Sfr[SFR_P2],bl
								.endif
								movzx	ebx,[esi].ADDIN.Sfr[SFR_P2]
								push	ebx
								push	2
								push	AM_PORTWRITE
								push	[esi].ADDIN.hWnd
								mov		eax,[esi].ADDIN.lpSendAddinMessage
								call	eax
								mov		[esi].ADDIN.Refresh,1
							.elseif eax>=P3_0 && eax<=P3_7
								lea		ecx,[eax-P3_0]
								mov		ebx,1
								shl		ebx,cl
								.if edi
									xor		ebx,0FFh
									and		[esi].ADDIN.Sfr[SFR_P3],bl
								.else
									or		[esi].ADDIN.Sfr[SFR_P3],bl
								.endif
								movzx	ebx,[esi].ADDIN.Sfr[SFR_P3]
								push	ebx
								push	3
								push	AM_PORTWRITE
								push	[esi].ADDIN.hWnd
								mov		eax,[esi].ADDIN.lpSendAddinMessage
								call	eax
								mov		[esi].ADDIN.Refresh,1
							.elseif eax>=MMI0_0 && eax<=MMI0_7
								mov		edx,[esi].ADDIN.mminport[0]
								.if edx!=-1
									lea		ecx,[eax-MMI0_0]
									mov		ebx,1
									shl		ebx,cl
									.if edi
										xor		ebx,0FFh
										and		[esi].ADDIN.mminportdata[0],ebx
									.else
										or		[esi].ADDIN.mminportdata[0],ebx
									.endif
									mov		ebx,[esi].ADDIN.mminportdata[0]
									mov		[esi].ADDIN.XRam[edx],bl
									mov		[esi].ADDIN.Refresh,1
								.endif
							.elseif eax>=MMI1_0 && eax<=MMI1_7
								mov		edx,[esi].ADDIN.mminport[4]
								.if edx!=-1
									lea		ecx,[eax-MMI1_0]
									mov		ebx,1
									shl		ebx,cl
									.if edi
										xor		ebx,0FFh
										and		[esi].ADDIN.mminportdata[4],ebx
									.else
										or		[esi].ADDIN.mminportdata[4],ebx
									.endif
									mov		ebx,[esi].ADDIN.mminportdata[4]
									mov		[esi].ADDIN.XRam[edx],bl
									mov		[esi].ADDIN.Refresh,1
								.endif
							.elseif eax>=MMI2_0 && eax<=MMI2_7
								mov		edx,[esi].ADDIN.mminport[8]
								.if edx!=-1
									lea		ecx,[eax-MMI2_0]
									mov		ebx,1
									shl		ebx,cl
									.if edi
										xor		ebx,0FFh
										and		[esi].ADDIN.mminportdata[8],ebx
									.else
										or		[esi].ADDIN.mminportdata[8],ebx
									.endif
									mov		ebx,[esi].ADDIN.mminportdata[8]
									mov		[esi].ADDIN.XRam[edx],bl
									mov		[esi].ADDIN.Refresh,1
								.endif
							.elseif eax>=MMI3_0 && eax<=MMI3_7
								mov		edx,[esi].ADDIN.mminport[12]
								.if edx!=-1
									lea		ecx,[eax-MMI3_0]
									mov		ebx,1
									shl		ebx,cl
									.if edi
										xor		ebx,0FFh
										and		[esi].ADDIN.mminportdata[12],ebx
									.else
										or		[esi].ADDIN.mminportdata[12],ebx
									.endif
									mov		ebx,[esi].ADDIN.mminportdata[12]
									mov		[esi].ADDIN.XRam[edx],bl
									mov		[esi].ADDIN.Refresh,1
								.endif
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
	LOCAL	buffer[512]:BYTE
	LOCAL	buffer1[32]:BYTE

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
		;Return hook flags
		mov		eax,AH_COMMAND or AH_PROJECTOPEN or AH_PROJECTCLOSE
		jmp		Ex
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
	.elseif eax==AM_PROJECTOPEN
		invoke GetPrivateProfileString,addr szProPB,addr szProPB,addr szNULL,addr buffer,sizeof buffer,lParam
		invoke GetItemInt,addr buffer,0
		.if eax
			invoke ShowWindow,hDlg,SW_SHOW
		.else
			invoke ShowWindow,hDlg,SW_HIDE
		.endif
		xor		ebx,ebx
		.while ebx<8
			invoke GetDlgItem,hDlg,addr [ebx+1000]
			push	eax
			invoke GetItemInt,addr buffer,0
			push	eax
			invoke CheckDlgButton,hDlg,addr [ebx+1020],eax
			invoke GetItemQuotedStr,addr buffer,addr szNULL,addr buffer1,sizeof buffer1
			pop		eax
			pop		edx
			invoke EnableWindow,edx,eax
			invoke SetDlgItemText,hDlg,addr [ebx+1030],addr buffer1
			invoke GetItemInt,addr buffer,0
			invoke SendDlgItemMessage,hDlg,addr [ebx+1050],CB_SETCURSEL,eax,0
			invoke GetItemInt,addr buffer,0
			invoke SendDlgItemMessage,hDlg,addr [ebx+1060],CB_SETCURSEL,eax,0
			inc		ebx
		.endw
	.elseif eax==AM_PROJECTCLOSE
		mov		buffer,0
		xor		ebx,ebx
		invoke IsWindowVisible,hDlg
		invoke PutItemInt,addr buffer,eax
		.while ebx<8
			invoke IsDlgButtonChecked,hDlg,addr [ebx+1020]
			invoke PutItemInt,addr buffer,eax
			invoke GetDlgItemText,hDlg,addr [ebx+1030],addr buffer1,sizeof buffer1
			invoke PutItemQuotedStr,addr buffer,addr buffer1
			invoke SendDlgItemMessage,hDlg,addr [ebx+1050],CB_GETCURSEL,0,0
			invoke PutItemInt,addr buffer,eax
			invoke SendDlgItemMessage,hDlg,addr [ebx+1060],CB_GETCURSEL,0,0
			invoke PutItemInt,addr buffer,eax
			inc		ebx
		.endw
		invoke WritePrivateProfileString,addr szProPB,addr szProPB,addr buffer[1],lParam
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
