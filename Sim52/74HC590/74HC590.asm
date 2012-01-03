.586
.model flat, stdcall
option casemap :none   ; case sensitive

include 74HC590.inc

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

p74HC590Proc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	rect:RECT
	LOCAL	buffer[32]:BYTE

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		eax,hWin
		mov		hDlg,eax
		mov		esi,offset szPorts
		.while byte ptr [esi]
			invoke SendDlgItemMessage,hWin,IDC_CBOQ,CB_ADDSTRING,0,esi
			invoke lstrlen,esi
			lea		esi,[esi+eax+1]
		.endw
		invoke SendDlgItemMessage,hWin,IDC_CBOCPR,CB_ADDSTRING,0,addr szPortBitsALE
		mov		esi,offset szPortBits
		.while byte ptr [esi]
			invoke SendDlgItemMessage,hWin,IDC_CBOQ7,CB_ADDSTRING,0,esi
			invoke SendDlgItemMessage,hWin,IDC_CBOCE,CB_ADDSTRING,0,esi
			invoke SendDlgItemMessage,hWin,IDC_CBOCPR,CB_ADDSTRING,0,esi
			invoke SendDlgItemMessage,hWin,IDC_CBOMRC,CB_ADDSTRING,0,esi
			invoke lstrlen,esi
			lea		esi,[esi+eax+1]
		.endw
		mov		esi,offset szPortBitsGND
		.while byte ptr [esi]
			invoke SendDlgItemMessage,hWin,IDC_CBOOE,CB_ADDSTRING,0,esi
			invoke lstrlen,esi
			lea		esi,[esi+eax+1]
		.endw
		invoke GetWindowRect,hWin,addr rect
		invoke MoveWindow,hWin,rect.left,rect.top,180,85,TRUE
		invoke SendDlgItemMessage,hWin,IDC_EDTDIVISOR,EM_LIMITTEXT,5,0
		invoke SendDlgItemMessage,hWin,IDC_UDNDIVISOR,UDM_SETRANGE,0,(1 shl 16) or 32767
		push	0
		push	1
		push	IDC_CBOQ
		push	P3_4
		push	IDC_CBOQ7
		push	0
		push	IDC_CBOOE
		push	P1_0
		push	IDC_CBOCE
		push	0
		push	IDC_CBOCPR
		push	P1_1
		mov		eax,IDC_CBOMRC
		.while eax
			pop		edx
			invoke SendDlgItemMessage,hDlg,eax,CB_SETCURSEL,edx,0
			pop		eax
		.endw
;		mov		portbit,0
;		mov		portaddr,-1
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDC_CHKACTIVE
				xor		fActive,TRUE
			.elseif eax==IDC_BTNEXPAND
				invoke GetWindowRect,hWin,addr rect
				mov		edx,rect.bottom
				sub		edx,rect.top
				.if edx==85
					mov		eax,390
					mov		edx,365
					push	offset szShrink
				.else
					mov		eax,180
					mov		edx,85
					push	offset szExpand
				.endif
				invoke MoveWindow,hWin,rect.left,rect.top,eax,edx,TRUE
				pop		eax
				invoke SetDlgItemText,hWin,IDC_BTNEXPAND,eax
			.endif
		.elseif edx==EN_CHANGE
			invoke GetDlgItemInt,hWin,IDC_EDTDIVISOR,NULL,FALSE
			.if !eax
				inc		eax
				push	eax
				invoke SetDlgItemInt,hWin,IDC_EDTDIVISOR,eax,FALSE
				pop		eax
			.elseif eax>32767
				mov		eax,32767
				push	eax
				invoke SetDlgItemInt,hWin,IDC_EDTDIVISOR,eax,FALSE
				pop		eax
			.endif
			mov		Divisor,eax
			invoke wsprintf,addr buffer,addr szFmtDiv,Divisor
			invoke SetDlgItemText,hWin,IDC_STCALE,addr buffer
		.elseif edx==CBN_SELCHANGE
			call	SetPorts
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
	;Q outputs
	invoke SendDlgItemMessage,hWin,IDC_CBOQ,CB_GETCURSEL,0,0
	.if eax
		dec		eax
		shl		eax,4
		or		eax,80h
	.else
		;NC
		dec		eax
	.endif
	mov		portoutadr,eax
	;Q7 output
	invoke SendDlgItemMessage,hWin,IDC_CBOQ7,CB_GETCURSEL,0,0
	xor		edx,edx
	.if eax
		call	GetPortBit
	.else
		;NC
		lea		eax,[eax-1]
	.endif
	mov		portbit.portadr[PORTBIT_Q7],eax
	mov		portbit.portbit[PORTBIT_Q7],edx
	;OE input
	invoke SendDlgItemMessage,hWin,IDC_CBOOE,CB_GETCURSEL,0,0
	xor		edx,edx
	.if eax>=2
		lea		eax,[eax-1]
		call	GetPortBit
	.elseif eax==1
		;NC
		lea		eax,[eax-2]
	.endif
	mov		portbit.portadr[PORTBIT_OE],eax
	mov		portbit.portbit[PORTBIT_OE],edx
	;MRC input
	invoke SendDlgItemMessage,hWin,IDC_CBOMRC,CB_GETCURSEL,0,0
	xor		edx,edx
	.if eax>=1
		call	GetPortBit
	.elseif eax==1
		;NC
		lea		eax,[eax-1]
	.endif
	mov		portbit.portadr[PORTBIT_MRC],eax
	mov		portbit.portbit[PORTBIT_MRC],edx
	;CPR input
	invoke SendDlgItemMessage,hWin,IDC_CBOCPR,CB_GETCURSEL,0,0
	xor		edx,edx
	.if eax>=2
		lea		eax,[eax-1]
		call	GetPortBit
	.elseif eax==1
		;NC
		lea		eax,[eax-2]
	.endif
	mov		portbit.portadr[PORTBIT_CPR],eax
	mov		portbit.portbit[PORTBIT_CPR],edx
	;CE input
	invoke SendDlgItemMessage,hWin,IDC_CBOCE,CB_GETCURSEL,0,0
	xor		edx,edx
	.if eax>=1
		call	GetPortBit
	.else
		;NC
		lea		eax,[eax-1]
	.endif
	mov		portbit.portadr[PORTBIT_CE],eax
	mov		portbit.portbit[PORTBIT_CE],edx
	retn

p74HC590Proc endp

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
		invoke AppendMenu,mii.hSubMenu,MF_STRING,[ebx].ADDIN.MenuID,offset szMenu74HC590
		mov		eax,[ebx].ADDIN.MenuID
		mov		IDAddin,eax
		inc		[ebx].ADDIN.MenuID
		invoke CreateDialogParam,hInstance,IDD_DLG74HC590,hWin,addr p74HC590Proc,0
		;Return hook flags
		mov		eax,AH_PORTWRITE or AH_ALECHANGED or AH_COMMAND or AH_RESET or AH_PROJECTOPEN or AH_PROJECTCLOSE
		jmp		Ex
	.elseif eax==AM_PORTWRITE
		.if fActive
			mov		eax,wParam
			shl		eax,4
			or		eax,80h
			mov		edx,lParam
			.if eax==portbit.portadr[PORTBIT_OE]
				mov		ecx,TRUE
				test		edx,portbit.portbit[PORTBIT_OE]
				.if ZERO?
					xor		ecx,ecx
				.endif
				mov		portbit.bitval[PORTBIT_OE],ecx
			.endif
			.if eax==portbit.portadr[PORTBIT_MRC]
				mov		ecx,TRUE
				test		edx,portbit.portbit[PORTBIT_MRC]
				.if ZERO?
					xor		ecx,ecx
					mov		nCountC,ecx
				.endif
				mov		portbit.bitval[PORTBIT_MRC],ecx
			.endif
			.if eax==portbit.portadr[PORTBIT_CPR]
				mov		ecx,TRUE
				test		edx,portbit.portbit[PORTBIT_CPR]
				.if ZERO?
					xor		ecx,ecx
				.endif
				.if ecx!=portbit.bitval[PORTBIT_CPR]
					mov		portbit.bitval[PORTBIT_CPR],ecx
					.if ecx
						;Low to High transition
						mov		eax,nCountC
						mov		nCountR,eax
						mov		ecx,TRUE
					.endif
				.endif
			.endif
			.if eax==portbit.portadr[PORTBIT_CE]
				mov		ecx,TRUE
				test		edx,portbit.portbit[PORTBIT_CE]
				.if ZERO?
					xor		ecx,ecx
				.endif
				mov		portbit.bitval[PORTBIT_CE],ecx
			.endif
		.endif
	.elseif eax==AM_ALECHANGED
		.if fActive
			mov		ebx,lpAddin
			.if !portbit.portadr[PORTBIT_CPR]
				;CPR is connected to ALE
				mov		eax,nCountC
				mov		nCountR,eax
				.if sdword ptr portoutadr>0
					mov		edx,portoutadr
					mov		[ebx].ADDIN.Sfr[edx],al
				.endif
				.if sdword ptr portbit.portadr[PORTBIT_Q7]>0
					mov		edx,portbit.portadr[PORTBIT_Q7]
					mov		ecx,portbit.portbit[PORTBIT_Q7]
					test	eax,80h
					.if ZERO?
						;Reset bit
						xor		ecx,0FFh
						and		[ebx].ADDIN.Sfr[edx],cl
					.else
						;Set bit
						or		[ebx].ADDIN.Sfr[edx],cl
					.endif
				.endif
			.endif
			.if !portbit.bitval[PORTBIT_OE]
				mov		eax,nCount
				lea		eax,[eax+1]
				.if eax>=Divisor
					.if !portbit.bitval[PORTBIT_CE] && portbit.bitval[PORTBIT_MRC]
						;CE is low, MRC is high, counting is enabled
						inc		nCountC
						and		nCountC,0FFh
					.endif
					xor		eax,eax
				.endif
			.else
				mov		eax,0FFh
			.endif
			mov		nCount,eax
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
	.elseif eax==AM_RESET
		mov		eax,portbit.portadr[PORTBIT_OE]
		.if sdword ptr eax>0
			;Port bit
			mov		portbit.bitval[PORTBIT_OE],TRUE
		.elseif !eax
			;GND
			mov		portbit.bitval[PORTBIT_OE],FALSE
		.else
			;NC
			mov		portbit.bitval[PORTBIT_OE],TRUE
		.endif
		;Port bit or NC
		mov		portbit.bitval[PORTBIT_MRC],TRUE
		mov		eax,portbit.portadr[PORTBIT_CPR]
		.if sdword ptr eax>0
			;Port bit
			mov		portbit.bitval[PORTBIT_CPR],TRUE
		.elseif !eax
			;ALE
			mov		portbit.bitval[PORTBIT_CPR],FALSE
		.else
			;NC
			mov		portbit.bitval[PORTBIT_CPR],TRUE
		.endif
		;Port bit or NC
		mov		portbit.bitval[PORTBIT_CE],TRUE
	.elseif eax==AM_PROJECTOPEN
		;Load settings from project file
		invoke GetPrivateProfileString,addr szPro74HC590,addr szPro74HC590,addr szNULL,addr buffer,sizeof buffer,lParam
		invoke GetItemInt,addr buffer,0
		.if eax
			invoke ShowWindow,hDlg,SW_SHOW
		.else
			invoke ShowWindow,hDlg,SW_HIDE
		.endif
		invoke GetItemInt,addr buffer,1
		mov		Divisor,eax
		invoke SetDlgItemInt,hDlg,IDC_EDTDIVISOR,eax,FALSE
		invoke GetItemInt,addr buffer,0
		mov		fActive,eax
		invoke CheckDlgButton,hDlg,IDC_CHKACTIVE,eax
		invoke GetItemInt,addr buffer,1
		invoke SendDlgItemMessage,hDlg,IDC_CBOQ,CB_SETCURSEL,eax,0
		invoke GetItemInt,addr buffer,P3_4
		invoke SendDlgItemMessage,hDlg,IDC_CBOQ7,CB_SETCURSEL,eax,0
		invoke GetItemInt,addr buffer,0
		invoke SendDlgItemMessage,hDlg,IDC_CBOOE,CB_SETCURSEL,eax,0
		invoke GetItemInt,addr buffer,P1_0
		invoke SendDlgItemMessage,hDlg,IDC_CBOCE,CB_SETCURSEL,eax,0
		invoke GetItemInt,addr buffer,0
		invoke SendDlgItemMessage,hDlg,IDC_CBOCPR,CB_SETCURSEL,eax,0
		invoke GetItemInt,addr buffer,P1_1
		invoke SendDlgItemMessage,hDlg,IDC_CBOMRC,CB_SETCURSEL,eax,0
		invoke SendMessage,hDlg,WM_COMMAND,(CBN_SELCHANGE shl 16) or IDC_CBOQ,0
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
		invoke PutItemInt,addr buffer,Divisor
		invoke PutItemInt,addr buffer,fActive
		invoke SendDlgItemMessage,hDlg,IDC_CBOQ,CB_GETCURSEL,0,0
		invoke PutItemInt,addr buffer,eax
		invoke SendDlgItemMessage,hDlg,IDC_CBOQ7,CB_GETCURSEL,0,0
		invoke PutItemInt,addr buffer,eax
		invoke SendDlgItemMessage,hDlg,IDC_CBOOE,CB_GETCURSEL,0,0
		invoke PutItemInt,addr buffer,eax
		invoke SendDlgItemMessage,hDlg,IDC_CBOCE,CB_GETCURSEL,0,0
		invoke PutItemInt,addr buffer,eax
		invoke SendDlgItemMessage,hDlg,IDC_CBOCPR,CB_GETCURSEL,0,0
		invoke PutItemInt,addr buffer,eax
		invoke SendDlgItemMessage,hDlg,IDC_CBOMRC,CB_GETCURSEL,0,0
		invoke PutItemInt,addr buffer,eax
		invoke GetWindowRect,hDlg,addr rect
		invoke PutItemInt,addr buffer,rect.left
		invoke PutItemInt,addr buffer,rect.top
		invoke WritePrivateProfileString,addr szPro74HC590,addr szPro74HC590,addr buffer[1],lParam
	.endif
	xor		eax,eax
  Ex:
	ret

AddinProc endp

Install74HC590 proc

	ret

Install74HC590 endp

UnInstall74HC590 proc

	invoke DestroyWindow,hDlg
	ret

UnInstall74HC590 endp

DllEntry proc hInst:HINSTANCE,reason:DWORD,reserved1:DWORD

	.if reason==DLL_PROCESS_ATTACH
		push	hInst
		pop		hInstance
		invoke Install74HC590
	.elseif reason==DLL_PROCESS_DETACH
		invoke UnInstall74HC590
	.endif
	mov     eax,TRUE
	ret

DllEntry endp

End DllEntry
