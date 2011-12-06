
TerminalProc		PROTO :HWND,:UINT,:WPARAM,:LPARAM

BOXWT				equ 9			;Width of character
BOXHT				equ 17			;Height of character
LINES				equ 26			;Number of lines

.data?

nLine				DWORD ?
nPos				DWORD ?
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
	invoke InvalidateRect,hScrn,NULL,TRUE
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
	invoke InvalidateRect,hScrn,NULL,TRUE
	ret

ScreenScroll endp

ScreenChar proc nChar:DWORD


	.if !hScrn
		invoke SendMessage,hWnd,WM_COMMAND,IDM_VIEW_TERMINAL,0
	.endif
	;Set TI bit in SCON
	movzx	eax,Sfr[SFR_SCON]
	or		eax,2
	mov		Sfr[SFR_SCON],al
	mov		eax,nChar
	.if al==0Eh
		;Cls
		invoke ScreenCls
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
  Ex:
	invoke InvalidateRect,hScrn,NULL,TRUE
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
		invoke SelectObject,ps.hdc,hLstFont
		push	eax
		invoke SetBkMode,ps.hdc,TRANSPARENT
		invoke ScreenDraw,ps.hdc
		pop		eax
		invoke SelectObject,ps.hdc,eax
		invoke EndPaint,hWin,addr ps
		invoke ScreenCaret
		xor		eax,eax
	.else
		invoke CallWindowProc,lpOldScreenProc,hWin,uMsg,wParam,lParam
	.endif
	ret

ScreenProc endp

TerminalProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	
	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke GetDlgItem,hWin,IDC_SCREEN
		mov		hScrn,eax
		invoke SetWindowLong,hScrn,GWL_WNDPROC,addr ScreenProc
		mov		lpOldScreenProc,eax
		invoke ScreenCls
		invoke CreateCaret,hScrn,NULL,BOXWT,BOXHT
		invoke ShowCaret,hScrn
	.elseif eax==WM_CLOSE
		mov		hScrn,0
		invoke DestroyWindow,hWin
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

TerminalProc endp

