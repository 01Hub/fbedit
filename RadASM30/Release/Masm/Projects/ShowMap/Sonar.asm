
.data?

pixcnt				DWORD ?
pixdir				DWORD ?
pixmov				DWORD ?
pixdpt				DWORD ?
rseed				DWORD ?

.code

Random proc uses ecx edx,range:DWORD

	mov		eax,rseed
	mov		ecx,23
	mul		ecx
	add		eax,7
	and		eax,0FFFFFFFFh
	ror		eax,1
	xor		eax,rseed
	mov		rseed,eax
	mov		ecx,range
	xor		edx,edx
	div		ecx
	mov		eax,edx
	ret

Random endp

;Description
;===========
;A short ping at 200KHz is transmitted at intervalls depending on range.
;From the time it takes for the echo to return we can calculate the depth.
;The adc measures the strenght of the echo at intervalls depending on range
;and stores it in a 512 byte array.
;
;Speed of sound in water
;=======================
;Temp (C)    Speed (m/s)
;  0             1403
;  5             1427
; 10             1447
; 20             1481
; 30             1507
; 40             1526
;
;1450m/s is probably a good estimate.
;
;The timer is clocked at 48MHz so it increments every 0,0208333 us.
;For each tick the sound travels 1450 * 0,0208333 = 30,208285 um or 30,208285e-6 meters.

;Timer value calculation
;=======================
;Example 2m range
;Timer period Tp=1/48MHz
;Each pixel is Px=2m/512.
;Time for each pixel is t=Px/1450/2
;Timer ticks Tt=t/Tp

;Formula T=((Range/512)/(1450/2))*48000000

RangeToTimer proc RangeInx:DWORD
	LOCAL	tmp:DWORD

	mov		eax,RangeInx
	lea		eax,[eax+eax*2]
	mov		eax,sonarrange.range[eax*4]
	mov		tmp,eax
	fild	tmp
	mov		tmp,MAXYECHO
	fild	tmp
	fdivp	st(1),st
	mov		tmp,1450/2			;Divide by 2 since it is the echo
	fild	tmp
	fdivp	st(1),st
	mov		tmp,48000000
	fild	tmp
	fmulp	st(1),st
	fistp	tmp
	mov		eax,tmp
	dec		eax
	ret

RangeToTimer endp

SetRange proc uses ebx esi edi,RangeInx:DWORD

	mov		ebx,RangeInx
	mov		sonardata.RangeInx,ebx
	lea		ebx,[ebx+ebx*2]
	mov		eax,sonarrange.skip[ebx*4]
	mov		sonardata.Skip,ax
	mov		eax,sonarrange.range[ebx*4]
	mov		sonardata.RangeVal,eax
	invoke wsprintf,addr sonardata.options.text,addr szFmtDec,eax
	invoke RangeToTimer,RangeInx
	mov		sonardata.Timer,ax
	ret

SetRange endp

UpdateBitmap proc uses ebx esi edi
	LOCAL	rect:RECT

	mov		rect.left,0
	mov		rect.top,0
	mov		rect.right,MAXXECHO
	mov		rect.bottom,MAXYECHO
	invoke CreateSolidBrush,SONARBACKCOLOR
	push	eax
	invoke FillRect,sonardata.mDC,addr rect,eax
	pop		eax
	invoke DeleteObject,eax
	mov		ebx,sonardata.RangeVal
	xor		esi,esi
	.while esi<MAXXECHO
		xor		edi,edi
		.while edi<MAXYECHO
			mov		eax,MAXYECHO
			mul		esi
			movzx	eax,sonardata.sonar[eax+edi]
			.if eax>sonardata.Noise
				.if eax<40
					mov		eax,40h
				.endif
				xor		eax,0FFh
				mov		ah,al
				shl		eax,8
				mov		al,ah
				push	eax
				mov		eax,edi
				movzx	ecx,sonardata.sonarrange[esi]
				lea		ecx,[ecx+ecx*2]
				mov		ecx,sonarrange.range[ecx*4]
				mul		ecx
				div		ebx
				mov		ecx,eax
				pop		eax
				invoke SetPixel,sonardata.mDC,esi,ecx,eax
			.endif
			inc		edi
		.endw
		inc		esi
	.endw
	ret

UpdateBitmap endp

SonarThreadProc proc uses ebx esi edi,lParam:DWORD
	LOCAL	rect:RECT
	LOCAL	buffer[16]:BYTE
	LOCAL	dptinx:DWORD
	LOCAL	dwwrite:DWORD

	.if sonardata.hReply
		invoke ReadFile,sonardata.hReply,addr sonardata.RangeInx,1,addr dwwrite,NULL
		.if dwwrite==1
			mov		eax,sonardata.RangeInx
			call	ScrollEchoArray
			invoke ReadFile,sonardata.hReply,addr sonardata.sonar[MAXXECHO*MAXYECHO-MAXYECHO],MAXYECHO,addr dwwrite,NULL
			.if dwwrite==MAXYECHO
				call	Update
			.else
				invoke CloseHandle,sonardata.hReply
				mov		sonardata.hReply,0
			.endif
		.else
			invoke CloseHandle,sonardata.hReply
			mov		sonardata.hReply,0
		.endif
	.elseif fSTLink && fSTLink!=IDIGNORE
		invoke SendDlgItemMessage,hWnd,IDC_TRBRANGE,TBM_GETPOS,0,0
		.if eax!=sonardata.RangeInx
			invoke SetRange,eax
			invoke UpdateBitmap
			mov		sonardata.nCount,4
		.endif
		mov		eax,sonardata.RangeInx
	 	;Upload Start, PingPulses, Gain, Timer and Skip
	 	mov		sonardata.Start,0
		invoke STLinkWrite,hWnd,STM32_Sonar,addr sonardata.Start,8
		.if eax
			;Download ADCBattery, ADCWaterTemp and ADCAirTemp
			invoke STLinkRead,hWnd,STM32_Sonar+8,addr sonardata.dmy1,8
			.if eax
				call	ScrollEchoArray
				;Download sonar echo array
				invoke STLinkRead,hWnd,STM32_Sonar+16,addr sonardata.sonar[MAXXECHO*MAXYECHO-MAXYECHO],MAXYECHO
				.if eax
					call	Update
				 	;Upload Start, PingPulses, Gain, Timer and Skip
				 	mov		sonardata.Start,1
					invoke STLinkWrite,hWnd,STM32_Sonar,addr sonardata.Start,8
				.endif
			.endif
			movzx	eax,sonardata.ADCBattery
			mov		ecx,100
			mul		ecx
			mov		ecx,1625
			div		ecx
			invoke wsprintf,addr buffer,addr szFmtDec,eax
			invoke strlen,addr buffer
			movzx	ecx,word ptr buffer[eax-1]
			shl		ecx,8
			mov		cl,'.'
			mov		dword ptr buffer[eax-1],ecx
			invoke strcat,addr buffer,addr szVolts
			invoke strcpy,addr map.options.text[sizeof OPTIONS],addr buffer
		.else
			mov		fSTLink,0
		.endif
	.elseif fSTLink==IDIGNORE
		invoke SendDlgItemMessage,hWnd,IDC_TRBRANGE,TBM_GETPOS,0,0
		.if eax!=sonardata.RangeInx
			invoke SetRange,eax
			invoke UpdateBitmap
			mov		sonardata.nCount,4
		.endif
		mov		eax,sonardata.RangeInx
		call	ScrollEchoArray
		invoke RtlZeroMemory,offset sonardata.sonar[(MAXXECHO*MAXYECHO)-MAXYECHO],MAXYECHO
		.if !(pixcnt & 63)
			;Random direction
			invoke Random,30
			mov		pixdir,eax
		.endif
		.if !(pixcnt & 31)
			;Random move
			invoke Random,31
			mov		pixmov,eax
		.endif
		mov		ebx,pixdpt
		mov		eax,pixdir
		.if eax<=10 && ebx>100
			;Up
			sub		ebx,pixmov
		.elseif eax>10 && eax<=20 && ebx<15000
			;Down
			add		ebx,pixmov
		.endif
		mov		pixdpt,ebx
		inc		pixcnt
		mov		eax,ebx
		mov		ecx,1024
		mul		ecx
		mov		ecx,sonardata.RangeVal
		xor		edx,edx
		div		ecx
		mov		ecx,100
		xor		edx,edx
		div		ecx
		mov		ebx,eax
		xor		ecx,ecx
		.while ecx<64
			invoke Random,255
			.if ebx<MAXYECHO
				;Random echo
				mov		sonardata.sonar[ebx+MAXXECHO*MAXYECHO-MAXYECHO],al
			.endif
			inc		ebx
			inc		ecx
		.endw
		invoke Random,ebx
		.if eax>MINYECHO && eax<MAXYECHO
			mov		edx,eax
			invoke Random,255
			.if eax>150 && eax<160
				;Random fish
				mov		sonardata.sonar[edx+MAXXECHO*MAXYECHO-MAXYECHO],al
			.endif
		.endif
		call	Update
	.endif
	mov		fThread,FALSE
	ret

ScrollEchoArray:
	mov		esi,offset sonardata.sonarrange+1
	mov		edi,offset sonardata.sonarrange
	mov		ecx,MAXXECHO-1
	rep movsb
	mov		eax,sonardata.RangeInx
	mov		[edi],al
	mov		esi,offset sonardata.sonar+MAXYECHO
	mov		edi,offset sonardata.sonar
	mov		ecx,(MAXXECHO*MAXYECHO-MAXYECHO)/4
	rep movsd
	retn

CalculateDepth:
	mov		eax,sonardata.RangeVal
	mov		ecx,10
	mul		ecx
	mul		ebx
	mov		ecx,MAXYECHO
	div		ecx
	invoke wsprintf,addr buffer,addr szFmtDepth,eax
	invoke strlen,addr buffer
	movzx	ecx,word ptr buffer[eax-1]
	shl		ecx,8
	mov		cl,'.'
	mov		dword ptr buffer[eax-1],ecx
	invoke strcpy,addr sonardata.options.text[1*sizeof OPTIONS],addr buffer
	retn

TestRangeChange:
	.if sonardata.AutoRange
		;Test range decrement
		mov		eax,sonardata.RangeInx
		mov		ebx,dptinx
		.if eax && ebx<MAXYECHO/3 && ebx
			dec		eax
			invoke SendDlgItemMessage,hWnd,IDC_TRBRANGE,TBM_SETPOS,TRUE,eax
		.endif
		;Test range increment
		mov		eax,sonardata.RangeInx
		.if eax<(MAXRANGE-1) && (ebx>(MAXYECHO-MAXYECHO/5) || !ebx)
			inc		eax
			invoke SendDlgItemMessage,hWnd,IDC_TRBRANGE,TBM_SETPOS,TRUE,eax
		.endif
	.endif
	retn

TestDepth:
	xor		ecx,ecx
	xor		edx,edx
	mov		dptinx,ecx
	.while ecx<16
		movzx	eax,sonardata.sonar[ebx+ecx+MAXXECHO*MAXYECHO-MAXYECHO]
		.if eax>sonardata.Noise
			movzx	eax,sonardata.sonar[ebx+ecx+MAXXECHO*MAXYECHO-MAXYECHO*2]
			.if eax>sonardata.Noise
				movzx	eax,sonardata.sonar[ebx+ecx+MAXXECHO*MAXYECHO-MAXYECHO*3]
				.if eax>sonardata.Noise
					inc		edx
				.endif
			.endif
		.endif
		inc		ecx
	.endw
	mov		eax,FALSE
	.if edx>4
		mov		dptinx,ebx
		call	CalculateDepth
		mov		eax,TRUE
	.endif
	retn

FindDepth:
	xor		ebx,ebx
	xor		edx,edx
	.while ebx<MAXYECHO-17
		movzx	eax,sonardata.sonar[ebx+MAXXECHO*MAXYECHO-MAXYECHO]
		.if eax<=sonardata.Noise
			movzx	eax,sonardata.sonar[ebx+MAXXECHO*MAXYECHO-MAXYECHO*2]
			.if eax<=sonardata.Noise
				movzx	eax,sonardata.sonar[ebx+MAXXECHO*MAXYECHO-MAXYECHO*3]
				.if eax<=sonardata.Noise
					inc		edx
					.if edx>=3
						.break
					.endif
				.else
					xor		edx,edx
				.endif
			.else
				xor		edx,edx
			.endif
		.else
			xor		edx,edx
		.endif
		inc		ebx
	.endw
	.while ebx<MAXYECHO-17
		inc		ebx
		movzx	eax,sonardata.sonar[ebx+MAXXECHO*MAXYECHO-MAXYECHO]
		.if eax>sonardata.Noise
			movzx	eax,sonardata.sonar[ebx+MAXXECHO*MAXYECHO-MAXYECHO]
			.if eax>sonardata.Noise
				movzx	eax,sonardata.sonar[ebx+MAXXECHO*MAXYECHO-MAXYECHO]
				.if eax>sonardata.Noise
					call	TestDepth
					.break .if eax
				.endif
			.endif
		.endif
		xor		eax,eax
	.endw
	retn

FindFish:
	.if sonardata.FishDetect
		mov		ebx,MINYECHO
		mov		edi,dptinx
		.while ebx<edi
			movzx	eax,sonardata.sonar[ebx+MAXXECHO*MAXYECHO-MAXYECHO]
			.if eax>sonardata.Noise
				mov		eax,edi
				sub		eax,16
				.if sdword ptr eax>ebx
					;Large fish
					mov		sonardata.sonar[ebx+MAXXECHO*MAXYECHO-MAXYECHO],255
				.endif
			.endif
			inc		ebx
		.endw
	.endif
	retn

Update:
	mov		rect.left,0
	mov		rect.top,0
	mov		rect.right,MAXXECHO
	mov		rect.bottom,MAXYECHO
	invoke ScrollDC,sonardata.mDC,-1,0,addr rect,addr rect,NULL,NULL
	xor		ebx,ebx
	.while ebx<MAXYECHO
		movzx	eax,sonardata.sonar[ebx+MAXXECHO*MAXYECHO-MAXYECHO]
		.if eax>=254
			mov		sonardata.sonar[ebx+MAXXECHO*MAXYECHO-MAXYECHO],253
		.endif
		.if eax>sonardata.Noise
			.if eax<40
				mov		eax,40h
			.endif
			xor		eax,0FFh
			mov		ah,al
			shl		eax,8
			mov		al,ah
		.else
			mov		eax,SONARBACKCOLOR
		.endif
		invoke SetPixel,sonardata.mDC,MAXXECHO-1,ebx,eax
		inc		ebx
	.endw
	.if sonardata.hLog
		invoke WriteFile,sonardata.hLog,addr sonardata.RangeInx,1,addr dwwrite,NULL
		invoke WriteFile,sonardata.hLog,addr sonardata.sonar[MAXXECHO*MAXYECHO-MAXYECHO],MAXYECHO,addr dwwrite,NULL
	.endif
	.if sonardata.nCount
		invoke InvalidateRect,hSonar,NULL,TRUE
		invoke UpdateWindow,hSonar
		dec		sonardata.nCount
	.else
		call	FindDepth
		push	eax
		call	FindFish
		invoke InvalidateRect,hSonar,NULL,TRUE
		invoke UpdateWindow,hSonar
		pop		eax
		.if !eax
			;Depth not found, increment range
			.if sonardata.AutoRange
				mov		eax,sonardata.RangeInx
				.if eax<MAXRANGE-1
					inc		eax
					invoke SendDlgItemMessage,hWnd,IDC_TRBRANGE,TBM_SETPOS,TRUE,eax
				.endif
			.endif
		.else
			.if sonardata.AutoRange && dptinx
				call	TestRangeChange
			.endif
		.endif
	.endif
	retn

SonarThreadProc endp

ShowRangeDepthTempScale proc uses ebx esi edi,hDC:HDC
	LOCAL	rcsonar:RECT
	LOCAL	rect:RECT
	LOCAL	x:DWORD
	LOCAL	buffer[32]:BYTE

	invoke GetClientRect,hSonar,addr rcsonar
	invoke SetBkMode,hDC,TRANSPARENT
	xor		ebx,ebx
	mov		esi,offset sonardata.options
	.while ebx<MAXSONAROPTION
		.if [esi].OPTIONS.show
			mov		ecx,[esi].OPTIONS.pt.x
			mov		edx,[esi].OPTIONS.pt.y
			mov		rect.left,ecx
			mov		rect.top,edx
			mov		eax,rcsonar.right
			sub		eax,ecx
			mov		rect.right,eax
			mov		eax,rcsonar.bottom
			sub		eax,edx
			mov		rect.bottom,eax
			mov		eax,[esi].OPTIONS.font
			add		eax,7
			invoke SelectObject,hDC,map.font[eax*4]
			push	eax
			invoke strlen,addr [esi].OPTIONS.text
			mov		edi,eax
			mov		edx,[esi].OPTIONS.position
			.if !edx
				;Left, Top
				invoke SetTextColor,hDC,0FFFFFFh
				invoke DrawText,hDC,addr [esi].OPTIONS.text,edi,addr rect,DT_LEFT or DT_SINGLELINE
				add		rect.top,4
				invoke DrawText,hDC,addr [esi].OPTIONS.text,edi,addr rect,DT_LEFT or DT_SINGLELINE
				sub		rect.top,2
				sub		rect.left,2
				invoke DrawText,hDC,addr [esi].OPTIONS.text,edi,addr rect,DT_LEFT or DT_SINGLELINE
				add		rect.left,4
				invoke DrawText,hDC,addr [esi].OPTIONS.text,edi,addr rect,DT_LEFT or DT_SINGLELINE
				sub		rect.left,2
				invoke SetTextColor,hDC,0404040h
				invoke DrawText,hDC,addr [esi].OPTIONS.text,edi,addr rect,DT_LEFT or DT_SINGLELINE
			.elseif edx==1
				;Center, Top
				mov		rect.left,0
				mov		eax,[esi].OPTIONS.pt.x
				sub		rect.right,eax
				invoke SetTextColor,hDC,0404040h
				invoke DrawText,hDC,addr [esi].OPTIONS.text,edi,addr rect,DT_CENTER or DT_SINGLELINE
			.elseif edx==2
				;Rioght, Top
				invoke SetTextColor,hDC,0FFFFFFh
				invoke DrawText,hDC,addr [esi].OPTIONS.text,edi,addr rect,DT_RIGHT or DT_SINGLELINE
				add		rect.top,4
				invoke DrawText,hDC,addr [esi].OPTIONS.text,edi,addr rect,DT_RIGHT or DT_SINGLELINE
				sub		rect.top,2
				sub		rect.right,2
				invoke DrawText,hDC,addr [esi].OPTIONS.text,edi,addr rect,DT_RIGHT or DT_SINGLELINE
				add		rect.right,4
				invoke DrawText,hDC,addr [esi].OPTIONS.text,edi,addr rect,DT_RIGHT or DT_SINGLELINE
				sub		rect.right,2
				invoke SetTextColor,hDC,0404040h
				invoke DrawText,hDC,addr [esi].OPTIONS.text,edi,addr rect,DT_RIGHT or DT_SINGLELINE
			.elseif edx==3
				;Left, Bottom
				invoke SetTextColor,hDC,0FFFFFFh
				invoke DrawText,hDC,addr [esi].OPTIONS.text,edi,addr rect,DT_LEFT or DT_BOTTOM or DT_SINGLELINE
				add		rect.bottom,4
				invoke DrawText,hDC,addr [esi].OPTIONS.text,edi,addr rect,DT_LEFT or DT_BOTTOM or DT_SINGLELINE
				sub		rect.bottom,2
				sub		rect.left,2
				invoke DrawText,hDC,addr [esi].OPTIONS.text,edi,addr rect,DT_LEFT or DT_BOTTOM or DT_SINGLELINE
				add		rect.left,4
				invoke DrawText,hDC,addr [esi].OPTIONS.text,edi,addr rect,DT_LEFT or DT_BOTTOM or DT_SINGLELINE
				sub		rect.left,2
				invoke SetTextColor,hDC,0404040h
				invoke DrawText,hDC,addr [esi].OPTIONS.text,edi,addr rect,DT_LEFT or DT_BOTTOM or DT_SINGLELINE
			.elseif edx==4
				;Center, Bottom
				mov		rect.left,0
				mov		eax,[esi].OPTIONS.pt.x
				sub		rect.right,eax
				invoke SetTextColor,hDC,0404040h
				invoke DrawText,hDC,addr [esi].OPTIONS.text,edi,addr rect,DT_CENTER or DT_BOTTOM or DT_SINGLELINE
			.elseif edx==5
				;Right, Bottom
				invoke SetTextColor,hDC,0FFFFFFh
				invoke DrawText,hDC,addr [esi].OPTIONS.text,edi,addr rect,DT_RIGHT or DT_BOTTOM or DT_SINGLELINE
				add		rect.bottom,4
				invoke DrawText,hDC,addr [esi].OPTIONS.text,edi,addr rect,DT_RIGHT or DT_BOTTOM or DT_SINGLELINE
				sub		rect.bottom,2
				sub		rect.right,2
				invoke DrawText,hDC,addr [esi].OPTIONS.text,edi,addr rect,DT_RIGHT or DT_BOTTOM or DT_SINGLELINE
				add		rect.right,4
				invoke DrawText,hDC,addr [esi].OPTIONS.text,edi,addr rect,DT_RIGHT or DT_BOTTOM or DT_SINGLELINE
				sub		rect.right,2
				invoke SetTextColor,hDC,0404040h
				invoke DrawText,hDC,addr [esi].OPTIONS.text,edi,addr rect,DT_RIGHT or DT_BOTTOM or DT_SINGLELINE
			.endif
			pop		eax
			invoke SelectObject,hDC,eax
		.endif
		lea		esi,[esi+sizeof OPTIONS]
		inc		ebx
	.endw
	call	ShowScale
	call	ShowFish
	ret

ShowFish:
	invoke GetClientRect,hSonar,addr rcsonar
	mov		ebx,sonardata.RangeVal
	mov		esi,512
	sub		esi,rect.right
	.while esi<MAXXECHO
		xor		edi,edi
		.while edi<MAXYECHO
			mov		eax,MAXYECHO
			mul		esi
			movzx	eax,sonardata.sonar[eax+edi]
			.if eax==255
				;Large fish
				mov		eax,edi
				movzx	ecx,sonardata.sonarrange[esi]
				lea		ecx,[ecx+ecx*2]
				mov		ecx,sonarrange.range[ecx*4]
				mul		ecx
				div		ebx
				mov		ecx,rect.bottom
				mul		ecx
				mov		ecx,MAXYECHO
				div		ecx
				mov		ecx,eax
				mov		edx,rect.right
				sub		edx,512
				invoke ImageList_Draw,hIml,18,hDC,addr [esi+edx-14],addr [ecx-8],ILD_TRANSPARENT
			.endif
			inc		edi
		.endw
		inc		esi
	.endw
	retn

ShowScale:
	invoke GetStockObject,WHITE_PEN
	invoke SelectObject,hDC,eax
	push	eax
	invoke SetTextColor,hDC,0FFFFFFh

	invoke MoveToEx,hDC,1,5,NULL
	invoke LineTo,hDC,9,5
	mov		word ptr buffer,'0'
	invoke TextOut,hDC,11,-1,addr buffer,1
	invoke MoveToEx,hDC,5,5,NULL
	mov		ebx,rect.bottom
	sub		ebx,13
	invoke LineTo,hDC,5,ebx
	invoke MoveToEx,hDC,1,ebx,NULL
	invoke LineTo,hDC,9,ebx
	mov		edi,sonardata.RangeVal
	invoke wsprintf,addr buffer,addr szFmtDec,edi
	invoke lstrlen,addr buffer
	invoke TextOut,hDC,11,addr [ebx-9],addr buffer,eax
	inc		ebx
	shr		ebx,1
	dec		ebx
	invoke MoveToEx,hDC,1,ebx,NULL
	invoke LineTo,hDC,9,ebx
	shr		edi,1
	invoke wsprintf,addr buffer,addr szFmtDec,edi
	invoke lstrlen,addr buffer
	invoke TextOut,hDC,11,addr [ebx-9],addr buffer,eax

	invoke MoveToEx,hDC,3,7,NULL
	invoke LineTo,hDC,11,7
	mov		word ptr buffer,'0'
	invoke TextOut,hDC,13,1,addr buffer,1
	invoke MoveToEx,hDC,7,7,NULL
	mov		ebx,rect.bottom
	sub		ebx,11
	invoke LineTo,hDC,7,ebx
	invoke MoveToEx,hDC,3,ebx,NULL
	invoke LineTo,hDC,11,ebx
	mov		edi,sonardata.RangeVal
	invoke wsprintf,addr buffer,addr szFmtDec,edi
	invoke lstrlen,addr buffer
	invoke TextOut,hDC,13,addr [ebx-11],addr buffer,eax
	dec		ebx
	shr		ebx,1
	inc		ebx
	invoke MoveToEx,hDC,3,ebx,NULL
	invoke LineTo,hDC,11,ebx
	shr		edi,1
	invoke wsprintf,addr buffer,addr szFmtDec,edi
	invoke lstrlen,addr buffer
	invoke TextOut,hDC,13,addr [ebx-11],addr buffer,eax

	pop		eax
	invoke SelectObject,hDC,eax
	invoke GetStockObject,BLACK_PEN
	invoke SelectObject,hDC,eax
	push	eax
	invoke SetTextColor,hDC,0h
	invoke MoveToEx,hDC,2,6,NULL
	invoke LineTo,hDC,10,6
	mov		word ptr buffer,'0'
	invoke TextOut,hDC,12,0,addr buffer,1
	invoke MoveToEx,hDC,6,6,NULL
	mov		ebx,rect.bottom
	sub		ebx,12
	invoke LineTo,hDC,6,ebx
	invoke MoveToEx,hDC,2,ebx,NULL
	invoke LineTo,hDC,10,ebx
	mov		edi,sonardata.RangeVal
	invoke wsprintf,addr buffer,addr szFmtDec,edi
	invoke lstrlen,addr buffer
	invoke TextOut,hDC,12,addr [ebx-10],addr buffer,eax
	shr		ebx,1
	invoke MoveToEx,hDC,2,ebx,NULL
	invoke LineTo,hDC,10,ebx
	shr		edi,1
	invoke wsprintf,addr buffer,addr szFmtDec,edi
	invoke lstrlen,addr buffer
	invoke TextOut,hDC,12,addr [ebx-10],addr buffer,eax
	pop		eax
	invoke SelectObject,hDC,eax
	retn

ShowRangeDepthTempScale endp

SonarProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	ps:PAINTSTRUCT
	LOCAL	rect:RECT
	LOCAL	hDC:HDC
	LOCAL	mDC:HDC
	LOCAL	hBmp:HBITMAP

	mov		eax,uMsg
	.if eax==WM_CREATE
		mov		eax,hWin
		mov		hSonar,eax
		invoke GetDC,hWin
		mov		hDC,eax
		invoke CreateCompatibleDC,hDC
		mov		sonardata.mDC,eax
		invoke CreateCompatibleBitmap,hDC,MAXXECHO,MAXYECHO
		mov		sonardata.hBmp,eax
		invoke SelectObject,sonardata.mDC,eax
		mov		sonardata.hBmpOld,eax
		mov		rect.left,0
		mov		rect.top,0
		mov		rect.right,MAXXECHO
		mov		rect.bottom,MAXYECHO
		invoke CreateSolidBrush,SONARBACKCOLOR
		push	eax
		invoke FillRect,sonardata.mDC,addr rect,eax
		pop		eax
		invoke DeleteObject,eax
		invoke ReleaseDC,hWin,hDC
		mov		pixdpt,250
		mov		eax,sonardata.RangeInx
		lea		eax,[eax+eax*2]
		mov		eax,sonarrange.interval[eax*4]
		invoke SetTimer,hWin,1000,eax,NULL
	.elseif eax==WM_TIMER
		.if !fSTLink
			mov		fSTLink,IDIGNORE
			invoke STLinkConnect,hWnd
			.if eax==IDABORT
				invoke SendMessage,hWnd,WM_CLOSE,0,0
			.else
				mov		fSTLink,eax
			.endif
			.if fSTLink && fSTLink!=IDIGNORE
				invoke STLinkReset,hWnd
			.endif
		.endif
		.if fSTLink && !fThread
			mov		fThread,TRUE
			invoke CreateThread,NULL,NULL,addr SonarThreadProc,hWin,0,addr tid
			invoke CloseHandle,eax
			invoke KillTimer,hWin,1000
			mov		eax,sonardata.RangeInx
			lea		eax,[eax+eax*2]
			mov		eax,sonarrange.interval[eax*4]
			invoke SetTimer,hWin,1000,eax,NULL
		.endif
	.elseif eax==WM_DESTROY
		.if fSTLink && fSTLink!=IDIGNORE
			invoke STLinkDisconnect
		.endif
		invoke SelectObject,sonardata.mDC,sonardata.hBmpOld
		invoke DeleteObject,sonardata.hBmp
		invoke DeleteDC,sonardata.mDC
	.elseif eax==WM_PAINT
		invoke GetClientRect,hWin,addr rect
		invoke BeginPaint,hWin,addr ps
		invoke CreateCompatibleDC,ps.hdc
		mov		mDC,eax
		invoke CreateCompatibleBitmap,ps.hdc,rect.right,rect.bottom
		invoke SelectObject,mDC,eax
		push	eax
		invoke CreateSolidBrush,SONARBACKCOLOR
		push	eax
		invoke FillRect,mDC,addr rect,eax
		pop		eax
		invoke DeleteObject,eax
		mov		ecx,MAXXECHO
		sub		ecx,rect.right
		mov		eax,sonardata.RangeVal
		mov		edx,10
		mul		edx
		sub		rect.bottom,12
		invoke StretchBlt,mDC,0,6,rect.right,rect.bottom,sonardata.mDC,ecx,0,rect.right,MAXYECHO,SRCCOPY
		invoke ShowRangeDepthTempScale,mDC
		add		rect.bottom,12
		invoke BitBlt,ps.hdc,0,0,rect.right,rect.bottom,mDC,0,0,SRCCOPY
		pop		eax
		invoke SelectObject,mDC,eax
		invoke DeleteObject,eax
		invoke DeleteDC,mDC
		invoke EndPaint,hWin,addr ps
	.else
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
		ret
	.endif
	xor    eax,eax
	ret

SonarProc endp
