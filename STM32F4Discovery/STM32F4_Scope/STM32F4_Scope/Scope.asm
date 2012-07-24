
.code

;########################################################################

GetSampleRate proc uses ebx esi,lpADC_CommandStruct:DWORD

	mov		esi,lpADC_CommandStruct
	movzx	eax,[esi].STM32_CommandStructDef.ScopeDataBits
	.if !eax
		mov		ebx,12
	.elseif eax==1
		mov		ebx,10
	.elseif eax==2
		mov		ebx,8
	.elseif eax==3
		mov		ebx,6
	.endif
	movzx	eax,[esi].STM32_CommandStructDef.ScopeSampleClocks
	.if !eax
		add		ebx,3
	.elseif eax==1
		add		ebx,15
	.elseif eax==2
		add		ebx,28
	.elseif eax==3
		add		ebx,56
	.elseif eax==4
		add		ebx,84
	.elseif eax==5
		add		ebx,112
	.elseif eax==6
		add		ebx,144
	.elseif eax==7
		add		ebx,480
	.endif
	mov		eax,STM32Clock
	shr		eax,1
	movzx	ecx,[esi].STM32_CommandStructDef.ScopeClockDiv
	.if !ecx
		shr		eax,1
	.elseif ecx==1
		shr		eax,2
	.elseif ecx==2
		cdq
		mov		ecx,6
		div		ecx
	.elseif ecx==3
		shr		eax,3
	.endif
	cdq
	div		ebx
	ret

GetSampleRate endp

;########################################################################

ScopeSetupProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		movzx	eax,scopedata.ADC_CommandStruct.TriggerMode
		add		eax,IDC_RBNTRIGMANUAL
		invoke CheckRadioButton,hWin,IDC_RBNTRIGMANUAL,IDC_RBNTRIGLGAEDGE,eax
		invoke SendDlgItemMessage,hWin,IDC_TRBTRIGLEVEL,TBM_SETRANGE,FALSE,(ADCMAX SHL 16)
		movzx	eax,scopedata.ADC_CommandStruct.TriggerValue
		invoke SendDlgItemMessage,hWin,IDC_TRBTRIGLEVEL,TBM_SETPOS,TRUE,eax
		invoke SendDlgItemMessage,hWin,IDC_TRBDCNULLOUTCHA,TBM_SETRANGE,FALSE,(ADCMAX SHL 16)
		movzx	eax,scopedata.ADC_CommandStruct.ScopeDCNullOutCHA
		invoke SendDlgItemMessage,hWin,IDC_TRBDCNULLOUTCHA,TBM_SETPOS,TRUE,eax
		invoke SendDlgItemMessage,hWin,IDC_TRBAMPLIFYCHA,TBM_SETRANGE,FALSE,(7 SHL 16)
		movzx	eax,scopedata.ADC_CommandStruct.ScopeAmplifyCHA
		xor		eax,07h
		invoke SendDlgItemMessage,hWin,IDC_TRBAMPLIFYCHA,TBM_SETPOS,TRUE,eax
		invoke SendDlgItemMessage,hWin,IDC_TRBDCNULLOUTCHB,TBM_SETRANGE,FALSE,(ADCMAX SHL 16)
		movzx	eax,scopedata.ADC_CommandStruct.ScopeDCNullOutCHB
		invoke SendDlgItemMessage,hWin,IDC_TRBDCNULLOUTCHB,TBM_SETPOS,TRUE,eax
		invoke SendDlgItemMessage,hWin,IDC_TRBAMPLIFYCHB,TBM_SETRANGE,FALSE,(7 SHL 16)
		movzx	eax,scopedata.ADC_CommandStruct.ScopeAmplifyCHB
		xor		eax,07h
		invoke SendDlgItemMessage,hWin,IDC_TRBAMPLIFYCHB,TBM_SETPOS,TRUE,eax
		mov		esi,offset szADCDataBits
		.while byte ptr [esi]
			invoke SendDlgItemMessage,hWin,IDC_CBODATABITS,CB_ADDSTRING,0,esi
			invoke lstrlen,esi
			lea		esi,[esi+eax+1]
		.endw
		movzx	eax,scopedata.ADC_CommandStruct.ScopeDataBits
		invoke SendDlgItemMessage,hWin,IDC_CBODATABITS,CB_SETCURSEL,eax,0
		mov		esi,offset szADCSampleClocks
		.while byte ptr [esi]
			invoke SendDlgItemMessage,hWin,IDC_CBOSAMPLECLOCKS,CB_ADDSTRING,0,esi
			invoke lstrlen,esi
			lea		esi,[esi+eax+1]
		.endw
		movzx	eax,scopedata.ADC_CommandStruct.ScopeSampleClocks
		invoke SendDlgItemMessage,hWin,IDC_CBOSAMPLECLOCKS,CB_SETCURSEL,eax,0
		mov		esi,offset szADCClockDiv
		.while byte ptr [esi]
			invoke SendDlgItemMessage,hWin,IDC_CBOCLOCKDIVISOR,CB_ADDSTRING,0,esi
			invoke lstrlen,esi
			lea		esi,[esi+eax+1]
		.endw
		movzx	eax,scopedata.ADC_CommandStruct.ScopeClockDiv
		invoke SendDlgItemMessage,hWin,IDC_CBOCLOCKDIVISOR,CB_SETCURSEL,eax,0
		invoke GetSampleRate,addr scopedata.ADC_CommandStruct
		invoke SendDlgItemMessage,hWin,IDC_TRBBUFFERSIZE,TBM_SETRANGE,FALSE,((STM32_MAXBLOCK) SHL 16)+1
		movzx	eax,scopedata.ADC_CommandStruct.DataBlocks
		invoke SendDlgItemMessage,hWin,IDC_TRBBUFFERSIZE,TBM_SETPOS,TRUE,eax
		call	Update
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDCANCEL
				invoke SendMessage,hWin,WM_CLOSE,0,1
			.else
				call	Update
			.endif
		.elseif edx==CBN_SELCHANGE
			call	Update
		.endif
	.elseif eax==WM_HSCROLL
		call	Update
	.elseif eax==WM_ACTIVATE
		mov		eax,wParam
		.if eax!=WA_INACTIVE
			mov		eax,hWin
			mov		hDlg,eax
		.endif
	.elseif eax==WM_CLOSE
		invoke DestroyWindow,hWin
		mov		childdialogs.hWndScopeSetup,0
		invoke SetFocus,hWnd
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

Update:
	;Get trigger type
	xor		ebx,ebx
	.while ebx<7
		invoke IsDlgButtonChecked,hWin,addr [ebx+IDC_RBNTRIGMANUAL]
		.break .if eax
		inc		ebx
	.endw
	mov		scopedata.ADC_CommandStruct.TriggerMode,bl
	;Get trigger levels
	invoke SendDlgItemMessage,hWin,IDC_TRBTRIGLEVEL,TBM_GETPOS,0,0
	xor		eax,0FFh
	mov		scopedata.ADC_CommandStruct.TriggerValue,al
	;Get DC nullouts
	invoke SendDlgItemMessage,hWin,IDC_TRBDCNULLOUTCHA,TBM_GETPOS,0,0
	xor		eax,0FFh
	mov		scopedata.ADC_CommandStruct.ScopeDCNullOutCHA,al
	invoke SendDlgItemMessage,hWin,IDC_TRBDCNULLOUTCHB,TBM_GETPOS,0,0
	xor		eax,0FFh
	mov		scopedata.ADC_CommandStruct.ScopeDCNullOutCHB,al
	;Get amplification levels
	invoke SendDlgItemMessage,hWin,IDC_TRBAMPLIFYCHA,TBM_GETPOS,0,0
	xor		eax,07h
	mov		scopedata.ADC_CommandStruct.ScopeAmplifyCHA,al
	invoke SendDlgItemMessage,hWin,IDC_TRBAMPLIFYCHB,TBM_GETPOS,0,0
	xor		eax,07h
	mov		scopedata.ADC_CommandStruct.ScopeAmplifyCHB,al
	;Get sample rate
	invoke SendDlgItemMessage,hWin,IDC_CBODATABITS,CB_GETCURSEL,0,0
	mov		scopedata.ADC_CommandStruct.ScopeDataBits,al
	invoke SendDlgItemMessage,hWin,IDC_CBOSAMPLECLOCKS,CB_GETCURSEL,0,0
	mov		scopedata.ADC_CommandStruct.ScopeSampleClocks,al
	invoke SendDlgItemMessage,hWin,IDC_CBOCLOCKDIVISOR,CB_GETCURSEL,0,0
	mov		scopedata.ADC_CommandStruct.ScopeClockDiv,al
	;Get buffer size
	invoke SendDlgItemMessage,hWin,IDC_TRBBUFFERSIZE,TBM_GETPOS,0,0
	mov		scopedata.ADC_CommandStruct.DataBlocks,al
	invoke GetSampleRate,addr scopedata.ADC_CommandStruct
	invoke SetDlgItemInt,hWin,IDC_STCSAMPLERATE,eax,FALSE
	retn

ScopeSetupProc endp

;#########################################################################

SubsamplingGetTrigger proc uses ebx esi edi,hWin:HWND
	LOCAL	tmp:DWORD

	invoke GetWindowLong,hWin,GWL_USERDATA
	mov		ebx,eax
	fld		[ebx].SCOPECHDATA.period
	fistp	tmp
	.if tmp
		xor		ecx,ecx
		lea		esi,[ebx].SCOPECHDATA.ADC_USData
		movzx	edi,[ebx].SCOPECHDATA.ADC_TriggerValue
		.if [ebx].SCOPECHDATA.ADC_TriggerEdge==STM32_TriggerRisingCHA || [ebx].SCOPECHDATA.ADC_TriggerEdge==STM32_TriggerRisingCHB
			;Find rising edge
			xor		eax,eax
			mov		al,ADCMAX
			.while ecx<sizeof SCOPECHDATA.ADC_USData
				.if al>[esi+ecx] && byte ptr [esi+ecx]
					mov		al,[esi+ecx]
					mov		edx,ecx
				.endif
				inc		ecx
			.endw
			mov		ecx,edx
			xor		edx,edx
			.while TRUE
				movzx	eax,byte ptr [esi+ecx]
				.break .if eax>=edi
				inc		ecx
				.if ecx>sizeof SCOPECHDATA.ADC_USData
					xor		ecx,ecx
					.break .if edx
					inc		edx
				.endif
			.endw
			mov		[ebx].SCOPECHDATA.nusstart,ecx
		.elseif [ebx].SCOPECHDATA.ADC_TriggerEdge==STM32_TriggerFallingCHA || [ebx].SCOPECHDATA.ADC_TriggerEdge==STM32_TriggerFallingCHB
			;Find falling edge
			xor		eax,eax
			.while ecx<sizeof SCOPECHDATA.ADC_USData
				.if byte ptr [esi+ecx]>al
					mov		al,byte ptr [esi+ecx]
					mov		edx,ecx
				.endif
				inc		ecx
			.endw
			mov		ecx,edx
			xor		edx,edx
			.while TRUE
				movzx	eax,byte ptr [esi+ecx]
				.break .if eax<=edi && eax
				inc		ecx
				.if ecx>sizeof SCOPECHDATA.ADC_USData
					xor		ecx,ecx
					.break .if edx
					inc		edx
				.endif
			.endw
			mov		[ebx].SCOPECHDATA.nusstart,ecx
		.else
			;No trigger
			mov		[ebx].SCOPECHDATA.nusstart,ecx
		.endif
	.endif
	ret

SubsamplingGetTrigger endp

Subsampling proc uses ebx esi edi,hWin:HWND
	LOCAL	tmp:DWORD

	invoke GetWindowLong,hWin,GWL_USERDATA
	mov		ebx,eax
	mov		[ebx].SCOPECHDATA.nusstart,0
	lea		edi,[ebx].SCOPECHDATA.ADC_USData
	invoke RtlZeroMemory,edi,sizeof SCOPECHDATA.ADC_USData
	fld		qword ptr nsinasec
	fld		[ebx].SCOPECHDATA.frequency
	fdivp	st(1),st
	fstp	[ebx].SCOPECHDATA.period
	invoke GetSampleRate,addr scopedata.ADC_CommandStructDone
	fld		qword ptr nsinasec
	mov		tmp,eax
	fild	tmp
	fdivp	st(1),st
	fstp	[ebx].SCOPECHDATA.convperiod
	fld		[ebx].SCOPECHDATA.period
	fistp	tmp
	.if tmp
		xor		edx,edx
		movzx	ecx,scopedata.ADC_CommandStructDone.DataBlocks
		mov		eax,STM32_BlockSize
		mul		ecx
		mov		ecx,eax
		lea		esi,[ebx].SCOPECHDATA.ADC_Data
		;The first byte seem to be corrupt, ignore it
		add		edx,1
		.while edx<ecx
			fld		[ebx].SCOPECHDATA.period
			.if [ebx].SCOPECHDATA.fTwoPeriods
				fld		[ebx].SCOPECHDATA.period
				faddp	st(1),st
			.endif
			mov		tmp,edx
			fild	tmp
			fld		[ebx].SCOPECHDATA.convperiod
			fmulp	st(1),st
			fprem
			fxch	st(1)
			fistp	tmp
			mov		tmp,STM32_MAXBLOCK*STM32_BlockSize-1
			fild	tmp
			fmulp	st(1),st
			fld		[ebx].SCOPECHDATA.period
			.if [ebx].SCOPECHDATA.fTwoPeriods
				fld		[ebx].SCOPECHDATA.period
				faddp	st(1),st
			.endif
			fdivp	st(1),st
			fistp	tmp
			mov		al,[esi+edx]
			;Avoid 0 as it is used to indicate not set bytes
			.if !al
				inc		al
			.endif
			push	edx
			mov		edx,tmp
			;If set, dont set it again
			.if !byte ptr [edi+edx]
				mov		[edi+edx],al
			.endif
			pop		edx
			inc		edx
		.endw
		invoke SubsamplingGetTrigger,hWin
	.endif
	ret

Subsampling endp

ScopeProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	ps:PAINTSTRUCT
	LOCAL	rect:RECT
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
		invoke GetParent,hWin
		invoke GetWindowLong,eax,GWL_USERDATA
		mov		ebx,eax
		.if !ebx
			xor		eax,eax
			ret
		.endif
		movzx	eax,scopedata.ADC_CommandStructDone.DataBlocks
		mov		ecx,STM32_BlockSize
		mul		ecx
		mov		samplesize,eax
		;Get Vmin, Vmax and Vpp
		lea		esi,[ebx].SCOPECHDATA.ADC_Data
		mov		ecx,255
		mov		edx,0
		xor		edi,edi
		.while edi<samplesize
			movzx	eax,byte ptr [esi+edi]
			.if eax<ecx
				mov		ecx,eax
			.elseif eax>edx
				mov		edx,eax
			.endif
			inc		edi
		.endw
		push	edx
		mov		eax,3000
		mul		ecx
		mov		ecx,255
		div		ecx
		mov		[ebx].SCOPECHDATA.vmin,eax
		pop		ecx
		mov		eax,3000
		mul		ecx
		mov		ecx,255
		div		ecx
		mov		[ebx].SCOPECHDATA.vmax,eax
		sub		eax,[ebx].SCOPECHDATA.vmin
		mov		[ebx].SCOPECHDATA.vpp,eax
		.if [ebx].SCOPECHDATA.fSubsampling
			mov		samplesize,STM32_MAXBLOCK*STM32_BlockSize
		.endif
		call	SetScrooll
		.if [ebx].SCOPECHDATA.fYMagnify
			invoke GetScrollRange,hWin,SB_VERT,addr nMin,addr nMax
			mov		eax,nMax
			sub		eax,rect.bottom
			shr		eax,1
			invoke SetScrollPos,hWin,SB_VERT,eax,TRUE
			mov		[ebx].SCOPECHDATA.fYMagnify,FALSE
			xor		eax,eax
			ret
		.endif
		invoke BeginPaint,hWin,addr ps
		invoke CreateCompatibleDC,ps.hdc
		mov		mDC,eax
		invoke CreateCompatibleBitmap,ps.hdc,rect.right,rect.bottom
		invoke SelectObject,mDC,eax
		push	eax
		invoke GetStockObject,BLACK_BRUSH
		invoke FillRect,mDC,addr rect,eax
		sub		rect.bottom,TEXTHIGHT
		;Draw horizontal lines
		invoke CreatePen,PS_SOLID,1,0303030h
		invoke SelectObject,mDC,eax
		push	eax
		mov		eax,rect.bottom
		mov		ecx,6
		xor		edx,edx
		div		ecx
		mov		edx,eax
		mov		edi,eax
		xor		ecx,ecx
		.while ecx<5
			push	ecx
			push	edx
			invoke MoveToEx,mDC,0,edi,NULL
			invoke LineTo,mDC,rect.right,edi
			pop		edx
			add		edi,edx
			pop		ecx
			inc		ecx
		.endw
		invoke MoveToEx,mDC,0,rect.bottom,NULL
		invoke LineTo,mDC,rect.right,rect.bottom
		;Draw vertical lines
		mov		eax,rect.right
		mov		ecx,10
		xor		edx,edx
		div		ecx
		mov		edx,eax
		mov		edi,eax
		xor		ecx,ecx
		.while ecx<9
			push	ecx
			push	edx
			invoke MoveToEx,mDC,edi,0,NULL
			invoke LineTo,mDC,edi,rect.bottom
			pop		edx
			add		edi,edx
			pop		ecx
			inc		ecx
		.endw
		pop		eax
		invoke SelectObject,mDC,eax
		invoke DeleteObject,eax
		;Draw trigger line
		invoke CreatePen,PS_SOLID,2,00080h
		invoke SelectObject,mDC,eax
		push	eax
		lea		esi,[ebx].SCOPECHDATA.ADC_TriggerValue
		push	[ebx].SCOPECHDATA.nusstart
		mov		[ebx].SCOPECHDATA.nusstart,0
		xor		edi,edi
		xor		[ebx].SCOPECHDATA.ADC_TriggerValue,0FFh
		call	GetPoint
		xor		[ebx].SCOPECHDATA.ADC_TriggerValue,0FFh
		pop		[ebx].SCOPECHDATA.nusstart
		invoke MoveToEx,mDC,pt.x,pt.y,NULL
		mov		eax,rect.right
		mov		pt.x,eax
		invoke LineTo,mDC,pt.x,pt.y
		pop		eax
		invoke SelectObject,mDC,eax
		invoke DeleteObject,eax
		mov		eax,hWin
		.if eax==scopedata.scopeCHAdata.hWndScope
			;Channel A
			mov		eax,00FF00h
		.else
			;Channel B
			mov		eax,0FFFF00h
		.endif
		invoke SetTextColor,mDC,eax
		invoke SetBkMode,mDC,TRANSPARENT
		invoke FormatFrequency,addr buffer,addr szFmtFrq,[ebx].SCOPECHDATA.frq_data.Frequency
		invoke FormatVoltage,addr buffer1,addr szFmtVmin,[ebx].SCOPECHDATA.vmin
		invoke lstrcat,addr buffer,addr buffer1
		invoke FormatVoltage,addr buffer1,addr szFmtVmax,[ebx].SCOPECHDATA.vmax
		invoke lstrcat,addr buffer,addr buffer1
		invoke FormatVoltage,addr buffer1,addr szFmtVpp,[ebx].SCOPECHDATA.vpp
		invoke lstrcat,addr buffer,addr buffer1
		invoke lstrlen,addr buffer
		mov		edx,rect.bottom
		add		edx,8
		invoke TextOut,mDC,0,edx,addr buffer,eax
		;Draw curve
		invoke CreateRectRgn,0,0,rect.right,rect.bottom
		push	eax
		invoke SelectClipRgn,mDC,eax
		pop		eax
		invoke DeleteObject,eax
		mov		eax,hWin
		.if eax==scopedata.scopeCHAdata.hWndScope
			;Channel A
			mov		eax,008000h
		.else
			;Channel B
			mov		eax,0808000h
		.endif
		invoke CreatePen,PS_SOLID,2,eax
		invoke SelectObject,mDC,eax
		push	eax
		.if [ebx].SCOPECHDATA.fSubsampling
			lea		esi,[ebx].SCOPECHDATA.ADC_USData
		.else
			lea		esi,[ebx].SCOPECHDATA.ADC_Data
			mov		[ebx].SCOPECHDATA.nusstart,0
		.endif
		xor		edi,edi
		call	GetPoint
		invoke MoveToEx,mDC,pt.x,pt.y,NULL
		.while edi<samplesize
			mov		edx,edi
			add		edx,[ebx].SCOPECHDATA.nusstart
			.if edx>=STM32_MAXBLOCK*STM32_BlockSize
				sub		edx,STM32_MAXBLOCK*STM32_BlockSize
			.endif
			.if byte ptr [esi+edx] || ![ebx].SCOPECHDATA.fSubsampling
				call	GetPoint
				.if sdword ptr pt.x>=0
					invoke LineTo,mDC,pt.x,pt.y
					mov		eax,pt.x
					.break .if sdword ptr eax>rect.right
				.else
					invoke MoveToEx,mDC,pt.x,pt.y,NULL
				.endif
			.endif
			inc		edi
		.endw
		pop		eax
		invoke SelectObject,mDC,eax
		invoke DeleteObject,eax
		.if [ebx].SCOPECHDATA.fBothChannels
			movzx	eax,scopedata.ADC_CommandStructDone.DataBlocks
			mov		ecx,STM32_BlockSize
			mul		ecx
			mov		samplesize,eax
			mov		eax,hWin
			.if eax==scopedata.scopeCHBdata.hWndScope
				;Channel A
				invoke GetParent,scopedata.scopeCHAdata.hWndScope
				invoke GetWindowLong,eax,GWL_USERDATA
				mov		ebx,eax
				mov		eax,008000h
			.else
				;Channel B
				invoke GetParent,scopedata.scopeCHBdata.hWndScope
				invoke GetWindowLong,eax,GWL_USERDATA
				mov		ebx,eax
				mov		eax,0808000h
			.endif
			invoke CreatePen,PS_SOLID,2,eax
			invoke SelectObject,mDC,eax
			push	eax
			lea		esi,[ebx].SCOPECHDATA.ADC_Data
			mov		[ebx].SCOPECHDATA.nusstart,0
			xor		edi,edi
			call	GetPoint
			invoke MoveToEx,mDC,pt.x,pt.y,NULL
			.while edi<samplesize
				mov		edx,edi
				add		edx,[ebx].SCOPECHDATA.nusstart
				call	GetPoint
				.if sdword ptr pt.x>=0
					invoke LineTo,mDC,pt.x,pt.y
					mov		eax,pt.x
					.break .if sdword ptr eax>rect.right
				.else
					invoke MoveToEx,mDC,pt.x,pt.y,NULL
				.endif
				inc		edi
			.endw
			pop		eax
			invoke SelectObject,mDC,eax
			invoke DeleteObject,eax
		.endif
		add		rect.bottom,TEXTHIGHT
		invoke BitBlt,ps.hdc,0,0,rect.right,rect.bottom,mDC,0,0,SRCCOPY
		pop		eax
		invoke SelectObject,mDC,eax
		invoke DeleteObject,eax
		invoke DeleteDC,mDC
		invoke EndPaint,hWin,addr ps
		xor		eax,eax
	.elseif eax==WM_SIZE
		invoke GetParent,hWin
		invoke GetWindowLong,eax,GWL_USERDATA
		.if eax
			mov		ebx,eax
			movzx	eax,scopedata.ADC_CommandStructDone.DataBlocks
			mov		ecx,STM32_BlockSize
			mul		ecx
			mov		samplesize,eax
			call	SetScrooll
		.endif
	.elseif eax==WM_HSCROLL
		mov		xsinf.cbSize,sizeof SCROLLINFO
		mov		xsinf.fMask,SIF_ALL
		invoke GetScrollInfo,hWin,SB_HORZ,addr xsinf
		mov		eax,wParam
		movzx	eax,ax
		.if eax==SB_THUMBPOSITION
			mov		eax,xsinf.nTrackPos
			invoke SetScrollPos,hWin,SB_HORZ,eax,TRUE
			invoke InvalidateRect,hWin,NULL,TRUE
		.elseif  eax==SB_THUMBTRACK
			mov		eax,xsinf.nTrackPos
			invoke SetScrollPos,hWin,SB_HORZ,eax,TRUE
			invoke InvalidateRect,hWin,NULL,TRUE
		.elseif  eax==SB_LINELEFT
			mov		eax,xsinf.nPos
			sub		eax,10
			.if CARRY?
				xor		eax,eax
			.endif
			invoke SetScrollPos,hWin,SB_HORZ,eax,TRUE
			invoke InvalidateRect,hWin,NULL,TRUE
		.elseif eax==SB_LINERIGHT
			mov		eax,xsinf.nPos
			add		eax,10
			invoke SetScrollPos,hWin,SB_HORZ,eax,TRUE
			invoke InvalidateRect,hWin,NULL,TRUE
		.elseif eax==SB_PAGELEFT
			mov		eax,xsinf.nPos
			sub		eax,xsinf.nPage
			.if CARRY?
				xor		eax,eax
			.endif
			invoke SetScrollPos,hWin,SB_HORZ,eax,TRUE
			invoke InvalidateRect,hWin,NULL,TRUE
		.elseif eax==SB_PAGERIGHT
			mov		eax,xsinf.nPos
			add		eax,xsinf.nPage
			invoke SetScrollPos,hWin,SB_HORZ,eax,TRUE
			invoke InvalidateRect,hWin,NULL,TRUE
		.endif
		xor		eax,eax
	.elseif eax==WM_VSCROLL
		mov		ysinf.cbSize,sizeof SCROLLINFO
		mov		ysinf.fMask,SIF_ALL
		invoke GetScrollInfo,hWin,SB_VERT,addr ysinf
		mov		eax,wParam
		movzx	eax,ax
		.if eax==SB_THUMBPOSITION
			mov		eax,ysinf.nTrackPos
			invoke SetScrollPos,hWin,SB_VERT,eax,TRUE
			invoke InvalidateRect,hWin,NULL,TRUE
		.elseif  eax==SB_THUMBTRACK
			mov		eax,ysinf.nTrackPos
			invoke SetScrollPos,hWin,SB_VERT,eax,TRUE
			invoke InvalidateRect,hWin,NULL,TRUE
		.elseif  eax==SB_LINELEFT
			mov		eax,ysinf.nPos
			sub		eax,10
			.if CARRY?
				xor		eax,eax
			.endif
			invoke SetScrollPos,hWin,SB_VERT,eax,TRUE
			invoke InvalidateRect,hWin,NULL,TRUE
		.elseif eax==SB_LINERIGHT
			mov		eax,ysinf.nPos
			add		eax,10
			invoke SetScrollPos,hWin,SB_VERT,eax,TRUE
			invoke InvalidateRect,hWin,NULL,TRUE
		.elseif eax==SB_PAGELEFT
			mov		eax,ysinf.nPos
			sub		eax,ysinf.nPage
			.if CARRY?
				xor		eax,eax
			.endif
			invoke SetScrollPos,hWin,SB_VERT,eax,TRUE
			invoke InvalidateRect,hWin,NULL,TRUE
		.elseif eax==SB_PAGERIGHT
			mov		eax,ysinf.nPos
			add		eax,ysinf.nPage
			invoke SetScrollPos,hWin,SB_VERT,eax,TRUE
			invoke InvalidateRect,hWin,NULL,TRUE
		.endif
		xor		eax,eax
	.else
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
	.endif
	ret

SetScrooll:
	invoke GetClientRect,hWin,addr rect
	sub		rect.bottom,TEXTHIGHT
	;Init horizontal scrollbar
	mov		xsinf.cbSize,sizeof SCROLLINFO
	mov		xsinf.fMask,SIF_ALL
	invoke GetScrollInfo,hWin,SB_HORZ,addr xsinf
	mov		xsinf.nMin,0
	mov		eax,samplesize
	mov		ecx,[ebx].SCOPECHDATA.xmag
	.if ecx>XMAGMAX/16
		sub		ecx,XMAGMAX/16
		add		ecx,10
		mul		ecx
		mov		ecx,10
		div		ecx
	.elseif ecx<XMAGMAX/16
		push	ecx
		mov		ecx,10
		mul		ecx
		pop		ecx
		sub		ecx,XMAGMAX/16
		neg		ecx
		add		ecx,10
		div		ecx
	.endif
	mov		ecx,rect.right
	mul		ecx
	mov		ecx,samplesize
	div		ecx
	mov		xsinf.nMax,eax
	mov		eax,rect.right
	inc		eax
	mov		xsinf.nPage,eax
	invoke SetScrollInfo,hWin,SB_HORZ,addr xsinf,TRUE
	;Init vertical scrollbar
	mov		ysinf.cbSize,sizeof SCROLLINFO
	mov		ysinf.fMask,SIF_ALL
	invoke GetScrollInfo,hWin,SB_VERT,addr ysinf
	mov		ysinf.nMin,0
	mov		eax,ADCMAX
	mov		ecx,[ebx].SCOPECHDATA.ymag
	.if ecx>YMAGMAX/16
		sub		ecx,YMAGMAX/16
		add		ecx,10
		mul		ecx
		mov		ecx,10
		div		ecx
	.elseif ecx<YMAGMAX/16
		push	ecx
		mov		ecx,10
		mul		ecx
		pop		ecx
		sub		ecx,YMAGMAX/16
		neg		ecx
		add		ecx,10
		div		ecx
	.endif
	mov		ecx,rect.bottom
	mul		ecx
	mov		ecx,ADCMAX
	div		ecx
	mov		ysinf.nMax,eax
	mov		eax,rect.bottom
	inc		eax
	mov		ysinf.nPage,eax
	invoke SetScrollInfo,hWin,SB_VERT,addr ysinf,TRUE
	add		rect.bottom,TEXTHIGHT
	retn

GetPoint:
	;Get X position
	mov		eax,edi
	mov		ecx,[ebx].SCOPECHDATA.xmag
	.if ecx>XMAGMAX/16
		sub		ecx,XMAGMAX/16
		add		ecx,10
		mul		ecx
		mov		ecx,10
		div		ecx
	.elseif ecx<XMAGMAX/16
		push	ecx
		mov		ecx,10
		mul		ecx
		pop		ecx
		sub		ecx,XMAGMAX/16
		neg		ecx
		add		ecx,10
		div		ecx
	.endif
	mov		ecx,rect.right
	mul		ecx
	mov		ecx,samplesize
	div		ecx
	sub		eax,xsinf.nPos
	mov		pt.x,eax
	;Get y position
	mov		edx,edi
	add		edx,[ebx].SCOPECHDATA.nusstart
	.if edx>=samplesize
		sub		edx,samplesize
	.endif
	movzx	eax,byte ptr [esi+edx]
	sub		eax,ADCMAX
	neg		eax
	mov		ecx,[ebx].SCOPECHDATA.ymag
	.if ecx>YMAGMAX/16
		sub		ecx,YMAGMAX/16
		add		ecx,10
		mul		ecx
		mov		ecx,10
		div		ecx
	.elseif ecx<YMAGMAX/16
		push	ecx
		mov		ecx,10
		mul		ecx
		pop		ecx
		sub		ecx,YMAGMAX/16
		neg		ecx
		add		ecx,10
		div		ecx
	.endif
	mov		ecx,rect.bottom
	sub		ecx,10
	mul		ecx
	mov		ecx,ADCMAX
	div		ecx
	sub		eax,ysinf.nPos
	add		eax,5
	mov		pt.y,eax
	retn

ScopeProc endp

ScopeToolChildProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke SendDlgItemMessage,hWin,IDC_TRBXMAG,TBM_SETRANGE,FALSE,(XMAGMAX SHL 16)+1
		invoke SendDlgItemMessage,hWin,IDC_TRBXMAG,TBM_SETPOS,TRUE,XMAGMAX/16
		invoke SendDlgItemMessage,hWin,IDC_TRBYMAG,TBM_SETRANGE,FALSE,(YMAGMAX SHL 16)+1
		invoke SendDlgItemMessage,hWin,IDC_TRBYMAG,TBM_SETPOS,TRUE,YMAGMAX/16
	.elseif eax==WM_COMMAND
		invoke GetParent,hWin
		invoke GetWindowLong,eax,GWL_USERDATA
		mov		ebx,eax
		mov		eax,wParam
		.if eax==IDC_CHKSUBSAMPLE
			invoke IsDlgButtonChecked,hWin,IDC_CHKSUBSAMPLE
			mov		[ebx].SCOPECHDATA.fSubsampling,eax
			.if eax
				invoke Subsampling,[ebx].SCOPECHDATA.hWndDialog
			.endif
			invoke InvalidateRect,[ebx].SCOPECHDATA.hWndScope,NULL,TRUE
		.elseif eax==IDC_CHKPERIODS
			invoke IsDlgButtonChecked,hWin,IDC_CHKPERIODS
			mov		[ebx].SCOPECHDATA.fTwoPeriods,eax
			.if [ebx].SCOPECHDATA.fSubsampling
				invoke Subsampling,[ebx].SCOPECHDATA.hWndDialog
				invoke InvalidateRect,[ebx].SCOPECHDATA.hWndScope,NULL,TRUE
			.endif
		.elseif eax==IDC_CHKBOTHCHANNELS
			invoke IsDlgButtonChecked,hWin,IDC_CHKBOTHCHANNELS
			mov		[ebx].SCOPECHDATA.fBothChannels,eax
			invoke InvalidateRect,[ebx].SCOPECHDATA.hWndScope,NULL,TRUE
		.endif
	.elseif eax==WM_HSCROLL
		invoke GetParent,hWin
		invoke GetWindowLong,eax,GWL_USERDATA
		mov		ebx,eax
		invoke GetDlgCtrlID,lParam
		.if eax==IDC_TRBXMAG
			;X-Magnification
			invoke SendDlgItemMessage,[ebx].SCOPECHDATA.hWndScopeTool,IDC_TRBXMAG,TBM_GETPOS,0,0
			mov		[ebx].SCOPECHDATA.xmag,eax
			invoke InvalidateRect,[ebx].SCOPECHDATA.hWndScope,NULL,TRUE
		.elseif eax==IDC_TRBYMAG
			;Y-Magnification
			mov		[ebx].SCOPECHDATA.fYMagnify,TRUE
			invoke SendDlgItemMessage,[ebx].SCOPECHDATA.hWndScopeTool,IDC_TRBYMAG,TBM_GETPOS,0,0
			mov		[ebx].SCOPECHDATA.ymag,eax
			invoke InvalidateRect,[ebx].SCOPECHDATA.hWndScope,NULL,TRUE
		.endif
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

ScopeToolChildProc endp

ScopeChildProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	rect:RECT

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		ebx,lParam
		invoke SetWindowLong,hWin,GWL_USERDATA,ebx
		mov		eax,hWin
		mov		[ebx].SCOPECHDATA.hWndDialog,eax
		invoke GetDlgItem,hWin,IDC_UDCSCOPE
		mov		[ebx].SCOPECHDATA.hWndScope,eax
		invoke CreateDialogParam,hInstance,IDD_DLGSCOPETOOL,hWin,addr ScopeToolChildProc,0
		mov		[ebx].SCOPECHDATA.hWndScopeTool,eax
		mov		[ebx].SCOPECHDATA.xmag,XMAGMAX/16
		mov		[ebx].SCOPECHDATA.ymag,YMAGMAX/16
		mov		[ebx].SCOPECHDATA.ADC_TriggerEdge,STM32_TriggerRisingCHA
		mov		[ebx].SCOPECHDATA.ADC_TriggerValue,7Fh
		mov		[ebx].SCOPECHDATA.ADC_DCNullOut,7Fh
	.elseif	eax==WM_SIZE
		invoke GetWindowLong,hWin,GWL_USERDATA
		mov		ebx,eax
		invoke GetClientRect,hWin,addr rect
		sub		rect.right,135
		sub		rect.bottom,2
		invoke MoveWindow,[ebx].SCOPECHDATA.hWndScope,0,0,rect.right,rect.bottom,TRUE
		invoke MoveWindow,[ebx].SCOPECHDATA.hWndScopeTool,rect.right,0,135,rect.bottom,TRUE
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

ScopeChildProc endp

