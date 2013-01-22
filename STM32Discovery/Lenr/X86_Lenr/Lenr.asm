.386
.model flat,stdcall
option casemap:none

include Lenr.inc

.code

GraphProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	ps:PAINTSTRUCT
	LOCAL	rect:RECT
	LOCAL	mDC:HDC
	LOCAL	pt:POINT
	LOCAL	buffer[128]:BYTE
	LOCAL	buffer1[128]:BYTE

	mov		eax,uMsg
	.if	eax==WM_CREATE
		invoke MoveWindow,hWin,0,0,GRPWDT+60+30,GRPHGT+60,FALSE
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
		mov		edi,30
		xor		ecx,ecx
		.while ecx<=10
			push	ecx
			invoke MoveToEx,mDC,60,edi,NULL
			invoke LineTo,mDC,GRPWDT+30,edi
			add		edi,GRPYST
			pop		ecx
			inc		ecx
		.endw
		;Draw vertical lines
		mov		edi,60
		xor		ecx,ecx
		.while ecx<=12
			push	ecx
			invoke MoveToEx,mDC,edi,30,NULL
			invoke LineTo,mDC,edi,GRPHGT+30
			add		edi,GRPXST
			pop		ecx
			inc		ecx
		.endw
		;Delete pen
		pop		eax
		invoke SelectObject,mDC,eax
		invoke DeleteObject,eax
		invoke SetTextColor,mDC,0FFFFFFh
		invoke SetBkMode,mDC,TRANSPARENT
		;Draw time scale
		mov		esi,offset szTime
		mov		ecx,45
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
	mov		ecx,25
	.while byte ptr [esi]
		push	ecx
		invoke TextOut,mDC,25,ecx,esi,3
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
		sub		eax,GRPHGT+30
		neg		eax
		invoke MoveToEx,mDC,addr [esi+60],eax,NULL
		movzx	eax,log.Volt[ebx+sizeof LOG]
		mov		ecx,4
		xor		edx,edx
		div		ecx
		sub		eax,GRPHGT+30
		neg		eax
		invoke LineTo,mDC,addr [esi+61],eax
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
;		mov		ecx,20
;		xor		edx,edx
;		div		ecx
		sub		eax,GRPHGT+30
		neg		eax
		invoke MoveToEx,mDC,addr [esi+60],eax,NULL
		movzx	eax,log.Amp[ebx+sizeof LOG]
;		mov		ecx,20
;		xor		edx,edx
;		div		ecx
		sub		eax,GRPHGT+30
		neg		eax
		invoke LineTo,mDC,addr [esi+61],eax
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
		sub		eax,GRPHGT+30
		neg		eax
		invoke MoveToEx,mDC,addr [esi+60],eax,NULL
		movzx	eax,log.Amp[ebx+sizeof LOG]
		mov		ecx,20
		xor		edx,edx
		div		ecx
		sub		eax,GRPHGT+30
		neg		eax
		invoke LineTo,mDC,addr [esi+61],eax
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
		sub		eax,GRPHGT+30
		neg		eax
		invoke MoveToEx,mDC,addr [esi+60],eax,NULL
		movzx	eax,log.Temp1[ebx+sizeof LOG]
		mov		ecx,20
		xor		edx,edx
		div		ecx
		sub		eax,GRPHGT+30
		neg		eax
		invoke LineTo,mDC,addr [esi+61],eax
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
		sub		eax,GRPHGT+30
		neg		eax
		invoke MoveToEx,mDC,addr [esi+60],eax,NULL
		movzx	eax,log.Temp2[ebx+sizeof LOG]
		mov		ecx,20
		xor		edx,edx
		div		ecx
		sub		eax,GRPHGT+30
		neg		eax
		invoke LineTo,mDC,addr [esi+61],eax
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
		;Create a timer.
		invoke SetTimer,hWin,1000,100,NULL
		invoke MoveWindow,hWin,0,0,1060,512+100,FALSE
		mov		ebx,IDC_RBNVOLT
		xor		edi,edi
		.while ebx<=IDC_RBNCELL
			invoke GetDlgItem,hWin,ebx
			invoke MoveWindow,eax,960,edi,90,15,FALSE
			add		edi,15
			inc		ebx
		.endw
		invoke CheckDlgButton,hWin,IDC_RBNVOLT,BST_CHECKED
		mov		graph,IDC_RBNVOLT
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
					PrintDec eax
					invoke STLinkWrite,hWin,20000004h,addr lenr.Pwm,DWORD
					invoke STLinkRead,hWin,20000008h,addr lenr.Volt,WORD*4
					PrintDec lenr.Volt
					PrintDec lenr.Amp
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
				mov		ecx,sizeof LOG
				mul		ecx
				mov		log.Volt[eax],1500
				mov		log.Amp[eax],150
				mov		log.Temp1[eax],2500
				mov		log.Temp2[eax],8000
				invoke GetDlgItem,hWin,IDC_GRAPH
				invoke InvalidateRect,eax,NULL,TRUE
			.endif
		.endif
	.elseif eax==WM_CLOSE
		invoke KillTimer,hWin,1000
		.if connected
			invoke STLinkDisconnect,hWin
		.endif
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
