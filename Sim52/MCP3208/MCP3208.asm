.586
.model flat, stdcall
option casemap :none   ; case sensitive

include MCP3208.inc

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

MCP3208Proc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	rect:RECT
	LOCAL	buffer[32]:BYTE

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		eax,hWin
		mov		hDlg,eax
		push	0
		push	IDC_TRBVREF
		push	IDC_TRBCH0
		push	IDC_TRBCH1
		push	IDC_TRBCH2
		push	IDC_TRBCH3
		push	IDC_TRBCH4
		push	IDC_TRBCH5
		push	IDC_TRBCH6
		mov		eax,IDC_TRBCH7
		.while eax
			invoke SendDlgItemMessage,hWin,eax,TBM_SETRANGE,0,(4095 shl 16)+0
			pop		eax
		.endw
		mov		esi,offset szPortBits
		.while byte ptr [esi]
			invoke SendDlgItemMessage,hWin,IDC_CBOCS,CB_ADDSTRING,0,esi
			invoke SendDlgItemMessage,hWin,IDC_CBOCLK,CB_ADDSTRING,0,esi
			invoke SendDlgItemMessage,hWin,IDC_CBODIN,CB_ADDSTRING,0,esi
			invoke SendDlgItemMessage,hWin,IDC_CBODOUT,CB_ADDSTRING,0,esi
			invoke lstrlen,esi
			lea		esi,[esi+eax+1]
		.endw
		invoke GetWindowRect,hWin,addr rect
		mov		eax,rect.right
		sub		eax,rect.left
		invoke MoveWindow,hWin,rect.left,rect.top,eax,240,TRUE
		push	0
		push	P1_0
		push	IDC_CBOCS
		push	P1_1
		push	IDC_CBOCLK
		push	P1_2
		push	IDC_CBODIN
		push	P1_3
		mov		eax,IDC_CBODOUT
		.while eax
			pop		edx
			invoke SendDlgItemMessage,hDlg,eax,CB_SETCURSEL,edx,0
			pop		eax
		.endw
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDC_CHKACTIVE
				xor		fActive,TRUE
			.elseif eax==IDC_BTNEXPAND
				invoke GetWindowRect,hWin,addr rect
				mov		eax,rect.right
				sub		eax,rect.left
				mov		edx,rect.bottom
				sub		edx,rect.top
				.if edx==240
					mov		edx,400
					push	offset szShrink
				.else
					mov		edx,240
					push	offset szExpand
				.endif
				invoke MoveWindow,hWin,rect.left,rect.top,eax,edx,TRUE
				pop		eax
				invoke SetDlgItemText,hWin,IDC_BTNEXPAND,eax
			.endif
		.elseif edx==CBN_SELCHANGE
			call	SetPorts
		.endif
	.elseif eax==WM_HSCROLL
		mov		edx,wParam
		movzx	eax,dx
		.if eax==SB_THUMBPOSITION || eax==SB_THUMBTRACK
			shr		edx,16
			push	edx
			invoke GetWindowLong,lParam,GWL_ID
			pop		edx
			.if eax==IDC_TRBVREF
				mov		VREFValue,edx
			.else
				lea		eax,[eax-IDC_TRBCH0]
				mov		CHValue[eax*4],edx
			.endif
		.elseif eax==SB_PAGELEFT || eax==SB_PAGERIGHT || eax==SB_LINELEFT || eax==SB_LINERIGHT
			invoke SendMessage,lParam,TBM_GETPOS,0,0
			push	eax
			invoke GetWindowLong,lParam,GWL_ID
			pop		edx
			.if eax==IDC_TRBVREF
				mov		VREFValue,edx
			.else
				lea		eax,[eax-IDC_TRBCH0]
				mov		CHValue[eax*4],edx
			.endif
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

GetPortBit:
	mov		edx,1
	.if eax>=P0_0 && eax<=P0_7
		lea		ecx,[eax-P0_0]
		mov		eax,SFR_P0
	.elseif eax>=P1_0 && eax<=P1_7
		lea		ecx,[eax-P1_0]
		mov		eax,SFR_P1
	.elseif eax>=P2_0 && eax<=P2_7
		lea		ecx,[eax-P2_0]
		mov		eax,SFR_P2
	.elseif eax>=P3_0 && eax<=P3_7
		lea		ecx,[eax-P3_0]
		mov		eax,SFR_P3
	.endif
	shl		edx,cl
	retn

SetPorts:
	;CS output
	invoke SendDlgItemMessage,hWin,IDC_CBOCS,CB_GETCURSEL,0,0
	xor		edx,edx
	.if eax
		call	GetPortBit
	.else
		;NC
		lea		eax,[eax-1]
	.endif
	mov		portbit.portadr[PORTBIT_CS],eax
	mov		portbit.portbit[PORTBIT_CS],edx
	mov		portbit.bitval[PORTBIT_CS],TRUE
	;CLK output
	invoke SendDlgItemMessage,hWin,IDC_CBOCLK,CB_GETCURSEL,0,0
	xor		edx,edx
	.if eax
		call	GetPortBit
	.else
		;NC
		lea		eax,[eax-1]
	.endif
	mov		portbit.portadr[PORTBIT_CLK],eax
	mov		portbit.portbit[PORTBIT_CLK],edx
	mov		portbit.bitval[PORTBIT_CLK],TRUE
	;DIN output
	invoke SendDlgItemMessage,hWin,IDC_CBODIN,CB_GETCURSEL,0,0
	xor		edx,edx
	.if eax
		call	GetPortBit
	.else
		;NC
		lea		eax,[eax-1]
	.endif
	mov		portbit.portadr[PORTBIT_DIN],eax
	mov		portbit.portbit[PORTBIT_DIN],edx
	mov		portbit.bitval[PORTBIT_DIN],TRUE
	;DOUT input
	invoke SendDlgItemMessage,hWin,IDC_CBODOUT,CB_GETCURSEL,0,0
	xor		edx,edx
	.if eax
		call	GetPortBit
	.else
		;NC
		lea		eax,[eax-1]
	.endif
	mov		portbit.portadr[PORTBIT_DOUT],eax
	mov		portbit.portbit[PORTBIT_DOUT],edx
	mov		portbit.bitval[PORTBIT_DOUT],TRUE
	retn

MCP3208Proc endp

AddinProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	mii:MENUITEMINFO
	LOCAL	buffer[256]:BYTE
	LOCAL	rect:RECT

	mov		eax,uMsg
	.if eax==AM_INIT
		mov		ebx,lParam
		mov		lpAddin,ebx
		mov		mii.cbSize,sizeof MENUITEMINFO
		mov		mii.fMask,MIIM_SUBMENU
		invoke GetMenuItemInfo,[ebx].ADDIN.hMenu,IDM_VIEW,FALSE,addr mii
		invoke AppendMenu,mii.hSubMenu,MF_STRING,[ebx].ADDIN.MenuID,offset szMenuMCP3208
		mov		eax,[ebx].ADDIN.MenuID
		mov		IDAddin,eax
		inc		[ebx].ADDIN.MenuID
		invoke CreateDialogParam,hInstance,IDD_DLGMCP3208,hWin,addr MCP3208Proc,0
		;Return hook flags
		mov		eax,AH_PORTWRITE or AH_COMMAND or AH_PROJECTOPEN or AH_PROJECTCLOSE
		jmp		Ex
	.elseif eax==AM_PORTWRITE
		.if fActive
			mov		eax,wParam
			shl		eax,4
			or		eax,80h
			mov		edx,lParam
			.if eax==portbit.portadr[PORTBIT_CS]
				mov		ecx,TRUE
				test		edx,portbit.portbit[PORTBIT_CS]
				.if ZERO?
					xor		ecx,ecx
				.endif
				mov		portbit.bitval[PORTBIT_CS],ecx
			.endif
			.if !portbit.bitval[PORTBIT_CS]
				;CS is low
				.if eax==portbit.portadr[PORTBIT_CLK]
					mov		ecx,TRUE
					test		edx,portbit.portbit[PORTBIT_CLK]
					.if ZERO?
						xor		ecx,ecx
					.endif
					.if ecx!=portbit.bitval[PORTBIT_CLK] && !ecx
						;High to low transition on CLK
						mov		fCLKTransition,TRUE
					.endif
					mov		portbit.bitval[PORTBIT_CLK],ecx
				.endif
				.if fCLKTransition
					mov		fCLKTransition,FALSE
					.if eax==portbit.portadr[PORTBIT_DIN]
						mov		ecx,TRUE
						test		edx,portbit.portbit[PORTBIT_DIN]
						.if ZERO?
							xor		ecx,ecx
						.endif
						mov		portbit.bitval[PORTBIT_DIN],ecx
						.if !nStarted && ecx
							;Startbit detected
							inc		nStarted
						.endif
					.endif
					mov		ecx,portbit.bitval[PORTBIT_DIN]
					.if nStarted==1
						inc		nStarted
					.elseif nStarted==2
						;Get the mode bit
						mov		nMode,ecx
						inc		nStarted
					.elseif nStarted<=5
						;Get 3 channel bits
						shl		nChannel,1
						or		nChannel,ecx
						inc		nStarted
					.elseif nStarted==6
						;Conversion started
						inc		nStarted
					.elseif nStarted==7
						;Conversion done
						inc		nStarted
						mov		edx,nChannel
						.if nMode
							;Single ended
							mov		eax,CHValue[edx*4]
						.else
							;Psaudo differential
							and		edx,06h
							mov		eax,CHValue[edx*4]
							inc		edx
							sub		eax,CHValue[edx*4]
						.endif
						shl		eax,16+4
						mov		ADCVal,eax
						mov		edx,portbit.portadr[PORTBIT_DOUT]
						.if sdword ptr edx>0
							mov		eax,portbit.portbit[PORTBIT_DOUT]
							xor		eax,0FFh
							mov		ecx,lpAddin
							and		[ecx].ADDIN.Sfr[edx],al
						.endif
					.elseif nStarted<=8+12
						;Shift out data bits, MSB First
						mov		edx,portbit.portadr[PORTBIT_DOUT]
						.if sdword ptr edx>0
							mov		eax,portbit.portbit[PORTBIT_DOUT]
							mov		ecx,lpAddin
							test	ADCVal,80000000h
							.if ZERO?
								xor		eax,0FFh
								and		[ecx].ADDIN.Sfr[edx],al
							.else
								or		[ecx].ADDIN.Sfr[edx],al
							.endif
							rol		ADCVal,1
						.endif
						inc		nStarted
					.elseif nStarted
						;Shift out data bits, LSB First
						shr		ADCVal,1
						mov		edx,portbit.portadr[PORTBIT_DOUT]
						.if sdword ptr edx>0
							mov		eax,portbit.portbit[PORTBIT_DOUT]
							mov		ecx,lpAddin
							test	ADCVal,01h
							.if ZERO?
								xor		eax,0FFh
								and		[ecx].ADDIN.Sfr[edx],al
							.else
								or		[ecx].ADDIN.Sfr[edx],al
							.endif
						.endif
						inc		nStarted
					.endif
				.endif
			.else
				xor		eax,eax
				mov		nStarted,eax
				mov		nChannel,eax
				mov		edx,portbit.portadr[PORTBIT_DOUT]
				.if sdword ptr edx>0
					mov		eax,portbit.portbit[PORTBIT_DOUT]
					mov		ecx,lpAddin
					or		[ecx].ADDIN.Sfr[edx],al
				.endif
			.endif
		.endif
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
		;Load settings from project file
		invoke GetPrivateProfileString,addr szProMCP3208,addr szProMCP3208,addr szNULL,addr buffer,sizeof buffer,lParam
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
		push	P1_0
		push	IDC_CBOCS
		push	P1_1
		push	IDC_CBOCLK
		push	P1_2
		push	IDC_CBODIN
		push	P1_3
		mov		eax,IDC_CBODOUT
		.while eax
			pop		edx
			push	eax
			invoke GetItemInt,addr buffer,edx
			pop		edx
			invoke SendDlgItemMessage,hDlg,edx,CB_SETCURSEL,eax,0
			pop		eax
		.endw
		invoke SendMessage,hDlg,WM_COMMAND,(CBN_SELCHANGE shl 16) or IDC_CBOCS,0
		push	0
		push	IDC_TRBVREF
		push	IDC_TRBCH0
		push	IDC_TRBCH1
		push	IDC_TRBCH2
		push	IDC_TRBCH3
		push	IDC_TRBCH4
		push	IDC_TRBCH5
		push	IDC_TRBCH6
		mov		eax,IDC_TRBCH7
		.while eax
			push	eax
			invoke GetItemInt,addr buffer,0
			pop		edx
			.if edx==IDC_TRBVREF
				mov		VREFValue,eax
			.else
				lea		ecx,[edx-IDC_TRBCH0]
				mov		CHValue[ecx*4],eax
			.endif
			invoke SendDlgItemMessage,hDlg,edx,TBM_SETPOS,TRUE,eax
			pop		eax
		.endw
		invoke GetWindowRect,hDlg,addr rect
		mov		eax,rect.left
		sub		rect.right,eax
		mov		eax,rect.top
		sub		rect.bottom,eax
		invoke GetItemInt,addr buffer,10
		mov		rect.left,eax
		invoke GetItemInt,addr buffer,10
		mov		rect.top,eax
		invoke MoveWindow,hDlg,rect.left,rect.top,rect.right,rect.bottom,TRUE
	.elseif eax==AM_PROJECTCLOSE
		;Save settings to project file
		mov		buffer,0
		invoke IsWindowVisible,hDlg
		invoke PutItemInt,addr buffer,eax
		invoke PutItemInt,addr buffer,fActive
		push	0
		push	IDC_CBOCS
		push	IDC_CBOCLK
		push	IDC_CBODIN
		mov		eax,IDC_CBODOUT
		.while eax
			invoke SendDlgItemMessage,hDlg,eax,CB_GETCURSEL,0,0
			invoke PutItemInt,addr buffer,eax
			pop		eax
		.endw
		push	0
		push	IDC_TRBVREF
		push	IDC_TRBCH0
		push	IDC_TRBCH1
		push	IDC_TRBCH2
		push	IDC_TRBCH3
		push	IDC_TRBCH4
		push	IDC_TRBCH5
		push	IDC_TRBCH6
		mov		eax,IDC_TRBCH7
		.while eax
			invoke SendDlgItemMessage,hDlg,eax,TBM_GETPOS,0,0
			invoke PutItemInt,addr buffer,eax
			pop		eax
		.endw
		invoke GetWindowRect,hDlg,addr rect
		invoke PutItemInt,addr buffer,rect.left
		invoke PutItemInt,addr buffer,rect.top
		invoke WritePrivateProfileString,addr szProMCP3208,addr szProMCP3208,addr buffer[1],lParam
	.endif
	xor		eax,eax
  Ex:
	ret

AddinProc endp

InstallMCP3208 proc

	ret

InstallMCP3208 endp

UnInstallMCP3208 proc

	invoke DestroyWindow,hDlg
	ret

UnInstallMCP3208 endp

DllEntry proc hInst:HINSTANCE,reason:DWORD,reserved1:DWORD

	.if reason==DLL_PROCESS_ATTACH
		push	hInst
		pop		hInstance
		invoke InstallMCP3208
	.elseif reason==DLL_PROCESS_DETACH
		invoke UnInstallMCP3208
	.endif
	mov     eax,TRUE
	ret

DllEntry endp

End DllEntry
