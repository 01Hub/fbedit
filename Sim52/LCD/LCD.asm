.386
.model flat, stdcall
option casemap :none   ; case sensitive

include LCD.inc

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
	LOCAL	hDC:HDC
	LOCAL	rect:RECT
	LOCAL	dotrect:RECT

	mov		eax,uMsg
	.if eax==WM_CREATE
		mov		eax,hWin
		mov		hLcd,eax
		invoke GetClientRect,hWin,addr rect
		invoke GetDC,hWin
		mov		hDC,eax
		invoke CreateCompatibleDC,hDC
		mov		mDC,eax
		invoke CreateCompatibleBitmap,hDC,rect.right,rect.bottom
		invoke SelectObject,mDC,eax
		mov		hBmp,eax
		invoke ReleaseDC,hWin,hDC
		invoke GetStockObject,BLACK_BRUSH
		mov		hDotBrush,eax
		invoke CreateSolidBrush,12D898h
		mov		hBackBrush,eax
	.elseif eax==WM_PAINT
		invoke BeginPaint,hWin,addr ps
		invoke GetClientRect,hWin,addr rect
		invoke FillRect,mDC,addr rect,hBackBrush
		mov		esi,11
		mov		edi,10
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
			lea		esi,[esi+6*4]
			lea		ecx,[ecx+1]
		.endw
		mov		esi,11
		mov		edi,10+4*8+5
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
			lea		esi,[esi+6*4]
			lea		ecx,[ecx+1]
		.endw
		invoke BitBlt,ps.hdc,0,0,rect.right,rect.bottom,mDC,0,0,SRCCOPY
		invoke EndPaint,hWin,addr ps
	.elseif eax==WM_DESTROY
		invoke DeleteObject,hBackBrush
		invoke SelectObject,mDC,hBmp
		invoke DeleteObject,eax
		invoke DeleteDC,mDC
	.else
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
		ret
	.endif
	xor    eax,eax
	ret

DrawChar:
	push	esi
	push	edi
	mov		ebx,8
	mul		ebx
	lea		ebx,[eax+offset CharTab]
	xor		edx,edx
	.while edx<8
		push	ebx
		push	edx
		xor		ecx,ecx
		push	esi
		movzx	ebx,byte ptr [ebx]
		.while ecx<5
			shl		bl,1
			.if CARRY?
				push	ecx
				mov		dotrect.left,esi
				lea		eax,[esi+3]
				mov		dotrect.right,eax
				mov		dotrect.top,edi
				lea		eax,[edi+3]
				mov		dotrect.bottom,eax
				invoke FillRect,mDC,addr dotrect,hDotBrush
				pop		ecx
			.endif
			lea		esi,[esi+4]
			lea		ecx,[ecx+1]
		.endw
		pop		esi
		pop		edx
		pop		ebx
		lea		ebx,[ebx+1]
		lea		edi,[edi+4]
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
		.elseif eax>=P1_0 && eax<=P1_7
			sub		eax,P1_0
			mov		ecx,eax
			mov		eax,01h
			shl		eax,cl
			or		P1Bits,eax
			mov		edx,1
		.elseif eax>=P2_0 && eax<=P2_7
			sub		eax,P2_0
			mov		ecx,eax
			mov		eax,01h
			shl		eax,cl
			or		P2Bits,eax
			mov		edx,2
		.elseif eax>=P3_0 && eax<=P3_7
			sub		eax,P3_0
			mov		ecx,eax
			mov		eax,01h
			shl		eax,cl
			or		P3Bits,eax
			mov		edx,3
		.elseif eax>=MMO0_0 && eax<=MMO0_7
			sub		eax,MMO0_0
			mov		ecx,eax
			mov		eax,01h
			shl		eax,cl
			or		MMBits[0],eax
			mov		ecx,lpAddin
			mov		edx,[ecx].ADDIN.mmoutport[0]
			mov		MMAddr[0],edx
			push	eax
			push	edx
			.if edx==-1
				invoke SetDlgItemText,hDlg,IDC_STCERROR,addr szError
			.else
				invoke SetDlgItemText,hDlg,IDC_STCERROR,NULL
			.endif
			pop		edx
			pop		eax
		.elseif eax>=MMO1_0 && eax<=MMO1_7
			sub		eax,MMO1_0
			mov		ecx,eax
			mov		eax,01h
			shl		eax,cl
			or		MMBits[4],eax
			mov		ecx,lpAddin
			mov		edx,[ecx].ADDIN.mmoutport[4]
			mov		MMAddr[4],edx
			push	eax
			push	edx
			.if edx==-1
				invoke SetDlgItemText,hDlg,IDC_STCERROR,addr szError
			.else
				invoke SetDlgItemText,hDlg,IDC_STCERROR,NULL
			.endif
			pop		edx
			pop		eax
		.elseif eax>=MMO2_0 && eax<=MMO2_7
			sub		eax,MMO2_0
			mov		ecx,eax
			mov		eax,01h
			shl		eax,cl
			or		MMBits[8],eax
			mov		ecx,lpAddin
			mov		edx,[ecx].ADDIN.mmoutport[8]
			mov		MMAddr[8],edx
			push	eax
			push	edx
			.if edx==-1
				invoke SetDlgItemText,hDlg,IDC_STCERROR,addr szError
			.else
				invoke SetDlgItemText,hDlg,IDC_STCERROR,NULL
			.endif
			pop		edx
			pop		eax
		.elseif eax>=MMO3_0 && eax<=MMO3_7
			sub		eax,MMO3_0
			mov		ecx,eax
			mov		eax,01h
			shl		eax,cl
			or		MMBits[12],eax
			mov		ecx,lpAddin
			mov		edx,[ecx].ADDIN.mmoutport[12]
			mov		MMAddr[12],edx
			push	eax
			push	edx
			.if edx==-1
				invoke SetDlgItemText,hDlg,IDC_STCERROR,addr szError
			.else
				invoke SetDlgItemText,hDlg,IDC_STCERROR,NULL
			.endif
			pop		edx
			pop		eax
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
	LOCAL	buffer[32]:BYTE

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
		mov		edx,142
		invoke MoveWindow,hWin,rect.left,rect.top,eax,edx,TRUE
		invoke CheckDlgButton,hWin,IDC_CHKBACKLIGHT,BST_CHECKED
		mov		BackLight,1
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
				.if eax==142
					mov		eax,offset szShrink
					mov		edx,252
				.else
					mov		eax,offset szExpand
					mov		edx,142
				.endif
				push	edx
				invoke SetDlgItemText,hWin,IDC_BTNEXPAND,eax
				pop		edx
				mov		eax,rect.right
				sub		eax,rect.left
				invoke MoveWindow,hWin,rect.left,rect.top,eax,edx,TRUE
			.elseif eax==IDC_CHKBACKLIGHT
				invoke DeleteObject,hBackBrush
				xor		BackLight,TRUE
				.if BackLight
					mov		eax,12D898h
				.else
					mov		eax,0E0E0E0h
				.endif
				invoke CreateSolidBrush,eax
				mov		hBackBrush,eax
				invoke InvalidateRect,hLcd,NULL,TRUE
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
	LOCAL	buffer[256]:BYTE

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
		invoke CreateDialogParam,hInstance,IDD_DLGLCD,hWin,addr LCDProc,0
	.elseif eax==AM_PORTWRITE
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
	.elseif eax==AM_MMPORTWRITE
		mov		eax,wParam
		mov		edx,lParam
		xor		ebx,ebx
		.while ebx<4
			.if eax==MMAddr[ebx*4] && MMBits[ebx*4]!=0
				call	SetData
				.break
			.endif
			inc		ebx
		.endw
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
		mov		LCDDB,8
		mov		LCDNIBBLE,0
		mov		LCDData,7FFh
		mov		edi,offset LCDDDRAM
		mov		ecx,128/4
		mov		eax,20202020h
		rep		stosd
		mov		LCDDDRAMADDR,0
		invoke InvalidateRect,hLcd,NULL,TRUE
	.elseif eax==AM_REFRESH
		invoke InvalidateRect,hLcd,NULL,TRUE
	.elseif eax==AM_PROJECTOPEN
		invoke GetPrivateProfileString,addr szProLCD,addr szProLCD,addr szNULL,addr buffer,sizeof buffer,lParam
		invoke GetItemInt,addr buffer,0
		.if eax
			invoke ShowWindow,hDlg,SW_SHOW
		.else
			invoke ShowWindow,hDlg,SW_HIDE
		.endif
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
		.while ebx
			invoke GetItemInt,addr buffer,0
			invoke SendDlgItemMessage,hDlg,ebx,CB_SETCURSEL,eax,0
			pop		ebx
		.endw
		invoke GetCBOBits
	.elseif eax==AM_PROJECTCLOSE
		;Save settings to project file
		mov		buffer,0
		invoke IsWindowVisible,hDlg
		invoke PutItemInt,addr buffer,eax
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
		mov		eax,IDC_CBOD0
		.while eax
			invoke SendDlgItemMessage,hDlg,eax,CB_GETCURSEL,0,0
			invoke PutItemInt,addr buffer,eax
			pop		eax
		.endw
		invoke WritePrivateProfileString,addr szProLCD,addr szProLCD,addr buffer[1],lParam
	.endif
	xor		eax,eax
	ret

LcdDataWrite:
	.if LCDCG
		mov		edx,LCDCGRAMADDR
		mov		LCDCGRAM[edx],al
		inc		LCDCGRAMADDR
		and		LCDCGRAMADDR,3Fh
	.else
		mov		edx,LCDDDRAMADDR
		mov		LCDDDRAM[edx],al
		inc		LCDDDRAMADDR
		and		LCDDDRAMADDR,7Fh
	.endif
	retn

LcdCommandWrite:
	.if eax & 80h
		;1	AC6	AC5	AC4	AC3	AC2	AC1	AC0		Set DDRAM address
		and		eax,7Fh
		mov		LCDDDRAMADDR,eax
	.elseif eax & 40h
		;0	1	AC5	AC4	AC3	AC2	AC1	AC0		Set CGRAM address
		and		eax,3Fh
		mov		LCDDDRAMADDR,eax
	.elseif eax & 20h
		;0	0	1	DL	N	F	x	x		DL 8/4 databits, N lines 2/1, F font 5x11/5x8
		test	eax,10h
		.if !ZERO?
			mov		LCDDB,8
			mov		LCDNIBBLE,0
		.elseif LCDDB!=4
			mov		LCDDB,4
			mov		LCDNibbleData,eax
			mov		LCDNIBBLE,1
		.endif
		test	eax,08h
		.if !ZERO?
			mov		LCDDL,1
		.else
			mov		LCDDL,0
		.endif
		test	eax,04h
		.if !ZERO?
			mov		LCDF,1
		.else
			mov		LCDF,0
		.endif
	.elseif eax & 10h
		;0	0	0	1	S/C	R/L	x	x		Cursor and display shift direction
		test	eax,08h
		.if !ZERO?
		.else
		.endif
		test	eax,04h
		.if !ZERO?
			mov		LCDDSD,1
		.else
			mov		LCDDSD,0
		.endif
	.elseif eax & 08h
		;0	0	0	0	1	D	C	B		D display on, C cursor on, B cursor position on
		test	eax,04h
		.if !ZERO?
			mov		LCDDON,1
		.else
			mov		LCDDON,0
		.endif
		test	eax,02h
		.if !ZERO?
			mov		LCDCON,1
		.else
			mov		LCDCON,0
		.endif
		test	eax,01h
		.if !ZERO?
			mov		LCDCPON,1
		.else
			mov		LCDCPON,0
		.endif
	.elseif eax & 04h
		;0	0	0	0	0	1	I/D	S		Set cursor direction and display shift on/off
		test	eax,02h
		.if !ZERO?
			mov		LCDCD,1
		.else
			mov		LCDCD,0
		.endif
		test	eax,01h
		.if !ZERO?
			mov		LCDDSON,1
		.else
			mov		LCDDSON,0
		.endif
	.elseif eax & 02h
		;0	0	0	0	0	0	1	x		Set DDRAM address to 00h and home the cursor
		mov		LCDDDRAMADDR,0
	.elseif eax & 01h
		;0	0	0	0	0	0	0	1		Write 20h to DDRAM and set DDRAM address to 00h
		mov		edi,offset LCDDDRAM
		mov		ecx,128/4
		mov		eax,20202020h
		rep		stosd
		mov		LCDDDRAMADDR,0
	.endif
	retn

;eax=portaddress, edx=portdata
SetData:
	push	LCDData
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
				;GND or NC. Reset bit
				mov		eax,[esi].LCDBIT.lcdbit
				xor		eax,7FFh
				and		LCDData,eax
			.endif
			pop		eax
		.endif
		inc		ecx
		lea		esi,[esi+sizeof LCDBIT]
	.endw
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
							call	LcdDataWrite
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
								call	LcdDataWrite
							.endif
						.endif
					.else
						;Command
						and		eax,0FFh
						.if LCDDB==8
							;8 bit mode
							call	LcdCommandWrite
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
								call	LcdCommandWrite
							.endif
						.endif
					.endif
				.endif
			.endif
		.endif
	.endif
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
