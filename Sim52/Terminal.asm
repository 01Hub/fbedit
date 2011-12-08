
TerminalProc		PROTO :HWND,:UINT,:WPARAM,:LPARAM

BOXWT				equ 9			;Width of character
BOXHT				equ 17			;Height of character
LINES				equ 26			;Number of lines

.data?

hTerm				HWND ?
hTermScrn			HWND ?
nLine				DWORD ?
nPos				DWORD ?
nLocate				DWORD ?
lpOldScreenProc		DWORD ?

scrn				WORD LINES*80 dup(?)

.code

ScreenCls proc

	mov		ax,20h
	mov		edx,offset scrn
	mov		ecx,80*LINES
	.while ecx
		mov		[edx],ax
		inc		edx
		inc		edx
		dec		ecx
	.endw
	mov		nLine,0
	mov		nPos,0
	invoke InvalidateRect,hTermScrn,NULL,TRUE
	ret

ScreenCls endp

ScreenScroll proc uses ebx esi edi

	mov		edi,offset scrn
	mov		esi,offset scrn+80*2
	mov		ecx,(LINES-1)*80
	rep		movsw
	mov		ecx,80
	mov		ax,20h
	rep		stosw
	invoke InvalidateRect,hTermScrn,NULL,TRUE
	ret

ScreenScroll endp

ScreenChar proc nChar:DWORD


	invoke IsWindowVisible,hTerm
	.if !eax
		invoke SendMessage,addin.hWnd,WM_COMMAND,IDM_VIEW_TERMINAL,0
	.endif
	;Set TI bit in SCON
	movzx	eax,addin.Sfr[SFR_SCON]
	or		eax,2
	mov		addin.Sfr[SFR_SCON],al
	mov		eax,nChar
	.if nLocate==1
		sub		eax,20h
		.if eax<LINES
			mov		nLine,eax
		.endif
		inc		nLocate
	.elseif nLocate==2
		sub		eax,20h
		.if eax<80
			mov		nPos,eax
		.endif
		mov		nLocate,0
	.else
		.if al==0Eh
			;Cls
			invoke ScreenCls
			jmp		Ex
		.elseif al==0Bh
			;Locate
			mov		nLocate,1
			jmp		Ex
		.elseif al==0Ch
			;Home
			mov		nPos,0
			mov		nLine,0
			jmp		Ex
		.elseif al==0Dh
			;Cr
			mov		nPos,0
			jmp		Ex
		.elseif al==0Ah
			;Lf
			inc		nLine
			.if nLine>=LINES
				invoke ScreenScroll
				mov		nLine,LINES-1
			.endif
			jmp		Ex
		.elseif al==08h
			;BS
			.if nPos
				dec		nPos
			.endif
			jmp		Ex
		.elseif al==01h
			;Program rom
		.elseif al==02h
			;End Program rom
		.elseif al==03h
			;Read rom data and write it to file
		.elseif al==04h
			;End Read rom data
		.elseif al==05h
			;Send 16 bytes of cmd file to emulator
		.elseif al==06h
			;End Send 16 bytes of cmd file to emulator
		.elseif al==07h
			;Single step, next 2 characters is binary address of next instruction
		.elseif al==10h
			;Send cmd file to emulator
		.elseif eax=='Ä'
			mov		eax,06h
		.elseif eax=='Ú'
			mov		eax,0Ch
		.elseif eax=='Ã'
			mov		eax,19h
		.elseif eax=='´'
			mov		eax,17h
		.elseif eax=='À'
			mov		eax,03h
		.elseif eax==0BFh
			mov		eax,02h
		.elseif  eax=='Ù'
			mov		eax,04h
		.elseif eax==0B3h
			mov		eax,05h
		.elseif eax=='û'
			mov		eax,07h
		.endif
		mov		nChar,eax
		mov		eax,nLine
		mov		edx,80*2
		imul	edx
		add		eax,nPos
		add		eax,nPos
		mov		edx,nChar
		mov		scrn[eax],dx
		inc		nPos
		.if nPos==80
			mov		nPos,0
			inc		nLine
			.if nLine==LINES
				invoke ScreenScroll
				mov		nLine,LINES-1
			.endif
		.endif
	.endif
	ret
  Ex:
	invoke InvalidateRect,hTermScrn,NULL,TRUE
	ret

ScreenChar endp

ScreenDraw proc uses ebx esi,hDC:HDC
	LOCAL	rect:RECT

	mov		rect.top,0
	xor		ebx,ebx
	mov		esi,offset scrn
	.while ebx<LINES
		mov		rect.left,0
		call	DrawLine
		add		rect.top,BOXHT
		inc		ebx
	.endw
	ret

DrawLine:
	push	ebx
	mov		eax,rect.top
	add		eax,BOXHT
	mov		rect.bottom,eax
	xor		ebx,ebx
	.while ebx<80
		mov		eax,rect.left
		add		eax,BOXWT
		mov		rect.right,eax
		mov		ax,[esi]
		.if ah
			invoke GetStockObject,BLACK_BRUSH
			invoke FillRect,hDC,addr rect,eax
			invoke SetTextColor,hDC,0FFFFFFh
		.else
			invoke GetStockObject,WHITE_BRUSH
			invoke FillRect,hDC,addr rect,eax
			invoke SetTextColor,hDC,0
		.endif
		invoke TextOut,hDC,rect.left,rect.top,esi,1
		add		rect.left,BOXWT
		inc		ebx
		inc		esi
		inc		esi
	.endw
	pop		ebx
	retn

ScreenDraw endp

ScreenCaret proc

	mov		eax,BOXHT
	mov		edx,nLine
	mul		edx
	push	eax
	mov		eax,BOXWT
	mov		edx,nPos
	mul		edx
	pop		edx
	invoke SetCaretPos,eax,edx
	ret

ScreenCaret endp

ScreenProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	ps:PAINTSTRUCT

	mov		eax,uMsg
	.if eax==WM_PAINT
		invoke BeginPaint,hWin,addr ps
		invoke SelectObject,ps.hdc,addin.hLstFont
		push	eax
		invoke SetBkMode,ps.hdc,TRANSPARENT
		invoke ScreenDraw,ps.hdc
		pop		eax
		invoke SelectObject,ps.hdc,eax
		invoke EndPaint,hWin,addr ps
		invoke ScreenCaret
		xor		eax,eax
	.elseif eax==WM_CHAR
		mov		eax,wParam
		.if eax==1Bh
			;Esc
			mov		eax,9Fh
		.elseif eax>='a' && eax<='z'
			;Convert to uppercase
			and		eax,5Fh
		.endif
		mov		addin.Sfr[SFR_SBUF],al
		or		addin.Sfr[SFR_SCON],01h
	.elseif eax==WM_KEYDOWN
		mov		eax,wParam
		.if eax==VK_RIGHT
			mov		addin.Sfr[SFR_SBUF],9Ch
			or		addin.Sfr[SFR_SCON],01h
		.elseif eax==VK_LEFT
			mov		addin.Sfr[SFR_SBUF],9Dh
			or		addin.Sfr[SFR_SCON],01h
		.elseif eax==VK_DOWN
			mov		addin.Sfr[SFR_SBUF],9Bh
			or		addin.Sfr[SFR_SCON],01h
		.elseif eax==VK_UP
			mov		addin.Sfr[SFR_SBUF],9Ah
			or		addin.Sfr[SFR_SCON],01h
		.elseif eax==VK_INSERT
			mov		addin.Sfr[SFR_SBUF],94h
			or		addin.Sfr[SFR_SCON],01h
		.endif
	.else
		invoke CallWindowProc,lpOldScreenProc,hWin,uMsg,wParam,lParam
	.endif
	ret

ScreenProc endp

TerminalProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	
	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		eax,hWin
		mov		hTerm,eax
		invoke GetDlgItem,hWin,IDC_SCREEN
		mov		hTermScrn,eax
		invoke SetWindowLong,hTermScrn,GWL_WNDPROC,addr ScreenProc
		mov		lpOldScreenProc,eax
		invoke ScreenCls
	.elseif eax==WM_CLOSE
		invoke ShowWindow,hWin,SW_HIDE
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

TerminalProc endp
