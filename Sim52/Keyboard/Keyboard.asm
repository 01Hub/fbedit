.386
.model flat, stdcall
option casemap :none   ; case sensitive

include Keyboard.inc

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

UnInstallKeyboard proc uses ebx

	invoke DestroyWindow,hDlg
	ret

UnInstallKeyboard endp

BtnProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_LBUTTONDOWN || eax==WM_LBUTTONDBLCLK
		invoke CallWindowProc,lpOldBtnProc,hWin,WM_LBUTTONUP,wParam,lParam
		invoke GetWindowLong,hWin,GWL_ID
		push	eax
		invoke GetParent,hWin
		pop		edx
		invoke SendMessage,eax,WM_KDOWN,hWin,edx
	.elseif eax==WM_LBUTTONUP
		invoke GetWindowLong,hWin,GWL_ID
		push	eax
		invoke GetParent,hWin
		pop		edx
		invoke SendMessage,eax,WM_KUP,hWin,edx
	.else
		invoke CallWindowProc,lpOldBtnProc,hWin,uMsg,wParam,lParam
		ret
	.endif
	xor		eax,eax
	ret

BtnProc endp

KeyboardProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	rect:RECT

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		eax,hWin
		mov		hDlg,eax
		push	0
		push	IDC_BTN7
		push	IDC_BTN8
		push	IDC_BTN9
		push	IDC_BTNADD
		push	IDC_BTN4
		push	IDC_BTN5
		push	IDC_BTN6
		push	IDC_BTNSUB
		push	IDC_BTN1
		push	IDC_BTN2
		push	IDC_BTN3
		push	IDC_BTNMUL
		push	IDC_BTNCE
		push	IDC_BTN0
		push	IDC_BTNDOT
		mov		eax,IDC_BTNDIV
		.while eax
			invoke GetDlgItem,hWin,eax
			invoke SetWindowLong,eax,GWL_WNDPROC,offset BtnProc
			mov		lpOldBtnProc,eax
			pop		eax
		.endw
		push	0
		push	P1_0
		push	IDC_CBO0
		push	P1_1
		push	IDC_CBO1
		push	P1_2
		push	IDC_CBO2
		push	P1_3
		mov		eax,IDC_CBO3
		.while eax
			invoke GetDlgItem,hWin,eax
			mov		ebx,eax
			mov		esi,offset szPorts
			.while byte ptr [esi]
				invoke SendMessage,ebx,CB_ADDSTRING,0,esi
				invoke lstrlen,esi
				lea		esi,[esi+eax+1]
			.endw
			mov		esi,offset szMMOPorts
			.while byte ptr [esi]
				invoke SendMessage,ebx,CB_ADDSTRING,0,esi
				invoke lstrlen,esi
				lea		esi,[esi+eax+1]
			.endw
			pop		eax
			invoke SendMessage,ebx,CB_SETCURSEL,eax,0
			pop		eax
		.endw
		push	0
		push	P1_4
		push	IDC_CBO4
		push	P1_5
		push	IDC_CBO5
		push	P1_6
		push	IDC_CBO6
		push	P1_7
		mov		eax,IDC_CBO7
		.while eax
			invoke GetDlgItem,hWin,eax
			mov		ebx,eax
			mov		esi,offset szPorts
			.while byte ptr [esi]
				invoke SendMessage,ebx,CB_ADDSTRING,0,esi
				invoke lstrlen,esi
				lea		esi,[esi+eax+1]
			.endw
			mov		esi,offset szMMIPorts
			.while byte ptr [esi]
				invoke SendMessage,ebx,CB_ADDSTRING,0,esi
				invoke lstrlen,esi
				lea		esi,[esi+eax+1]
			.endw
			pop		eax
			invoke SendMessage,ebx,CB_SETCURSEL,eax,0
			pop		eax
		.endw
		invoke GetWindowRect,hWin,addr rect
		mov		eax,263
		mov		edx,237
		invoke MoveWindow,hWin,rect.left,rect.top,edx,eax,TRUE
		invoke SendMessage,hWin,WM_COMMAND,CBN_SELCHANGE shl 16,0
	.elseif eax==WM_KDOWN
		invoke CheckDlgButton,hWin,lParam,BST_CHECKED
		invoke SendMessage,hWin,WM_COMMAND,lParam,wParam
	.elseif eax==WM_KUP
		invoke CheckDlgButton,hWin,lParam,BST_UNCHECKED
		invoke SendMessage,hWin,WM_COMMAND,lParam,wParam
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax>=IDC_BTN7 && eax<=IDC_BTNDIV
				mov		ebx,eax
				mov		keydown,0
				invoke IsDlgButtonChecked,hWin,ebx
				.if ebx==IDC_BTN7
					;col0,row0
					.if eax
						;Down
						mov		keydown,11h
					.endif
				.elseif ebx==IDC_BTN4
					;col0,row1
					.if eax
						;Down
						mov		keydown,21h
					.endif
				.elseif ebx==IDC_BTN1
					;col0,row2
					.if eax
						;Down
						mov		keydown,41h
					.endif
				.elseif ebx==IDC_BTNCE
					;col0,row3
					.if eax
						;Down
						mov		keydown,81h
					.endif
				.elseif ebx==IDC_BTN8
					;col1, row0
					.if eax
						;Down
						mov		keydown,12h
					.endif
				.elseif ebx==IDC_BTN5
					;col1, row1
					.if eax
						;Down
						mov		keydown,22h
					.endif
				.elseif ebx==IDC_BTN2
					;col1, row2
					.if eax
						;Down
						mov		keydown,42h
					.endif
				.elseif ebx==IDC_BTN0
					;col1, row3
					.if eax
						;Down
						mov		keydown,82h
					.endif
				.elseif ebx==IDC_BTN9
					;col2, row0
					.if eax
						;Down
						mov		keydown,14h
					.endif
				.elseif ebx==IDC_BTN6
					;col2, row1
					.if eax
						;Down
						mov		keydown,24h
					.endif
				.elseif ebx==IDC_BTN3
					;col2, row2
					.if eax
						;Down
						mov		keydown,44h
					.endif
				.elseif ebx==IDC_BTNDOT
					;col2, row3
					.if eax
						;Down
						mov		keydown,84h
					.endif
				.elseif ebx==IDC_BTNADD
					;col3, row0
					.if eax
						;Down
						mov		keydown,18h
					.endif
				.elseif ebx==IDC_BTNSUB
					;col3, row1
					.if eax
						;Down
						mov		keydown,28h
					.endif
				.elseif ebx==IDC_BTNMUL
					;col3, row2
					.if eax
						;Down
						mov		keydown,48h
					.endif
				.elseif ebx==IDC_BTNDIV
					;col3, row3
					.if eax
						;Down
						mov		keydown,88h
					.endif
				.endif
				mov		eax,keydown
				.if eax
					and		eax,0Fh
PrintHex eax
					test	portcol.keybit[0*sizeof PORT],eax
					.if !ZERO?
						mov		eax,portcol.bit[0*sizeof PORT]
						mov		keydowncolbit,eax
						mov		eax,portcol.adr[0*sizeof PORT]
						mov		keydowncolport,eax
					.else
						test	portcol.keybit[1*sizeof PORT],eax
						.if !ZERO?
							mov		eax,portcol.bit[1*sizeof PORT]
							mov		keydowncolbit,eax
							mov		eax,portcol.adr[1*sizeof PORT]
							mov		keydowncolport,eax
						.else
							test	portcol.keybit[2*sizeof PORT],eax
							.if !ZERO?
								mov		eax,portcol.bit[2*sizeof PORT]
								mov		keydowncolbit,eax
								mov		eax,portcol.adr[2*sizeof PORT]
								mov		keydowncolport,eax
							.else
								test	portcol.keybit[3*sizeof PORT],eax
								.if !ZERO?
									mov		eax,portcol.bit[3*sizeof PORT]
									mov		keydowncolbit,eax
									mov		eax,portcol.adr[3*sizeof PORT]
									mov		keydowncolport,eax
								.endif
							.endif
						.endif
					.endif
PrintHex keydowncolport
PrintHex keydowncolbit
				.endif
			.elseif eax==IDC_BTNCONFIG
				invoke GetWindowRect,hWin,addr rect
				mov		eax,rect.left
				sub		rect.right,eax
				mov		eax,rect.bottom
				sub		eax,rect.top
				.if eax==263
					invoke SetDlgItemText,hWin,IDC_BTNCONFIG,addr szShrink
					mov		eax,442
					mov		edx,302
				.else
					invoke SetDlgItemText,hWin,IDC_BTNCONFIG,addr szExpand
					mov		eax,263
					mov		edx,237
				.endif
				invoke MoveWindow,hWin,rect.left,rect.top,edx,eax,TRUE
			.elseif eax==IDC_CHKACTIVE
				invoke IsDlgButtonChecked,hWin,IDC_CHKACTIVE
				mov		fActive,eax
			.endif
		.elseif edx==CBN_SELCHANGE
			xor		eax,eax
			xor		ecx,ecx
			mov		ebx,offset portcol
			.while ecx<4
				mov		[ebx].PORT.adr,eax
				mov		[ebx].PORT.bit,eax
				mov		[ebx].PORT.value,eax
				inc		ecx
				lea		ebx,[ebx+sizeof PORT]
			.endw
			xor		eax,eax
			xor		ecx,ecx
			mov		ebx,offset mmoportcol
			.while ecx<4
				mov		[ebx].PORT.adr,eax
				mov		[ebx].PORT.bit,eax
				mov		[ebx].PORT.value,eax
				inc		ecx
				lea		ebx,[ebx+sizeof PORT]
			.endw
			call	GetColPorts
			xor		eax,eax
			xor		ecx,ecx
			mov		ebx,offset portrow
			.while ecx<4
				mov		[ebx].PORT.adr,eax
				mov		[ebx].PORT.bit,eax
				mov		[ebx].PORT.value,eax
				inc		ecx
				lea		ebx,[ebx+sizeof PORT]
			.endw
			xor		eax,eax
			xor		ecx,ecx
			mov		ebx,offset mmiportrow
			.while ecx<4
				mov		[ebx].PORT.adr,eax
				mov		[ebx].PORT.bit,eax
				mov		[ebx].PORT.value,eax
				inc		ecx
				lea		ebx,[ebx+sizeof PORT]
			.endw
			call	GetRowPorts
;mov		eax,portcol.adr[0*sizeof PORT]
;PrintHex eax
;mov		eax,portcol.bit[0*sizeof PORT]
;PrintHex eax
;mov		eax,portcol.value[0*sizeof PORT]
;PrintHex eax
;mov		eax,portcol.keybit[0*sizeof PORT]
;PrintHex eax
;mov		eax,portcol.adr[1*sizeof PORT]
;PrintHex eax
;mov		eax,portcol.bit[1*sizeof PORT]
;PrintHex eax
;mov		eax,portcol.value[1*sizeof PORT]
;PrintHex eax
;mov		eax,portcol.keybit[1*sizeof PORT]
;PrintHex eax
;
;mov		eax,portrow.adr[1*sizeof PORT]
;PrintHex eax
;mov		eax,portrow.bit[1*sizeof PORT]
;PrintHex eax
;mov		eax,portrow.value[1*sizeof PORT]
;PrintHex eax
;mov		eax,portrow.keybit[1*sizeof PORT]
;PrintHex eax
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

GetOutPort:
	mov		edx,1
	.if eax>=P0_0 && eax<=P0_7
		lea		ecx,[eax-P0_0]
		shl		edx,cl
		mov		ecx,edx
		mov		eax,SFR_P0
	.elseif eax>=P1_0 && eax<=P1_7
		lea		ecx,[eax-P1_0]
		shl		edx,cl
		mov		ecx,edx
		mov		eax,SFR_P1
	.elseif eax>=P2_0 && eax<=P2_7
		lea		ecx,[eax-P2_0]
		shl		edx,cl
		mov		ecx,edx
		mov		eax,SFR_P2
	.elseif eax>=P3_0 && eax<=P3_7
		lea		ecx,[eax-P3_0]
		shl		edx,cl
		mov		ecx,edx
		mov		eax,SFR_P3
	.elseif eax>=MMO0_0 && eax<=MMO0_7
		lea		ecx,[eax-MMO0_0]
		shl		edx,cl
		mov		ecx,edx
		mov		eax,[esi].ADDIN.mmoutport[0]
		or		eax,80000000h
	.elseif eax>=MMO1_0 && eax<=MMO1_7
		lea		ecx,[eax-MMO1_0]
		shl		edx,cl
		mov		ecx,edx
		mov		eax,[esi].ADDIN.mmoutport[4]
		or		eax,80000000h
	.elseif eax>=MMO2_0 && eax<=MMO2_7
		lea		ecx,[eax-MMO2_0]
		shl		edx,cl
		mov		ecx,edx
		mov		eax,[esi].ADDIN.mmoutport[8]
		or		eax,80000000h
	.elseif eax>=MMO3_0 && eax<=MMO3_7
		lea		ecx,[eax-MMO3_0]
		shl		edx,cl
		mov		ecx,edx
		mov		eax,[esi].ADDIN.mmoutport[12]
		or		eax,80000000h
	.endif
	retn

GetInPort:
	mov		edx,1
	.if eax>=P0_0 && eax<=P0_7
		lea		ecx,[eax-P0_0]
		shl		edx,cl
		mov		ecx,edx
		mov		edx,0*sizeof PORT
		mov		eax,SFR_P0
	.elseif eax>=P1_0 && eax<=P1_7
		lea		ecx,[eax-P1_0]
		shl		edx,cl
		mov		ecx,edx
		mov		edx,1*sizeof PORT
		mov		eax,SFR_P1
	.elseif eax>=P2_0 && eax<=P2_7
		lea		ecx,[eax-P2_0]
		shl		edx,cl
		mov		ecx,edx
		mov		edx,2*sizeof PORT
		mov		eax,SFR_P2
	.elseif eax>=P3_0 && eax<=P3_7
		lea		ecx,[eax-P3_0]
		shl		edx,cl
		mov		ecx,edx
		mov		edx,3*sizeof PORT
		mov		eax,SFR_P3
	.elseif eax>=MMI0_0 && eax<=MMI0_7
		lea		ecx,[eax-MMI0_0]
		shl		edx,cl
		mov		ecx,edx
		mov		edx,0*sizeof PORT
		mov		eax,[esi].ADDIN.mminport[0]
		or		eax,80000000h
	.elseif eax>=MMI1_0 && eax<=MMI1_7
		lea		ecx,[eax-MMI1_0]
		shl		edx,cl
		mov		ecx,edx
		mov		edx,1*sizeof PORT
		mov		eax,[esi].ADDIN.mminport[4]
		or		eax,80000000h
	.elseif eax>=MMI2_0 && eax<=MMI2_7
		lea		ecx,[eax-MMI2_0]
		shl		edx,cl
		mov		ecx,edx
		mov		edx,2*sizeof PORT
		mov		eax,[esi].ADDIN.mminport[8]
		or		eax,80000000h
	.elseif eax>=MMI3_0 && eax<=MMI3_7
		lea		ecx,[eax-MMI3_0]
		shl		edx,cl
		mov		ecx,edx
		mov		edx,3*sizeof PORT
		mov		eax,[esi].ADDIN.mminport[12]
		or		eax,80000000h
	.endif
	retn

GetColPorts:
	push	0
	push	IDC_CBO3
	push	IDC_CBO2
	push	IDC_CBO1
	mov		eax,IDC_CBO0
	mov		esi,01h
	xor		ebx,ebx
	.while eax
		invoke SendDlgItemMessage,hWin,eax,CB_GETCURSEL,0,0
		call	GetOutPort
		.if sdword ptr eax>=0
			mov		portcol.adr[ebx],eax
			or		portcol.bit[ebx],ecx
			or		portcol.keybit[ebx],esi
		.else
			mov		mmoportcol.adr[ebx],eax
			or		mmoportcol.bit[ebx],ecx
			or		mmoportcol.keybit[ebx],esi
		.endif
		lea		ebx,[ebx+sizeof PORT]
		pop		eax
		shl		esi,1
	.endw
	retn

GetRowPorts:
	push	0
	push	IDC_CBO7
	push	IDC_CBO6
	push	IDC_CBO5
	mov		eax,IDC_CBO4
	mov		esi,10h
	.while eax
		invoke SendDlgItemMessage,hWin,eax,CB_GETCURSEL,0,0
		call	GetInPort
		.if sdword ptr eax>0
			mov		portrow.adr[edx],eax
			or		portrow.bit[edx],ecx
			or		portrow.keybit[edx],esi
		.else
			mov		mmiportrow.adr[edx],eax
			or		mmiportrow.bit[edx],ecx
			or		mmiportrow.keybit[edx],esi
		.endif
		pop		eax
		shl		esi,1
	.endw
	retn

KeyboardProc endp

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
		invoke AppendMenu,mii.hSubMenu,MF_STRING,[ebx].ADDIN.MenuID,offset szMenuKeyboard
		mov		eax,[ebx].ADDIN.MenuID
		mov		IDAddin,eax
		inc		[ebx].ADDIN.MenuID
		invoke CreateDialogParam,hInstance,IDD_DLGKEYBOARD,hWin,addr KeyboardProc,0
		;Return hook flags
		mov		eax,AH_COMMAND or AH_PORTWRITE or AH_MMPORTWRITE or AH_PROJECTOPEN or AH_PROJECTCLOSE
		jmp		Ex
	.elseif eax==AM_PORTWRITE
		.if fActive
			mov		eax,wParam
			mov		edx,sizeof PORT
			mul		edx
			.if portcol.bit[eax]
				mov		edx,lParam
				xor		edx,0FFh
				and		edx,portcol.bit[eax]
				.if edx
					PrintHex edx
				.endif
;PrintHex eax
;PrintHex wParam
;PrintHex lParam
			.endif
		.endif
		mov		ebx,offset portcol
	.elseif eax==AM_MMPORTWRITE
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
		invoke GetPrivateProfileString,addr szProKeyboard,addr szProKeyboard,addr szNULL,addr buffer,sizeof buffer,lParam
		invoke GetItemInt,addr buffer,0
		.if eax
			invoke ShowWindow,hDlg,SW_SHOW
		.else
			invoke ShowWindow,hDlg,SW_HIDE
		.endif
		invoke GetItemInt,addr buffer,0
		mov		fActive,eax
		invoke CheckDlgButton,hDlg,IDC_CHKACTIVE,eax
		push	0
		push	P1_7
		push	IDC_CBO7
		push	P1_6
		push	IDC_CBO6
		push	P1_5
		push	IDC_CBO5
		push	P1_4
		push	IDC_CBO4
		push	P1_3
		push	IDC_CBO3
		push	P1_2
		push	IDC_CBO2
		push	P1_1
		push	IDC_CBO1
		push	P1_0
		mov		ebx,IDC_CBO0
		.while ebx
			pop		eax
			invoke GetItemInt,addr buffer,eax
			invoke SendDlgItemMessage,hDlg,ebx,CB_SETCURSEL,eax,0
			pop		ebx
		.endw
	.elseif eax==AM_PROJECTCLOSE
		mov		buffer,0
		xor		ebx,ebx
		invoke IsWindowVisible,hDlg
		invoke PutItemInt,addr buffer,eax
		invoke PutItemInt,addr buffer,fActive
		push	0
		push	IDC_CBO7
		push	IDC_CBO6
		push	IDC_CBO5
		push	IDC_CBO4
		push	IDC_CBO3
		push	IDC_CBO2
		push	IDC_CBO1
		mov		eax,IDC_CBO0
		.while eax
			invoke SendDlgItemMessage,hDlg,eax,CB_GETCURSEL,0,0
			invoke PutItemInt,addr buffer,eax
			pop		eax
		.endw
		invoke WritePrivateProfileString,addr szProKeyboard,addr szProKeyboard,addr buffer[1],lParam
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
		invoke UnInstallKeyboard
	.endif
	mov     eax,TRUE
	ret

DllEntry endp

End DllEntry

