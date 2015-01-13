.386
.model flat, stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include LCMeter.inc
include BlueTooth.asm
include Misc.asm
include Scope.asm
include DDSWave.asm
include HSClock.asm
include LogicAnalyser.asm

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

LcmChildProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke GetDlgItem,hWin,IDC_UDCLCM
		mov		hLcm,eax
		mov		eax,FALSE
		ret
	.elseif	eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDC_BTNLCMMODE
				.if fBluetooth
					.if mode==CMD_LCMCAP
						mov		mode,CMD_LCMIND
					.elseif mode==CMD_LCMIND
						mov		mode,CMD_LCMCAP
					.endif
					invoke SetMode
				.endif
			.elseif eax==IDC_BTNLCMCAL
				.if fBluetooth
					mov		mode,CMD_LCMCAL
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
	LOCAL	tci:TC_ITEM
	LOCAL	xsinf:SCROLLINFO

	mov		eax,uMsg
	.if	eax==WM_INITDIALOG
		mov		eax,hWin
		mov		hWnd,eax
		;Create the tabs
		invoke GetDlgItem,hWin,IDC_TABFUNCTION
		mov		ebx,eax
		mov		tci.imask,TCIF_TEXT
		mov		tci.pszText,offset szLCM
		invoke SendMessage,ebx,TCM_INSERTITEM,0,addr tci
		mov		tci.pszText,offset szFerquencyCH1
		invoke SendMessage,ebx,TCM_INSERTITEM,1,addr tci
		mov		tci.pszText,offset szScope
		invoke SendMessage,ebx,TCM_INSERTITEM,2,addr tci
		mov		tci.pszText,offset szDDS
		invoke SendMessage,ebx,TCM_INSERTITEM,3,addr tci
		mov		tci.pszText,offset szLGA
		invoke SendMessage,ebx,TCM_INSERTITEM,4,addr tci

		mov		STM32_Cmd.STM32_Hsc.HSCDiv,50000-1
		mov		STM32_Cmd.STM32_Hsc.HSCSet,1
		mov		STM32_Cmd.STM32_Scp.ADC_Prescaler,0
		mov		STM32_Cmd.STM32_Scp.ADC_TwoSamplingDelay,0
		mov		STM32_Cmd.STM32_Scp.ScopeTrigger,1
		mov		STM32_Cmd.STM32_Scp.ScopeTriggerLevel,2048
		mov		STM32_Cmd.STM32_Scp.ScopeTimeDiv,8
		mov		STM32_Cmd.STM32_Scp.ScopeMag,1
		mov		STM32_Cmd.STM32_Scp.ScopeVoltDiv,8
		mov		STM32_Cmd.STM32_Scp.ScopeVPos,2150
		mov		STM32_Cmd.STM32_Scp.ADC_TripleMode,TRUE

		mov		STM32_Cmd.STM32_Lga.LGASampleRateDiv,3
		mov		STM32_Cmd.STM32_Lga.LGASampleRate,49999
		mov		STM32_Cmd.STM32_Lga.DataBlocks,1

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

		;Create LGA screen child dialog
		invoke CreateDialogParam,hInstance,IDD_DLGLGACLD,hWin,addr LGAScrnChildProc,0
		mov		hLGAScrnCld,eax
		;Create LGA child dialog
		invoke CreateDialogParam,hInstance,IDD_DLGLGA,hWin,addr LGAChildProc,0
		mov		hLGACld,eax

		;Create DDS screen child dialog
		invoke CreateDialogParam,hInstance,IDD_DLGDDSCLD,hWin,addr DDSScrnChildProc,0
		mov		hDDSScrnCld,eax
		;Create DDS child dialog
		invoke CreateDialogParam,hInstance,IDD_DLGDDS,hWin,addr DDSChildProc,0

		mov		STM32_Cmd.STM32_Scp.ScopeTrigger,1
		mov		mode,CMD_LCMCAP
		xor		ebx,ebx
		.while ebx<ADCSAMPLESIZE/2
			mov		ADC_Data[ebx*WORD],2048
			inc		ebx
		.endw
		mov		fThreadDone,TRUE
		mov		STM32_Scp.ADC_SampleSize,10000h
		invoke SetMode
		invoke ImageList_GetIcon,hIml,2,ILD_NORMAL
		mov		hGrayIcon,eax
		invoke ImageList_GetIcon,hIml,3,ILD_NORMAL
		mov		hGreenIcon,eax
		invoke ImageList_GetIcon,hIml,4,ILD_NORMAL
		mov		hRedIcon,eax
		invoke SendDlgItemMessage,hWin,IDC_IMGCONNECTED,STM_SETICON,hGrayIcon,0
	.elseif	eax==WM_COMMAND
		mov edx,wParam
		movzx eax,dx
		shr edx,16
		.if edx==BN_CLICKED
			.if eax==IDOK
				.if !fBluetooth
					invoke SendDlgItemMessage,hWin,IDC_IMGCONNECTED,STM_SETICON,hRedIcon,0
					invoke DeleteObject,eax
					invoke BlueToothConnect
					mov		fBluetooth,eax
					.if eax
						mov		mode,CMD_LCMCAP
						invoke SetMode
						;Create a timer. The event will read the frequency, format it and display the result
						invoke SetTimer,hWin,1000,100,NULL
						invoke SendDlgItemMessage,hWin,IDC_IMGCONNECTED,STM_SETICON,hGreenIcon,0
						invoke DeleteObject,eax
					.else
						invoke SendDlgItemMessage,hWnd,IDC_IMGCONNECTED,STM_SETICON,hGrayIcon,0
					.endif
				.endif
			.elseif eax==IDCANCEL
				invoke	SendMessage,hWin,WM_CLOSE,NULL,NULL
			.endif
		.endif
	.elseif	eax==WM_TIMER
		invoke KillTimer,hWin,1000
		invoke SendDlgItemMessage,hWin,IDC_IMGCONNECTED,STM_SETICON,hRedIcon,0
		.if mode==CMD_SCPSET
			.if !fHoldSampling && fSampleDone
				mov		fSampleDone,FALSE
				invoke CreateThread,NULL,NULL,addr ScopeSampleThreadProc,hWin,0,addr tid
				invoke CloseHandle,eax
			.endif
		.elseif mode==CMD_HSCSET
			.if fThreadDone
				invoke BTPut,offset mode,4
				invoke BTPut,offset STM32_Cmd.STM32_Hsc,8
				invoke BTGet,offset STM32_Cmd.STM32_Frq,8
				invoke FormatFrequency,STM32_Cmd.STM32_Frq.Frequency,addr buffer
				invoke SetWindowText,hHsc,addr buffer
				mov		mode,CMD_FRQCH1
				invoke SetMode
			.endif
		.elseif mode==CMD_FRQCH1
			.if fThreadDone
				invoke BTPut,offset mode,4
				invoke BTGet,offset STM32_Cmd.STM32_Frq,8
				invoke FormatFrequency,STM32_Cmd.STM32_Frq.Frequency,addr buffer
				invoke SetWindowText,hHsc,addr buffer
			.endif
		.elseif mode==CMD_LCMCAL
			.if fThreadDone
				invoke BTPut,offset mode,4
				invoke BTGet,offset STM32_Cmd.STM32_Lcm,8
				mov		mode,CMD_LCMCAP
				invoke SetMode
			.endif
		.elseif mode==CMD_LCMCAP
			.if fThreadDone
				invoke BTPut,offset mode,4
				invoke BTGet,offset STM32_Cmd.STM32_Frq,8
				invoke BTGet,offset STM32_Cmd.STM32_Lcm,8
				invoke CalculateCapacitor,addr buffer
				invoke SetWindowText,hLcm,addr buffer
			.endif
		.elseif mode==CMD_LCMIND
			.if fThreadDone
				invoke BTPut,offset mode,4
				invoke BTGet,offset STM32_Cmd.STM32_Frq,8
				invoke BTGet,offset STM32_Cmd.STM32_Lcm,8
				invoke CalculateInductor,addr buffer
				invoke SetWindowText,hLcm,addr buffer
			.endif
		.elseif mode==CMD_DDSSET
			.if fThreadDone
				invoke BTPut,offset mode,4
				invoke BTPut,offset STM32_Cmd.STM32_Dds,sizeof STM32_DDS
				mov		mode,CMD_DONE
			.endif
		.elseif mode==CMD_LGASET
			.if fThreadDone
				invoke BTPut,offset mode,4
				invoke BTPut,offset STM32_Cmd.STM32_Lga,sizeof STM32_LGA
				movzx	eax,STM32_Cmd.STM32_Lga.DataBlocks
				mov		ecx,1024
				mul		ecx
				push	eax
				invoke BTGet,offset LGA_Data,eax
				;Init horizontal scrollbar
				mov		xsinf.cbSize,sizeof SCROLLINFO
				mov		xsinf.fMask,SIF_ALL
				invoke GetScrollInfo,hLGAScrn,SB_HORZ,addr xsinf
				mov		xsinf.nMin,0
				pop		eax
				add		eax,23
				mov		xsinf.nMax,eax
				mov		xsinf.nPos,0
				mov		xsinf.nPage,GRIDSIZE
				invoke SetScrollInfo,hLGAScrn,SB_HORZ,addr xsinf,TRUE
				invoke InvalidateRect,hLGAScrn,NULL,TRUE
				invoke UpdateWindow,hLGAScrn
				mov		mode,CMD_DONE
			.endif
		.endif
		.if fThreadDone && fBluetooth
			invoke SendDlgItemMessage,hWin,IDC_IMGCONNECTED,STM_SETICON,hGreenIcon,0
		.elseif ! fBluetooth
			invoke SendDlgItemMessage,hWin,IDC_IMGCONNECTED,STM_SETICON,hGrayIcon,0
		.endif
		.if fBluetooth
			invoke SetTimer,hWin,1000,100,NULL
		.endif
	.elseif	eax==WM_CLOSE
		mov		fExitThread,TRUE
		invoke KillTimer,hWin,1000
		xor		ebx,ebx
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
		invoke Sleep,100
		invoke BlueToothDisconnect
		invoke DeleteObject,hFont
		invoke DestroyIcon,hGrayIcon
		invoke DestroyIcon,hGreenIcon
		invoke DestroyIcon,hRedIcon
		invoke ImageList_Destroy,hIml
		invoke EndDialog,hWin,0
	.elseif eax==WM_NOTIFY
		mov		eax,lParam
		mov		eax,[eax].NMHDR.code
		.if eax==TCN_SELCHANGE
			;Tab selection
			invoke SendDlgItemMessage,hWin,IDC_TABFUNCTION,TCM_GETCURSEL,0,0
			.if !eax
				;LC Meter
				invoke ShowWindow,hScpCld,SW_HIDE
				invoke ShowWindow,hHscCld,SW_HIDE
				invoke ShowWindow,hDDSCld,SW_HIDE
				invoke ShowWindow,hLGACld,SW_HIDE
				invoke ShowWindow,hLcmCld,SW_SHOW
				mov		mode,CMD_LCMCAP
			.elseif eax==1
				;High Speed Clock
				invoke ShowWindow,hScpCld,SW_HIDE
				invoke ShowWindow,hDDSCld,SW_HIDE
				invoke ShowWindow,hLcmCld,SW_HIDE
				invoke ShowWindow,hLGACld,SW_HIDE
				invoke ShowWindow,hHscCld,SW_SHOW
				mov		mode,CMD_FRQCH1
			.elseif eax==2
				;Scope
				invoke ShowWindow,hLcmCld,SW_HIDE
				invoke ShowWindow,hHscCld,SW_HIDE
				invoke ShowWindow,hDDSCld,SW_HIDE
				invoke ShowWindow,hLGACld,SW_HIDE
				invoke ShowWindow,hScpCld,SW_SHOW
				invoke ShowWindow,hScpScrnCld,SW_SHOW
				invoke ShowWindow,hLGAScrnCld,SW_HIDE
				invoke ShowWindow,hDDSScrnCld,SW_HIDE
				mov		fSampleDone,TRUE
				mov		mode,CMD_SCPSET
			.elseif eax==3
				;DDSWave
				invoke ShowWindow,hScpCld,SW_HIDE
				invoke ShowWindow,hHscCld,SW_HIDE
				invoke ShowWindow,hLcmCld,SW_HIDE
				invoke ShowWindow,hLGACld,SW_HIDE
				invoke ShowWindow,hDDSCld,SW_SHOW
				invoke ShowWindow,hDDSScrnCld,SW_SHOW
				invoke ShowWindow,hLGAScrnCld,SW_HIDE
				invoke ShowWindow,hScpScrnCld,SW_HIDE
				mov		mode,CMD_DDSSET
			.elseif eax==4
				;LGA
				invoke ShowWindow,hScpCld,SW_HIDE
				invoke ShowWindow,hHscCld,SW_HIDE
				invoke ShowWindow,hLcmCld,SW_HIDE
				invoke ShowWindow,hDDSCld,SW_HIDE
				invoke ShowWindow,hLGACld,SW_SHOW
				invoke ShowWindow,hLGAScrnCld,SW_SHOW
				invoke ShowWindow,hDDSScrnCld,SW_HIDE
				invoke ShowWindow,hScpScrnCld,SW_HIDE
				mov		mode,CMD_LGASET
			.endif
			invoke SetMode
		.endif
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

	mov		wc.lpfnWndProc,offset DDSProc
	invoke LoadCursor,0,IDC_CROSS
	mov		wc.hCursor,eax
	mov		wc.lpszClassName,offset szDDSCLASS
	invoke RegisterClassEx,addr wc

	mov		wc.lpfnWndProc,offset LGAProc
	invoke LoadCursor,0,IDC_CROSS
	mov		wc.hCursor,eax
	mov		wc.lpszClassName,offset szLGACLASS
	invoke RegisterClassEx,addr wc

	invoke	DialogBoxParam,hInstance,IDD_MAIN,NULL,addr DlgProc,NULL
	invoke	ExitProcess,0

end start
