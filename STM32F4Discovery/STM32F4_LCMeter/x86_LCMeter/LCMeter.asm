.386
.model flat, stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include LCMeter.inc

.code

;########################################################################

FpToAscii proc USES esi edi,lpFpin:DWORD,lpStr:DWORD,fSci:DWORD
	LOCAL	iExp:DWORD
	LOCAL	sztemp[32]:BYTE
	LOCAL	temp:REAL10

	mov		esi,lpFpin
	mov		edi,lpStr
	.if	dword ptr [esi]== 0 && dword ptr [esi+4]==0
		; Special case zero.  fxtract fails for zero.
		mov		word ptr [edi], '0'
		ret
	.endif
	; Check for a negative number.
	push	[esi+6]
	.if	sdword ptr [esi+6]<0
		and		byte ptr [esi+9],07fh	; change to positive
		mov		byte ptr [edi],'-'		; store a minus sign
		inc		edi
	.endif
	fld		REAL10 ptr [esi]
	fld		st(0)
	; Compute the closest power of 10 below the number.  We can't get an
	; exact value because of rounding.  We could get close by adding in
	; log10(mantissa), but it still wouldn't be exact.  Since we'll have to
	; check the result anyway, it's silly to waste cycles worrying about
	; the mantissa.
	;
	; The exponent is basically log2(lpfpin).  Those of you who remember
	; algebra realize that log2(lpfpin) x log10(2) = log10(lpfpin), which is
	; what we want.
	fxtract					; ST=> mantissa, exponent, [lpfpin]
	fstp	st(0)			; drop the mantissa
	fldlg2					; push log10(2)
	fmulp	st(1),st		; ST = log10([lpfpin]), [lpfpin]
	fistp 	iExp			; ST = [lpfpin]
	; A 10-byte double can carry 19.5 digits, but fbstp only stores 18.
	.IF	iExp<18
		fld		st(0)		; ST = lpfpin, lpfpin
		frndint				; ST = int(lpfpin), lpfpin
		fcomp	st(1)		; ST = lpfpin, status set
		fstsw	ax
		.IF ah&FP_EQUALTO && !fSci	; if EQUAL
			; We have an integer!  Lucky day.  Go convert it into a temp buffer.
			call FloatToBCD
			mov		eax,17
			mov		ecx,iExp
			sub		eax,ecx
			inc		ecx
			lea		esi,[sztemp+eax]
			; The off-by-one order of magnitude problem below can hit us here.  
			; We just trim off the possible leading zero.
			.IF byte ptr [esi]=='0'
				inc esi
				dec ecx
			.ENDIF
			; Copy the rest of the converted BCD value to our buffer.
			rep movsb
			jmp ftsExit
		.ENDIF
	.ENDIF
	; Have fbstp round to 17 places.
	mov		eax, 17			; experiment
	sub		eax,iExp		; adjust exponent to 17
	call PowerOf10
	; Either we have exactly 17 digits, or we have exactly 16 digits.  We can
	; detect that condition and adjust now.
	fcom	ten16
	; x0xxxx00 means top of stack > ten16
	; x0xxxx01 means top of stack < ten16
	; x1xxxx00 means top of stack = ten16
	fstsw	ax
	.IF ah & 1
		fmul	ten
		dec		iExp
	.ENDIF
	; Go convert to BCD.
	call FloatToBCD
	lea		esi,sztemp		; point to converted buffer
	; If the exponent is between -15 and 16, we should express this as a number
	; without scientific notation.
	mov ecx, iExp
	.IF SDWORD PTR ecx>=-15 && SDWORD PTR ecx<=16 && !fSci
		; If the exponent is less than zero, we insert '0.', then -ecx
		; leading zeros, then 16 digits of mantissa.  If the exponent is
		; positive, we copy ecx+1 digits, then a decimal point (maybe), then 
		; the remaining 16-ecx digits.
		inc ecx
		.IF SDWORD PTR ecx<=0
			mov		word ptr [edi],'.0'
			add		edi, 2
			neg		ecx
			mov		al,'0'
			rep		stosb
			mov		ecx,18
		.ELSE
			.if byte ptr [esi]=='0' && ecx>1
				inc		esi
				dec		ecx
			.endif
			rep		movsb
			mov		byte ptr [edi],'.'
			inc		edi
			mov		ecx,17
			sub		ecx,iExp
		.ENDIF
		rep movsb
		; Trim off trailing zeros.
		.WHILE byte ptr [edi-1]=='0'
			dec		edi
		.ENDW
		; If we cleared out all the decimal digits, kill the decimal point, too.
		.IF byte ptr [edi-1]=='.'
			dec		edi
		.ENDIF
		; That's it.
		jmp		ftsExit
	.ENDIF
	; Now convert this to a standard, usable format.  If needed, a minus
	; sign is already present in the outgoing buffer, and edi already points
	; past it.
	mov		ecx,17
	.if byte ptr [esi]=='0'
		inc		esi
		dec		iExp
		dec		ecx
	.endif
	movsb						; copy the first digit
	mov		byte ptr [edi],'.'	; plop in a decimal point
	inc		edi
	rep movsb
	; The printf %g specified trims off trailing zeros here.  I dislike
	; this, so I've disabled it.  Comment out the if 0 and endif if you
	; want this.
	.WHILE byte ptr [edi-1]=='0'
		dec		edi
	.ENDW
	.if byte ptr [edi-1]=='.'
		dec		edi
	.endif
	; Shove in the exponent.
	mov		byte ptr [edi],'e'	; start the exponent
	mov		eax,iExp
	.IF sdword ptr eax<0		; plop in the exponent sign
		mov		byte ptr [edi+1],'-'
		neg		eax
	.ELSE
		mov		byte ptr [edi+1],'+'
	.ENDIF
	mov		ecx, 10
	xor		edx,edx
	div		ecx
	add		dl,'0'
	mov		[edi+5],dl		; shove in the ones exponent digit
	xor		edx,edx
	div		ecx
	add		dl,'0'
	mov		[edi+4],dl		; shove in the tens exponent digit
	xor		edx,edx
	div		ecx
	add		dl,'0'
	mov		[edi+3],dl		; shove in the hundreds exponent digit
	xor		edx,edx
	div		ecx
	add		dl,'0'
	mov		[edi+2],dl		; shove in the thousands exponent digit
	add		edi,6			; point to terminator
ftsExit:
	; Clean up and go home.
	mov		esi,lpFpin
	pop		[esi+6]
	mov		byte ptr [edi],0
	fwait
	ret

; Convert a floating point register to ASCII.
; The result always has exactly 18 digits, with zero padding on the
; left if required.
;
; Entry:	ST(0) = a number to convert, 0 <= ST(0) < 1E19.
;			sztemp = an 18-character buffer.
;
; Exit:		sztemp = the converted result.
FloatToBCD:
	push	esi
	push	edi
    fbstp	temp
	; Now we need to unpack the BCD to ASCII.
    lea		esi,[temp]
    lea		edi,[sztemp]
    mov		ecx,8
    .REPEAT
		movzx	ax,byte ptr [esi+ecx]	; 0000 0000 AAAA BBBB
		rol		ax,12					; BBBB 0000 0000 AAAA
		shr		ah,4					; 0000 BBBB 0000 AAAA
		add		ax,3030h				; 3B3A
		stosw
		dec		ecx
    .UNTIL SIGN?
	pop		edi
	pop		esi
    retn

PowerOf10:
    mov		ecx,eax
    .IF	SDWORD PTR eax<0
		neg		eax
    .ENDIF
    fld1
    mov		dl,al
    and		edx,0fh
    .IF	!ZERO?
		lea		edx,[edx+edx*4]
		fld		ten_1[edx*2][-10]
		fmulp	st(1),st
    .ENDIF
    mov		dl,al
    shr		dl,4
    and		edx,0fh
    .IF !ZERO?
		lea		edx,[edx+edx*4]
		fld		ten_16[edx*2][-10]
		fmulp	st(1),st
    .ENDIF
    mov		dl,ah
    and		edx,1fh
    .IF !ZERO?
		lea		edx,[edx+edx*4]
		fld		ten_256[edx*2][-10]
		fmulp	st(1),st
    .ENDIF
    .IF SDWORD PTR ecx<0
		fdivp	st(1),st
    .ELSE
		fmulp	st(1),st
    .ENDIF
    retn

FpToAscii endp

FrequencyProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	buffer[32]:BYTE
	LOCAL	ps:PAINTSTRUCT
	LOCAL	rect:RECT
	LOCAL	mDC:HDC

	mov		eax,uMsg
	.if eax==WM_PAINT
		invoke GetClientRect,hWin,addr rect
		invoke SendMessage,hWin,WM_GETTEXT,sizeof buffer,addr buffer		
		invoke BeginPaint,hWin,addr ps
		invoke CreateCompatibleDC,ps.hdc
		mov		mDC,eax
		invoke CreateCompatibleBitmap,ps.hdc,rect.right,rect.bottom
		invoke SelectObject,mDC,eax
		push	eax
		invoke CreateSolidBrush,0C0FFFFh
		push	eax
		invoke FillRect,mDC,addr rect,eax
		pop		eax
		invoke DeleteObject,eax
		invoke SelectObject,mDC,hFont
		push	eax
		invoke SetBkMode,mDC,TRANSPARENT
		invoke lstrlen,addr buffer
		mov		edx,eax
		invoke DrawText,mDC,addr buffer,edx,addr rect,DT_CENTER or DT_VCENTER or DT_SINGLELINE
		add		rect.right,15
		pop		eax
		invoke SelectObject,mDC,eax
		invoke BitBlt,ps.hdc,0,0,rect.right,rect.bottom,mDC,0,0,SRCCOPY
		pop		eax
		invoke SelectObject,mDC,eax
		invoke DeleteObject,eax
		invoke DeleteDC,mDC
		invoke EndPaint,hWin,addr ps
		xor		eax,eax
	.elseif eax==WM_SETTEXT
		invoke InvalidateRect,hWin,NULL,TRUE
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
	.else
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
	.endif
	ret

FrequencyProc endp

ScopeProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	ps:PAINTSTRUCT
	LOCAL	rect:RECT
	LOCAL	scprect:RECT
	LOCAL	mDC:HDC
	LOCAL	pt:POINT
	LOCAL	xsinf:SCROLLINFO
	LOCAL	ysinf:SCROLLINFO
	LOCAL	nMin:DWORD
	LOCAL	nMax:DWORD
	LOCAL	samplesize:DWORD
	LOCAL	buffer[128]:BYTE
	LOCAL	buffer1[128]:BYTE

	mov		eax,uMsg
	.if eax==WM_PAINT
PrintHex eax
		mov		samplesize,8000h
		;Get Vmin, Vmax and Vpp
		mov		esi,offset ADC_Data
		mov		ecx,2047
		mov		edx,0
		xor		edi,edi
		.while edi<samplesize
			movzx	eax,word ptr [esi+edi]
			.if eax<ecx
				mov		ecx,eax
			.elseif eax>edx
				mov		edx,eax
			.endif
			lea		edi,[edi+WORD]
		.endw
		invoke GetClientRect,hWin,addr rect
		invoke BeginPaint,hWin,addr ps
		invoke CreateCompatibleDC,ps.hdc
		mov		mDC,eax
		invoke CreateCompatibleBitmap,ps.hdc,rect.right,rect.bottom
		invoke SelectObject,mDC,eax
		push	eax
		invoke GetStockObject,BLACK_BRUSH
		invoke FillRect,mDC,addr rect,eax
		sub		rect.bottom,TEXTHIGHT
		; Create gridlines pen
		invoke CreatePen,PS_SOLID,1,404040h
		invoke SelectObject,mDC,eax
		push	eax
		; Calculate the scope rect
		mov		eax,rect.right
		sub		eax,GRIDSIZE*10
		shr		eax,1
		mov		scprect.left,eax
		add		eax,GRIDSIZE*10
		mov		scprect.right,eax
		mov		eax,rect.bottom
		sub		eax,GRIDSIZE*6
		shr		eax,1
		mov		scprect.top,eax
		add		eax,GRIDSIZE*6
		mov		scprect.bottom,eax
		;Draw horizontal lines
		mov		edi,scprect.top
		xor		ecx,ecx
		.while ecx<7
			push	ecx
			invoke MoveToEx,mDC,scprect.left,edi,NULL
			invoke LineTo,mDC,scprect.right,edi
			add		edi,GRIDSIZE
			pop		ecx
			inc		ecx
		.endw
		;Draw vertical lines
		mov		edi,scprect.left
		xor		ecx,ecx
		.while ecx<11
			push	ecx
			invoke MoveToEx,mDC,edi,scprect.top,NULL
			invoke LineTo,mDC,edi,scprect.bottom
			add		edi,GRIDSIZE
			pop		ecx
			inc		ecx
		.endw
		pop		eax
		invoke SelectObject,mDC,eax
		invoke DeleteObject,eax

		;Draw curve
		invoke CreateRectRgn,scprect.left,scprect.top,scprect.right,scprect.bottom
		push	eax
		invoke SelectClipRgn,mDC,eax
		pop		eax
		invoke DeleteObject,eax
		invoke CreatePen,PS_SOLID,2,008000h
		invoke SelectObject,mDC,eax
		push	eax
		mov		esi,offset ADC_Data
		xor		edi,edi
		call	GetPoint
		invoke MoveToEx,mDC,pt.x,pt.y,NULL
		.while edi<samplesize
			mov		edx,edi
			call	GetPoint
			invoke LineTo,mDC,pt.x,pt.y
			mov		eax,pt.x
			.break .if sdword ptr eax>scprect.right
			lea		edi,[edi+WORD]
		.endw
		add		rect.bottom,TEXTHIGHT
		invoke BitBlt,ps.hdc,0,0,rect.right,rect.bottom,mDC,0,0,SRCCOPY
		pop		eax
		invoke SelectObject,mDC,eax
		invoke DeleteObject,eax
		invoke DeleteDC,mDC
		invoke EndPaint,hWin,addr ps
		xor		eax,eax
	.else
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
	.endif
	ret

GetPoint:
	;Get X position
	mov		eax,edi
	shr		eax,1
	add		eax,scprect.left
	mov		pt.x,eax
	;Get y position
	mov		edx,edi
	movzx	eax,word ptr [esi+edx]
	sub		eax,ADCMAX
	neg		eax
	shr eax,3
	mov		pt.y,eax
	retn

ScopeProc endp

ScopeChildProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	rect:RECT

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke GetDlgItem,hWin,IDC_UDCSCOPE
		mov		hScp,eax
	.elseif	eax==WM_SIZE
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

ScopeChildProc endp

;------------------------------------------------------------------
;Capacitance meter: Cx=((((F1/F3)^2)-1)/(((F1/F2)^2)-1))*Ccal
;IN:	Nothing
;OUT:	Nothing
;------------------------------------------------------------------
CalculateCapacitor proc uses esi,lpBuffer:PTR BYTE
	LOCAL	tmp:REAL10
	LOCAL	iExp:DWORD

	fild	STM32_Cmd.STM32_Lcm.FrequencyCal0
	fild	STM32_Cmd.STM32_Frq.Frequency
	fdivp	st(1),st
	fstp	REAL10 ptr [tmp]
	fld		tmp
	fld		tmp
	fmulp	st(1),st
	fld1
	fsubp	st(1),st
	fild	STM32_Cmd.STM32_Lcm.FrequencyCal0
	fild	STM32_Cmd.STM32_Lcm.FrequencyCal1
	fdivp	st(1),st
	fstp	REAL10 ptr [tmp]
	fld		tmp
	fld		tmp
	fmulp	st(1),st
	fld1
	fsubp	st(1),st
	fdivp	st(1),st
	fld		REAL10 ptr [CCal]
	fmulp	st(1),st
	fstp	REAL10 ptr [LCx]
	fld		REAL10 ptr [LCx]
	fxtract					; ST=> mantissa, exponent, [lpfpin]
	fstp	st(0)			; drop the mantissa
	fldlg2					; push log10(2)
	fmulp	st(1),st		; ST = log10([lpfpin]), [lpfpin]
	fistp 	iExp			; ST = [lpfpin]
	.if sdword ptr iExp<=-10
		fld		REAL10 ptr [LCx]
		fld		REAL10 ptr [ten_12]
		fmulp	st(1),st
		fstp	REAL10 ptr [LCx]
		mov		esi,offset szPF
	.elseif  sdword ptr iExp<=-7
		fld		REAL10 ptr [LCx]
		fld		REAL10 ptr [ten_9]
		fmulp	st(1),st
		fstp	REAL10 ptr [LCx]
		mov		esi,offset szNF
	.else
		fld		REAL10 ptr [LCx]
		fld		REAL10 ptr [ten_6]
		fmulp	st(1),st
		fstp	REAL10 ptr [LCx]
		mov		esi,offset szUF
	.endif
	invoke FpToAscii,offset LCx,lpBuffer,FALSE
	mov		edx,lpBuffer
	xor		ecx,ecx
	.if byte ptr [edx]=='-'
		mov		word ptr [edx],'0'
	.endif
	.while byte ptr [edx]
		.if byte ptr [edx]=='.'
			mov		byte ptr [edx+4],0
			inc		edx
			.break
		.elseif byte ptr [edx]!='0'
			inc		ecx
		.endif
		inc		edx
	.endw
	.while byte ptr [edx]
		.if byte ptr [edx]!='0'
			inc		ecx
			.break
		.endif
		inc		edx
	.endw
	.if !ecx
		mov		edx,lpBuffer
		mov		word ptr [edx],'0'
	.endif
	invoke lstrcat,lpBuffer,esi
	ret

CalculateCapacitor endp

;------------------------------------------------------------------
;Induktance meter: Lx=(((F1/F3)^2)-1)*(((F1/F2)^2)-1)*(1/Ccal)*(1/(2*PI*F1))^2
;IN:	Nothing
;OUT:	Nothing
;------------------------------------------------------------------
CalculateInductor proc uses esi,lpBuffer:PTR BYTE
	LOCAL	tmp:REAL10
	LOCAL	tmpa:REAL10
	LOCAL	tmpb:REAL10
	LOCAL	tmpc:REAL10
	LOCAL	tmpd:REAL10
	LOCAL	iExp:DWORD

	; (((F1/F3)^2)-1)
	fild	STM32_Cmd.STM32_Lcm.FrequencyCal0
	fild	STM32_Cmd.STM32_Frq.Frequency
	fdivp	st(1),st
	fstp	REAL10 ptr [tmp]
	fld		REAL10 ptr [tmp]
	fld		REAL10 ptr [tmp]
	fmulp	st(1),st
	fld1
	fsubp	st(1),st
	fstp	REAL10 ptr [tmpa]
	; (((F1/F2)^2)-1)
	fild	STM32_Cmd.STM32_Lcm.FrequencyCal0
	fild	STM32_Cmd.STM32_Lcm.FrequencyCal1
	fdivp	st(1),st
	fstp	REAL10 ptr [tmp]
	fld		REAL10 ptr [tmp]
	fld		REAL10 ptr [tmp]
	fmulp	st(1),st
	fld1
	fsubp	st(1),st
	fstp	REAL10 ptr [tmpb]
	; (1/Ccal)
	fld1
	fld		REAL10 ptr [CCal]
	fdivp	st(1),st
	fstp	REAL10 ptr [tmpc]
	; (1/(2PI*F1))^2
	fldpi
	fld		REAL10 ptr [two]
	fmulp	st(1),st
	fild	STM32_Cmd.STM32_Lcm.FrequencyCal0
	fmulp	st(1),st
	fstp	REAL10 ptr [tmp]
	fld1
	fld		REAL10 ptr [tmp]
	fdivp	st(1),st
	fstp	REAL10 ptr [tmp]
	fld		REAL10 ptr [tmp]
	fld		REAL10 ptr [tmp]
	fmulp	st(1),st
	fstp	REAL10 ptr [tmpd]
	fld		REAL10 ptr [tmpd]
	fld		REAL10 ptr [tmpa]
	fmulp	st(1),st
	fstp	REAL10 ptr [tmp]
	fld		REAL10 ptr [tmp]
	fld		REAL10 ptr [tmpb]
	fmulp	st(1),st
	fld		REAL10 ptr [tmpc]
	fmulp	st(1),st
	fstp	REAL10 ptr [LCx]
	fld		REAL10 ptr [LCx]
	fxtract					; ST=> mantissa, exponent, [lpfpin]
	fstp	st(0)			; drop the mantissa
	fldlg2					; push log10(2)
	fmulp	st(1),st		; ST = log10([lpfpin]), [lpfpin]
	fistp 	iExp			; ST = [lpfpin]
	.if  sdword ptr iExp<=-7
		fld		REAL10 ptr [LCx]
		fld		REAL10 ptr [ten_9]
		fmulp	st(1),st
		fstp	REAL10 ptr [LCx]
		mov		esi,offset szNH
	.elseif  sdword ptr iExp<=-3
		fld		REAL10 ptr [LCx]
		fld		REAL10 ptr [ten_6]
		fmulp	st(1),st
		fstp	REAL10 ptr [LCx]
		mov		esi,offset szUH
	.elseif  sdword ptr iExp<=-1
		fld		REAL10 ptr [LCx]
		fld		REAL10 ptr [ten_3]
		fmulp	st(1),st
		fstp	REAL10 ptr [LCx]
		mov		esi,offset szMH
	.else
		mov		esi,offset szH
	.endif
	invoke FpToAscii,offset LCx,lpBuffer,FALSE
	mov		edx,lpBuffer
	xor		ecx,ecx
	.if byte ptr [edx]=='-'
		mov		word ptr [edx],'0'
	.endif
	.while byte ptr [edx]
		.if byte ptr [edx]=='.'
			mov		byte ptr [edx+4],0
			inc		edx
			.break
		.elseif byte ptr [edx]!='0'
			inc		ecx
		.endif
		inc		edx
	.endw
	.while byte ptr [edx]
		.if byte ptr [edx]!='0'
			inc		ecx
			.break
		.endif
		inc		edx
	.endw
	.if !ecx
		mov		edx,lpBuffer
		mov		word ptr [edx],'0'
	.endif
	invoke lstrcat,lpBuffer,esi
	ret

CalculateInductor endp

SetMode proc
	LOCAL	buffer[64]:BYTE

	invoke lstrcpy,addr buffer,offset szLCMeter
	.if mode==CMD_LCMCAP
		mov		eax,offset szCapacitance
	.elseif mode==CMD_LCMIND
		mov		eax,offset szInductance
	.elseif mode==CMD_FRQCH1
		mov		eax,offset szFerquencyCH1
	.elseif mode==CMD_FRQCH2
		mov		eax,offset szFerquencyCH2
	.elseif mode==CMD_FRQCH3
		mov		eax,offset szFerquencyCH3
	.elseif mode==CMD_SCPSET
		mov		eax,offset szScope
	.endif
	invoke lstrcat,addr buffer,eax
	invoke SetWindowText,hWnd,addr buffer
	ret

SetMode endp

DlgProc	proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	buffer[32]:BYTE

	mov		eax,uMsg
	.if	eax==WM_INITDIALOG
		mov		eax,hWin
		mov		hWnd,eax
		invoke CreateFontIndirect,addr Tahoma_36
		mov		hFont,eax
		mov		STM32_Cmd.HSCSet,41
		;Create scope child dialogs
		invoke CreateDialogParam,hInstance,IDD_DLGSCOPE,hWin,addr ScopeChildProc,0;offset scopedata.scopeCHAdata
;		mov		childdialogs.hWndScopeCHA,eax
	.elseif	eax==WM_COMMAND
		mov edx,wParam
		movzx eax,dx
		shr edx,16
		.if edx==BN_CLICKED
			.if eax==IDOK
				.if !connected
					;Connect to the STLink
					invoke STLinkConnect,hWin
					.if eax && eax!=IDIGNORE && eax!=IDABORT
						mov		connected,eax
						mov		mode,CMD_LCMCAP
						invoke SetMode
						invoke STLinkWrite,hWin,20000014h,addr mode,DWORD
						;Create a timer. The event will read the frequency, format it and display the result
						invoke SetTimer,hWin,1000,500,NULL
					.endif
				.endif
			.elseif eax==IDCANCEL
				invoke	SendMessage,hWin,WM_CLOSE,NULL,NULL
			.elseif eax==IDC_BTNCALIBRATE
				.if connected
					mov		mode,CMD_LCMCAL
					invoke STLinkWrite,hWin,20000014h,addr mode,DWORD
					mov		mode,CMD_LCMCAP
					invoke SetMode
				.endif
			.elseif eax==IDC_BTNMODE
				.if mode==CMD_SCPSET
					mov		mode,CMD_LCMCAP
				.else
					inc		mode
				.endif
				.if connected
					invoke STLinkWrite,hWin,20000014h,addr mode,DWORD
					invoke SetMode
				.endif
			.elseif eax==IDC_BTNHSCDN
				.if STM32_Cmd.HSCSet<65534
					inc		STM32_Cmd.HSCSet
					mov		STM32_Cmd.Cmd,CMD_HSCSET
					invoke STLinkWrite,hWin,20000018h,addr STM32_Cmd.HSCSet,DWORD
					invoke STLinkWrite,hWin,20000014h,addr STM32_Cmd.Cmd,DWORD
				.endif
			.elseif eax==IDC_BTNHSCUP
				.if STM32_Cmd.HSCSet
					dec		STM32_Cmd.HSCSet
					mov		STM32_Cmd.Cmd,CMD_HSCSET
					invoke STLinkWrite,hWin,20000018h,addr STM32_Cmd.HSCSet,DWORD
					invoke STLinkWrite,hWin,20000014h,addr STM32_Cmd.Cmd,DWORD
				.endif
			.endif
		.endif
	.elseif	eax==WM_TIMER
		;Read 28 bytes from STM32F4xx ram and store it in STM32_Cmd.
		invoke STLinkRead,hWin,20000014h,offset STM32_Cmd,7*DWORD
		.if eax
			mov		eax,STM32_Cmd.STM32_Frq.Frequency
			.if eax<1000
				;Hz
				invoke wsprintf,addr buffer,addr szFmtHz,eax
			.elseif eax<1000000
				;KHz
				invoke wsprintf,addr buffer,addr szFmtKHz,eax
				mov		ebx,6
				call	InsertDot
			.else
				;MHz
				invoke wsprintf,addr buffer,addr szFmtMHz,eax
				mov		ebx,9
				call	InsertDot
			.endif
			invoke SetDlgItemText,hWin,IDC_FREQUENCY,addr buffer
			mov		buffer,0
			.if mode==CMD_LCMCAP
				invoke CalculateCapacitor,addr buffer
			.elseif mode==CMD_LCMIND
				invoke CalculateInductor,addr buffer
			.endif
			invoke SetDlgItemText,hWin,IDC_LCMETER,addr buffer
			.if mode==CMD_SCPSET
				.while TRUE
					invoke STLinkRead,hWin,20000014h,offset STM32_Cmd,DWORD
					.break .if !STM32_Cmd.Cmd
				.endw
				invoke STLinkRead,hWin,20010000h,offset ADC_Data,8000h
				invoke InvalidateRect,hScp,NULL,TRUE
			.endif
		.else
			invoke KillTimer,hWin,1000
			mov		connected,FALSE
		.endif
	.elseif	eax==WM_CLOSE
		invoke KillTimer,hWin,1000
		invoke STLinkDisconnect,hWin
		invoke DeleteObject,hFont
		invoke EndDialog,hWin,0
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

InsertDot:
	lea		esi,buffer
	invoke lstrlen,esi
	mov		edx,eax
	sub		ebx,edx
	neg		ebx
	mov		al,'.'
	.while ebx<=edx
		xchg	al,[esi+ebx]
		inc		ebx
	.endw
	mov		[esi+ebx],al
	retn

DlgProc endp

start:
	invoke	GetModuleHandle,NULL
	mov	hInstance,eax
	invoke	InitCommonControls
	mov		wc.cbSize,sizeof WNDCLASSEX
	mov		wc.style,CS_HREDRAW or CS_VREDRAW
	mov		wc.lpfnWndProc,offset FrequencyProc
	mov		wc.cbClsExtra,0
	mov		wc.cbWndExtra,0
	mov		eax,hInstance
	mov		wc.hInstance,eax
	mov		wc.hIcon,0
	invoke LoadCursor,0,IDC_ARROW
	mov		wc.hCursor,eax
	mov		wc.hbrBackground,NULL
	mov		wc.lpszMenuName,NULL
	mov		wc.lpszClassName,offset szFREQUENCYCLASS
	mov		wc.hIconSm,NULL
	invoke RegisterClassEx,addr wc
	mov		wc.lpfnWndProc,offset ScopeProc
	invoke LoadCursor,0,IDC_CROSS
	mov		wc.hCursor,eax
	mov		wc.lpszClassName,offset szSCOPECLASS
	invoke RegisterClassEx,addr wc
	invoke	DialogBoxParam,hInstance,IDD_MAIN,NULL,addr DlgProc,NULL
	invoke	ExitProcess,0

end start
