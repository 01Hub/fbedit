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
	mov		wc.hbrBackground,NULL
	mov		wc.lpszMenuName,NULL
	mov		wc.lpszClassName,offset LCDClass
	mov		wc.hIcon,NULL
	mov		wc.hIconSm,NULL
	invoke LoadCursor,0,IDC_ARROW
	mov		wc.hCursor,eax
	invoke RegisterClassEx,addr wc
	ret

InstallLCD endp

UnInstallLCD proc

	invoke DestroyWindow,hDlg
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
		mov		ebx,offset LCDDDRAM
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
		mov		ebx,offset LCDDDRAM+40h
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
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
		ret
	.endif
	xor    eax,eax
	ret

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
				push	ecx
				mov		rect.left,esi
				lea		eax,[esi+3]
				mov		rect.right,eax
				mov		rect.top,edi
				lea		eax,[edi+3]
				mov		rect.bottom,eax
				invoke FillRect,ps.hdc,addr rect,hBrush
				pop		ecx
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

GetCBOBits proc uses ebx edi
	LOCAL	nlcdbit:DWORD

	mov		P0Bits,0
	mov		P1Bits,0
	mov		P2Bits,0
	mov		P3Bits,0
	mov		nlcdbit,1
	push	0
	push	IDC_CBOE
	push	IDC_CBORW
	push	IDC_CBORS
	push	IDC_CBOD7
	push	IDC_CBOD6
	push	IDC_CBOD5
	push	IDC_CBOD4
	push	IDC_CBOD3
	push	IDC_CBOD2
	push	IDC_CBOD1
	mov		ebx,IDC_CBOD0
	mov		edi,offset lcdbit
	.while ebx
		invoke SendDlgItemMessage,hDlg,ebx,CB_GETCURSEL,0,0
		.if eax>=GND && eax<=NC
			mov		edx,-1
		.elseif eax>=P0_0 && eax<=P0_7
			sub		eax,P0_0
			mov		ecx,eax
			mov		eax,01h
			shl		eax,cl
			or		P0Bits,eax
			mov		edx,0
		.elseif eax>=P0_1 && eax<=P1_7
			sub		eax,P1_0
			mov		ecx,eax
			mov		eax,01h
			shl		eax,cl
			or		P1Bits,eax
			mov		edx,1
		.elseif eax>=P0_2 && eax<=P2_7
			sub		eax,P2_0
			mov		ecx,eax
			mov		eax,01h
			shl		eax,cl
			or		P2Bits,eax
			mov		edx,2
		.elseif eax>=P0_3 && eax<=P3_7
			sub		eax,P3_0
			mov		ecx,eax
			mov		eax,01h
			shl		eax,cl
			or		P3Bits,eax
			mov		edx,3
		.endif
		mov		[edi].LCDBIT.port,edx
		mov		[edi].LCDBIT.portbit,eax
		mov		eax,nlcdbit
		mov		[edi].LCDBIT.lcdbit,eax
		pop		ebx
		shl		nlcdbit,1
		lea		edi,[edi+sizeof LCDBIT]
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
		invoke GetWindowRect,hWin,addr rect
		mov		eax,rect.right
		sub		eax,rect.left
		mov		edx,127
		invoke MoveWindow,hWin,rect.left,rect.top,eax,edx,TRUE
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
		invoke ShowWindow,hWin,SW_HIDE
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
		invoke GetStockObject,BLACK_BRUSH
		mov		hBrush,eax
		invoke CreateDialogParam,hInstance,IDD_DLGLCD,hWin,addr LCDProc,0
	.elseif eax==AM_PORTCHANGED
		push	LCDData
		mov		eax,wParam
		mov		edx,lParam
		.if eax==0 && P0Bits
			call	SetData
		.elseif eax==1 && P1Bits
			call	SetData
		.elseif eax==2 && P2Bits
			call	SetData
		.elseif eax==3 && P3Bits
			call	SetData
		.endif
		;Check for a high to low transition on E
		mov		eax,LCDData
		pop		edx
		.if eax!=edx
			test	eax,BITE
			.if ZERO?
				test	edx,BITE
				.if !ZERO?
					test	eax,BITRW
					.if !ZERO?
						;Read
					.else
						;Write
						test	eax,BITRS
						.if !ZERO?
							;Data
							and		eax,0FFh
							.if LCDDB==8
								;8 bit mode
								call	LcdData
							.else
								;4 bit mode
								.if !LCDNIBBLE
									;First nibble
									and		eax,0F0h
									mov		LCDNibbleData,eax
									mov		LCDNIBBLE,1
								.else
									;Second nibble
									and		eax,0F0h
									shr		eax,4
									or		eax,LCDNibbleData
									mov		LCDNIBBLE,0
									call	LcdData
								.endif
							.endif
						.else
							;Command
							and		eax,0FFh
							.if LCDDB==8
								;8 bit mode
								call	LcdCommand
							.else
								;4 bit mode
								.if !LCDNIBBLE
									;First nibble
									and		eax,0F0h
									mov		LCDNibbleData,eax
									mov		LCDNIBBLE,1
								.else
									;Second nibble
									and		eax,0F0h
									shr		eax,4
									or		eax,LCDNibbleData
									mov		LCDNIBBLE,0
									call	LcdCommand
								.endif
							.endif
						.endif
					.endif
				.endif
			.endif
		.endif
	.elseif eax==AM_COMMAND
		mov		eax,lParam
		.if eax==IDAddin
			invoke ShowWindow,hDlg,SW_SHOW
		.endif
	.elseif eax==AM_RESET
		mov		LCDDB,8
		mov		LCDNIBBLE,0
		mov		LCDData,7FFh
		mov		edi,offset LCDDDRAM
		mov		ecx,128/4
		mov		eax,20202020h
		rep		stosd
		mov		LCDDDRAMAddr,0
		invoke GetDlgItem,hDlg,IDC_LCD
		invoke InvalidateRect,eax,NULL,TRUE
	.endif
	ret

LcdData:
PrintHex eax
	retn

LcdCommand:
	.if eax>=80h
	.elseif eax>=40h
	.elseif eax>=20h
		test	eax,10h
		.if !ZERO?
			mov		LCDDB,8
			mov		LCDNIBBLE,0
		.else
			mov		LCDDB,4
			mov		LCDNibbleData,eax
			mov		LCDNIBBLE,1
		.endif
	.elseif eax>=10h
	.elseif eax>=08h
	.elseif eax>=04h
	.elseif eax>=02h
	.elseif eax>=01h
	.endif
	retn

SetData:
	xor		ecx,ecx
	mov		esi,offset lcdbit
	.while ecx<8+3
		.if eax==[esi].LCDBIT.port
			push	eax
			test	edx,[esi].LCDBIT.portbit
			.if ZERO?
				;Reset bit
				mov		eax,[esi].LCDBIT.lcdbit
				xor		eax,7FFh
				and		LCDData,eax
			.else
				;Set bit
				mov		eax,[esi].LCDBIT.lcdbit
				or		LCDData,eax
			.endif
			pop		eax
		.elseif [esi].LCDBIT.port==-1
			push	eax
			.if [esi].LCDBIT.portbit==1
				;VCC. Set bit
				mov		eax,[esi].LCDBIT.lcdbit
				or		LCDData,eax
			.else
				;GND, NC. Reset bit
				mov		eax,[esi].LCDBIT.lcdbit
				xor		eax,7FFh
				and		LCDData,eax
			.endif
			pop		eax
		.endif
		inc		ecx
		lea		esi,[esi+sizeof LCDBIT]
	.endw
	retn

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
