
.code

ScopeScrnChildProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke GetDlgItem,hWin,IDC_UDCSCPSCRN
		mov		hScpScrn,eax
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

ScopeScrnChildProc endp

ScpChildProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	
	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke GetDlgItem,hWin,IDC_UDCSCP
		mov		hScp,eax
		invoke SendDlgItemMessage,hWin,IDC_CHKTRIPLE,BM_SETCHECK,BST_CHECKED,0
		invoke SendDlgItemMessage,hWin,IDC_TRBADCCLOCK,TBM_SETRANGE,FALSE,3 SHL 16
		mov		eax,3
		sub		eax,STM32_Cmd.STM32_Scp.ADC_Prescaler
		invoke SendDlgItemMessage,hWin,IDC_TRBADCCLOCK,TBM_SETPOS,TRUE,eax
		invoke SendDlgItemMessage,hWin,IDC_TRBADCDELAY,TBM_SETRANGE,FALSE,(20-5) SHL 16
		mov		eax,20-5
		sub		eax,STM32_Cmd.STM32_Scp.ADC_TwoSamplingDelay
		invoke SendDlgItemMessage,hWin,IDC_TRBADCDELAY,TBM_SETPOS,TRUE,eax
		invoke SendDlgItemMessage,hWin,IDC_TRBTIMEDIV,TBM_SETRANGE,FALSE,MAXTIMEDIV SHL 16
		mov		eax,STM32_Cmd.STM32_Scp.ScopeTimeDiv
		invoke SendDlgItemMessage,hWin,IDC_TRBTIMEDIV,TBM_SETPOS,TRUE,eax
		invoke SendDlgItemMessage,hWin,IDC_TRBVOLTDIV,TBM_SETRANGE,FALSE,MAXVOLTDIV SHL 16
		mov		eax,STM32_Cmd.STM32_Scp.ScopeVoltDiv
		invoke SendDlgItemMessage,hWin,IDC_TRBVOLTDIV,TBM_SETPOS,TRUE,eax
		mov		eax,STM32_Cmd.STM32_Scp.ScopeTrigger
		add		eax,IDC_RBNTRIGGERNONE
		invoke SendDlgItemMessage,hWin,eax,BM_SETCHECK,BST_CHECKED,0
		invoke SendDlgItemMessage,hWin,IDC_TRBTRIGGERLEVEL,TBM_SETRANGE,FALSE,255 SHL 16
		mov		eax,STM32_Cmd.STM32_Scp.ScopeTriggerLevel
		shr		eax,4
		invoke SendDlgItemMessage,hWin,IDC_TRBTRIGGERLEVEL,TBM_SETPOS,TRUE,eax
		invoke SendDlgItemMessage,hWin,IDC_TRBVPOS,TBM_SETRANGE,FALSE,4095 SHL 16
		mov		eax,STM32_Cmd.STM32_Scp.ScopeVPos
		invoke SendDlgItemMessage,hWin,IDC_TRBVPOS,TBM_SETPOS,TRUE,eax
		invoke ImageList_GetIcon,hIml,0,ILD_NORMAL
		mov		ebx,eax
		push	0
		push	IDC_BTNSRD
		push	IDC_BTNADD
		push	IDC_BTNTDD
		push	IDC_BTNVDD
		push	IDC_BTNVPD
		mov		eax,IDC_BTNTLD
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
		push	IDC_BTNSRU
		push	IDC_BTNADU
		push	IDC_BTNTDU
		push	IDC_BTNVDU
		push	IDC_BTNVPU
		mov		eax,IDC_BTNTLU
		.while eax
			invoke GetDlgItem,hWin,eax
			mov		edi,eax
			invoke SendMessage,edi,BM_SETIMAGE,IMAGE_ICON,ebx
			invoke SetWindowLong,edi,GWL_WNDPROC,offset ButtonProc
			mov		lpOldButtonProc,eax
			pop		eax
		.endw
		invoke GetSampleTime,offset STM32_Cmd.STM32_Scp
	.elseif	eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax>=IDC_RBNTRIGGERNONE && eax<=IDC_RBNTRIGGERFALLING
				sub		eax,IDC_RBNTRIGGERNONE
				mov		STM32_Cmd.STM32_Scp.ScopeTrigger,eax
				invoke InvalidateRect,hScpScrn,NULL,TRUE
			.elseif eax==IDC_CHKSUBSAMPLING
				xor		fSubSampling,TRUE
			.elseif eax==IDC_CHKHOLDSAMPLING
				xor		fHoldSampling,TRUE
			.elseif eax==IDC_BTNSRD
				mov		eax,STM32_Cmd.STM32_Scp.ADC_Prescaler
				.if eax<3
					inc		eax
					mov		STM32_Cmd.STM32_Scp.ADC_Prescaler,eax
					sub		eax,3
					neg		eax
					invoke SendDlgItemMessage,hWin,IDC_TRBADCCLOCK,TBM_SETPOS,TRUE,eax
				.endif
			.elseif eax==IDC_BTNSRU
				mov		eax,STM32_Cmd.STM32_Scp.ADC_Prescaler
				.if eax
					dec		eax
					mov		STM32_Cmd.STM32_Scp.ADC_Prescaler,eax
					sub		eax,3
					neg		eax
					invoke SendDlgItemMessage,hWin,IDC_TRBADCCLOCK,TBM_SETPOS,TRUE,eax
				.endif
			.elseif eax==IDC_BTNADD
				.if STM32_Cmd.STM32_Scp.ADC_TripleMode
					mov		eax,STM32_Cmd.STM32_Scp.ADC_TwoSamplingDelay
					.if eax<15
						inc		eax
						mov		STM32_Cmd.STM32_Scp.ADC_TwoSamplingDelay,eax
						sub		eax,15
						neg		eax
						invoke SendDlgItemMessage,hWin,IDC_TRBADCDELAY,TBM_SETPOS,TRUE,eax
					.endif
				.else
					mov		eax,STM32_Cmd.STM32_Scp.ADC_SampleTime
					.if eax<7
						inc		eax
						mov		STM32_Cmd.STM32_Scp.ADC_SampleTime,eax
						sub		eax,7
						neg		eax
						invoke SendDlgItemMessage,hWin,IDC_TRBADCDELAY,TBM_SETPOS,TRUE,eax
					.endif
				.endif
			.elseif eax==IDC_BTNADU
				.if STM32_Cmd.STM32_Scp.ADC_TripleMode
					mov		eax,STM32_Cmd.STM32_Scp.ADC_TwoSamplingDelay
					.if eax
						dec		eax
						mov		STM32_Cmd.STM32_Scp.ADC_TwoSamplingDelay,eax
						sub		eax,15
						neg		eax
						invoke SendDlgItemMessage,hWin,IDC_TRBADCDELAY,TBM_SETPOS,TRUE,eax
					.endif
				.else
					mov		eax,STM32_Cmd.STM32_Scp.ADC_SampleTime
					.if eax
						dec		eax
						mov		STM32_Cmd.STM32_Scp.ADC_SampleTime,eax
						sub		eax,7
						neg		eax
						invoke SendDlgItemMessage,hWin,IDC_TRBADCDELAY,TBM_SETPOS,TRUE,eax
					.endif
				.endif
			.elseif eax==IDC_BTNTDU
				mov		eax,STM32_Cmd.STM32_Scp.ScopeTimeDiv
				.if eax<MAXTIMEDIV
					inc		eax
					mov		STM32_Cmd.STM32_Scp.ScopeTimeDiv,eax
					invoke SendDlgItemMessage,hWin,IDC_TRBTIMEDIV,TBM_SETPOS,TRUE,eax
				.endif
			.elseif eax==IDC_BTNTDD
				mov		eax,STM32_Cmd.STM32_Scp.ScopeTimeDiv
				.if eax
					dec		eax
					mov		STM32_Cmd.STM32_Scp.ScopeTimeDiv,eax
					invoke SendDlgItemMessage,hWin,IDC_TRBTIMEDIV,TBM_SETPOS,TRUE,eax
				.endif
			.elseif eax==IDC_BTNVDU
				mov		eax,STM32_Cmd.STM32_Scp.ScopeVoltDiv
				.if eax<MAXVOLTDIV
					inc		eax
					mov		STM32_Cmd.STM32_Scp.ScopeVoltDiv,eax
					invoke SendDlgItemMessage,hWin,IDC_TRBVOLTDIV,TBM_SETPOS,TRUE,eax
				.endif
			.elseif eax==IDC_BTNVDD
				mov		eax,STM32_Cmd.STM32_Scp.ScopeVoltDiv
				.if eax
					dec		eax
					mov		STM32_Cmd.STM32_Scp.ScopeVoltDiv,eax
					invoke SendDlgItemMessage,hWin,IDC_TRBVOLTDIV,TBM_SETPOS,TRUE,eax
				.endif
			.elseif eax==IDC_BTNVPU
				mov		eax,STM32_Cmd.STM32_Scp.ScopeVPos
				.if eax<4095
					inc		eax
					mov		STM32_Cmd.STM32_Scp.ScopeVPos,eax
					invoke SendDlgItemMessage,hWin,IDC_TRBVPOS,TBM_SETPOS,TRUE,eax
				.endif
			.elseif eax==IDC_BTNVPD
				mov		eax,STM32_Cmd.STM32_Scp.ScopeVPos
				.if eax
					dec		eax
					mov		STM32_Cmd.STM32_Scp.ScopeVPos,eax
					invoke SendDlgItemMessage,hWin,IDC_TRBVPOS,TBM_SETPOS,TRUE,eax
				.endif
			.elseif eax==IDC_BTNTLU
				mov		eax,STM32_Cmd.STM32_Scp.ScopeTriggerLevel
				shr		eax,4
				.if eax<255
					inc		eax
					push	eax
					invoke SendDlgItemMessage,hWin,IDC_TRBTRIGGERLEVEL,TBM_SETPOS,TRUE,eax
					pop		eax
					shl		eax,4
					mov		STM32_Cmd.STM32_Scp.ScopeTriggerLevel,eax
				.endif
			.elseif eax==IDC_BTNTLD
				mov		eax,STM32_Cmd.STM32_Scp.ScopeTriggerLevel
				shr		eax,4
				.if eax
					dec		eax
					push	eax
					invoke SendDlgItemMessage,hWin,IDC_TRBTRIGGERLEVEL,TBM_SETPOS,TRUE,eax
					pop		eax
					shl		eax,4
					mov		STM32_Cmd.STM32_Scp.ScopeTriggerLevel,eax
				.endif
			.elseif eax==IDC_CHKTRIPLE
				xor		STM32_Cmd.STM32_Scp.ADC_TripleMode,TRUE
				.if STM32_Cmd.STM32_Scp.ADC_TripleMode
					invoke SendDlgItemMessage,hWin,IDC_TRBADCDELAY,TBM_SETRANGE,FALSE,(20-5) SHL 16
					mov		eax,20-5
					sub		eax,STM32_Cmd.STM32_Scp.ADC_TwoSamplingDelay
					invoke SendDlgItemMessage,hWin,IDC_TRBADCDELAY,TBM_SETPOS,TRUE,eax
				.else
					invoke SendDlgItemMessage,hWin,IDC_TRBADCDELAY,TBM_SETRANGE,FALSE,7 SHL 16
					mov		eax,7
					sub		eax,STM32_Cmd.STM32_Scp.ADC_SampleTime
					invoke SendDlgItemMessage,hWin,IDC_TRBADCDELAY,TBM_SETPOS,TRUE,eax
				.endif
			.elseif eax==IDC_BTNAUTO
				invoke GetAuto,hWin
			.endif
		.endif
	.elseif eax==WM_HSCROLL
		invoke GetDlgCtrlID,lParam
		.if eax==IDC_TRBADCCLOCK
			;ADC Clock Divider
			invoke SendDlgItemMessage,hWin,IDC_TRBADCCLOCK,TBM_GETPOS,0,0
			sub		eax,3
			neg		eax
			mov		STM32_Cmd.STM32_Scp.ADC_Prescaler,eax
		.elseif eax==IDC_TRBADCDELAY
			.if STM32_Cmd.STM32_Scp.ADC_TripleMode
				;ADC Two Sampling Delay
				invoke SendDlgItemMessage,hWin,IDC_TRBADCDELAY,TBM_GETPOS,0,0
				sub		eax,20-5
				neg		eax
				mov		STM32_Cmd.STM32_Scp.ADC_TwoSamplingDelay,eax
			.else
				;ADC Sample time
				invoke SendDlgItemMessage,hWin,IDC_TRBADCDELAY,TBM_GETPOS,0,0
				sub		eax,7
				neg		eax
				mov		STM32_Cmd.STM32_Scp.ADC_SampleTime,eax
			.endif
		.elseif eax==IDC_TRBTIMEDIV
			;Scope Time / Div
			invoke SendDlgItemMessage,hWin,IDC_TRBTIMEDIV,TBM_GETPOS,0,0
			mov		STM32_Cmd.STM32_Scp.ScopeTimeDiv,eax
		.elseif eax==IDC_TRBVOLTDIV
			;Scope Volt / Div
			invoke SendDlgItemMessage,hWin,IDC_TRBVOLTDIV,TBM_GETPOS,0,0
			mov		STM32_Cmd.STM32_Scp.ScopeVoltDiv,eax
		.elseif eax==IDC_TRBTRIGGERLEVEL
			;Scope Trigger Level
			invoke SendDlgItemMessage,hWin,IDC_TRBTRIGGERLEVEL,TBM_GETPOS,0,0
			shl		eax,4
			mov		STM32_Cmd.STM32_Scp.ScopeTriggerLevel,eax
		.elseif eax==IDC_TRBVPOS
			;Scope V-Pos
			invoke SendDlgItemMessage,hWin,IDC_TRBVPOS,TBM_GETPOS,0,0
			mov		STM32_Cmd.STM32_Scp.ScopeVPos,eax
		.endif
		invoke InvalidateRect,hScpScrn,NULL,TRUE
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

ScpChildProc endp

ScopeProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	ps:PAINTSTRUCT
	LOCAL	rect:RECT
	LOCAL	scprect:RECT
	LOCAL	mDC:HDC
	LOCAL	hBmp:HBITMAP
	LOCAL	pt:POINT
	LOCAL	samplesize:DWORD
	LOCAL	iTmp:DWORD
	LOCAL	fTmp:REAL10
	LOCAL	nMin:DWORD
	LOCAL	nMax:DWORD
	LOCAL	nCenter:DWORD
	LOCAL	pixns:REAL10
	LOCAL	xmul:REAL10
	LOCAL	ymul:REAL10
	LOCAL	adcperiod:REAL10
	LOCAL	buffer[128]:BYTE
	LOCAL	tpos:DWORD
	LOCAL	tptx:DWORD
	LOCAL	tptxc:DWORD
	LOCAL	prevptx:DWORD
	LOCAL	prevpty:DWORD
	LOCAL	xofs:DWORD
	LOCAL	vdofs:DWORD
	LOCAL	ydiv:DWORD

	mov		eax,uMsg
	.if eax==WM_PAINT
		invoke FpToAscii,addr SampleRate,addr buffer,FALSE
		invoke lstrcat,addr buffer,offset szHz
		invoke SetDlgItemText,hScpCld,IDC_STCADCSAMPLERATE,addr buffer
		;Get time in ns for each pixel
		mov		eax,STM32_Cmd.STM32_Scp.ScopeTimeDiv
		mov		ecx,sizeof SCOPETIME
		mul		ecx
		mov		eax,ScopeTime.time[eax]
		mov		iTmp,eax
		fild	iTmp
		mov		iTmp,GRIDSIZE
		fild	iTmp
		fdivp	st(1),st
		fstp	pixns
		;Get x scale
		fld		SampleTime
		fld		pixns
		fdivp	st(1),st
		fstp	xmul
		;Get y scale
		mov		iTmp,ADCMAXMV
		fild	iTmp
		mov		iTmp,GRIDSIZE
		fild	iTmp
		fmulp	st(1),st
		mov		iTmp,ADCDIVMV
		fild	iTmp
		fdivp	st(1),st
		mov		iTmp,ADCMAX
		fild	iTmp
		fdivp	st(1),st
		fstp	ymul
		mov		eax,STM32_Cmd.STM32_Scp.ScopeVoltDiv
		mov		ecx,sizeof SCOPERANGE
		mul		ecx
		mov		vdofs,eax
		mov		eax,ScopeRange.ydiv[eax]
		mov		ydiv,eax

		mov		samplesize,ADCSAMPLESIZE
		;Get nMin and nMax
		mov		esi,offset ADC_Data
		mov		ecx,ADCMAX
		mov		edx,0
		mov		edi,16
		.while edi<samplesize
			movzx	eax,word ptr [esi+edi]
			.if eax<ecx
				mov		ecx,eax
			.elseif eax>edx
				mov		edx,eax
			.endif
			lea		edi,[edi+WORD]
		.endw
		mov		nMin,ecx
		mov		nMax,edx
		mov		nCenter,2048
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
		call	DrawScpText

		; Calculate the scope rect
		mov		eax,rect.right
		sub		eax,SCOPEWT
		shr		eax,1
		mov		scprect.left,eax
		add		eax,SCOPEWT
		inc		eax
		mov		scprect.right,eax
		mov		eax,rect.bottom
		sub		eax,SCOPEHT
		shr		eax,1
		mov		scprect.top,eax
		add		eax,SCOPEHT
		inc		eax
		mov		scprect.bottom,eax
		;Create a clip region
		invoke CreateRectRgn,scprect.left,scprect.top,scprect.right,scprect.bottom
		push	eax
		invoke SelectClipRgn,mDC,eax
		pop		eax
		invoke DeleteObject,eax

		mov		tpos,0
		mov		xofs,0
		.if STM32_Cmd.STM32_Scp.ScopeTrigger
			;Get trigger y position
			mov		eax,STM32_Cmd.STM32_Scp.ScopeTriggerLevel
			sub		eax,nCenter
			neg		eax
			mov		iTmp,eax
			fild	iTmp
			fld		ymul
			fmulp	st(1),st
			fistp	iTmp
			mov		eax,iTmp
			add		eax,SCOPEHT/2
			add		eax,scprect.top
			mov		tpos,eax
			mov		tptx,0
			mov		tptxc,0

			;Find trigger xofs
			call	DrawCurve
			.if tptx
				mov		esi,tptx
				mov		edi,tpos
				.while esi<scprect.right
					invoke GetPixel,mDC,esi,edi
					.break .if eax
					inc		esi
				.endw
				.if esi<scprect.right
					sub		esi,scprect.left
					mov		xofs,esi
				.endif
			.endif
			invoke GetStockObject,BLACK_BRUSH
			invoke FillRect,mDC,addr scprect,eax
		.endif
		;Draw grid
		call	DrawGrid
		;Draw trigger line
		call	DrawTrigger
		;Draw curve
		call	DrawCurve
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
	
DrawScpText:
	invoke SetBkMode,mDC,TRANSPARENT
	invoke SetTextColor,mDC,0FFFFFFh
	mov		eax,vdofs
	lea		esi,ScopeRange.range[eax]
	mov		pt.x,10
	mov		eax,rect.bottom
	mov		pt.y,eax
	call	TextDraw
	mov		pt.x,200
	mov		eax,nMax
	sub		eax,nMin
	mov		ecx,12500
	imul	ecx
	mov		ecx,3050
	idiv	ecx
	mov		iTmp,eax
	fld		ymul
	fild	iTmp
	fmulp	st(1),st
	fistp	iTmp
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
	mov		pt.x,10
	add		pt.y,20
	mov		eax,STM32_Cmd.STM32_Scp.ScopeTimeDiv
	mov		ecx,sizeof SCOPETIME
	mul		ecx
	lea		esi,ScopeTime.range[eax]
	call	TextDraw
	mov		eax,STM32_Cmd.STM32_Frq.FrequencySCP
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

DrawTrigger:
	.if tpos
		; Create trigger pen
		invoke CreatePen,PS_SOLID,1,0000C0h
		invoke SelectObject,mDC,eax
		push	eax
		invoke MoveToEx,mDC,scprect.left,tpos,NULL
		invoke LineTo,mDC,scprect.right,tpos
		pop		eax
		invoke SelectObject,mDC,eax
		invoke DeleteObject,eax
	.endif
	retn

DrawGrid:
	; Create gridlines pen
	invoke CreatePen,PS_SOLID,1,404040h
	invoke SelectObject,mDC,eax
	push	eax
	;Draw horizontal lines
	mov		edi,scprect.top
	xor		ecx,ecx
	.while ecx<GRIDY+1
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
	.while ecx<GRIDX+1
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
	retn

DrawCurve:
	invoke CreatePen,PS_SOLID,2,008000h
	invoke SelectObject,mDC,eax
	push	eax
	.if fSubSampling && !fNoFrequency
		fld		ten_9
		fild	STM32_Cmd.STM32_Frq.FrequencySCP
		fdivp	st(1),st
		fstp	adcperiod
		xor		ebx,ebx
		call	GetPointSubSample
		invoke MoveToEx,mDC,pt.x,pt.y,NULL
		mov		eax,pt.x
		mov		prevptx,eax
		mov		eax,pt.y
		mov		prevpty,eax
		lea		ebx,[ebx+1]
		.while TRUE
			call	GetPointSubSample
			.if pt.y
				invoke LineTo,mDC,pt.x,pt.y
				call	IsTrigger
			.endif
			mov		eax,pt.x
			.break .if sdword ptr eax>scprect.right
			lea		ebx,[ebx+1]
		.endw
	.else
		mov		edi,16
		mov		esi,offset ADC_Data
		xor		ebx,ebx
		call	GetPoint
		invoke MoveToEx,mDC,pt.x,pt.y,NULL
		mov		eax,pt.x
		mov		prevptx,eax
		mov		eax,pt.y
		mov		prevpty,eax
		lea		edi,[edi+WORD]
		lea		ebx,[ebx+1]
		.while edi<samplesize
			call	GetPoint
			invoke LineTo,mDC,pt.x,pt.y
			call	IsTrigger
			mov		eax,pt.x
			.break .if sdword ptr eax>scprect.right
			lea		edi,[edi+WORD]
			lea		ebx,[ebx+1]
		.endw
	.endif
	pop		eax
	invoke SelectObject,mDC,eax
	invoke DeleteObject,eax
	retn

IsTrigger:
	.if !tptx || tptxc<=1
		mov		ecx,pt.y
		mov		edx,prevpty
		.if STM32_Cmd.STM32_Scp.ScopeTrigger==1
			;Rising
			.if !tptxc
				.if edx>=tpos && ecx<tpos
					mov		ecx,prevptx
					mov		tptx,ecx
					mov		tptxc,1
				.endif
			.else
				.if edx<tpos && ecx<tpos
					mov		tptxc,2
				.else
					mov		tptx,0
					mov		tptxc,0
				.endif
			.endif
		.elseif STM32_Cmd.STM32_Scp.ScopeTrigger==2
			;Falling
			.if !tptxc
				.if edx<=tpos && ecx>tpos
					mov		ecx,prevptx
					mov		tptx,ecx
					mov		tptxc,1
				.endif
			.else
				.if edx>tpos && ecx>tpos
					mov		tptxc,2
				.else
					mov		tptx,0
					mov		tptxc,0
				.endif
			.endif
		.endif
		mov		ecx,pt.x
		mov		prevptx,ecx
		mov		ecx,pt.y
		mov		prevpty,ecx
	.endif
	retn

GetPoint:
	;Get X position
	fld		xmul
	mov		iTmp,ebx
	fild	iTmp
	fmulp	st(1),st
	fistp	iTmp
	mov		eax,iTmp
	add		eax,scprect.left
	sub		eax,xofs
	mov		pt.x,eax
	;Get y position
	fld		ymul
	movzx	eax,word ptr [esi+edi]
	sub		eax,nCenter
	neg		eax

	mov		ecx,4096
	imul	ecx
	mov		ecx,ydiv
	idiv	ecx

	mov		iTmp,eax
	fild	iTmp
	fmulp	st(1),st
	fistp	iTmp
	mov		eax,iTmp
	add		eax,SCOPEHT/2
	add		eax,scprect.top
	mov		pt.y,eax
	retn

GetPointSubSample:
	;Get X position
	mov		eax,STM32_Cmd.STM32_Scp.ScopeTimeDiv
	mov		ecx,sizeof SCOPETIME
	mul		ecx
	mov		eax,ScopeTime.time[eax]
	mov		iTmp,eax
	fild	iTmp
	fld		adcperiod
	fdivp	st(1),st
	mov		iTmp,2048/64
	fild	iTmp
	fmulp	st(1),st
	mov		iTmp,ebx
	fild	iTmp
	fdivrp	st(1),st
	fistp	iTmp
	mov		eax,iTmp
	add		eax,scprect.left
	sub		eax,xofs
	mov		pt.x,eax
	;Get y position
	mov		eax,ebx
	and		eax,2047
	mov		eax,SubSample[eax*DWORD]
	.if eax
		sub		eax,nCenter
		neg		eax

		mov		ecx,4096
		imul	ecx
		mov		ecx,ydiv
		idiv	ecx

		mov		iTmp,eax
		fld		ymul
		fild	iTmp
		fmulp	st(1),st
		fistp	iTmp
		mov		eax,iTmp
		add		eax,SCOPEHT/2
		add		eax,scprect.top
	.endif
	mov		pt.y,eax
	retn

ScopeProc endp

