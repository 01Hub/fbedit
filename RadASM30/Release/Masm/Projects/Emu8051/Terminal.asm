
;*****************************************************
;SCREEN DRIVER
;-----------------------------------------------------
;01				START SEND ROMDATA.HEX FILE
;02				STOP SEND FILE
;03				START RECIEVE ROMDATA.HEX FILE
;04				STOP RECIEVE FILE
;05				START RECIEVE FILE IN 16 BYTE BLOCKS
;06				STOP RECIEVE FILE IN 16 BYTE BLOCKS
;07				BELL, if from MCU then next 2
;				binary characters is the single step
;				address to be executed.
;08				BACK SPACE
;09				TAB
;0A				LF
;0B				LOCATE
;0C				HOME
;0D				CR
;0E				CLS
;0F				MODE
;10				START SEND CMDFILE.CMD FILE
;-----------------------------------------------------
;*****************************************************

BOXWT				equ 9
BOXHT				equ 17

.data?

nLine				DWORD ?
nPos				DWORD ?
nLocate				DWORD ?
nDebug				DWORD ?
SingleStepAdr		DWORD ?

scrn				WORD 80 dup(?)
					WORD 80 dup(?)
					WORD 80 dup(?)
					WORD 80 dup(?)
					WORD 80 dup(?)
					WORD 80 dup(?)
					WORD 80 dup(?)
					WORD 80 dup(?)
					WORD 80 dup(?)
					WORD 80 dup(?)
					WORD 80 dup(?)
					WORD 80 dup(?)
					WORD 80 dup(?)
					WORD 80 dup(?)
					WORD 80 dup(?)
					WORD 80 dup(?)
					WORD 80 dup(?)
					WORD 80 dup(?)
					WORD 80 dup(?)
					WORD 80 dup(?)
					WORD 80 dup(?)
					WORD 80 dup(?)
					WORD 80 dup(?)
					WORD 80 dup(?)

.code

ScreenCls proc

	mov		ax,20h
	mov		edx,offset scrn
	mov		ecx,80*24
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
	mov		ecx,23*80
	rep		movsw
	mov		ecx,80
	mov		ax,20h
	rep		stosw
	invoke InvalidateRect,hScrn,NULL,TRUE
	ret

ScreenScroll endp

ScreenChar proc nChar:DWORD

	mov		eax,nChar
	.if eax=='�'
		mov		eax,06h
	.elseif eax=='�'
		mov		eax,0Ch
	.elseif eax=='�'
		mov		eax,19h
	.elseif eax=='�'
		mov		eax,17h
	.elseif eax=='�'
		mov		eax,03h
	.elseif eax==0BFh
		mov		eax,02h
	.elseif  eax=='�'
		mov		eax,04h
	.elseif eax==0B3h
		mov		eax,05h
	.elseif eax=='�'
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
		.if nLine==24
			invoke ScreenScroll
			mov		nLine,23
		.endif
	.endif
	invoke InvalidateRect,hScrn,NULL,TRUE
	ret

ScreenChar endp

ScreenOut proc nChar:DWORD
	LOCAL	tid:DWORD
	LOCAL	nRead:DWORD
	LOCAL	nWrite:DWORD
	LOCAL	buffer[32]:BYTE

	mov		eax,nChar
	.if nLocate==1
		sub		eax,20h
		.if eax<24
			mov		nLine,eax
		.endif
		inc		nLocate
	.elseif nLocate==2
		sub		eax,20h
		.if eax<80
			mov		nPos,eax
		.endif
		mov		nLocate,0
	.elseif nDebug==1
		mov		eax,nChar
		mov		SingleStepAdr,eax
		mov		nDebug,2
	.elseif nDebug==2
		mov		eax,nChar
		xchg	al,ah
		or		SingleStepAdr,eax
		mov		eax,SingleStepAdr
		push	eax
		call	ToHex
		mov		buffer[3],al
		pop		eax
		shr		eax,4
		push	eax
		call	ToHex
		mov		buffer[2],al
		pop		eax
		shr		eax,4
		push	eax
		call	ToHex
		mov		buffer[1],al
		pop		eax
		shr		eax,4
		call	ToHex
		mov		buffer[0],al
		mov		buffer[4],0
		invoke Find,addr buffer
		.if !eax
			;Addrss not found
			invoke WriteCom,0Dh
		.endif
		mov		nDebug,0
	.elseif hwrfile && eax!=04h
		mov		buffer,al
		invoke WriteFile,hwrfile,addr buffer,1,addr nWrite,NULL
	.else
		.if al==0Eh
			;Cls
			invoke ScreenCls
		.elseif al==0Bh
			;Locate
			mov		nLocate,1
		.elseif al==0Ch
			;Home
			mov		nPos,0
			mov		nLine,0
		.elseif al==0Fh
			;Mode
;			call	GetChar
		.elseif al==0Dh
			;Cr
			mov		nPos,0
		.elseif al==0Ah
			;Lf
			inc		nLine
			.if nLine>23
				invoke ScreenScroll
				mov		nLine,23
			.endif
		.elseif al==08h
			;BS
			.if nPos
				dec		nPos
			.endif
		.elseif al==01h
			;Program rom
			invoke CreateFile,addr szcmdfilename,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
			.if eax!=INVALID_HANDLE_VALUE
				mov		wrhead,0
				mov		wrtail,0
				mov		fprogrom,TRUE
				mov		hrdfile,eax
			.endif
		.elseif al==02h
			;End Program rom
			mov		fprogrom,FALSE
			.if hrdfile
				invoke CloseHandle,hrdfile
				mov		hrdfile,0
			.endif
		.elseif al==03h
			;Read rom data and write it to file
			invoke CreateFile,addr szromfilename,GENERIC_WRITE,FILE_SHARE_READ,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL
			.if eax!=INVALID_HANDLE_VALUE
				mov		hwrfile,eax
			.endif
		.elseif al==04h
			;End Read rom data
			.if hwrfile
				invoke CloseHandle,hwrfile
				mov		hwrfile,0
			.endif
		.elseif al==05h
			;Send 16 bytes of cmd file to emulator
			.if !hrdblock
				invoke CreateFile,addr szcmdfilename,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
				mov		hrdblock,eax
			.endif
			mov		fblockmode,TRUE
		.elseif al==06h
			;End Send 16 bytes of cmd file to emulator
			mov		fblockmode,FALSE
			invoke CloseHandle,hrdblock
			mov		hrdblock,0
		.elseif al==07h
			;Single step, next 2 characters is binary address of next instruction
			mov		nDebug,1
		.elseif al==10h
			;Send cmd file to emulator
			mov		fprogrom,FALSE
			invoke CreateFile,addr szcmdfilename,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
			.if eax!=INVALID_HANDLE_VALUE
				mov		hrdfile,eax
			.endif
		.else
			invoke ScreenChar,eax
		.endif
	.endif
	ret

ToHex:
	and     eax,0fh
	cmp     eax,0ah
	jb      ToHex1
	add     eax,07h
ToHex1:
	add     eax,30h
	retn

ScreenOut endp

ScreenDraw proc uses ebx esi,hDC:HDC
	LOCAL	rect:RECT

	mov		rect.top,0
	xor		ebx,ebx
	mov		esi,offset scrn
	.while ebx<24
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
		invoke SelectObject,ps.hdc,hFont
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
