.386
.model flat, stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include LCMeter.inc
include Misc.asm
include Scope.asm
include DDSWave.asm

.code

;########################################################################

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

SampleThreadProc proc lParam:DWORD
	LOCAL	buffer[32]:BYTE

	mov		fThreadDone,FALSE
	.if connected && !fExitThread
		;Read 16 bytes from STM32F4xx ram and store it in STM32_Cmd.
		invoke STLinkRead,lParam,20000020h,offset STM32_Cmd.STM32_Frq,4*DWORD
		.if !eax
			jmp		Err
		.endif
		mov		edx,STM32_Cmd.STM32_Frq.FrequencySCP
		invoke FormatFrequency,edx,addr buffer
		invoke SetWindowText,hScp,addr buffer
		
		invoke RtlZeroMemory,offset ADC_Data,sizeof ADC_Data
		;Copy current scope settings
		invoke RtlMoveMemory,offset STM32_Scp,offset STM32_Cmd.STM32_Scp,sizeof STM32_SCP
		invoke GetSampleTime,offset STM32_Scp
		invoke GetSignalPeriod
		invoke GetSamplesPrPeriod
		invoke GetTotalSamples,offset STM32_Scp
		mov		STM32_Scp.ADC_SampleSize,eax
		invoke STLinkWrite,lParam,20000030h,offset STM32_Scp,sizeof STM32_SCP
		.if !eax
			jmp		Err
		.endif
		invoke STLinkWrite,lParam,20000014h,addr mode,DWORD
		.if !eax
			jmp		Err
		.endif
		xor		ebx,ebx
		.while ebx<50 && !fExitThread
			invoke Sleep,100
			invoke STLinkRead,lParam,20000014h,offset STM32_Cmd,DWORD
			.if !eax
				jmp		Err
			.endif
			.break .if !STM32_Cmd.Cmd
			inc		ebx
		.endw
		.if !fExitThread
			mov		fNoFrequency,TRUE
			invoke STLinkRead,lParam,20008000h,offset ADC_Data,STM32_Scp.ADC_SampleSize
			.if !eax
				jmp		Err
			.endif
			.if STM32_Scp.fSubSampling
				invoke ScopeSubSampling
			.endif
			invoke InvalidateRect,hScpScrn,NULL,TRUE
			invoke UpdateWindow,hScpScrn
			mov		fSampleDone,TRUE
		.endif
	.endif
	mov		fThreadDone,TRUE
	ret
Err:
	mov		connected,FALSE
	mov		fThreadDone,TRUE
	ret

SampleThreadProc endp

HscChildProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	resfrq:DWORD

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke GetDlgItem,hWin,IDC_UDCHSC
		mov		hHsc,eax
		mov		eax,STM32_Cmd.STM32_Hsc.HSCDiv
		inc		eax
		invoke ClockToFrequency,eax,STM32_CLOCK/4
		invoke SetDlgItemInt,hWin,IDC_EDTHSCFRQ,eax,FALSE
		invoke ImageList_GetIcon,hIml,0,ILD_NORMAL
		mov		ebx,eax
		invoke SendDlgItemMessage,hWin,IDC_BTNHSCDN,BM_SETIMAGE,IMAGE_ICON,ebx
		invoke ImageList_GetIcon,hIml,1,ILD_NORMAL
		mov		ebx,eax
		invoke SendDlgItemMessage,hWin,IDC_BTNHSCUP,BM_SETIMAGE,IMAGE_ICON,ebx
		push	0
		push	IDC_BTNHSCDN
		mov		eax,IDC_BTNHSCUP
		.while eax
			invoke GetDlgItem,hWin,eax
			invoke SetWindowLong,eax,GWL_WNDPROC,offset ButtonProc
			mov		lpOldButtonProc,eax
			pop		eax
		.endw
	.elseif	eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDC_BTNHSCDN
				invoke GetDlgItemInt,hWin,IDC_EDTHSCFRQ,NULL,FALSE
				.if eax>1
					dec		eax
					mov		resfrq,eax
					inc		eax
					.while eax!=resfrq
						dec		eax
						push	eax
						mov		edx,eax
						invoke GetHSCFrq,edx,addr resfrq
						pop		eax
					.endw
					
					invoke SetHSC,hWin,eax
				.endif
			.elseif eax==IDC_BTNHSCUP
				invoke GetDlgItemInt,hWin,IDC_EDTHSCFRQ,NULL,FALSE
				.if eax<50000000
					inc		eax
					invoke SetHSC,hWin,eax
				.endif
			.endif
		.elseif edx==EN_KILLFOCUS
			.if eax==IDC_EDTHSCFRQ
				invoke GetDlgItemInt,hWin,IDC_EDTHSCFRQ,NULL,FALSE
				invoke SetHSC,hWin,eax
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
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
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

DlgProc	proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	buffer[32]:BYTE
	LOCAL	tid:DWORD

	mov		eax,uMsg
	.if	eax==WM_INITDIALOG
		mov		eax,hWin
		mov		hWnd,eax
		mov		STM32_Cmd.STM32_Hsc.HSCDiv,50000-1
		mov		STM32_Cmd.STM32_Hsc.HSCSet,1
		mov		STM32_Cmd.STM32_Scp.ADC_Prescaler,0
		mov		STM32_Cmd.STM32_Scp.ADC_TwoSamplingDelay,0
		mov		STM32_Cmd.STM32_Scp.ScopeTrigger,1
		mov		STM32_Cmd.STM32_Scp.ScopeTriggerLevel,2048
		mov		STM32_Cmd.STM32_Scp.ScopeTimeDiv,8
		mov		STM32_Cmd.STM32_Scp.ScopeVoltDiv,8
		mov		STM32_Cmd.STM32_Scp.ScopeVPos,2245
		mov		STM32_Cmd.STM32_Scp.ADC_TripleMode,TRUE
		invoke CreateFontIndirect,addr Tahoma_36
		mov		hFont,eax
		invoke ImageList_Create,16,16,ILC_COLOR24 or ILC_MASK,2,0
		mov		hIml,eax
		invoke LoadBitmap,hInstance,100
		mov		ebx,eax
		invoke ImageList_AddMasked,hIml,ebx,0FF00FFh
		invoke DeleteObject,ebx
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

		;Create DDS screen child dialog
		invoke CreateDialogParam,hInstance,IDD_DLGDDSCLD,hWin,addr DDSScrnChildProc,0
		mov		hDDSScrnCld,eax
		;Create DDS child dialog
		invoke CreateDialogParam,hInstance,IDD_DLGDDS,hWin,addr DDSChildProc,0
		mov		hDDSCld,eax

		mov		STM32_Cmd.STM32_Scp.ScopeTrigger,1
		mov		mode,CMD_LCMCAP
		xor		ebx,ebx
		.while ebx<ADCSAMPLESIZE/2
			mov		ADC_Data[ebx*WORD],2048
			inc		ebx
		.endw
		mov		fThreadDone,TRUE
		mov		STM32_Scp.ADC_SampleSize,10000h
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
						invoke SetTimer,hWin,1000,100,NULL
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
					invoke ShowWindow,hScpScrnCld,SW_SHOW
					invoke ShowWindow,hDDSScrnCld,SW_HIDE
					mov		fSampleDone,TRUE
					mov		mode,CMD_SCPSET
				.elseif mode==CMD_SCPSET
					;DDSWave
					invoke ShowWindow,hScpCld,SW_HIDE
					invoke ShowWindow,hHscCld,SW_HIDE
					invoke ShowWindow,hLcmCld,SW_HIDE
					invoke ShowWindow,hDDSCld,SW_SHOW
					invoke ShowWindow,hDDSScrnCld,SW_SHOW
					invoke ShowWindow,hScpScrnCld,SW_HIDE
					mov		mode,CMD_DDSSET
				.elseif mode==CMD_DDSSET
					;LCMeter
					invoke ShowWindow,hScpCld,SW_HIDE
					invoke ShowWindow,hHscCld,SW_HIDE
					invoke ShowWindow,hDDSCld,SW_HIDE
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
		.if mode==CMD_SCPSET
			.if !fHoldSampling && fSampleDone
				mov		fSampleDone,FALSE
				invoke CreateThread,NULL,NULL,addr SampleThreadProc,hWin,0,addr tid
				invoke CloseHandle,eax
			.endif
		.elseif mode==CMD_FRQCH1
			;Read 16 bytes from STM32F4xx ram and store it in STM32_Cmd.
			invoke STLinkRead,hWin,20000020h,offset STM32_Cmd.STM32_Frq,4*DWORD
			mov		edx,STM32_Cmd.STM32_Frq.Frequency
			invoke FormatFrequency,edx,addr buffer
			invoke SetWindowText,hHsc,addr buffer
		.elseif mode==CMD_LCMCAP
			;Read 16 bytes from STM32F4xx ram and store it in STM32_Cmd.
			invoke STLinkRead,hWin,20000020h,offset STM32_Cmd.STM32_Frq,4*DWORD
			invoke CalculateCapacitor,addr buffer
			invoke SetWindowText,hLcm,addr buffer
		.elseif mode==CMD_LCMIND
			;Read 16 bytes from STM32F4xx ram and store it in STM32_Cmd.
			invoke STLinkRead,hWin,20000020h,offset STM32_Cmd.STM32_Frq,4*DWORD
			invoke CalculateInductor,addr buffer
			invoke SetWindowText,hLcm,addr buffer
		.endif
		invoke SetTimer,hWin,1000,100,NULL
	.elseif	eax==WM_CLOSE
		mov		fExitThread,TRUE
		invoke KillTimer,hWin,1000
		xor		ebx,ebx
		.if mode==CMD_SCPSET
			.while !fThreadDone && ebx<5
				invoke GetMessage,addr msg,NULL,0,0
			  	.if eax
					invoke IsDialogMessage,hWnd,addr msg
					.if !eax
						invoke TranslateMessage,addr msg
						invoke DispatchMessage,addr msg
					.endif
			  	.endif
				invoke Sleep,100
				inc		ebx
			.endw
		.endif
		invoke Sleep,500
		invoke STLinkDisconnect,hWin
		invoke DeleteObject,hFont
		invoke EndDialog,hWin,0
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret
Err:
	mov		connected,FALSE
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

	mov		wc.lpfnWndProc,offset DDSProc
	invoke LoadCursor,0,IDC_CROSS
	mov		wc.hCursor,eax
	mov		wc.lpszClassName,offset szDDSCLASS
	invoke RegisterClassEx,addr wc

	invoke	DialogBoxParam,hInstance,IDD_MAIN,NULL,addr DlgProc,NULL
	invoke	ExitProcess,0

end start
