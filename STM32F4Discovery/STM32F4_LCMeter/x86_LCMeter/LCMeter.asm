.386
.model flat, stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include LCMeter.inc
include Misc.asm

.code

;########################################################################

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

FormatFrequency proc uses ebx,frq:DWORD,lpBuffer:DWORD

	mov		eax,frq
	.if eax<1000
		;Hz
		invoke wsprintf,lpBuffer,addr szFmtHz,eax
	.elseif eax<1000000
		;KHz
		invoke wsprintf,lpBuffer,addr szFmtKHz,eax
		mov		ebx,6
		call	InsertDot
	.else
		;MHz
		invoke wsprintf,lpBuffer,addr szFmtMHz,eax
		mov		ebx,9
		call	InsertDot
	.endif
	ret

InsertDot:
	mov		esi,lpBuffer
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

FormatFrequency endp

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
	LOCAL	samplesize:DWORD
	LOCAL	iTmp:DWORD
	LOCAL	fTmp:REAL10
	LOCAL	nMin:DWORD
	LOCAL	nMax:DWORD
	LOCAL	nCenter:DWORD
	LOCAL	srms:REAL10
	LOCAL	stns:REAL10
	LOCAL	pixns:REAL10
	LOCAL	xmul:REAL10
	LOCAL	ymul:REAL10
	LOCAL	adcperiod:REAL10
	LOCAL	buffer[128]:BYTE

	mov		eax,uMsg
	.if eax==WM_PAINT
		;Get sample time in ns
		mov		iTmp,STM32_CLOCK/2
		fild	iTmp
		mov		eax,STM32_Cmd.STM32_Scp.ADC_Prescaler
		inc		eax
		shl		eax,1
		mov		iTmp,eax
		fild	iTmp
		fdivp	st(1),st
		mov		eax,STM32_Cmd.STM32_Scp.ADC_TwoSamplingDelay
		add		eax,5
		mov		iTmp,eax
		fild	iTmp
		fdivp	st(1),st
		fstp	srms
		invoke FpToAscii,addr srms,addr buffer,FALSE
		invoke lstrcat,addr buffer,offset szHz
		invoke SetDlgItemText,hScpCld,IDC_STCADCSAMPLERATE,addr buffer
		fld1
		fld		srms
		fdivp	st(1),st
		fld		ten_9
		fmulp	st(1),st
		fstp	stns
;		invoke PrintFp,addr stns
		;Get time in ns for each pixel
		mov		eax,STM32_Cmd.STM32_Scp.ScopeTimeDiv
		mov		iTmp,eax
		fild	iTmp
		mov		iTmp,GRIDSIZE
		fild	iTmp
		fdivp	st(1),st
		fstp	pixns
;		invoke PrintFp,addr pixns
		;Get x scale
		fld		stns
		fld		pixns
		fdivp	st(1),st
		fstp	xmul
;		invoke PrintFp,addr xmul
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

		mov		samplesize,ADCSAMPLESIZE
		;Get Vmin, Vmax and Vpp
		mov		esi,offset ADC_Data
		mov		ecx,ADCMAX
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
		mov		nMin,ecx
		mov		nMax,edx
		;Find Center
		sub		edx,ecx
		shr		edx,1
		add		edx,ecx
		mov		nCenter,edx
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
		sub		eax,SCOPEWT
		shr		eax,1
		mov		scprect.left,eax
		add		eax,SCOPEWT
		mov		scprect.right,eax
		mov		eax,rect.bottom
		sub		eax,SCOPEHT
		shr		eax,1
		mov		scprect.top,eax
		add		eax,SCOPEHT
		mov		scprect.bottom,eax
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

		;Draw curve
		invoke CreateRectRgn,scprect.left,scprect.top,scprect.right,scprect.bottom
		push	eax
		invoke SelectClipRgn,mDC,eax
		pop		eax
		invoke DeleteObject,eax
		invoke CreatePen,PS_SOLID,2,008000h
		invoke SelectObject,mDC,eax
		push	eax
		.if fSubSampling
			fld		ten_9
			fild	STM32_Cmd.STM32_Frq.FrequencySCP
			fdivp	st(1),st
			fstp	adcperiod
			xor		ebx,ebx
			call	GetPointSubSample
			invoke MoveToEx,mDC,pt.x,pt.y,NULL
			lea		ebx,[ebx+1]
			.while edi<samplesize
				call	GetPointSubSample
				.if pt.y
					invoke LineTo,mDC,pt.x,pt.y
				.endif
				mov		eax,pt.x
				.break .if sdword ptr eax>scprect.right
				lea		ebx,[ebx+1]
			.endw
		.else
			mov		esi,offset ADC_Data
			;Find trigger
			mov		ecx,nMax
			sub		ecx,nMin
			shr		ecx,1
			add		ecx,nMin
			mov		eax,STM32_Cmd.STM32_Scp.ScopeTriggerLevel
			sub		eax,2048
			add		ecx,eax
			xor		edi,edi
			.if STM32_Cmd.STM32_Scp.ScopeTrigger==1
				;Rising
				.while edi<samplesize
					.break.if word ptr [esi+edi]<cx && word ptr [esi+edi+WORD]>=cx
					lea		edi,[edi+WORD]
				.endw
			.elseif STM32_Cmd.STM32_Scp.ScopeTrigger==2
				;Falling
				.while edi<samplesize
					.break.if word ptr [esi+edi]>cx && word ptr [esi+edi+WORD]<=cx
					lea		edi,[edi+WORD]
				.endw
			.endif
			.if edi==samplesize
				;No trigger found
				xor		edi,edi
			.endif
			xor		ebx,ebx
			call	GetPoint
			invoke MoveToEx,mDC,pt.x,pt.y,NULL
			lea		edi,[edi+WORD]
			lea		ebx,[ebx+1]
			.while edi<samplesize
				call	GetPoint
				invoke LineTo,mDC,pt.x,pt.y
				mov		eax,pt.x
				.break .if sdword ptr eax>scprect.right
				lea		edi,[edi+WORD]
				lea		ebx,[ebx+1]
			.endw
		.endif
		pop		eax
		invoke SelectObject,mDC,eax
		invoke DeleteObject,eax

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
	fld		xmul
	mov		iTmp,ebx
	fild	iTmp
	fmulp	st(1),st
	fistp	iTmp
	mov		eax,iTmp
	add		eax,scprect.left
	mov		pt.x,eax
	;Get y position
	fld		ymul
	movzx	eax,word ptr [esi+edi]
	sub		eax,nCenter
	neg		eax
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
	fild	STM32_Cmd.STM32_Scp.ScopeTimeDiv
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
	mov		pt.x,eax

	;Get y position
	mov		eax,ebx
	and		eax,2047
	mov		eax,SubSample[eax*DWORD]
	.if eax
		sub		eax,nCenter
		neg		eax
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

SampleThreadProc proc lParam:DWORD
	LOCAL	buffer[32]:BYTE

	mov		edx,STM32_Cmd.STM32_Frq.FrequencySCP
	invoke FormatFrequency,edx,addr buffer
	invoke SetWindowText,hScp,addr buffer
	invoke STLinkWrite,hWnd,2000002Ch,offset STM32_Cmd.STM32_Scp,sizeof STM32_SCP
	.if !eax
		jmp		Err
	.endif
	invoke STLinkWrite,hWnd,20000014h,addr mode,DWORD
	.if !eax
		jmp		Err
	.endif
	xor		ebx,ebx
	.while ebx<50
		invoke Sleep,100
		invoke STLinkRead,hWnd,20000014h,offset STM32_Cmd,DWORD
		.if !eax
			jmp		Err
		.endif
		.break .if !STM32_Cmd.Cmd
		inc		ebx
	.endw
	invoke STLinkRead,hWnd,20008000h,offset ADC_Data,ADCSAMPLESIZE
	.if !eax
		jmp		Err
	.endif
	.if fSubSampling
		invoke ScopeSubSampling
	.endif
	invoke InvalidateRect,hScpScrn,NULL,TRUE
	mov		fSampleDone,TRUE
Err:
	ret

SampleThreadProc endp

HscChildProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	
	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke GetDlgItem,hWin,IDC_UDCHSC
		mov		hHsc,eax
		mov		eax,STM32_Cmd.STM32_Hsc.HSCSet
		inc		eax
		invoke ClockToFrequency,eax,STM32_CLOCK/4
		invoke SetDlgItemInt,hWin,IDC_EDTHSCFRQ,eax,FALSE
	.elseif	eax==WM_COMMAND
		mov edx,wParam
		movzx eax,dx
		shr edx,16
		.if edx==BN_CLICKED
			.if eax==IDC_BTNHSCDN
				.if STM32_Cmd.STM32_Hsc.HSCSet<65534
					inc		STM32_Cmd.STM32_Hsc.HSCSet
					mov		eax,STM32_Cmd.STM32_Hsc.HSCSet
					inc		eax
					invoke ClockToFrequency,eax,STM32_CLOCK/4
					invoke SetDlgItemInt,hWin,IDC_EDTHSCFRQ,eax,FALSE
					mov		STM32_Cmd.Cmd,CMD_HSCSET
					.if connected
						invoke STLinkWrite,hWnd,20000018h,addr STM32_Cmd.STM32_Hsc.HSCSet,DWORD
						invoke STLinkWrite,hWnd,20000014h,addr STM32_Cmd.Cmd,DWORD
					.endif
				.endif
			.elseif eax==IDC_BTNHSCUP
				.if STM32_Cmd.STM32_Hsc.HSCSet
					dec		STM32_Cmd.STM32_Hsc.HSCSet
					mov		eax,STM32_Cmd.STM32_Hsc.HSCSet
					inc		eax
					invoke ClockToFrequency,eax,STM32_CLOCK/4
					invoke SetDlgItemInt,hWin,IDC_EDTHSCFRQ,eax,FALSE
					mov		STM32_Cmd.Cmd,CMD_HSCSET
					.if connected
						invoke STLinkWrite,hWnd,20000018h,addr STM32_Cmd.STM32_Hsc.HSCSet,DWORD
						invoke STLinkWrite,hWnd,20000014h,addr STM32_Cmd.Cmd,DWORD
					.endif
				.endif
			.endif
		.elseif edx==EN_KILLFOCUS
			.if eax==IDC_EDTHSCFRQ
				invoke GetDlgItemInt,hWin,IDC_EDTHSCFRQ,NULL,FALSE
				invoke FrequencyToClock,eax,STM32_CLOCK/4
				push	eax
				dec		eax
				mov		STM32_Cmd.STM32_Hsc.HSCSet,eax
				pop		eax
				invoke ClockToFrequency,eax,STM32_CLOCK/4
				invoke SetDlgItemInt,hWin,IDC_EDTHSCFRQ,eax,FALSE
				mov		STM32_Cmd.Cmd,CMD_HSCSET
				.if connected
					invoke STLinkWrite,hWnd,20000018h,addr STM32_Cmd.STM32_Hsc.HSCSet,DWORD
					invoke STLinkWrite,hWnd,20000014h,addr STM32_Cmd.Cmd,DWORD
				.endif
			.endif
		.endif
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

HscChildProc endp

LcmChildProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke GetDlgItem,hWin,IDC_UDCLCM
		mov		hLcm,eax
	.elseif	eax==WM_COMMAND
		mov edx,wParam
		movzx eax,dx
		shr edx,16
		.if edx==BN_CLICKED
			.if eax==IDC_BTNLCMMODE
				.if mode==CMD_LCMCAP
					mov		mode,CMD_LCMIND
				.elseif mode==CMD_LCMIND
					mov		mode,CMD_LCMCAP
				.endif
				.if connected
					invoke STLinkWrite,hWnd,20000014h,addr mode,DWORD
					invoke SetMode
				.endif
			.elseif eax==IDC_BTNLCMCAL
				mov		mode,CMD_LCMCAL
				.if connected
					invoke STLinkWrite,hWnd,20000014h,addr mode,DWORD
					mov		mode,CMD_LCMCAP
					invoke SetMode
				.endif
			.endif
		.endif
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

LcmChildProc endp

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
		invoke SendDlgItemMessage,hWin,IDC_TRBADCCLOCK,TBM_SETRANGE,FALSE,3 SHL 16
		mov		eax,3
		sub		eax,STM32_Cmd.STM32_Scp.ADC_Prescaler
		invoke SendDlgItemMessage,hWin,IDC_TRBADCCLOCK,TBM_SETPOS,TRUE,eax
		invoke SendDlgItemMessage,hWin,IDC_TRBADCDELAY,TBM_SETRANGE,FALSE,(20-5) SHL 16
		mov		eax,20-5
		sub		eax,STM32_Cmd.STM32_Scp.ADC_Prescaler
		invoke SendDlgItemMessage,hWin,IDC_TRBADCDELAY,TBM_SETPOS,TRUE,eax
		invoke SendDlgItemMessage,hWin,IDC_TRBTIMEDIV,TBM_SETRANGE,FALSE,17 SHL 16
		mov		eax,STM32_Cmd.STM32_Scp.ScopeTimeDiv
		xor		edx,edx
		.while edx<18
			.break .if eax==ScopeTimeDiv[edx*DWORD]
			lea		edx,[edx+1]
		.endw
		invoke SendDlgItemMessage,hWin,IDC_TRBTIMEDIV,TBM_SETPOS,TRUE,edx
		invoke SendDlgItemMessage,hWin,IDC_TRBVOLTDIV,TBM_SETRANGE,FALSE,8 SHL 16
		mov		eax,STM32_Cmd.STM32_Scp.ScopeVoltDiv
		xor		edx,edx
		.while edx<9
			.break .if eax==ScopeVoltDiv[edx*DWORD]
			lea		edx,[edx+1]
		.endw
		mov		eax,STM32_Cmd.STM32_Scp.ScopeTrigger
		add		eax,IDC_RBNTRIGGERNONE
		invoke SendDlgItemMessage,hWin,eax,BM_SETCHECK,BST_CHECKED,0
		invoke SendDlgItemMessage,hWin,IDC_TRBVOLTDIV,TBM_SETPOS,TRUE,edx
		invoke SendDlgItemMessage,hWin,IDC_TRBTRIGGERLEVEL,TBM_SETRANGE,FALSE,255 SHL 16
		mov		eax,STM32_Cmd.STM32_Scp.ScopeTriggerLevel
		shr		eax,4
		invoke SendDlgItemMessage,hWin,IDC_TRBTRIGGERLEVEL,TBM_SETPOS,TRUE,eax
		invoke SendDlgItemMessage,hWin,IDC_TRBVPOS,TBM_SETRANGE,FALSE,4095 SHL 16
		mov		eax,STM32_Cmd.STM32_Scp.ScopeVPos
		invoke SendDlgItemMessage,hWin,IDC_TRBVPOS,TBM_SETPOS,TRUE,eax
	.elseif	eax==WM_COMMAND
		mov edx,wParam
		movzx eax,dx
		shr edx,16
		.if edx==BN_CLICKED
			.if eax>=IDC_RBNTRIGGERNONE && eax<=IDC_RBNTRIGGERFALLING
				sub		eax,IDC_RBNTRIGGERNONE
				mov		STM32_Cmd.STM32_Scp.ScopeTrigger,eax
			.elseif eax==IDC_CHKSUBSAMPLING
				xor		fSubSampling,TRUE
			.elseif eax==IDC_CHKHOLDSAMPLING
				xor		fHoldSampling,TRUE
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
			;ADC Sampling Delay
			invoke SendDlgItemMessage,hWin,IDC_TRBADCDELAY,TBM_GETPOS,0,0
			sub		eax,20-5
			neg		eax
			mov		STM32_Cmd.STM32_Scp.ADC_TwoSamplingDelay,eax
		.elseif eax==IDC_TRBTIMEDIV
			;Scope Time / Div
			invoke SendDlgItemMessage,hWin,IDC_TRBTIMEDIV,TBM_GETPOS,0,0
			mov		eax,ScopeTimeDiv[eax*DWORD]
			mov		STM32_Cmd.STM32_Scp.ScopeTimeDiv,eax
		.elseif eax==IDC_TRBVOLTDIV
			;Scope Volt / Div
			invoke SendDlgItemMessage,hWin,IDC_TRBVOLTDIV,TBM_GETPOS,0,0
			mov		eax,ScopeVoltDiv[eax*DWORD]
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
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

ScpChildProc endp

DlgProc	proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	buffer[32]:BYTE
	LOCAL	tid:DWORD

	mov		eax,uMsg
	.if	eax==WM_INITDIALOG
		mov		eax,hWin
		mov		hWnd,eax
		mov		STM32_Cmd.STM32_Hsc.HSCSet,50000-1
		mov		STM32_Cmd.STM32_Scp.ADC_Prescaler,0
		mov		STM32_Cmd.STM32_Scp.ADC_TwoSamplingDelay,0
		mov		STM32_Cmd.STM32_Scp.ScopeTrigger,1
		mov		STM32_Cmd.STM32_Scp.ScopeTriggerLevel,2048
		mov		STM32_Cmd.STM32_Scp.ScopeTimeDiv,10000
		mov		STM32_Cmd.STM32_Scp.ScopeVoltDiv,500
		mov		STM32_Cmd.STM32_Scp.ScopeVPos,2048
		invoke CreateFontIndirect,addr Tahoma_36
		mov		hFont,eax
		;Create FRQ child dialog
		invoke CreateDialogParam,hInstance,IDD_DLGHSC,hWin,addr HscChildProc,0
		mov		hHscCld,eax
		;Create LCM child dialog
		invoke CreateDialogParam,hInstance,IDD_DLGLCMETER,hWin,addr LcmChildProc,0
		mov		hLcmCld,eax
		;Create scope screen child dialog
		invoke CreateDialogParam,hInstance,IDD_DLGSCPSCRNCLD,hWin,addr ScopeScrnChildProc,0
		mov		hScpScrnCld,eax
		;Create scope child dialog
		invoke CreateDialogParam,hInstance,IDD_DLGSCP,hWin,addr ScpChildProc,0
		mov		hScpCld,eax
		mov		STM32_Cmd.STM32_Scp.ScopeTrigger,1
		mov		mode,CMD_LCMCAP
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
			.elseif eax==IDC_BTNMODE
				.if mode==CMD_LCMCAP || mode==CMD_LCMIND
					;High Speed Clock
					invoke ShowWindow,hScpCld,SW_HIDE
					invoke ShowWindow,hLcmCld,SW_HIDE
					invoke ShowWindow,hHscCld,SW_SHOW
					mov		mode,CMD_FRQCH1
					.if connected
						invoke STLinkWrite,hWin,20000014h,addr mode,DWORD
						.if !eax
							invoke KillTimer,hWin,1000
							jmp		Err
						.endif
					.endif
				.elseif mode==CMD_FRQCH1
					;Scope
					invoke ShowWindow,hLcmCld,SW_HIDE
					invoke ShowWindow,hHscCld,SW_HIDE
					invoke ShowWindow,hScpCld,SW_SHOW
					mov		fSampleDone,TRUE
					mov		mode,CMD_SCPSET
				.elseif mode==CMD_SCPSET
					;LCMeter
					invoke ShowWindow,hScpCld,SW_HIDE
					invoke ShowWindow,hHscCld,SW_HIDE
					invoke ShowWindow,hLcmCld,SW_SHOW
					mov		mode,CMD_LCMCAP
					.if connected
						invoke STLinkWrite,hWin,20000014h,addr mode,DWORD
						.if !eax
							invoke KillTimer,hWin,1000
							jmp		Err
						.endif
					.endif
				.endif
				invoke SetMode
			.endif
		.endif
	.elseif	eax==WM_TIMER
		invoke KillTimer,hWin,1000
		;Read 16 bytes from STM32F4xx ram and store it in STM32_Cmd.
		invoke STLinkRead,hWin,2000001Ch,offset STM32_Cmd.STM32_Frq,4*DWORD
		.if eax
			.if mode==CMD_SCPSET
				.if !fHoldSampling && fSampleDone
					mov		fSampleDone,FALSE
					invoke CreateThread,NULL,NULL,addr SampleThreadProc,hWin,0,addr tid
					invoke CloseHandle,eax
				.endif
			.elseif mode==CMD_FRQCH1
				mov		edx,STM32_Cmd.STM32_Frq.Frequency
				invoke FormatFrequency,edx,addr buffer
				invoke SetWindowText,hHsc,addr buffer
			.elseif mode==CMD_LCMCAP
				invoke CalculateCapacitor,addr buffer
				invoke SetWindowText,hLcm,addr buffer
			.elseif mode==CMD_LCMIND
				invoke CalculateInductor,addr buffer
				invoke SetWindowText,hLcm,addr buffer
			.endif
			invoke SetTimer,hWin,1000,500,NULL
		.else
Err:
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
