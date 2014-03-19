
.code

DDSGenWave proc uses ebx esi edi

	mov		ddswavedata.DDS_VMin,4095
	mov		ddswavedata.DDS_VMax,0
	mov		eax,ddswavedata.DDS_WaveForm
	lea		edx,[eax+1]
;	mov		command.WaveType,edx
;	mov		edx,ddswavedata.DDS_Amplitude
;	mov		command.Amplitude,edx
;	mov		edx,ddswavedata.DDS_DCOffset
;	mov		command.DCOffset,edx
	.if !eax
		mov		esi,offset DDS_SineWave
		mov		edi,offset ddswavedata.DDS_WaveData
		mov		ecx,2048
		rep		movsw
		mov		esi,offset DDS_SineWave
		mov		ecx,2048
		rep		movsw
		mov		esi,offset DDS_SineWave
		movsw
	.elseif eax==1
		mov		esi,offset DDS_TriangleWave
		mov		edi,offset ddswavedata.DDS_WaveData
		mov		ecx,2048
		rep		movsw
		mov		esi,offset DDS_TriangleWave
		mov		ecx,2048
		rep		movsw
		mov		esi,offset DDS_TriangleWave
		movsw
	.elseif eax==2
		mov		esi,offset DDS_SquareWave
		mov		edi,offset ddswavedata.DDS_WaveData
		mov		ecx,2048
		rep		movsw
		mov		esi,offset DDS_SquareWave
		mov		ecx,2048
		rep		movsw
		mov		esi,offset DDS_SquareWave
		movsw
	.elseif eax==3
		mov		esi,offset DDS_SawToothWave
		mov		edi,offset ddswavedata.DDS_WaveData
		mov		ecx,2048
		rep		movsw
		mov		esi,offset DDS_SawToothWave
		mov		ecx,2048
		rep		movsw
		mov		esi,offset DDS_SawToothWave
		movsw
	.elseif eax==4
		mov		esi,offset DDS_RevSawToothWave
		mov		edi,offset ddswavedata.DDS_WaveData
		mov		ecx,2048
		rep		movsw
		mov		esi,offset DDS_RevSawToothWave
		mov		ecx,2048
		rep		movsw
		mov		esi,offset DDS_RevSawToothWave
		movsw
	.endif
	xor		ebx,ebx
	mov		edi,offset ddswavedata.DDS_WaveData
	.while ebx<4098
		movzx	eax,word ptr [edi+ebx*WORD]
		mov		ecx,ddswavedata.DDS_Amplitude
		mul		ecx
		mov		ecx,4096
		div		ecx
		mov		ecx,ddswavedata.DDS_Amplitude
		shr		ecx,1
		sub		ax,cx
		add		ax,2048
		mov		ecx,ddswavedata.DDS_DCOffset
		add		ax,cx
		sub		ax,4096
		.if CARRY?
			xor		ax,ax
		.elseif ax>4095
			mov		ax,4095
		.endif
		mov		[edi+ebx*WORD],ax
		movzx	eax,ax
		.if eax<ddswavedata.DDS_VMin
			mov		ddswavedata.DDS_VMin,eax
		.endif
		.if eax>ddswavedata.DDS_VMax
			mov		ddswavedata.DDS_VMax,eax
		.endif
		inc		ebx
	.endw
	invoke InvalidateRect,hDDSScrn,NULL,TRUE
	invoke UpdateWindow,hDDSScrn
	mov		eax,ddswavedata.SWEEP_StepSize
	mov		ecx,ddswavedata.SWEEP_StepCount
	shr		ecx,1
	mul		ecx
	mov		ebx,ddswavedata.DDS_PhaseFrq
	sub		ebx,eax
	mov		eax,ddswavedata.SWEEP_StepSize
	mov		ecx,ddswavedata.SWEEP_StepCount
	mul		ecx
	mov		edx,ebx
	add		edx,eax
	mov		eax,ddswavedata.SWEEP_SubMode
	.if eax==SWEEP_SubModeUp
		mov		ddswavedata.DDS_Sweep.SWEEP_UpDovn,FALSE
		mov		ddswavedata.DDS_Sweep.SWEEP_Min,ebx
		mov		ddswavedata.DDS_Sweep.SWEEP_Max,edx
		mov		eax,ddswavedata.SWEEP_StepSize
		mov		ddswavedata.DDS_Sweep.SWEEP_Add,eax
	.elseif eax==SWEEP_SubModeDown
		mov		ddswavedata.DDS_Sweep.SWEEP_UpDovn,FALSE
		mov		ddswavedata.DDS_Sweep.SWEEP_Max,ebx
		mov		ddswavedata.DDS_Sweep.SWEEP_Min,edx
		mov		eax,ddswavedata.SWEEP_StepSize
		neg		eax
		mov		ddswavedata.DDS_Sweep.SWEEP_Add,eax
	.elseif eax==SWEEP_SubModeUpDown
		mov		ddswavedata.DDS_Sweep.SWEEP_UpDovn,TRUE
		mov		ddswavedata.DDS_Sweep.SWEEP_Min,ebx
		mov		ddswavedata.DDS_Sweep.SWEEP_Max,edx
		mov		eax,ddswavedata.SWEEP_StepSize
		mov		ddswavedata.DDS_Sweep.SWEEP_Add,eax
	.elseif eax==SWEEP_SubModePeak
		mov		ddswavedata.DDS_Sweep.SWEEP_UpDovn,FALSE
		mov		ddswavedata.DDS_Sweep.SWEEP_Min,ebx
		mov		ddswavedata.DDS_Sweep.SWEEP_Max,edx
		mov		eax,ddswavedata.SWEEP_StepSize
		mov		ddswavedata.DDS_Sweep.SWEEP_Add,eax
	.endif
	ret

DDSGenWave endp

DDSHzToPhaseAdd proc frq:DWORD
	LOCAL	iTmp:DWORD

	fild	frq
	fild	dds64
	fmulp	st(1),st
	fild	ddscycles
	fmulp	st(1),st
	mov		iTmp,STM32_CLOCK
	fild	iTmp
	fdivp	st(1),st
	fistp	frq
	mov		eax,frq
	ret

DDSHzToPhaseAdd endp

DDSScrnChildProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke GetDlgItem,hWin,IDC_UDCDDSSCRN
		mov		hDDSScrn,eax
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

DDSScrnChildProc endp

DDSChildProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	
	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke GetDlgItem,hWin,IDC_UDCDDSFRQ
		mov		hDDS,eax
		mov		ddswavedata.SWEEP_SubMode,SWEEP_SubModeOff
		mov		ddswavedata.DDS_DacBuffer,TRUE
		invoke DDSHzToPhaseAdd,5000	;5KHz
		mov		ddswavedata.DDS_Frequency,eax
		inc		eax
		mov		ddswavedata.DDS_PhaseFrq,eax
		mov		ddswavedata.DDS_WaveForm,DDS_ModeSinWave
		mov		ddswavedata.DDS_Amplitude,DACMAX
		mov		ddswavedata.DDS_DCOffset,DACMAX
		invoke DDSHzToPhaseAdd,10	;10Hz
		mov		ddswavedata.SWEEP_StepSize,eax
		mov		ddswavedata.SWEEP_StepTime,999
		mov		ddswavedata.SWEEP_StepCount,101
		invoke DDSGenWave
		call	SetWave
		mov		esi,offset DDS_SineWave
		mov		edi,offset ddswavedata.DDS_PeakData
		xor		ebx,ebx
		.while ebx<1536
			mov		ax,[esi+ebx*WORD]
			mov		[edi+ebx*WORD],ax
			inc		ebx
		.endw
	.elseif	eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDC_BTNDDSWAVEDN
				mov		eax,ddswavedata.DDS_WaveForm
				.if eax
					dec		ddswavedata.DDS_WaveForm
					invoke DDSGenWave
					call	SetWave
				.endif
			.elseif eax==IDC_BTNDDSWAVEUP
				mov		eax,ddswavedata.DDS_WaveForm
				.if eax<DDS_ModeRevSawWave
					inc		ddswavedata.DDS_WaveForm
					invoke DDSGenWave
					call	SetWave
				.endif
			.endif
		.endif
	.else
		mov		eax,FALSE
		ret
	.endif
	ret

SetWave:
	mov		ebx,ddswavedata.DDS_WaveForm
	mov		esi,offset szDDS_Waves
	.while ebx
		invoke lstrlen,esi
		lea		esi,[esi+eax+1]
		dec		ebx
	.endw
	invoke SetDlgItemText,hWin,IDC_STCDDSWAVE,esi
	retn

DDSChildProc  endp

DDSProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	rect:RECT
	LOCAL	ddsrect:RECT
	LOCAL	ps:PAINTSTRUCT
	LOCAL	mDC:HDC
	LOCAL	hBmp:HBITMAP
	LOCAL	pt:POINT

	mov		eax,uMsg
	.if eax==WM_PAINT
		invoke GetClientRect,hWin,addr rect
		invoke BeginPaint,hWin,addr ps
		invoke CreateCompatibleDC,ps.hdc
		mov		mDC,eax
		invoke CreateCompatibleBitmap,ps.hdc,rect.right,rect.bottom
		mov		hBmp,eax
		invoke SelectObject,mDC,eax
		push	eax
		invoke GetStockObject,BLACK_BRUSH
		invoke FillRect,mDC,addr rect,eax
		; Calculate the scope rect
		mov		eax,rect.right
		sub		eax,SCOPEWT
		shr		eax,1
		mov		ddsrect.left,eax
		add		eax,SCOPEWT
		inc		eax
		mov		ddsrect.right,eax
		mov		eax,rect.bottom
		sub		eax,SCOPEHT
		shr		eax,1
		mov		ddsrect.top,eax
		add		eax,SCOPEHT
		inc		eax
		mov		ddsrect.bottom,eax
		;Create a clip region
		invoke CreateRectRgn,ddsrect.left,ddsrect.top,ddsrect.right,ddsrect.bottom
		push	eax
		invoke SelectClipRgn,mDC,eax
		pop		eax
		invoke DeleteObject,eax
		;Draw grid
		call	DrawGrid
		;Draw wave
		call	DrawWave

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

DrawWave:
	invoke CreatePen,PS_SOLID,2,008000h
	invoke SelectObject,mDC,eax
	push	eax
	mov		esi,offset ddswavedata.DDS_WaveData
	xor		edi,edi
	call	GetPoint
	invoke MoveToEx,mDC,pt.x,pt.y,NULL
	.while edi<4097*WORD
		call	GetPoint
		invoke LineTo,mDC,pt.x,pt.y
		inc		edi
		inc		edi
	.endw
	pop		eax
	invoke SelectObject,mDC,eax
	invoke DeleteObject,eax
	retn

DrawGrid:
	; Create gridlines pen
	invoke CreatePen,PS_SOLID,1,404040h
	invoke SelectObject,mDC,eax
	push	eax
	;Draw horizontal lines
	mov		edi,ddsrect.top
	xor		ecx,ecx
	.while ecx<GRIDY+1
		push	ecx
		invoke MoveToEx,mDC,ddsrect.left,edi,NULL
		invoke LineTo,mDC,ddsrect.right,edi
		add		edi,GRIDSIZE
		pop		ecx
		inc		ecx
	.endw
	;Draw vertical lines
	mov		edi,ddsrect.left
	xor		ecx,ecx
	.while ecx<GRIDX+1
		push	ecx
		invoke MoveToEx,mDC,edi,ddsrect.top,NULL
		invoke LineTo,mDC,edi,ddsrect.bottom
		add		edi,GRIDSIZE
		pop		ecx
		inc		ecx
	.endw
	pop		eax
	invoke SelectObject,mDC,eax
	invoke DeleteObject,eax
	retn

GetPoint:
	;Get X position
	mov		eax,edi
	mov		ecx,ddsrect.right
	sub		ecx,ddsrect.left
	mul		ecx
	mov		ecx,4097*2
	div		ecx
	add		eax,ddsrect.left
	mov		pt.x,eax
	;Get y position
	movzx	eax,word ptr [esi+edi]
	sub		eax,DACMAX
	neg		eax
	mov		ecx,ddsrect.bottom
	sub		ecx,ddsrect.top
	sub		ecx,GRIDSIZE*2
	mul		ecx
	mov		ecx,DACMAX
	div		ecx
	add		eax,ddsrect.top
	add		eax,GRIDSIZE
	mov		pt.y,eax
	retn

DDSProc endp

