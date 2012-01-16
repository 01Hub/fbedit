.386
.model flat, stdcall
option casemap :none   ; case sensitive

include GLCD.inc

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
	mov		wc.lpszClassName,offset GLCDClass
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
	LOCAL	tattrib:DWORD

	mov		eax,uMsg
	.if eax==WM_CREATE
		mov		eax,hWin
		mov		hLcd,eax
		invoke MoveWindow,hWin,0,0,XPIX*2+6,YPIX*2+6,FALSE
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
		invoke RtlZeroMemory,addr glcd.scrn,sizeof GLCD.scrn
		.if glcd.gon
			;Graphics on
			mov		esi,glcd.ghome
			xor		edi,edi
			.while edi<XPIX*YPIX
				call	DrawGLine
				lea		edi,[edi+XPIX]
			.endw
		.endif
		.if glcd.ton
			;Text on
			mov		esi,glcd.thome
			xor		edi,edi
			.while edi<XPIX*YPIX
				call	DrawTLine
				lea		edi,[edi+XPIX*8]
			.endw
		.endif
		.if glcd.con
			call	DrawCursor
		.endif
		xor		ebx,ebx
		xor		edi,edi
		xor		esi,esi
		.while esi<sizeof GLCD.scrn
			.if glcd.scrn[esi]
				lea		edx,[ebx*2+1]
				mov		dotrect.left,edx
				lea		edx,[edx+2]
				mov		dotrect.right,edx
				lea		edx,[edi*2+1]
				mov		dotrect.top,edx
				lea		edx,[edx+2]
				mov		dotrect.bottom,edx
				invoke FillRect,mDC,addr dotrect,hDotBrush
			.endif
			inc		esi
			inc		ebx
			.if ebx==XPIX
				xor		ebx,ebx
				inc		edi
			.endif
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

DrawGByte:
	.if glcdbit.bitval[GLCDBIT_FS]
		;Font 6x8
		push	ebx
		shl		eax,2
		lea		ecx,[ebx*2]
		lea		ebx,[ebx*4+ecx]
		xor		ecx,ecx
		.while ecx<6
			test	eax,80h
			.if !ZERO?
				lea		edx,[ebx+ecx]
				mov		glcd.scrn[edi+edx],TRUE
			.endif
			shl		eax,1
			inc		ecx
		.endw
		pop		ebx
	.else
		;Font 8x8
		xor		ecx,ecx
		.while ecx<8
			test	eax,80h
			.if !ZERO?
				lea		edx,[ebx*8+ecx]
				mov		glcd.scrn[edi+edx],TRUE
			.endif
			shl		eax,1
			inc		ecx
		.endw
	.endif
	retn

DrawGLine:
	xor		ebx,ebx
	.while ebx<glcd.gcol
		and		esi,0FFFFh
		movzx	eax,glcd.ram[esi]
		call	DrawGByte
		inc		esi
		inc		ebx
	.endw
	retn

DrawTCharOR:
	push	esi
	xor		edx,edx
	.if eax>=80h || glcd.ecg
		;CG RAM
		mov		esi,glcd.chome
		lea		esi,[esi+eax*8+offset glcd.ram]
	.else
		;CG ROM
		lea		esi,[eax*8+offset CharTab]
	.endif
	.while edx<XPIX*8
		xor		ecx,ecx
		movzx	eax,byte ptr [esi]
		push	edx
		lea		edx,[edi+edx]
		.if glcdbit.bitval[GLCDBIT_FS]
			;Font 6x8
			lea		edx,[edx+ebx*2]
			lea		edx,[edx+ebx*4]
			shl		eax,2
			.while ecx<6
				test	eax,80h
				.if !ZERO?
					mov		glcd.scrn[edx+ecx],TRUE
				.endif
				shl		eax,1
				inc		ecx
			.endw
		.else
			;Font 8x8
			lea		edx,[edx+ebx*8]
			.while ecx<8
				test	eax,80h
				.if !ZERO?
					mov		glcd.scrn[edx+ecx],TRUE
				.endif
				shl		eax,1
				inc		ecx
			.endw
		.endif
		pop		edx
		inc		esi
		lea		edx,[edx+XPIX]
	.endw
	pop		esi
	retn

DrawTCharEXOR:
	push	esi
	xor		edx,edx
	.if eax>=80h || glcd.ecg
		;CG RAM
		mov		esi,glcd.chome
		lea		esi,[esi+eax*8+offset glcd.ram]
	.else
		;CG ROM
		lea		esi,[eax*8+offset CharTab]
	.endif
	.while edx<XPIX*8
		xor		ecx,ecx
		movzx	eax,byte ptr [esi]
		push	edx
		lea		edx,[edi+edx]
		.if glcdbit.bitval[GLCDBIT_FS]
			;Font 6x8
			lea		edx,[edx+ebx*2]
			lea		edx,[edx+ebx*4]
			shl		eax,2
			.while ecx<6
				test	eax,80h
				.if !ZERO?
					xor		glcd.scrn[edx+ecx],TRUE
				.endif
				shl		eax,1
				inc		ecx
			.endw
		.else
			;Font 8x8
			lea		edx,[edx+ebx*8]
			.while ecx<8
				test	eax,80h
				.if !ZERO?
					xor		glcd.scrn[edx+ecx],TRUE
				.endif
				shl		eax,1
				inc		ecx
			.endw
		.endif
		pop		edx
		inc		esi
		lea		edx,[edx+XPIX]
	.endw
	pop		esi
	retn

DrawTCharAND:
	push	esi
	xor		edx,edx
	.if eax>=80h || glcd.ecg
		;CG RAM
		mov		esi,glcd.chome
		lea		esi,[esi+eax*8+offset glcd.ram]
	.else
		;CG ROM
		lea		esi,[eax*8+offset CharTab]
	.endif
	.while edx<XPIX*8
		xor		ecx,ecx
		movzx	eax,byte ptr [esi]
		push	edx
		lea		edx,[edi+edx]
		.if glcdbit.bitval[GLCDBIT_FS]
			;Font 6x8
			lea		edx,[edx+ebx*2]
			lea		edx,[edx+ebx*4]
			shl		eax,2
			.while ecx<6
				test	eax,80h
				.if !ZERO?
					and		glcd.scrn[edx+ecx],TRUE
				.else
					mov		glcd.scrn[edx+ecx],FALSE
				.endif
				shl		eax,1
				inc		ecx
			.endw
		.else
			;Font 8x8
			lea		edx,[edx+ebx*8]
			.while ecx<8
				test	eax,80h
				.if !ZERO?
					and		glcd.scrn[edx+ecx],TRUE
				.else
					mov		glcd.scrn[edx+ecx],FALSE
				.endif
				shl		eax,1
				inc		ecx
			.endw
		.endif
		pop		edx
		inc		esi
		lea		edx,[edx+XPIX]
	.endw
	pop		esi
	retn

DrawTCharATTRIBUTE:
	push	esi
	xor		edx,edx
	.if eax>=80h || glcd.ecg
		;CG RAM
		mov		esi,glcd.chome
		lea		esi,[esi+eax*8+offset glcd.ram]
	.else
		;CG ROM
		lea		esi,[eax*8+offset CharTab]
	.endif
	.while edx<XPIX*8
		mov		ecx,tattrib
		movzx	eax,byte ptr [esi]
		test	ecx,08h					;Blink
		.if ZERO?
			;No blink
			.if ecx==1
				;Reverse display
				xor		eax,0FFh
			.elseif ecx==3
				;Inhibit display
				xor		eax,eax				
			.endif
		.else
			;Blink
			and		ecx,07h
			.if ecx==0
				;Blink of normal display
				.if glcd.fblink
					xor		eax,eax
				.endif
			.elseif ecx==1
				;Blink of reverse display
				.if glcd.fblink
					xor		eax,0FFh
				.endif
			.elseif ecx==3
				;Blink of inhibit display
				.if !glcd.fblink
					xor		eax,eax
				.endif
			.endif
		.endif
		push	edx
		lea		edx,[edi+edx]
		xor		ecx,ecx
		.if glcdbit.bitval[GLCDBIT_FS]
			;Font 6x8
			lea		edx,[edx+ebx*2]
			lea		edx,[edx+ebx*4]
			shl		eax,2
			.while ecx<6
				test	eax,80h
				.if !ZERO?
					mov		glcd.scrn[edx+ecx],TRUE
				.endif
				shl		eax,1
				inc		ecx
			.endw
		.else
			;Font 8x8
			lea		edx,[edx+ebx*8]
			.while ecx<8
				test	eax,80h
				.if !ZERO?
					mov		glcd.scrn[edx+ecx],TRUE
				.endif
				shl		eax,1
				inc		ecx
			.endw
		.endif
		pop		edx
		inc		esi
		lea		edx,[edx+XPIX]
	.endw
	pop		esi
	retn

DrawTLine:
	xor		ebx,ebx
	.while ebx<glcd.tcol
		and		esi,0FFFFh
		movzx	eax,glcd.ram[esi]
		.if glcd.mode==0
			call	DrawTCharOR
		.elseif glcd.mode==1
			call	DrawTCharEXOR
		.elseif glcd.mode==3
			call	DrawTCharAND
		.elseif glcd.mode==4
			mov		edx,esi
			sub		edx,glcd.thome
			add		edx,glcd.ghome
			movzx	edx,glcd.ram[edx]
			mov		tattrib,edx
			call	DrawTCharATTRIBUTE
		.endif
		inc		esi
		inc		ebx
	.endw
	retn

DrawCursor:
	.if glcd.fblink && glcd.bon
		retn
	.endif
	mov		eax,glcd.cp
	movzx	ecx,al				;x
	movzx	edx,ah				;y
	mov		eax,XPIX*8
	mul		edx
	mov		edx,eax
	push	edx
	xor		edx,edx
	mov		eax,8
	.if glcdbit.bitval[GLCDBIT_FS]
		mov		eax,6
	.endif
	mul		ecx
	mov		ecx,eax
	pop		edx
	mov		edi,7
	.while sdword ptr edi>=0
		.if edi<=glcd.cur
			xor		ebx,ebx
			.if glcdbit.bitval[GLCDBIT_FS]
				;Font 6x8
				.while ebx<6
					lea		eax,[edx+ecx]
					xor		glcd.scrn[eax+ebx],TRUE
					inc		ebx
				.endw
			.else
				;Font 8x8
				.while ebx<8
					lea		eax,[edx+ecx]
					xor		glcd.scrn[eax+ebx],TRUE
					inc		ebx
				.endw
			.endif
		.endif
		dec		edi
		lea		edx,[edx+XPIX]
	.endw
	retn

DisplayProc endp

GetCBOBits proc uses ebx edi

	mov		P0Bits,0
	mov		P1Bits,0
	mov		P2Bits,0
	mov		P3Bits,0
	invoke SendDlgItemMessage,hDlg,IDC_CBODATA,CB_GETCURSEL,0,0
	shl		eax,4
	or		al,80h
	mov		glcd.port,eax
	push	0
	push	IDC_CBOFS
	push	IDC_CBOMD
	push	IDC_CBORST
	push	IDC_CBOW
	push	IDC_CBOR
	push	IDC_CBOCD
	mov		ebx,IDC_CBOCS
	mov		edi,offset glcdbit
	.while ebx
		invoke SendDlgItemMessage,hDlg,ebx,CB_GETCURSEL,0,0
		.if eax==GND
			mov		[edi].GLCDBIT.bitval,FALSE
			xor		eax,eax
			mov		edx,-1
		.elseif eax==VCC
			mov		[edi].GLCDBIT.bitval,TRUE
			xor		eax,eax
			mov		edx,-1
		.elseif eax>=P0_0 && eax<=P0_7
			sub		eax,P0_0
			mov		ecx,eax
			mov		eax,01h
			shl		eax,cl
			or		P0Bits,eax
			mov		edx,SFR_P0
		.elseif eax>=P1_0 && eax<=P1_7
			sub		eax,P1_0
			mov		ecx,eax
			mov		eax,01h
			shl		eax,cl
			or		P1Bits,eax
			mov		edx,SFR_P1
		.elseif eax>=P2_0 && eax<=P2_7
			sub		eax,P2_0
			mov		ecx,eax
			mov		eax,01h
			shl		eax,cl
			or		P2Bits,eax
			mov		edx,SFR_P2
		.elseif eax>=P3_0 && eax<=P3_7
			sub		eax,P3_0
			mov		ecx,eax
			mov		eax,01h
			shl		eax,cl
			or		P3Bits,eax
			mov		edx,SFR_P3
		.endif
		mov		[edi].GLCDBIT.port,edx
		mov		[edi].GLCDBIT.portbit,eax
		pop		ebx
		lea		edi,[edi+sizeof GLCDBIT]
	.endw
	ret

GetCBOBits endp

GLCDProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	rect:RECT
	LOCAL	buffer[32]:BYTE

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		eax,hWin
		mov		hDlg,eax
		mov		esi,offset szPorts
		.while byte ptr [esi]
			invoke SendDlgItemMessage,hWin,IDC_CBODATA,CB_ADDSTRING,0,esi
			invoke lstrlen,esi
			lea		esi,[esi+eax+1]
		.endw
		invoke SendDlgItemMessage,hWin,IDC_CBODATA,CB_SETCURSEL,2,0
		push	0
		push	IDC_CBOCS
		push	IDC_CBOCD
		push	IDC_CBOR
		push	IDC_CBOW
		push	IDC_CBORST
		push	IDC_CBOMD
		mov		eax,IDC_CBOFS
		.while eax
			call	InitCbo
			pop		eax
		.endw
		push	0
		push	P1_0
		push	IDC_CBOCS
		push	P1_1
		push	IDC_CBOCD
		push	P1_2
		push	IDC_CBOR
		push	P1_3
		push	IDC_CBOW
		push	P1_4
		push	IDC_CBORST
		push	P1_5
		push	IDC_CBOMD
		push	P1_6
		mov		eax,IDC_CBOFS
		.while eax
			invoke GetDlgItem,hWin,eax
			pop		edx
			invoke SendMessage,eax,CB_SETCURSEL,edx,0
			pop		eax
		.endw
		invoke GetCBOBits
		invoke GetWindowRect,hWin,addr rect
		mov		eax,rect.right
		sub		eax,rect.left
		mov		edx,317
		invoke MoveWindow,hWin,rect.left,rect.top,eax,edx,TRUE
		invoke CheckDlgButton,hWin,IDC_CHKBACKLIGHT,BST_CHECKED
		mov		BackLight,1
		invoke SetTimer,hWin,1000,500,NULL
	.elseif eax==WM_TIMER
		xor		glcd.fblink,TRUE
		.if fActive && glcd.con && glcd.bon
			;Blinking cursor
			mov		fChanged,TRUE
		.elseif fActive && glcd.mode==4
			;Text attribute mode
			mov		fChanged,TRUE
		.endif
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==CBN_SELCHANGE
			mov		fChanged,TRUE
			invoke GetCBOBits
		.elseif edx==BN_CLICKED
			.if eax==IDC_BTNEXPAND
				invoke GetWindowRect,hWin,addr rect
				mov		eax,rect.bottom
				sub		eax,rect.top
				.if eax==317
					mov		eax,offset szShrink
					mov		edx,525
				.else
					mov		eax,offset szExpand
					mov		edx,317
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
			.elseif eax==IDC_CHKACTIVE
				xor		fActive,TRUE
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

GLCDProc endp

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
		invoke AppendMenu,mii.hSubMenu,MF_STRING,[ebx].ADDIN.MenuID,offset szMenuGLCD
		mov		eax,[ebx].ADDIN.MenuID
		mov		IDAddin,eax
		inc		[ebx].ADDIN.MenuID
		invoke CreateDialogParam,hInstance,IDD_DLGGLCD,hWin,addr GLCDProc,0
		;Return hook flags
		mov		eax,AH_PORTWRITE or AH_COMMAND or AH_RESET or AH_REFRESH or AH_PROJECTOPEN or AH_PROJECTCLOSE
		jmp		Ex
	.elseif eax==AM_PORTWRITE
		.if fActive
			mov		eax,wParam
			shl		eax,4
			or		eax,80h
			mov		edx,lParam
			.if eax==SFR_P0 && P0Bits
				call	SetData
			.elseif eax==SFR_P1 && P1Bits
				call	SetData
			.elseif eax==SFR_P2 && P2Bits
				call	SetData
			.elseif eax==SFR_P3 && P3Bits
				call	SetData
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
	.elseif eax==AM_RESET
		invoke RtlZeroMemory,addr glcd,sizeof GLCD
		xor		ecx,ecx
		mov		esi,offset glcdbit
		.while ecx<7
			;Set bit
			mov		[esi].GLCDBIT.bitval,TRUE
			mov		[esi].GLCDBIT.oldbitval,TRUE
			inc		ecx
			lea		esi,[esi+sizeof GLCDBIT]
		.endw
		invoke GetCBOBits
		.if fActive
			invoke InvalidateRect,hLcd,NULL,TRUE
		.endif
	.elseif eax==AM_REFRESH
		.if fActive && fChanged
			mov		fChanged,FALSE
			invoke InvalidateRect,hLcd,NULL,TRUE
		.endif
	.elseif eax==AM_PROJECTOPEN
		invoke GetPrivateProfileString,addr szProGLCD,addr szProGLCD,addr szNULL,addr buffer,sizeof buffer,lParam
		invoke GetItemInt,addr buffer,0
		.if eax
			invoke ShowWindow,hDlg,SW_SHOW
		.else
			invoke ShowWindow,hDlg,SW_HIDE
		.endif
		invoke GetItemInt,addr buffer,2
		invoke SendDlgItemMessage,hDlg,IDC_CBODATA,CB_SETCURSEL,eax,0
		push	0
		push	P1_0
		push	IDC_CBOCS
		push	P1_1
		push	IDC_CBOCD
		push	P1_2
		push	IDC_CBOR
		push	P1_3
		push	IDC_CBOW
		push	P1_4
		push	IDC_CBORST
		push	P1_5
		push	IDC_CBOMD
		push	P1_6
		mov		ebx,IDC_CBOFS
		.while ebx
			pop		eax
			invoke GetItemInt,addr buffer,eax
			invoke SendDlgItemMessage,hDlg,ebx,CB_SETCURSEL,eax,0
			pop		ebx
		.endw
		invoke GetItemInt,addr buffer,0
		mov		fActive,eax
		invoke CheckDlgButton,hDlg,IDC_CHKACTIVE,eax
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
		invoke GetCBOBits
	.elseif eax==AM_PROJECTCLOSE
		;Save settings to project file
		mov		buffer,0
		invoke IsWindowVisible,hDlg
		invoke PutItemInt,addr buffer,eax
		invoke SendDlgItemMessage,hDlg,IDC_CBODATA,CB_GETCURSEL,0,0
		invoke PutItemInt,addr buffer,eax
		push	0
		push	IDC_CBOCS
		push	IDC_CBOCD
		push	IDC_CBOR
		push	IDC_CBOW
		push	IDC_CBORST
		push	IDC_CBOMD
		mov		eax,IDC_CBOFS
		.while eax
			invoke SendDlgItemMessage,hDlg,eax,CB_GETCURSEL,0,0
			invoke PutItemInt,addr buffer,eax
			pop		eax
		.endw
		invoke PutItemInt,addr buffer,fActive
		invoke GetWindowRect,hDlg,addr rect
		invoke PutItemInt,addr buffer,rect.left
		invoke PutItemInt,addr buffer,rect.top
		invoke WritePrivateProfileString,addr szProGLCD,addr szProGLCD,addr buffer[1],lParam
	.endif
	xor		eax,eax
  Ex:
	ret

DataRead:
	.if glcd.ard
		mov		edi,glcd.adp
		movzx	eax,glcd.ram[edi]
		mov		edx,glcd.port
		mov		[ebx].ADDIN.Sfr[edx],al
		inc		word ptr glcd.adp
	.endif
	retn

CommandRead:
	;Get status
	xor		eax,eax
	;Command execution capability
	or		eax,STA0
	;Data read / write capability
	or		eax,STA1
	;Auto read
	or		eax,STA2
	;Auto write
	or		eax,STA3
	;Controller operation capability
	or		eax,STA5
	;Blink condition
	.if !glcd.fblink
		or		eax,STA7
	.endif
	mov		glcd.status,eax
	mov		edx,glcd.port
	mov		[ebx].ADDIN.Sfr[edx],al
	retn

Read:
	.if glcdbit.bitval[GLCDBIT_CD]
		jmp		CommandRead
	.endif
	jmp		DataRead

DataWrite:
	.if glcd.awr
		mov		edi,glcd.adp
		mov		eax,glcd.port
		movzx	eax,[ebx].ADDIN.Sfr[eax]
		mov		glcd.ram[edi],al
		inc		word ptr glcd.adp
		mov		fChanged,TRUE
	.else
		shr		glcd.data,8
		mov		eax,glcd.port
		movzx	eax,[ebx].ADDIN.Sfr[eax]
		shl		eax,8
		or		glcd.data,eax
	.endif
	retn

CommandWrite:
	mov		eax,glcd.port
	movzx	eax,[ebx].ADDIN.Sfr[eax]
	mov		glcd.cmnd,eax
	.if eax>=21h && eax<=24h
		;Setting registers
		.if eax==21h
			;CURSOR POINTER
			mov		eax,glcd.data
			mov		glcd.cp,eax
		.elseif eax==22h
			;OFFSET REGISTER
			mov		eax,glcd.data
			shl		eax,11
			and		eax,0FFFFh
			mov		glcd.chome,eax
		.elseif eax==24h
			;ADDRESS POINTER
			mov		eax,glcd.data
			mov		glcd.adp,eax
		.else
			;Error
		.endif
	.elseif eax>=40h && eax<=43h
		;Set Control Word
		.if eax==40h
			;Set Text Home Address
			mov		eax,glcd.data
			mov		glcd.thome,eax
		.elseif eax==41h
			;Set Text Area
			mov		eax,glcd.data
			mov		glcd.tcol,eax
		.elseif eax==42h
			;Set Graphic Home Address
			mov		eax,glcd.data
			mov		glcd.ghome,eax
		.elseif eax==43h
			;Graphic Area
			mov		eax,glcd.data
			mov		glcd.gcol,eax
		.endif
	.elseif eax>=80h && eax<=8Fh
		;Mode set
		test	eax,08h
		.if ZERO?
			mov		glcd.ecg,FALSE
		.else
			mov		glcd.ecg,TRUE
		.endif
		and		eax,07h
		mov		glcd.mode,eax
	.elseif eax>=90h && eax<=9Fh
		;Display mode
		mov		glcd.bon,FALSE
		mov		glcd.con,FALSE
		mov		glcd.ton,FALSE
		mov		glcd.gon,FALSE
		.if eax & 01h
			;Blink on
			mov		glcd.bon,TRUE
		.endif
		.if eax & 02h
			;Cursor on
			mov		glcd.con,TRUE
		.endif
		.if eax & 04h
			;Text on
			mov		glcd.ton,TRUE
		.endif
		.if eax & 08h
			;Graphic on
			mov		glcd.gon,TRUE
		.endif
	.elseif eax>=0A0h && eax<=0A7h
		;Cursor pattern select
		and		eax,07h
		mov		glcd.cur,eax
	.elseif eax>=0B0h && eax<=0B2h
		;Data Auto Read / Write
		.if eax==0B0h
			;Set Data Auto Write
			mov		glcd.awr,TRUE
		.elseif eax==0B1h
			;Set Data Auto Read
			mov		glcd.ard,TRUE
		.elseif eax==0B2h
			;Set Data Auto Read / Write off
			mov		glcd.awr,FALSE
			mov		glcd.ard,FALSE
		.endif
	.elseif eax>=0C0h && eax<=0C5h
		;Data Read / Write
		mov		edi,glcd.adp
		.if eax==0C0h
			;Data Write and Increment ADP
			mov		eax,glcd.data
			mov		glcd.ram[edi],ah
			inc		edi
		.elseif eax==0C1h
			;Data Read and Increment ADP
			movzx	eax,glcd.ram[edi]
			mov		edx,glcd.port
			mov		[ebx].ADDIN.Sfr[edx],al
			inc		edi
		.elseif eax==0C2h
			;Data Write and Decrement ADP
			mov		eax,glcd.data
			mov		glcd.ram[edi],ah
			dec		edi
		.elseif eax==0C3h
			;Data Read and Decrement ADP
			movzx	eax,glcd.ram[edi]
			mov		edx,glcd.port
			mov		[ebx].ADDIN.Sfr[edx],al
			dec		edi
		.elseif eax==0C4h
			;Data Write and Nonvariable ADP
			mov		eax,glcd.data
			mov		glcd.ram[edi],ah
		.elseif eax==0C5h
			;Data Read and Nonvariable ADP
			movzx	eax,glcd.ram[edi]
			mov		edx,glcd.port
			mov		[ebx].ADDIN.Sfr[edx],al
		.endif
		and		edi,0FFFFh
		mov		glcd.adp,edi
	.elseif eax==0E0h
		;Screen Peek
	.elseif eax==0E8h
		;Screen Copy
	.elseif eax>=0F0h && eax<=0FFh
		;BIT SET / RESET
		mov		ecx,eax
		and		ecx,07h
		mov		edx,01h
		shl		edx,cl
		mov		edi,glcd.adp
		test	eax,08h
		.if ZERO?
			;BIT RESET
			xor		edx,0FFh
			and		glcd.ram[edi],dl
		.else
			;BIT SET
			or		glcd.ram[edi],dl
		.endif
	.else
		;Error
	.endif
	mov		fChanged,TRUE
	retn

Write:
	.if glcdbit.bitval[GLCDBIT_CD]
		jmp		CommandWrite
	.endif
	jmp		DataWrite

;eax=portaddress, edx=portdata
SetData:
	xor		ecx,ecx
	xor		ebx,ebx
	mov		esi,offset glcdbit
	.while ecx<7
		.if eax==[esi].GLCDBIT.port
			push	[esi].GLCDBIT.bitval
			pop		[esi].GLCDBIT.oldbitval
			inc		ebx
			test	edx,[esi].GLCDBIT.portbit
			.if ZERO?
				;Reset bit
				mov		[esi].GLCDBIT.bitval,FALSE
			.else
				;Set bit
				mov		[esi].GLCDBIT.bitval,TRUE
			.endif
		.endif
		inc		ecx
		lea		esi,[esi+sizeof GLCDBIT]
	.endw
	.if ebx
		;Asigned port bit(s) changed
		mov		ebx,lpAddin
		.if !glcdbit.oldbitval[GLCDBIT_CS] && glcdbit.bitval[GLCDBIT_CS]
			;Low to High transition on CS
			.if !glcdbit.oldbitval[GLCDBIT_R] || !glcdbit.bitval[GLCDBIT_R]
				;R was / is low
				call	Read
			.elseif !glcdbit.oldbitval[GLCDBIT_W] || !glcdbit.bitval[GLCDBIT_W]
				;W was / is low
				call	Write
			.endif
		.elseif !glcdbit.bitval[GLCDBIT_CS] && glcdbit.oldbitval[GLCDBIT_R] && !glcdbit.bitval[GLCDBIT_R]
			;CS is low, high to low transition on R
			call	Read
		.elseif !glcdbit.bitval[GLCDBIT_CS] && !glcdbit.oldbitval[GLCDBIT_W] && glcdbit.bitval[GLCDBIT_W]
			;CS is low, low to high transition on W
			call	Write
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
