
.code

DDSGenWave proc uses ebx esi edi

	mov		ddswavedata.DDS_VMin,4095
	mov		ddswavedata.DDS_VMax,0
	mov		eax,ddswavedata.DDS_WaveForm
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
		mov		ecx,DACMAX+1
		mul		ecx
		cdq
		mov		ecx,4096
		div		ecx
		mov		ecx,ddswavedata.DDS_Amplitude
		mul		ecx
		mov		ecx,DACMAX+1
		div		ecx
		mov		ecx,ddswavedata.DDS_Amplitude
		shr		ecx,1
		sub		ax,cx
		add		ax,DACMAX+1
		mov		ecx,ddswavedata.DDS_DCOffset
		add		ax,cx
		sub		ax,DACMAX+1+(DACMAX+1)/2
		.if CARRY?
			xor		ax,ax
		.elseif ax>DACMAX
			mov		ax,DACMAX
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

DDSSetStruct proc cmnd:DWORD

	mov		eax,cmnd
	mov		STM32_Cmd.STM32_Dds.DDS_Cmd,ax
	mov		eax,ddswavedata.DDS_WaveForm
	mov		STM32_Cmd.STM32_Dds.DDS_Wave,ax
	mov		eax,ddswavedata.DDS_Amplitude
	mov		STM32_Cmd.STM32_Dds.DDS_Amplitude,eax
	mov		eax,ddswavedata.DDS_DCOffset
	mov		STM32_Cmd.STM32_Dds.DDS_DCOffset,eax
	mov		eax,ddswavedata.DDS_PhaseFrq
	mov		STM32_Cmd.STM32_Dds.DDS__PhaseAdd,eax
	.if connected && fThreadDone
		mov		mode,CMD_DDSSET
	.endif
	ret

DDSSetStruct endp

DDSChildProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	buffer[64]:BYTE

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke GetDlgItem,hWin,IDC_UDCDDSFRQ
		mov		hDDS,eax
		mov		ddswavedata.SWEEP_SubMode,SWEEP_SubModeOff
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
		invoke SendDlgItemMessage,hWin,IDC_TRBDDSAMP,TBM_SETRANGE,FALSE,DACMAX SHL 16
		invoke SendDlgItemMessage,hWin,IDC_TRBDDSAMP,TBM_SETPOS,TRUE,ddswavedata.DDS_Amplitude
		invoke SendDlgItemMessage,hWin,IDC_TRBDDSOFS,TBM_SETRANGE,FALSE,(((DACMAX+1)*2-1) SHL 16)
		invoke SendDlgItemMessage,hWin,IDC_TRBDDSOFS,TBM_SETPOS,TRUE,ddswavedata.DDS_DCOffset
		invoke ImageList_GetIcon,hIml,0,ILD_NORMAL
		mov		ebx,eax
		push	0
		push	IDC_BTNDDSWAVEDN
		push	IDC_BTNDDSFRQDN
		push	IDC_BTNDDSAMPDN
		mov		eax,IDC_BTNDDSOFSDN
		.while eax
			invoke GetDlgItem,hWin,eax
			mov		edi,eax
			invoke SendMessage,edi,BM_SETIMAGE,IMAGE_ICON,ebx
			invoke SetWindowLong,edi,GWL_WNDPROC,offset ButtonProc
			mov		lpOldButtonProc,eax
			pop		eax
		.endw
		invoke ImageList_GetIcon,hIml,1,ILD_NORMAL
		mov		ebx,eax
		push	0
		push	IDC_BTNDDSWAVEUP
		push	IDC_BTNDDSFRQUP
		push	IDC_BTNDDSAMPUP
		mov		eax,IDC_BTNDDSOFSUP
		.while eax
			invoke GetDlgItem,hWin,eax
			mov		edi,eax
			invoke SendMessage,edi,BM_SETIMAGE,IMAGE_ICON,ebx
			invoke SetWindowLong,edi,GWL_WNDPROC,offset ButtonProc
			mov		lpOldButtonProc,eax
			pop		eax
		.endw
		mov		ddswavedata.DDS_Frequency,5000
		invoke SetDlgItemInt,hWin,IDC_EDTDDSFRQ,ddswavedata.DDS_Frequency,FALSE
		invoke DDSHzToPhaseAdd,eax
		mov		ddswavedata.DDS_PhaseFrq,eax
		invoke FormatFrequency,ddswavedata.DDS_Frequency,addr buffer
		invoke SetWindowText,hDDS,addr buffer
	.elseif	eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDC_BTNDDSFRQDN
				.if ddswavedata.DDS_Frequency>1
					dec		ddswavedata.DDS_Frequency
					invoke SetDlgItemInt,hWin,IDC_EDTDDSFRQ,ddswavedata.DDS_Frequency,FALSE
					invoke DDSHzToPhaseAdd,ddswavedata.DDS_Frequency
					mov		ddswavedata.DDS_PhaseFrq,eax
					invoke FormatFrequency,ddswavedata.DDS_Frequency,addr buffer
					invoke SetWindowText,hDDS,addr buffer
					invoke DDSSetStruct,DDS_PHASESET
					invoke InvalidateRect,hDDSScrn,NULL,TRUE
				.endif
			.elseif eax==IDC_BTNDDSFRQUP
				.if ddswavedata.DDS_Frequency<5000000
					inc		ddswavedata.DDS_Frequency
					invoke SetDlgItemInt,hWin,IDC_EDTDDSFRQ,ddswavedata.DDS_Frequency,FALSE
					invoke DDSHzToPhaseAdd,ddswavedata.DDS_Frequency
					mov		ddswavedata.DDS_PhaseFrq,eax
					invoke FormatFrequency,ddswavedata.DDS_Frequency,addr buffer
					invoke SetWindowText,hDDS,addr buffer
					invoke DDSSetStruct,DDS_PHASESET
					invoke InvalidateRect,hDDSScrn,NULL,TRUE
				.endif
			.elseif eax==IDC_BTNDDSWAVEDN
				mov		eax,ddswavedata.DDS_WaveForm
				.if eax
					dec		ddswavedata.DDS_WaveForm
					invoke DDSGenWave
					call	SetWave
					invoke DDSSetStruct,DDS_WAVESET
				.endif
			.elseif eax==IDC_BTNDDSWAVEUP
				mov		eax,ddswavedata.DDS_WaveForm
				.if eax<DDS_ModeRevSawWave
					inc		ddswavedata.DDS_WaveForm
					invoke DDSGenWave
					call	SetWave
					invoke DDSSetStruct,DDS_WAVESET
				.endif
			.elseif eax==IDC_BTNDDSAMPDN
				.if ddswavedata.DDS_Amplitude
					dec		ddswavedata.DDS_Amplitude
					invoke SendDlgItemMessage,hWin,IDC_TRBDDSAMP,TBM_SETPOS,TRUE,ddswavedata.DDS_Amplitude
					invoke DDSGenWave
					invoke DDSSetStruct,DDS_WAVESET
				.endif
			.elseif eax==IDC_BTNDDSAMPUP
				.if ddswavedata.DDS_Amplitude<DACMAX
					inc		ddswavedata.DDS_Amplitude
					invoke SendDlgItemMessage,hWin,IDC_TRBDDSAMP,TBM_SETPOS,TRUE,ddswavedata.DDS_Amplitude
					invoke DDSGenWave
					invoke DDSSetStruct,DDS_WAVESET
				.endif
			.elseif eax==IDC_BTNDDSOFSDN
				.if ddswavedata.DDS_DCOffset
					dec		ddswavedata.DDS_DCOffset
					invoke SendDlgItemMessage,hWin,IDC_TRBDDSOFS,TBM_SETPOS,TRUE,ddswavedata.DDS_DCOffset
					invoke DDSGenWave
					invoke DDSSetStruct,DDS_WAVESET
				.endif
			.elseif eax==IDC_BTNDDSOFSUP
				mov		eax,(DACMAX+1)*2-1
				.if ddswavedata.DDS_DCOffset<eax
					inc		ddswavedata.DDS_DCOffset
					invoke SendDlgItemMessage,hWin,IDC_TRBDDSOFS,TBM_SETPOS,TRUE,ddswavedata.DDS_DCOffset
					invoke DDSGenWave
					invoke DDSSetStruct,DDS_WAVESET
				.endif
			.endif
		.elseif edx==EN_KILLFOCUS
			.if eax==IDC_EDTDDSFRQ
				invoke GetDlgItemInt,hWin,IDC_EDTDDSFRQ,NULL,FALSE
				mov		ddswavedata.DDS_Frequency,eax
				invoke DDSHzToPhaseAdd,eax
				mov		ddswavedata.DDS_PhaseFrq,eax
				invoke FormatFrequency,ddswavedata.DDS_Frequency,addr buffer
				invoke SetWindowText,hDDS,addr buffer
				invoke DDSSetStruct,DDS_PHASESET
				invoke InvalidateRect,hDDSScrn,NULL,TRUE
			.endif
		.endif
	.elseif eax==WM_HSCROLL
		invoke GetDlgCtrlID,lParam
		.if eax==IDC_TRBDDSAMP
			invoke SendDlgItemMessage,hWin,IDC_TRBDDSAMP,TBM_GETPOS,0,0
			mov		ddswavedata.DDS_Amplitude,eax
			invoke DDSGenWave
			invoke DDSSetStruct,DDS_WAVESET
		.elseif eax==IDC_TRBDDSOFS
			invoke SendDlgItemMessage,hWin,IDC_TRBDDSOFS,TBM_GETPOS,0,0
			mov		ddswavedata.DDS_DCOffset,eax
			invoke DDSGenWave
			invoke DDSSetStruct,DDS_WAVESET
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
	LOCAL	buffer[128]:BYTE
	LOCAL	nMin:DWORD
	LOCAL	nMax:DWORD
	LOCAL	iTmp:DWORD
	LOCAL	fTmp:REAL10

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
		sub		rect.bottom,TEXTHIGHT
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
		invoke SelectClipRgn,mDC,NULL
		call	DrawDDSText

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

DrawDDSText:
	invoke SetBkMode,mDC,TRANSPARENT
	invoke SetTextColor,mDC,0FFFFFFh
	;Peak to Peak voltage
	mov		pt.x,10
	mov		eax,rect.bottom
	mov		pt.y,eax
	mov		eax,nMax
	sub		eax,nMin
	mov		ecx,ADCMAXMV
	imul	ecx
	mov		ecx,4095
	idiv	ecx
	mov		iTmp,eax
	invoke wsprintf,addr buffer[64],offset szFmtPPV,iTmp
	;Insert a'.' after the first digit
	mov		eax,dword ptr buffer[64+1]
	mov		buffer[64+1],'.'
	mov		dword ptr buffer[64+2],eax
	mov		dword ptr buffer[64+6],0
	invoke lstrcpy,addr buffer,offset szFmtVPP
	invoke lstrcat,addr buffer,addr buffer[64]
	lea		esi,buffer
	call	TextDraw
	;Signal period
	mov		eax,ddswavedata.DDS_Frequency
	.if eax
		mov		pt.x,200
		mov		iTmp,eax
		.if eax>1000000
			;Get signals period in ns
			fld		ten_9
			mov		ebx,offset sznS
		.elseif eax>1000
			;Get signals period in us
			fld		ten_6
			mov		ebx,offset szuS
		.else
			;Get signals period in ms
			fld		ten_3
			mov		ebx,offset szmS
		.endif
		fild	iTmp
		fdivp	st(1),st
		fstp	fTmp
		invoke FpToAscii,addr fTmp,addr buffer[64],FALSE
		mov		eax,64
		.while buffer[eax]
			.if buffer[eax]=='.'
				mov		buffer[eax+4],0
				.break
			.endif
			inc		eax
		.endw
		invoke lstrcpy,addr buffer,offset szFmtPER
		invoke lstrcat,addr buffer,addr buffer[64]
		invoke lstrcat,addr buffer,ebx
		lea		esi,buffer
		call	TextDraw
	.endif
	retn

TextDraw:
	invoke lstrlen,esi
	invoke TextOut,mDC,pt.x,pt.y,esi,eax
	retn

DrawWave:
	invoke CreatePen,PS_SOLID,2,008000h
	invoke SelectObject,mDC,eax
	push	eax
	mov		nMin,4096
	mov		nMax,0
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
	.if eax<nMin
		mov		nMin,eax
	.endif
	.if eax>nMax
		mov		nMax,eax
	.endif
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

