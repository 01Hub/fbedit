.386
.model flat, stdcall
option casemap :none   ; case sensitive

include MMIO.inc

.code

UnInstallMMIO proc

	invoke DestroyWindow,hDlg
	ret

UnInstallMMIO endp

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

HexToBin proc lpStr:DWORD

	push	esi
	xor		eax,eax
	xor		edx,edx
	mov		esi,lpStr
  @@:
	shl		eax,4
	add		eax,edx
	movzx	edx,byte ptr [esi]
	.if edx>='0' && edx<='9'
		sub		edx,'0'
		inc		esi
		jmp		@b
	.elseif  edx>='A' && edx<='F'
		sub		edx,'A'-10
		inc		esi
		jmp		@b
	.elseif  edx>='a' && edx<='f'
		sub		edx,'a'-10
		inc		esi
		jmp		@b
	.endif
	pop		esi
	ret

HexToBin endp

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

PutItemStr proc uses esi,lpBuff:DWORD,lpStr:DWORD

	mov		esi,lpBuff
	invoke lstrlen,esi
	mov		byte ptr [esi+eax],','
	invoke lstrcpy,addr [esi+eax+1],lpStr
	ret

PutItemStr endp

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

ResetOutputs proc uses ebx,fDelete:DWORD

	mov		ebx,lpAddin
	push	0
	push	IDC_IMG57
	push	IDC_IMG58
	push	IDC_IMG59
	push	IDC_IMG44
	push	IDC_IMG61
	push	IDC_IMG62
	push	IDC_IMG63
	push	IDC_IMG32
	push	IDC_IMG41
	push	IDC_IMG42
	push	IDC_IMG43
	push	IDC_IMG60
	push	IDC_IMG45
	push	IDC_IMG46
	push	IDC_IMG47
	push	IDC_IMG48
	push	IDC_IMG25
	push	IDC_IMG26
	push	IDC_IMG27
	push	IDC_IMG28
	push	IDC_IMG29
	push	IDC_IMG30
	push	IDC_IMG31
	push	IDC_IMG64
	push	IDC_IMG9
	push	IDC_IMG10
	push	IDC_IMG11
	push	IDC_IMG12
	push	IDC_IMG13
	push	IDC_IMG14
	push	IDC_IMG15
	mov		eax,IDC_IMG16
	.while eax
		invoke SendDlgItemMessage,hDlg,eax,STM_SETIMAGE,IMAGE_BITMAP,[ebx].ADDIN.hBmpGrayLed
		.if fDelete
			invoke DeleteObject,eax
		.endif
		pop		eax
	.endw
	mov		eax,00h
	mov		[ebx].ADDIN.mmoutportdata[0],eax
	mov		[ebx].ADDIN.mmoutportdata[4],eax
	mov		[ebx].ADDIN.mmoutportdata[8],eax
	mov		[ebx].ADDIN.mmoutportdata[12],eax
	ret

ResetOutputs endp

ResetInputs proc uses ebx,fDelete:DWORD

	mov		ebx,lpAddin
	push	0
	push	IDC_IMG49
	push	IDC_IMG50
	push	IDC_IMG51
	push	IDC_IMG52
	push	IDC_IMG53
	push	IDC_IMG54
	push	IDC_IMG55
	push	IDC_IMG56
	push	IDC_IMG33
	push	IDC_IMG34
	push	IDC_IMG35
	push	IDC_IMG36
	push	IDC_IMG37
	push	IDC_IMG38
	push	IDC_IMG39
	push	IDC_IMG40
	push	IDC_IMG17
	push	IDC_IMG18
	push	IDC_IMG19
	push	IDC_IMG20
	push	IDC_IMG21
	push	IDC_IMG22
	push	IDC_IMG23
	push	IDC_IMG24
	push	IDC_IMG1
	push	IDC_IMG2
	push	IDC_IMG3
	push	IDC_IMG4
	push	IDC_IMG5
	push	IDC_IMG6
	push	IDC_IMG7
	mov		eax,IDC_IMG8
	.while eax
		invoke SendDlgItemMessage,hDlg,eax,STM_SETIMAGE,IMAGE_BITMAP,[ebx].ADDIN.hBmpRedLed
		.if fDelete
			invoke DeleteObject,eax
		.endif
		pop		eax
	.endw
	mov		eax,0FFh
	mov		[ebx].ADDIN.mminportdata[0],eax
	mov		[ebx].ADDIN.mminportdata[4],eax
	mov		[ebx].ADDIN.mminportdata[8],eax
	mov		[ebx].ADDIN.mminportdata[12],eax
	ret

ResetInputs endp

MMIOProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	buffer[32]:BYTE

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		eax,hWin
		mov		hDlg,eax
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
		push	0
		push	IDC_STCMMO0
		push	IDC_STCMMO1
		push	IDC_STCMMO2
		push	IDC_STCMMO3
		push	IDC_STCMMI3
		push	IDC_STCMMI2
		push	IDC_STCMMI1
		mov		eax,IDC_STCMMI0
		.while eax
			invoke SendDlgItemMessage,hWin,eax,WM_SETFONT,0,FALSE
			pop		eax
		.endw
		mov		eax,-1
		mov		ebx,lpAddin
		mov		[ebx].ADDIN.mmoutport[0],eax
		mov		[ebx].ADDIN.mmoutport[4],eax
		mov		[ebx].ADDIN.mmoutport[8],eax
		mov		[ebx].ADDIN.mmoutport[12],eax
		mov		[ebx].ADDIN.mminport[0],eax
		mov		[ebx].ADDIN.mminport[4],eax
		mov		[ebx].ADDIN.mminport[8],eax
		mov		[ebx].ADDIN.mminport[12],eax
		invoke ResetOutputs,TRUE
		invoke ResetInputs,TRUE
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			mov		ebx,eax
			mov		edi,lpAddin
			invoke IsDlgButtonChecked,hWin,ebx
			.if ebx==IDC_CHKMMO0
				.if eax
					mov		ebx,IDC_EDTADDRMMO0
					call	GetHex
				.else
					mov		eax,-1
				.endif
				mov		[edi].ADDIN.mmoutport[0],eax
			.elseif ebx==IDC_CHKMMO1
				.if eax
					mov		ebx,IDC_EDTADDRMMO1
					call	GetHex
				.else
					mov		eax,-1
				.endif
				mov		[edi].ADDIN.mmoutport[4],eax
			.elseif ebx==IDC_CHKMMO2
				.if eax
					mov		ebx,IDC_EDTADDRMMO2
					call	GetHex
				.else
					mov		eax,-1
				.endif
				mov		[edi].ADDIN.mmoutport[8],eax
			.elseif ebx==IDC_CHKMMO3
				.if eax
					mov		ebx,IDC_EDTADDRMMO3
					call	GetHex
				.else
					mov		eax,-1
				.endif
				mov		[edi].ADDIN.mmoutport[12],eax
			.elseif ebx==IDC_CHKMMI0
				.if eax
					mov		ebx,IDC_EDTADDRMMI0
					call	GetHex
				.else
					mov		eax,-1
				.endif
				mov		[edi].ADDIN.mminport[0],eax
			.elseif ebx==IDC_CHKMMI1
				.if eax
					mov		ebx,IDC_EDTADDRMMI1
					call	GetHex
				.else
					mov		eax,-1
				.endif
				mov		[edi].ADDIN.mminport[4],eax
			.elseif ebx==IDC_CHKMMI2
				.if eax
					mov		ebx,IDC_EDTADDRMMI2
					call	GetHex
				.else
					mov		eax,-1
				.endif
				mov		[edi].ADDIN.mminport[8],eax
			.elseif ebx==IDC_CHKMMI3
				.if eax
					mov		ebx,IDC_EDTADDRMMI3
					call	GetHex
				.else
					mov		eax,-1
				.endif
				mov		[edi].ADDIN.mminport[12],eax
			.elseif ebx>=1110 && ebx<=1117
				;MMI0
				lea		ecx,[ebx-1110]
				mov		edx,01h
				shl		edx,cl
				xor		[edi].ADDIN.mminportdata[0],edx
				mov		eax,[edi].ADDIN.mminportdata[0]
				mov		edx,[edi].ADDIN.mminport[0]
				call	ToggleLed
			.elseif ebx>=1210 && ebx<=1217
				;MMI1
				lea		ecx,[ebx-1210]
				mov		edx,01h
				shl		edx,cl
				xor		[edi].ADDIN.mminportdata[4],edx
				mov		eax,[edi].ADDIN.mminportdata[4]
				mov		edx,[edi].ADDIN.mminport[4]
				call	ToggleLed
			.elseif ebx>=1310 && ebx<=1317
				;MMI2
				lea		ecx,[ebx-1310]
				mov		edx,01h
				shl		edx,cl
				xor		[edi].ADDIN.mminportdata[8],edx
				mov		eax,[edi].ADDIN.mminportdata[8]
				mov		edx,[edi].ADDIN.mminport[8]
				call	ToggleLed
			.elseif ebx>=1410 && ebx<=1417
				;MMI3
				lea		ecx,[ebx-1410]
				mov		edx,01h
				shl		edx,cl
				xor		[edi].ADDIN.mminportdata[12],edx
				mov		eax,[edi].ADDIN.mminportdata[12]
				mov		edx,[edi].ADDIN.mminport[12]
				call	ToggleLed
			.endif
		.elseif edx==EN_KILLFOCUS
			mov		ebx,eax
			invoke GetDlgItemText,hWin,ebx,addr buffer,sizeof buffer
			mov		dword ptr buffer[16],'0000'
			invoke lstrlen,addr buffer
			mov		edx,4
			sub		edx,eax
			invoke lstrcpy,addr buffer[edx+16],addr buffer
			invoke SetDlgItemText,hWin,ebx,addr buffer[16]
			mov		edi,lpAddin
			.if ebx==IDC_EDTADDRMMO0
				.if [edi].ADDIN.mmoutport[0]!=-1
					call	GetHex
					mov		[edi].ADDIN.mmoutport[0],eax
				.endif
			.elseif ebx==IDC_EDTADDRMMO1
				.if [edi].ADDIN.mmoutport[4]!=-1
					call	GetHex
					mov		[edi].ADDIN.mmoutport[4],eax
				.endif
			.elseif ebx==IDC_EDTADDRMMO2
				.if [edi].ADDIN.mmoutport[8]!=-1
					call	GetHex
					mov		[edi].ADDIN.mmoutport[8],eax
				.endif
			.elseif ebx==IDC_EDTADDRMMO3
				.if [edi].ADDIN.mmoutport[12]!=-1
					call	GetHex
					mov		[edi].ADDIN.mmoutport[12],eax
				.endif
			.elseif ebx==IDC_EDTADDRMMI0
				.if [edi].ADDIN.mminport[0]!=-1
					call	GetHex
					mov		[edi].ADDIN.mminport[0],eax
				.endif
			.elseif ebx==IDC_EDTADDRMMI1
				.if [edi].ADDIN.mminport[4]!=-1
					call	GetHex
					mov		[edi].ADDIN.mminport[4],eax
				.endif
			.elseif ebx==IDC_EDTADDRMMI2
				.if [edi].ADDIN.mminport[8]!=-1
					call	GetHex
					mov		[edi].ADDIN.mminport[8],eax
				.endif
			.elseif ebx==IDC_EDTADDRMMI3
				.if [edi].ADDIN.mminport[12]!=-1
					call	GetHex
					mov		[edi].ADDIN.mminport[12],eax
				.endif
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

GetHex:
	invoke GetDlgItemText,hWin,ebx,addr buffer,sizeof buffer
	invoke HexToBin,addr buffer
	retn

ToggleLed:
	.if edx!=-1
		mov		[edi].ADDIN.XRam[edx],al
	.endif
	invoke SendDlgItemMessage,hWin,ebx,STM_GETIMAGE,IMAGE_BITMAP,0
	.if eax==[edi].ADDIN.hBmpGrayLed
		mov		eax,[edi].ADDIN.hBmpRedLed
	.else
		mov		eax,[edi].ADDIN.hBmpGrayLed
	.endif
	invoke SendDlgItemMessage,hWin,ebx,STM_SETIMAGE,IMAGE_BITMAP,eax
	retn

MMIOProc endp

AddinProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	mii:MENUITEMINFO
	LOCAL	buffer[256]:BYTE
	LOCAL	buffer1[16]:BYTE

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
		;Return hook flags
		mov		eax,AH_COMMAND or AH_RESET or AH_REFRESH or AH_PROJECTOPEN or AH_PROJECTCLOSE
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
	.elseif eax==AM_RESET
		invoke ResetOutputs,FALSE
		invoke ResetInputs,FALSE
	.elseif eax==AM_REFRESH
		mov		esi,lpAddin
		push	0
		push	IDC_IMG57
		push	IDC_IMG58
		push	IDC_IMG59
		push	IDC_IMG44
		push	IDC_IMG61
		push	IDC_IMG62
		push	IDC_IMG63
		mov		eax,IDC_IMG32
		mov		edx,[esi].ADDIN.mmoutportdata[0]
		.while eax
			mov		ecx,[esi].ADDIN.hBmpGrayLed
			shl		dl,1
			.if CARRY?
				mov		ecx,[esi].ADDIN.hBmpRedLed
			.endif
			push	edx
			invoke SendDlgItemMessage,hDlg,eax,STM_SETIMAGE,IMAGE_BITMAP,ecx
			pop		edx
			pop		eax
		.endw
		push	0
		push	IDC_IMG41
		push	IDC_IMG42
		push	IDC_IMG43
		push	IDC_IMG60
		push	IDC_IMG45
		push	IDC_IMG46
		push	IDC_IMG47
		mov		eax,IDC_IMG48
		mov		edx,[esi].ADDIN.mmoutportdata[4]
		.while eax
			mov		ecx,[esi].ADDIN.hBmpGrayLed
			shl		dl,1
			.if CARRY?
				mov		ecx,[esi].ADDIN.hBmpRedLed
			.endif
			push	edx
			invoke SendDlgItemMessage,hDlg,eax,STM_SETIMAGE,IMAGE_BITMAP,ecx
			pop		edx
			pop		eax
		.endw
		push	0
		push	IDC_IMG25
		push	IDC_IMG26
		push	IDC_IMG27
		push	IDC_IMG28
		push	IDC_IMG29
		push	IDC_IMG30
		push	IDC_IMG31
		mov		eax,IDC_IMG64
		mov		edx,[esi].ADDIN.mmoutportdata[8]
		.while eax
			mov		ecx,[esi].ADDIN.hBmpGrayLed
			shl		dl,1
			.if CARRY?
				mov		ecx,[esi].ADDIN.hBmpRedLed
			.endif
			push	edx
			invoke SendDlgItemMessage,hDlg,eax,STM_SETIMAGE,IMAGE_BITMAP,ecx
			pop		edx
			pop		eax
		.endw
		push	0
		push	IDC_IMG9
		push	IDC_IMG10
		push	IDC_IMG11
		push	IDC_IMG12
		push	IDC_IMG13
		push	IDC_IMG14
		push	IDC_IMG15
		mov		eax,IDC_IMG16
		mov		edx,[esi].ADDIN.mmoutportdata[12]
		.while eax
			mov		ecx,[esi].ADDIN.hBmpGrayLed
			shl		dl,1
			.if CARRY?
				mov		ecx,[esi].ADDIN.hBmpRedLed
			.endif
			push	edx
			invoke SendDlgItemMessage,hDlg,eax,STM_SETIMAGE,IMAGE_BITMAP,ecx
			pop		edx
			pop		eax
		.endw
		push	0
		push	IDC_IMG49
		push	IDC_IMG50
		push	IDC_IMG51
		push	IDC_IMG52
		push	IDC_IMG53
		push	IDC_IMG54
		push	IDC_IMG55
		mov		eax,IDC_IMG56
		mov		edx,[esi].ADDIN.mminportdata[0]
		.while eax
			mov		ecx,[esi].ADDIN.hBmpGrayLed
			shl		dl,1
			.if CARRY?
				mov		ecx,[esi].ADDIN.hBmpRedLed
			.endif
			push	edx
			invoke SendDlgItemMessage,hDlg,eax,STM_SETIMAGE,IMAGE_BITMAP,ecx
			pop		edx
			pop		eax
		.endw
		push	0
		push	IDC_IMG33
		push	IDC_IMG34
		push	IDC_IMG35
		push	IDC_IMG36
		push	IDC_IMG37
		push	IDC_IMG38
		push	IDC_IMG39
		mov		eax,IDC_IMG40
		mov		edx,[esi].ADDIN.mminportdata[4]
		.while eax
			mov		ecx,[esi].ADDIN.hBmpGrayLed
			shl		dl,1
			.if CARRY?
				mov		ecx,[esi].ADDIN.hBmpRedLed
			.endif
			push	edx
			invoke SendDlgItemMessage,hDlg,eax,STM_SETIMAGE,IMAGE_BITMAP,ecx
			pop		edx
			pop		eax
		.endw
		push	0
		push	IDC_IMG17
		push	IDC_IMG18
		push	IDC_IMG19
		push	IDC_IMG20
		push	IDC_IMG21
		push	IDC_IMG22
		push	IDC_IMG23
		mov		eax,IDC_IMG24
		mov		edx,[esi].ADDIN.mminportdata[8]
		.while eax
			mov		ecx,[esi].ADDIN.hBmpGrayLed
			shl		dl,1
			.if CARRY?
				mov		ecx,[esi].ADDIN.hBmpRedLed
			.endif
			push	edx
			invoke SendDlgItemMessage,hDlg,eax,STM_SETIMAGE,IMAGE_BITMAP,ecx
			pop		edx
			pop		eax
		.endw
		push	0
		push	IDC_IMG1
		push	IDC_IMG2
		push	IDC_IMG3
		push	IDC_IMG4
		push	IDC_IMG5
		push	IDC_IMG6
		push	IDC_IMG7
		mov		eax,IDC_IMG8
		mov		edx,[esi].ADDIN.mminportdata[12]
		.while eax
			mov		ecx,[esi].ADDIN.hBmpGrayLed
			shl		dl,1
			.if CARRY?
				mov		ecx,[esi].ADDIN.hBmpRedLed
			.endif
			push	edx
			invoke SendDlgItemMessage,hDlg,eax,STM_SETIMAGE,IMAGE_BITMAP,ecx
			pop		edx
			pop		eax
		.endw
	.elseif eax==AM_PROJECTOPEN
		invoke GetPrivateProfileString,addr szProMMIO,addr szProMMIO,addr szNULL,addr buffer,sizeof buffer,lParam
		invoke GetItemInt,addr buffer,0
		.if eax
			invoke ShowWindow,hDlg,SW_SHOW
		.else
			invoke ShowWindow,hDlg,SW_HIDE
		.endif
		push	0
		push	IDC_EDTADDRMMI3
		push	IDC_CHKMMI3
		push	IDC_EDTADDRMMI2
		push	IDC_CHKMMI2
		push	IDC_EDTADDRMMI1
		push	IDC_CHKMMI1
		push	IDC_EDTADDRMMI0
		push	IDC_CHKMMI0
		push	IDC_EDTADDRMMO3
		push	IDC_CHKMMO3
		push	IDC_EDTADDRMMO2
		push	IDC_CHKMMO2
		push	IDC_EDTADDRMMO1
		push	IDC_CHKMMO1
		push	IDC_EDTADDRMMO0
		mov		ebx,IDC_CHKMMO0
		.while ebx
			invoke GetItemInt,addr buffer,0
			invoke CheckDlgButton,hDlg,ebx,eax
			invoke GetItemStr,addr buffer,addr szNULL,addr buffer1,sizeof buffer1
			pop		ebx
			invoke SetDlgItemText,hDlg,ebx,addr buffer1
			pop		ebx
		.endw
		invoke SendMessage,hDlg,WM_COMMAND,IDC_CHKMMO0,NULL
		invoke SendMessage,hDlg,WM_COMMAND,IDC_CHKMMO1,NULL
		invoke SendMessage,hDlg,WM_COMMAND,IDC_CHKMMO2,NULL
		invoke SendMessage,hDlg,WM_COMMAND,IDC_CHKMMO3,NULL
		invoke SendMessage,hDlg,WM_COMMAND,IDC_CHKMMI0,NULL
		invoke SendMessage,hDlg,WM_COMMAND,IDC_CHKMMI1,NULL
		invoke SendMessage,hDlg,WM_COMMAND,IDC_CHKMMI2,NULL
		invoke SendMessage,hDlg,WM_COMMAND,IDC_CHKMMI3,NULL
	.elseif eax==AM_PROJECTCLOSE
		mov		buffer,0
		invoke IsWindowVisible,hDlg
		invoke PutItemInt,addr buffer,eax
		push	0
		push	IDC_EDTADDRMMI3
		push	IDC_CHKMMI3
		push	IDC_EDTADDRMMI2
		push	IDC_CHKMMI2
		push	IDC_EDTADDRMMI1
		push	IDC_CHKMMI1
		push	IDC_EDTADDRMMI0
		push	IDC_CHKMMI0
		push	IDC_EDTADDRMMO3
		push	IDC_CHKMMO3
		push	IDC_EDTADDRMMO2
		push	IDC_CHKMMO2
		push	IDC_EDTADDRMMO1
		push	IDC_CHKMMO1
		push	IDC_EDTADDRMMO0
		mov		eax,IDC_CHKMMO0
		.while eax
			invoke IsDlgButtonChecked,hDlg,eax
			invoke PutItemInt,addr buffer,eax
			pop		edx
			invoke GetDlgItemText,hDlg,edx,addr buffer1,sizeof buffer1
			invoke PutItemStr,addr buffer,addr buffer1
			pop		eax
		.endw
		invoke WritePrivateProfileString,addr szProMMIO,addr szProMMIO,addr buffer[1],lParam
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
