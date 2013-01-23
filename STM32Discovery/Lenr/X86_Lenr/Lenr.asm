.386
.model flat,stdcall
option casemap:none

include Lenr.inc

.code

DisplayProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	ps:PAINTSTRUCT
	LOCAL	rect:RECT
	LOCAL	mDC:HDC

	mov		eax,uMsg
	.if	eax==WM_CREATE
		invoke MoveWindow,hWin,GRPWDT+GRPXPS+GRPXPS-202,GRPHGT+GRPYPS+GRPYPS,200,74,FALSE
		xor		eax,eax
	.elseif eax==WM_PAINT
		mov		eax,graph
		.if eax==IDC_RBNVOLT
			movzx	eax,lenr.log.Volt
			shr		eax,1
			invoke wsprintf,addr display,addr szFmtVolt,eax
		.elseif eax==IDC_RBNAMP
			movzx	eax,lenr.log.Amp
			shr		eax,3
			invoke wsprintf,addr display,addr szFmtAmp,eax
		.elseif eax==IDC_RBNPOWER
			movzx	eax,lenr.log.Volt
			shr		eax,1
			movzx	ecx,lenr.log.Amp
			shr		ecx,3
			mul		ecx
			mov		ecx,100
			xor		edx,edx
			div		ecx
			invoke wsprintf,addr display,addr szFmtPower,eax
		.elseif eax==IDC_RBNAMB
			movzx	eax,lenr.log.Temp1
			invoke wsprintf,addr display,addr szFmtTemp,eax
		.elseif eax==IDC_RBNCELL
			movzx	eax,lenr.log.Temp2
			shl		eax,2
			invoke wsprintf,addr display,addr szFmtTemp,eax
		.endif
		invoke lstrlen,addr display
		mov		edx,dword ptr display[eax-3]
		mov		display[eax-3],'.'
		mov		dword ptr display[eax-2],edx
		invoke GetClientRect,hWin,addr rect
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
		invoke lstrlen,addr display
		mov		edx,eax
		invoke DrawText,mDC,addr display,edx,addr rect,DT_CENTER or DT_VCENTER or DT_SINGLELINE
		pop		eax
		invoke SelectObject,mDC,eax
		invoke BitBlt,ps.hdc,0,0,rect.right,rect.bottom,mDC,0,0,SRCCOPY
		;Delete bitmap
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

DisplayProc endp

GraphProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	ps:PAINTSTRUCT
	LOCAL	rect:RECT
	LOCAL	mDC:HDC
	LOCAL	buffer[32]:BYTE

	mov		eax,uMsg
	.if	eax==WM_CREATE
		invoke MoveWindow,hWin,0,0,GRPWDT+GRPXPS+30,GRPHGT+GRPYPS+30,FALSE
		xor		eax,eax
	.elseif eax==WM_PAINT
		invoke GetClientRect,hWin,addr rect
		invoke BeginPaint,hWin,addr ps
		invoke CreateCompatibleDC,ps.hdc
		mov		mDC,eax
		invoke CreateCompatibleBitmap,ps.hdc,rect.right,rect.bottom
		invoke SelectObject,mDC,eax
		push	eax
		invoke GetStockObject,BLACK_BRUSH
		invoke FillRect,mDC,addr rect,eax
		invoke CreatePen,PS_SOLID,1,0303030h
		invoke SelectObject,mDC,eax
		push	eax
		;Draw horizontal lines
		mov		edi,GRPXPS
		xor		ecx,ecx
		.while ecx<=10
			push	ecx
			invoke MoveToEx,mDC,GRPXPS,edi,NULL
			invoke LineTo,mDC,GRPWDT+GRPXPS,edi
			add		edi,GRPYST
			pop		ecx
			inc		ecx
		.endw
		;Draw vertical lines
		mov		edi,GRPXPS
		xor		ecx,ecx
		.while ecx<=12
			push	ecx
			invoke MoveToEx,mDC,edi,GRPYPS,NULL
			invoke LineTo,mDC,edi,GRPHGT+GRPYPS
			add		edi,GRPXST
			pop		ecx
			inc		ecx
		.endw
		;Delete pen
		pop		eax
		invoke SelectObject,mDC,eax
		invoke DeleteObject,eax
		invoke CreatePen,PS_SOLID,1,0FFFFFFh
		invoke SelectObject,mDC,eax
		push	eax
		mov		ebx,logpos
		add		ebx,GRPXPS
		invoke MoveToEx,mDC,ebx,GRPYPS,NULL
		invoke LineTo,mDC,ebx,GRPHGT+GRPYPS
		;Delete pen
		pop		eax
		invoke SelectObject,mDC,eax
		invoke DeleteObject,eax
		invoke SetTextColor,mDC,0FFFFFFh
		invoke SetBkMode,mDC,TRANSPARENT
		;Draw time scale
		mov		esi,offset szTime
		mov		ecx,GRPXPS-15
		.while byte ptr [esi]
			push	ecx
			mov		edx,rect.bottom
			sub		edx,20
			invoke TextOut,mDC,ecx,edx,esi,5
			lea		esi,[esi+6]
			pop		ecx
			lea		ecx,[ecx+GRPXST]
		.endw
		mov		eax,graph
		.if eax==IDC_RBNVOLT
			call	DrawVolt
		.elseif eax==IDC_RBNAMP
			call	DrawAmp
		.elseif eax==IDC_RBNPOWER
			call	DrawPower
		.elseif eax==IDC_RBNAMB
			call	DrawTemp1
		.elseif eax==IDC_RBNCELL
			call	DrawTemp2
		.endif
		;Draw PWM
		invoke wsprintf,addr buffer,addr szFmtPwm,lenr.Pwm
		invoke lstrlen,addr buffer
		invoke TextOut,mDC,15,5,addr buffer,eax
		invoke BitBlt,ps.hdc,0,0,rect.right,rect.bottom,mDC,0,0,SRCCOPY
		;Delete bitmap
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

DrawYScale:
	invoke lstrlen,esi
	push	eax
	invoke TextOut,mDC,400,5,esi,eax
	pop		eax
	lea		esi,[esi+eax+1]
	mov		ecx,20
	.while byte ptr [esi]
		push	ecx
		invoke TextOut,mDC,GRPXPS-22,ecx,esi,3
		lea		esi,[esi+4]
		pop		ecx
		lea		ecx,[ecx+GRPYST]
	.endw
	retn

DrawVolt:
	;Draw volt scale
	mov		esi,offset szVolt
	call DrawYScale
	invoke CreatePen,PS_SOLID,2,00000FFh
	invoke SelectObject,mDC,eax
	push	eax
	xor		esi,esi
	.while esi<864-1
		mov		eax,sizeof LOG
		mul		esi
		mov		ebx,eax
		movzx	eax,log.Volt[ebx]
		mov		ecx,4
		xor		edx,edx
		div		ecx
		sub		eax,GRPHGT+GRPYPS
		neg		eax
		invoke MoveToEx,mDC,addr [esi+GRPXPS],eax,NULL
		movzx	eax,log.Volt[ebx+sizeof LOG]
		mov		ecx,4
		xor		edx,edx
		div		ecx
		sub		eax,GRPHGT+GRPYPS
		neg		eax
		invoke LineTo,mDC,addr [esi+GRPXPS+1],eax
		lea		esi,[esi+1]
	.endw
	;Delete pen
	pop		eax
	invoke SelectObject,mDC,eax
	invoke DeleteObject,eax
	retn

DrawAmp:
	;Draw amp scale
	mov		esi,offset szAmp
	call DrawYScale
	invoke CreatePen,PS_SOLID,2,000FF00h
	invoke SelectObject,mDC,eax
	push	eax
	xor		esi,esi
	.while esi<864-1
		mov		eax,sizeof LOG
		mul		esi
		mov		ebx,eax
		movzx	eax,log.Amp[ebx]
		sub		eax,GRPHGT+GRPYPS
		neg		eax
		invoke MoveToEx,mDC,addr [esi+GRPXPS],eax,NULL
		movzx	eax,log.Amp[ebx+sizeof LOG]
		sub		eax,GRPHGT+GRPYPS
		neg		eax
		invoke LineTo,mDC,addr [esi+GRPXPS+1],eax
		lea		esi,[esi+1]
	.endw
	;Delete pen
	pop		eax
	invoke SelectObject,mDC,eax
	invoke DeleteObject,eax
	retn

DrawPower:
	;Draw power scale
	mov		esi,offset szPower
	call DrawYScale
	invoke CreatePen,PS_SOLID,2,000FFFFh
	invoke SelectObject,mDC,eax
	push	eax
	xor		esi,esi
	.while esi<864-1
		mov		eax,sizeof LOG
		mul		esi
		mov		ebx,eax
		movzx	eax,log.Volt[ebx]
		movzx	ecx,log.Amp[ebx]
		mul		ecx
		mov		ecx,2000
		xor		edx,edx
		div		ecx
		sub		eax,GRPHGT+GRPYPS
		neg		eax
		invoke MoveToEx,mDC,addr [esi+GRPXPS],eax,NULL
		movzx	eax,log.Volt[ebx+sizeof LOG]
		movzx	ecx,log.Amp[ebx+sizeof LOG]
		mul		ecx
		mov		ecx,2000
		xor		edx,edx
		div		ecx
		sub		eax,GRPHGT+GRPYPS
		neg		eax
		invoke LineTo,mDC,addr [esi+GRPXPS+1],eax
		lea		esi,[esi+1]
	.endw
	;Delete pen
	pop		eax
	invoke SelectObject,mDC,eax
	invoke DeleteObject,eax
	retn

DrawTemp1:
	;Draw temp scale
	mov		esi,offset szTemp
	call DrawYScale
	invoke CreatePen,PS_SOLID,2,0FF0000h
	invoke SelectObject,mDC,eax
	push	eax
	xor		esi,esi
	.while esi<864-1
		mov		eax,sizeof LOG
		mul		esi
		mov		ebx,eax
		movzx	eax,log.Temp1[ebx]
		mov		ecx,20
		xor		edx,edx
		div		ecx
		sub		eax,GRPHGT+GRPYPS
		neg		eax
		invoke MoveToEx,mDC,addr [esi+GRPXPS],eax,NULL
		movzx	eax,log.Temp1[ebx+sizeof LOG]
		mov		ecx,20
		xor		edx,edx
		div		ecx
		sub		eax,GRPHGT+GRPYPS
		neg		eax
		invoke LineTo,mDC,addr [esi+GRPXPS+1],eax
		lea		esi,[esi+1]
	.endw
	;Delete pen
	pop		eax
	invoke SelectObject,mDC,eax
	invoke DeleteObject,eax
	retn

DrawTemp2:
	;Draw temp scale
	mov		esi,offset szTemp
	call DrawYScale
	invoke CreatePen,PS_SOLID,2,0FFFF00h
	invoke SelectObject,mDC,eax
	push	eax
	xor		esi,esi
	.while esi<864-1
		mov		eax,sizeof LOG
		mul		esi
		mov		ebx,eax
		movzx	eax,log.Temp2[ebx]
		mov		ecx,20
		xor		edx,edx
		div		ecx
		sub		eax,GRPHGT+GRPYPS
		neg		eax
		invoke MoveToEx,mDC,addr [esi+GRPXPS],eax,NULL
		movzx	eax,log.Temp2[ebx+sizeof LOG]
		mov		ecx,20
		xor		edx,edx
		div		ecx
		sub		eax,GRPHGT+GRPYPS
		neg		eax
		invoke LineTo,mDC,addr [esi+GRPXPS+1],eax
		lea		esi,[esi+1]
	.endw
	;Delete pen
	pop		eax
	invoke SelectObject,mDC,eax
	invoke DeleteObject,eax
	retn

GraphProc endp

WndProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	res:DWORD
	LOCAL	systime:SYSTEMTIME

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		push	hWin
		pop		hWnd
		invoke STLinkConnect,hWin
		.if eax && eax!=IDIGNORE && eax!=IDABORT
			mov		connected,eax
			invoke STLinkWrite,hWin,20000000h,addr lenr,DWORD*2+WORD*4
		.endif
		invoke CreateFontIndirect,addr Tahoma_36
		mov		hFont,eax
		;Create a timer.
		invoke SetTimer,hWin,1000,100,NULL
		invoke MoveWindow,hWin,0,0,GRPWDT+GRPXPS+GRPXPS+6,GRPHGT+GRPYPS+GRPYPS+120,FALSE
		mov		ebx,IDC_RBNVOLT
		xor		edi,edi
		.while ebx<=IDC_RBNCELL
			invoke GetDlgItem,hWin,ebx
			invoke MoveWindow,eax,edi,560,90,15,FALSE
			add		edi,100
			inc		ebx
		.endw
		invoke CheckDlgButton,hWin,IDC_RBNVOLT,BST_CHECKED
		mov		graph,IDC_RBNVOLT
		invoke GetDlgItem,hWin,IDC_STCPOWER
		invoke MoveWindow,eax,0,585,90,15,FALSE
		invoke GetDlgItem,hWin,IDC_EDTPOWER
		invoke MoveWindow,eax,0,600,90,25,FALSE
		invoke GetDlgItem,hWin,IDC_UDNPOWER
		invoke MoveWindow,eax,90,600,16,25,FALSE
		invoke SendDlgItemMessage,hWin,IDC_UDNPOWER,UDM_SETRANGE,0,00000028h
		invoke GetDlgItem,hWin,IDC_CHKSTEP
		invoke MoveWindow,eax,130,605,170,16,FALSE
		invoke GetDlgItem,hWin,IDC_STCPOWERMIN
		invoke MoveWindow,eax,300,585,90,15,FALSE
		invoke GetDlgItem,hWin,IDC_EDTPOWERMIN
		invoke MoveWindow,eax,300,605,90,25,FALSE
		invoke GetDlgItem,hWin,IDC_UDNPOWERMIN
		invoke MoveWindow,eax,390,605,16,25,FALSE
		invoke SendDlgItemMessage,hWin,IDC_UDNPOWERMIN,UDM_SETRANGE,0,00000028h
		invoke GetDlgItem,hWin,IDC_STCPOWERMAX
		invoke MoveWindow,eax,420,585,90,15,FALSE
		invoke GetDlgItem,hWin,IDC_EDTPOWERMAX
		invoke MoveWindow,eax,420,605,90,25,FALSE
		invoke GetDlgItem,hWin,IDC_UDNPOWERMAX
		invoke MoveWindow,eax,510,605,16,25,FALSE
		invoke SendDlgItemMessage,hWin,IDC_UDNPOWERMAX,UDM_SETRANGE,0,00000028h
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDM_FILE_EXIT
				invoke SendMessage,hWin,WM_CLOSE,0,0
			.elseif eax==IDM_HELP_ABOUT
				invoke ShellAbout,hWin,addr AppName,addr AboutMsg,NULL
			.elseif eax>=IDC_RBNVOLT && eax<=IDC_RBNCELL
				mov		graph,eax
				invoke GetDlgItem,hWin,IDC_GRAPH
				invoke InvalidateRect,eax,NULL,TRUE
				invoke GetDlgItem,hWin,IDC_DISPLAY
				invoke InvalidateRect,eax,NULL,TRUE
			.elseif eax==IDC_CHKSTEP
				invoke IsDlgButtonChecked,hWin,IDC_CHKSTEP
				mov		rampupdown,0
				.if eax
					mov		rampupdown,1
				.endif
			.endif
		.endif
	.elseif	eax==WM_TIMER
		.if connected
			;Read 4 bytes from STM32 ram and store it in res.
			invoke STLinkRead,hWin,20000000h,addr res,DWORD
			.if eax
				mov		eax,res
				.if eax!=lenr.SecCount
					mov		lenr.SecCount,eax
					;Scroll the readings
					mov		ecx,199*sizeof LOG
					.while ecx
						mov		ax,lenr.log.Volt[ecx-sizeof LOG]
						mov		lenr.log.Volt[ecx],ax
						mov		ax,lenr.log.Amp[ecx-sizeof LOG]
						mov		lenr.log.Amp[ecx],ax
						mov		ax,lenr.log.Temp1[ecx-sizeof LOG]
						mov		lenr.log.Temp1[ecx],ax
						mov		ax,lenr.log.Temp2[ecx-sizeof LOG]
						mov		lenr.log.Temp2[ecx],ax
						sub		ecx,sizeof LOG
					.endw
					invoke STLinkRead,hWin,20000008h,addr lenr.log.Volt,WORD*4
					;Convert values
					shr		lenr.log.Volt,1
					shr		lenr.log.Amp,3
					shl		lenr.log.Temp1,1
					shl		lenr.log.Temp1,2
					invoke GetDlgItem,hWin,IDC_DISPLAY
					invoke InvalidateRect,eax,NULL,TRUE
					;Adjust power
					invoke GetDlgItemInt,hWin,IDC_EDTPOWER,NULL,FALSE
					mov		edx,100
					mul		edx
					mov		ebx,eax
					movzx	eax,lenr.log.Volt
					movzx	edx,lenr.log.Amp
					mul		edx
					mov		ecx,100
					xor		edx,edx
					div		ecx
					.if eax>ebx
						.if lenr.Pwm
							dec		lenr.Pwm
							invoke GetDlgItem,hWin,IDC_GRAPH
							invoke InvalidateRect,eax,NULL,TRUE
						.endif
					.elseif eax<ebx
						.if lenr.Pwm<255
							inc		lenr.Pwm
							invoke GetDlgItem,hWin,IDC_GRAPH
							invoke InvalidateRect,eax,NULL,TRUE
						.endif
					.endif
					;Update pwm
					invoke STLinkWrite,hWin,20000004h,addr lenr.Pwm,DWORD
				.endif
			.endif
		.endif
		invoke GetLocalTime,addr systime
		movzx	eax,systime.wSecond
		.if eax!=lastsec
			mov		lastsec,eax
			;Convert to seconds since 00:00:00
			mov		ebx,eax
			movzx	eax,systime.wMinute
			mov		edx,60
			mul		edx
			add		ebx,eax
			movzx	eax,systime.wHour
			mov		edx,60*60
			mul		edx
			add		ebx,eax
			;Update log every 100 seconds
			mov		eax,ebx
			mov		ecx,100
			xor		edx,edx
			div		ecx
			.if !edx
				mov		logpos,eax
				mov		ecx,sizeof LOG
				mul		ecx
				mov		ebx,eax
				;Average 200 voltage readings
				xor		ecx,ecx
				xor		edi,edi
				.while ecx<200
					mov		eax,sizeof LOG
					mul		ecx
					movzx	eax,lenr.log.Volt[eax]
					add		edi,eax
					inc		ecx
				.endw
				mov		ecx,200
				xor		edx,edx
				div		ecx
				mov		log.Volt[ebx],ax
				;Average 200 current readings
				xor		ecx,ecx
				xor		edi,edi
				.while ecx<200
					mov		eax,sizeof LOG
					mul		ecx
					movzx	eax,lenr.log.Amp[eax]
					add		edi,eax
					inc		ecx
				.endw
				mov		ecx,200
				xor		edx,edx
				div		ecx
				mov		log.Amp[ebx],ax
				;Average 200 ambient temp readings
				xor		ecx,ecx
				xor		edi,edi
				.while ecx<200
					mov		eax,sizeof LOG
					mul		ecx
					movzx	eax,lenr.log.Temp1[eax]
					add		edi,eax
					inc		ecx
				.endw
				mov		ecx,200
				xor		edx,edx
				div		ecx
				mov		log.Temp1[ebx],ax
				;Average 200 cell temp readings
				xor		ecx,ecx
				xor		edi,edi
				.while ecx<200
					mov		eax,sizeof LOG
					mul		ecx
					movzx	eax,lenr.log.Temp2[eax]
					add		edi,eax
					inc		ecx
				.endw
				mov		ecx,200
				xor		edx,edx
				div		ecx
				mov		log.Temp2[ebx],ax
				invoke GetDlgItem,hWin,IDC_GRAPH
				invoke InvalidateRect,eax,NULL,TRUE
			.endif
			invoke IsDlgButtonChecked,hWin,IDC_CHKSTEP
			.if eax
				.if systime.wSecond==0 && systime.wMinute==0
					invoke GetDlgItemInt,hWin,IDC_EDTPOWER,NULL,FALSE
					mov		ebx,eax
					.if rampupdown==1
						;Up
						invoke GetDlgItemInt,hWin,IDC_EDTPOWERMAX,NULL,FALSE
						.if ebx>=eax
							mov		rampupdown,-1
						.endif
					.elseif rampupdown==-1
						;Down
						invoke GetDlgItemInt,hWin,IDC_EDTPOWERMIN,NULL,FALSE
						.if ebx<=eax
							mov		rampupdown,1
						.endif
					.endif
					invoke SendDlgItemMessage,hWin,IDC_UDNPOWER,UDM_GETPOS,0,0
					add		eax,rampupdown
					invoke SendDlgItemMessage,hWin,IDC_UDNPOWER,UDM_SETPOS,0,eax
				.endif
			.endif
		.endif
	.elseif eax==WM_CLOSE
		invoke KillTimer,hWin,1000
		.if connected
			invoke STLinkDisconnect,hWin
		.endif
		invoke DeleteObject,hFont
		invoke DestroyWindow,hWin
	.elseif uMsg==WM_DESTROY
		invoke PostQuitMessage,NULL
	.else
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
		ret
	.endif
	xor    eax,eax
	ret

WndProc endp

WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
	LOCAL	wc:WNDCLASSEX
	LOCAL	msg:MSG

	mov		wc.cbSize,sizeof WNDCLASSEX
	mov		wc.style,CS_HREDRAW or CS_VREDRAW
	mov		wc.lpfnWndProc,offset WndProc
	mov		wc.cbClsExtra,NULL
	mov		wc.cbWndExtra,DLGWINDOWEXTRA
	push	hInst
	pop		wc.hInstance
	mov		wc.hbrBackground,COLOR_BTNFACE+1
	mov		wc.lpszMenuName,IDM_MENU
	mov		wc.lpszClassName,offset szMainClass
	xor		eax,eax
	mov		wc.hIcon,eax
	mov		wc.hIconSm,eax
	invoke LoadCursor,NULL,IDC_ARROW
	mov		wc.hCursor,eax
	invoke RegisterClassEx,addr wc
	mov		wc.lpfnWndProc,offset GraphProc
	mov		wc.lpszClassName,offset szGraphClass
	mov		wc.hbrBackground,NULL
	invoke RegisterClassEx,addr wc
	mov		wc.lpfnWndProc,offset DisplayProc
	mov		wc.lpszClassName,offset szDisplayClass
	mov		wc.hbrBackground,NULL
	invoke RegisterClassEx,addr wc
	invoke CreateDialogParam,hInstance,IDD_DIALOG,NULL,addr WndProc,NULL
	invoke ShowWindow,hWnd,SW_SHOWNORMAL
	invoke UpdateWindow,hWnd
	.while TRUE
		invoke GetMessage,addr msg,NULL,0,0
	  .BREAK .if !eax
		invoke TranslateMessage,addr msg
		invoke DispatchMessage,addr msg
	.endw
	mov		eax,msg.wParam
	ret

WinMain endp

start:

	invoke GetModuleHandle,NULL
	mov    hInstance,eax
	invoke GetCommandLine
	invoke InitCommonControls
	mov		CommandLine,eax
	invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
	invoke ExitProcess,eax

end start
