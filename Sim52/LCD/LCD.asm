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
	;invoke GetStockObject,GRAY_BRUSH
	mov		wc.hbrBackground,NULL
	mov		wc.lpszMenuName,NULL
	mov		wc.lpszClassName,offset LCDClass
	mov		wc.hIcon,NULL
	mov		wc.hIconSm,NULL
	invoke LoadCursor,0,IDC_ARROW
	mov		wc.hCursor,eax
	invoke RegisterClassEx,addr wc
	mov		databits,8
	ret

InstallLCD endp

UnInstallLCD proc

	.if hDlg
		invoke SendMessage,hDlg,WM_CLOSE,0,0
	.endif
	ret

UnInstallLCD endp

DisplayProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	ps:PAINTSTRUCT
	LOCAL	rect:RECT

	mov		eax,uMsg
	.if eax==WM_CREATE
	.elseif eax==WM_PAINT
		invoke BeginPaint,hWin,addr ps
		mov		eax,0E0E0E0h
		.if BackLight
			mov		eax,12D898h
		.endif
		invoke CreateSolidBrush,eax
		mov		ebx,eax
		invoke FillRect,ps.hdc,addr ps.rcPaint,ebx
		invoke DeleteObject,ebx
		mov		esi,11
		mov		edi,12
		xor		ecx,ecx
		mov		ebx,offset LCDLine1
		.while ecx<16
			push	ebx
			push	ecx
			movzx	eax,byte ptr [ebx]
			call	DrawChar
			pop		ecx
			pop		ebx
			lea		ebx,[ebx+1]
			lea		esi,[esi+6*3]
			lea		ecx,[ecx+1]
		.endw
		mov		esi,12
		mov		edi,11+3*9
		xor		ecx,ecx
		mov		ebx,offset LCDLine2
		.while ecx<16
			push	ebx
			push	ecx
			movzx	eax,byte ptr [ebx]
			call	DrawChar
			pop		ecx
			pop		ebx
			lea		ebx,[ebx+1]
			lea		esi,[esi+6*3]
			lea		ecx,[ecx+1]
		.endw
		invoke EndPaint,hWin,addr ps
	.else
  ExDef:
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
		ret
	.endif
	xor    eax,eax
  Ex:
	ret

DrawDot:
	push	ecx
	mov		rect.left,esi
	lea		eax,[esi+3]
	mov		rect.right,eax
	mov		rect.top,edi
	lea		eax,[edi+3]
	mov		rect.bottom,eax
	invoke GetStockObject,BLACK_BRUSH
	invoke FillRect,ps.hdc,addr rect,eax
	pop		ecx
	retn
	invoke SetPixel,ps.hdc,esi,edi,0
	invoke SetPixel,ps.hdc,addr [esi+1],edi,0
	invoke SetPixel,ps.hdc,addr [esi+2],edi,0
	invoke SetPixel,ps.hdc,esi,addr [edi+1],0
	invoke SetPixel,ps.hdc,addr [esi+1],addr [edi+1],0
	invoke SetPixel,ps.hdc,addr [esi+2],addr [edi+1],0
	invoke SetPixel,ps.hdc,esi,addr [edi+2],0
	invoke SetPixel,ps.hdc,addr [esi+1],addr [edi+2],0
	invoke SetPixel,ps.hdc,addr [esi+2],addr [edi+2],0
	pop		ecx
	retn

DrawChar:
	push	esi
	push	edi
	mov		ebx,7
	mul		ebx
	lea		ebx,[eax+offset CharTab]
	xor		edx,edx
	.while edx<7
		push	ebx
		push	edx
		xor		ecx,ecx
		push	esi
		movzx	ebx,byte ptr [ebx]
		.while ecx<5
			shl		bl,1
			.if CARRY?
				call	DrawDot
			.endif
			lea		esi,[esi+3]
			lea		ecx,[ecx+1]
		.endw
		pop		esi
		pop		edx
		pop		ebx
		lea		ebx,[ebx+1]
		lea		edi,[edi+3]
		lea		edx,[edx+1]
	.endw
	pop		edi
	pop		esi
	retn

DisplayProc endp

GetCBOBits proc

	mov		P0Bits,0
	mov		P1Bits,0
	mov		P2Bits,0
	mov		P3Bits,0
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
	mov		ebx,IDC_CBOE
	.while ebx
		invoke SendDlgItemMessage,hDlg,ebx,CB_GETCURSEL,0,0
		.if ebx==IDC_CBOD0
			mov		DB0,eax
		.elseif ebx==IDC_CBOD1
			mov		DB1,eax
		.elseif ebx==IDC_CBOD2
			mov		DB2,eax
		.elseif ebx==IDC_CBOD3
			mov		DB3,eax
		.elseif ebx==IDC_CBOD4
			mov		DB4,eax
		.elseif ebx==IDC_CBOD5
			mov		DB5,eax
		.elseif ebx==IDC_CBOD6
			mov		DB6,eax
		.elseif ebx==IDC_CBOD7
			mov		DB7,eax
		.elseif ebx==IDC_CBORS
			mov		RS,eax
		.elseif ebx==IDC_CBORW
			mov		RW,eax
		.elseif ebx==IDC_CBOE
			mov		E,eax
		.endif
		.if eax<=NC
		.elseif eax>=P0_0 && eax<=P0_7
			sub		eax,P0_0
			mov		ecx,eax
			mov		eax,01h
			shl		eax,cl
			or		P0Bits,eax
		.elseif eax>=P0_1 && eax<=P1_7
			sub		eax,P1_0
			mov		ecx,eax
			mov		eax,01h
			shl		eax,cl
			or		P1Bits,eax
		.elseif eax>=P0_2 && eax<=P2_7
			sub		eax,P2_0
			mov		ecx,eax
			mov		eax,01h
			shl		eax,cl
			or		P2Bits,eax
		.elseif eax>=P0_3 && eax<=P3_7
			sub		eax,P3_0
			mov		ecx,eax
			mov		eax,01h
			shl		eax,cl
			or		P3Bits,eax
		.endif
		pop		ebx
	.endw
	ret

GetCBOBits endp

LCDProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	rect:RECT

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		eax,hWin
		mov		hDlg,eax
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
		push	GND
		push	IDC_CBOD1
		push	GND
		push	IDC_CBOD2
		push	GND
		push	IDC_CBOD3
		push	GND
		push	IDC_CBOD4
		push	P2_0
		push	IDC_CBOD5
		push	P2_1
		push	IDC_CBOD6
		push	P2_2
		push	IDC_CBOD7
		push	P2_3
		push	IDC_CBORS
		push	P2_4
		push	IDC_CBORW
		push	GND
		mov		eax,IDC_CBOE
		mov		edx,P2_5
		.while eax
			push	edx
			invoke GetDlgItem,hWin,eax
			pop		edx
			invoke SendMessage,eax,CB_SETCURSEL,edx,0
			pop		edx
			pop		eax
		.endw
		invoke GetCBOBits
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==CBN_SELCHANGE
			invoke GetCBOBits
		.elseif edx==BN_CLICKED
			.if eax==IDC_BTNEXPAND
				invoke GetWindowRect,hWin,addr rect
				mov		eax,rect.bottom
				sub		eax,rect.top
				.if eax>=237
					mov		eax,offset szExpand
					mov		edx,127
				.else
					mov		eax,offset szShrink
					mov		edx,237
				.endif
				push	edx
				invoke SetDlgItemText,hWin,IDC_BTNEXPAND,eax
				pop		edx
				mov		eax,rect.right
				sub		eax,rect.left
				invoke MoveWindow,hWin,rect.left,rect.top,eax,edx,TRUE
			.elseif eax==IDC_CHKBACKLIGHT
				xor		BackLight,TRUE
				invoke GetDlgItem,hWin,IDC_LCD
				invoke InvalidateRect,eax,NULL,TRUE
			.endif
		.endif
	.elseif eax==WM_CLOSE
		invoke DestroyWindow,hWin
		mov		hDlg,0
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
	LOCAL	mii:MENUITEMINFO

	mov		eax,uMsg
	.if eax==AM_INIT
		mov		ebx,lParam
		mov		lpAddin,ebx
		mov		mii.cbSize,sizeof MENUITEMINFO
		mov		mii.fMask,MIIM_SUBMENU
		invoke GetMenuItemInfo,[ebx].ADDIN.hMenu,IDM_VIEW,FALSE,addr mii
		invoke AppendMenu,mii.hSubMenu,MF_STRING,[ebx].ADDIN.MenuID,offset szMenuLCD
		mov		eax,[ebx].ADDIN.MenuID
		mov		IDAddin,eax
		inc		[ebx].ADDIN.MenuID
	.elseif eax==AM_PORTCHANGED
		mov		eax,wParam
		.if eax==0 && P0Bits
PrintHex wParam
PrintHex lParam
		.elseif eax==1 && P1Bits
PrintHex wParam
PrintHex lParam
		.elseif eax==2 && P2Bits
PrintHex wParam
PrintHex lParam
		.elseif eax==3 && P3Bits
PrintHex wParam
PrintHex lParam
		.endif
	.elseif eax==AM_COMMAND
		mov		eax,lParam
		.if eax==IDAddin
			invoke CreateDialogParam,hInstance,IDD_DLGLCD,hWin,addr LCDProc,0
		.endif
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
