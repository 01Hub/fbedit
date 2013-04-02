;/*******************************************************************************
;* Port pins
;* PA.08 Cell heater pvm voltage
;* PA.09 Ambient heater pwm voltage
;* PA.10 Catalyser pwm voltage
;* PA.11 Not used
;* PC.00 Heater voltage
;* PC.01 Heater current
;* PC.02 Ambient temprature
;* PC.03 Cell temprature
;* PC.04 Cell heater temprature
;*******************************************************************************/

.386
.model flat,stdcall
option casemap:none

include Lenr2.inc

.code

DisplayProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	ps:PAINTSTRUCT
	LOCAL	rect:RECT
	LOCAL	mDC:HDC

	mov		eax,uMsg
	.if	eax==WM_CREATE
		xor		eax,eax
	.elseif eax==WM_PAINT
		mov		eax,graph
		.if eax==IDC_RBNVOLTAGE
			movzx	eax,lenr.log.Volt
			invoke wsprintf,addr display,addr szFmtVolt,eax
		.elseif eax==IDC_RBNCURRENT
			movzx	eax,lenr.log.Amp
			invoke wsprintf,addr display,addr szFmtAmp,eax
		.elseif eax==IDC_RBNPOWER
			movzx	eax,lenr.log.Volt
			movzx	ecx,lenr.log.Amp
			mul		ecx
			mov		ecx,100
			xor		edx,edx
			div		ecx
			invoke wsprintf,addr display,addr szFmtPower,eax
		.elseif eax==IDC_RBNCELL
			movsx	eax,lenr.log.Temp1
			invoke wsprintf,addr display,addr szFmtTemp,eax
		.elseif eax==IDC_RBNAMB
			movsx	eax,lenr.log.Temp2
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
	LOCAL	pt:POINT
	LOCAL	hWinPt:HWND

	mov		eax,uMsg
	.if	eax==WM_CREATE
		invoke MoveWindow,hWin,0,0,GRPWDT/4+GRPXPS+30,GRPHGT+GRPYPS+30,FALSE
		xor		eax,eax
	.elseif eax==WM_MOUSEMOVE
		invoke InvalidateRect,hWin,NULL,TRUE
	.elseif eax==WM_PAINT
		invoke GetCursorPos,addr pt
		invoke WindowFromPoint,pt.x,pt.y
		mov		hWinPt,eax
		invoke ScreenToClient,hWin,addr pt
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
			invoke LineTo,mDC,GRPWDT/4+GRPXPS,edi
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
			add		edi,GRPXST/4
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
		invoke SetTextColor,mDC,0FFFFFFh
		invoke SetBkMode,mDC,TRANSPARENT
		mov		edi,offset log
		.if fileshow
			mov		edi,offset filelog
		.endif
		mov		eax,hWinPt
		.if eax==hWin
			mov		eax,pt.x
			mov		ecx,rect.right
			sub		ecx,25
			.if eax>GRPXPS && eax<ecx
				mov		edx,pt.y
				mov		ecx,rect.bottom
				sub		ecx,25
				.if edx>GRPYPS && edx<ecx
					invoke MoveToEx,mDC,GRPXPS,pt.y,NULL
					mov		eax,rect.right
					sub		eax,25
					invoke LineTo,mDC,eax,pt.y
					invoke MoveToEx,mDC,pt.x,GRPYPS,NULL
					invoke LineTo,mDC,pt.x,GRPHGT+GRPYPS
					mov		eax,pt.x
					sub		eax,GRPXPS
					add		eax,xofs
					mov		edx,sizeof LOG
					mul		edx
					mov		edx,graph
					.if edx==IDC_RBNVOLTAGE
						movzx	eax,[edi].LOG.Volt[eax]
						mov		edx,offset szFmtVolt
					.elseif edx==IDC_RBNCURRENT
						movzx	eax,[edi].LOG.Amp[eax]
						mov		edx,offset szFmtAmp
					.elseif edx==IDC_RBNPOWER
						movzx	ecx,[edi].LOG.Amp[eax]
						movzx	eax,[edi].LOG.Volt[eax]
						mul		ecx
						mov		ecx,100
						xor		edx,edx
						div		ecx
						mov		edx,offset szFmtPower
					.elseif edx==IDC_RBNCELL
						movzx	eax,[edi].LOG.Temp1[eax]
						mov		edx,offset szFmtTemp
					.elseif edx==IDC_RBNAMB
						movzx	eax,[edi].LOG.Temp2[eax]
						mov		edx,offset szFmtTemp
					.endif
					invoke wsprintf,addr buffer,edx,eax
					invoke lstrlen,addr buffer
					mov		edx,dword ptr buffer[eax-3]
					mov		buffer[eax-3],'.'
					mov		dword ptr buffer[eax-2],edx
					mov		edx,pt.x
					add		edx,20
					invoke TextOut,mDC,edx,pt.y,addr buffer,addr [eax+1]
				.endif
			.endif
		.endif
		mov		ebx,logpos
		sub		ebx,xofs
		add		ebx,GRPXPS
		invoke MoveToEx,mDC,ebx,GRPYPS,NULL
		invoke LineTo,mDC,ebx,GRPHGT+GRPYPS
		;Delete pen
		pop		eax
		invoke SelectObject,mDC,eax
		invoke DeleteObject,eax
		;Draw time scale
		mov		esi,offset szTime
		mov		ecx,GRPXPS-15
		sub		ecx,xofs
		.while byte ptr [esi]
			push	ecx
			mov		edx,rect.bottom
			sub		edx,20
			invoke TextOut,mDC,ecx,edx,esi,5
			lea		esi,[esi+6]
			pop		ecx
			lea		ecx,[ecx+GRPXST/2]
		.endw
		mov		eax,graph
		.if eax==IDC_RBNVOLTAGE
			call	DrawVolt
		.elseif eax==IDC_RBNCURRENT
			call	DrawAmp
		.elseif eax==IDC_RBNPOWER
			call	DrawPower
		.elseif eax==IDC_RBNCELL
			call	DrawTemp1
		.elseif eax==IDC_RBNAMB
			call	DrawTemp2
		.endif
		;Draw PWM
		movzx	eax,lenr.Pwm1
		sub		eax,255
		neg		eax
		invoke wsprintf,addr buffer,addr szFmtPwm1,eax
		invoke lstrlen,addr buffer
		invoke TextOut,mDC,500,5,addr buffer,eax
		movzx	eax,lenr.Pwm2
		sub		eax,255
		neg		eax
		invoke wsprintf,addr buffer,addr szFmtPwm2,eax
		invoke lstrlen,addr buffer
		invoke TextOut,mDC,600,5,addr buffer,eax
		movzx	eax,lenr.Pwm3
		sub		eax,255
		neg		eax
		invoke wsprintf,addr buffer,addr szFmtPwm3,eax
		invoke lstrlen,addr buffer
		invoke TextOut,mDC,700,5,addr buffer,eax
		movzx	eax,lenr.Pwm4
		sub		eax,255
		neg		eax
		invoke wsprintf,addr buffer,addr szFmtPwm4,eax
		invoke lstrlen,addr buffer
		invoke TextOut,mDC,800,5,addr buffer,eax
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
	invoke TextOut,mDC,100,5,esi,eax
	pop		eax
	lea		esi,[esi+eax+1]
	mov		ecx,20
	.while byte ptr [esi]
		push	ecx
		invoke TextOut,mDC,GRPXPS-26,ecx,esi,3
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
	.while esi<GRPWDT-1
		mov		eax,sizeof LOG
		mul		esi
		mov		ebx,eax
		movzx	eax,[edi].LOG.Volt[ebx]
		mov		ecx,4
		xor		edx,edx
		div		ecx
		sub		eax,GRPHGT+GRPYPS
		neg		eax
		lea		edx,[esi+GRPXPS]
		sub		edx,xofs
		.if sdword ptr edx>=GRPXPS && edx<GRPWDT/4+GRPXPS
			push	edx
			invoke MoveToEx,mDC,edx,eax,NULL
			movzx	eax,[edi].LOG.Volt[ebx+sizeof LOG]
			mov		ecx,4
			xor		edx,edx
			div		ecx
			sub		eax,GRPHGT+GRPYPS
			neg		eax
			pop		edx
			invoke LineTo,mDC,addr [edx+1],eax
		.endif
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
	.while esi<GRPWDT-1
		mov		eax,sizeof LOG
		mul		esi
		mov		ebx,eax
		movzx	eax,[edi].LOG.Amp[ebx]
		sub		eax,GRPHGT+GRPYPS
		neg		eax
		lea		edx,[esi+GRPXPS]
		sub		edx,xofs
		.if sdword ptr edx>=GRPXPS && edx<GRPWDT/4+GRPXPS
			push	edx
			invoke MoveToEx,mDC,edx,eax,NULL
			movzx	eax,[edi].LOG.Amp[ebx+sizeof LOG]
			sub		eax,GRPHGT+GRPYPS
			neg		eax
			pop		edx
			invoke LineTo,mDC,addr [edx+1],eax
		.endif
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
	.while esi<GRPWDT-1
		mov		eax,sizeof LOG
		mul		esi
		mov		ebx,eax
		movzx	eax,[edi].LOG.Volt[ebx]
		movzx	ecx,[edi].LOG.Amp[ebx]
		mul		ecx
		mov		ecx,2000
		xor		edx,edx
		div		ecx
		sub		eax,GRPHGT+GRPYPS
		neg		eax
		lea		edx,[esi+GRPXPS]
		sub		edx,xofs
		.if sdword ptr edx>=GRPXPS && edx<GRPWDT/4+GRPXPS
			push	edx
			invoke MoveToEx,mDC,edx,eax,NULL
			movzx	eax,[edi].LOG.Volt[ebx+sizeof LOG]
			movzx	ecx,[edi].LOG.Amp[ebx+sizeof LOG]
			mul		ecx
			mov		ecx,2000
			xor		edx,edx
			div		ecx
			sub		eax,GRPHGT+GRPYPS
			neg		eax
			pop		edx
			invoke LineTo,mDC,addr [edx+1],eax
		.endif
		lea		esi,[esi+1]
	.endw
	;Delete pen
	pop		eax
	invoke SelectObject,mDC,eax
	invoke DeleteObject,eax
	retn

DrawTemp2:
	;Draw temp scale
	mov		esi,offset szTempAmbient
	call DrawYScale
	invoke CreatePen,PS_SOLID,2,0FF0000h
	invoke SelectObject,mDC,eax
	push	eax
	xor		esi,esi
	.while esi<GRPWDT-1
		mov		eax,sizeof LOG
		mul		esi
		mov		ebx,eax
		movzx	eax,[edi].LOG.Temp2[ebx]
		mov		ecx,8
		xor		edx,edx
		div		ecx
		sub		eax,GRPHGT+GRPYPS
		neg		eax
		lea		edx,[esi+GRPXPS]
		sub		edx,xofs
		.if sdword ptr edx>=GRPXPS && edx<GRPWDT/4+GRPXPS
			push	edx
			invoke MoveToEx,mDC,edx,eax,NULL
			movzx	eax,[edi].LOG.Temp2[ebx+sizeof LOG]
			mov		ecx,8
			xor		edx,edx
			div		ecx
			sub		eax,GRPHGT+GRPYPS
			neg		eax
			pop		edx
			invoke LineTo,mDC,addr [edx+1],eax
		.endif
		lea		esi,[esi+1]
	.endw
	;Delete pen
	pop		eax
	invoke SelectObject,mDC,eax
	invoke DeleteObject,eax
	retn

DrawTemp1:
	;Draw temp scale
	mov		esi,offset szTempCell
	call DrawYScale
	invoke CreatePen,PS_SOLID,2,0FFFF00h
	invoke SelectObject,mDC,eax
	push	eax
	xor		esi,esi
	.while esi<GRPWDT-1
		mov		eax,sizeof LOG
		mul		esi
		mov		ebx,eax
		movzx	eax,[edi].LOG.Temp1[ebx]
		mov		ecx,20
		xor		edx,edx
		div		ecx
		sub		eax,GRPHGT+GRPYPS
		neg		eax
		lea		edx,[esi+GRPXPS]
		sub		edx,xofs
		.if sdword ptr edx>=GRPXPS && edx<GRPWDT/4+GRPXPS
			push	edx
			invoke MoveToEx,mDC,edx,eax,NULL
			movzx	eax,[edi].LOG.Temp1[ebx+sizeof LOG]
			mov		ecx,20
			xor		edx,edx
			div		ecx
			sub		eax,GRPHGT+GRPYPS
			neg		eax
			pop		edx
			invoke LineTo,mDC,addr [edx+1],eax
		.endif
		lea		esi,[esi+1]
	.endw
	;Delete pen
	pop		eax
	invoke SelectObject,mDC,eax
	invoke DeleteObject,eax
	retn

GraphProc endp

; File handling
ReadTheFile proc uses ebx,lpFileName:DWORD,fLoad:DWORD
	LOCAL	hFile:HANDLE
	LOCAL	BytesRead:DWORD

	invoke CreateFile,lpFileName,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
	.if eax!=INVALID_HANDLE_VALUE
		mov		hFile,eax
		invoke GetFileSize,hFile,0
		mov		ebx,eax
		.if fLoad
			invoke ReadFile,hFile,addr log,ebx,addr BytesRead,NULL
		.else
			invoke ReadFile,hFile,addr filelog,ebx,addr BytesRead,NULL
		.endif
		invoke CloseHandle,hFile
		xor		eax,eax
	.endif
	ret

ReadTheFile endp

WriteTheFile proc lpFileName:DWORD
	LOCAL	hFile:HANDLE
	LOCAL	BytesWritten:DWORD

	invoke CreateFile,lpFileName,GENERIC_WRITE,FILE_SHARE_READ,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL
	.if eax!=INVALID_HANDLE_VALUE
		mov		hFile,eax
		invoke WriteFile,hFile,addr log,GRPWDT*sizeof LOG,addr BytesWritten,NULL
		invoke CloseHandle,hFile
		xor		eax,eax
	.endif
	ret

WriteTheFile endp

WndProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	res:DWORD
	LOCAL	systime:SYSTEMTIME
	LOCAL	ofn:OPENFILENAME
	LOCAL	buffer[MAX_PATH]:BYTE

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
		mov		lenr.Pwm1,255
		mov		lenr.Pwm2,255
		mov		lenr.Pwm3,255
		mov		lenr.Pwm4,255
		invoke GetLocalTime,addr systime
		movzx	eax,systime.wYear
		movzx	ecx,systime.wMonth
		movzx	edx,systime.wDay
		invoke wsprintf,addr buffer,addr szFmtFile,addr apppath,eax,ecx,edx
		invoke ReadTheFile,addr buffer,TRUE
		;Create a timer.
		invoke SetTimer,hWin,1000,100,NULL
		invoke CheckDlgButton,hWin,IDC_RBNVOLTAGE,BST_CHECKED
		mov		graph,IDC_RBNVOLTAGE
		invoke SendDlgItemMessage,hWin,IDC_UDNAMBTEMP,UDM_SETRANGE,0,000A0028h
		invoke SendDlgItemMessage,hWin,IDC_UDNAMBTEMP,UDM_SETPOS,0,001Ch
		invoke SendDlgItemMessage,hWin,IDC_UDNCELLTEMP,UDM_SETRANGE,0,00000063h
		invoke SendDlgItemMessage,hWin,IDC_UDNCELLTEMP,UDM_SETPOS,0,0000h
		invoke SendDlgItemMessage,hWin,IDC_UDNOFS,UDM_SETRANGE,0,00000009h
		invoke SendDlgItemMessage,hWin,IDC_UDNPWM3,UDM_SETRANGE,0,000000FFh
		invoke SendDlgItemMessage,hWin,IDC_UDNPWM3,UDM_SETPOS,0,0000h
		invoke SendDlgItemMessage,hWin,IDC_UDNPWM4,UDM_SETRANGE,0,000000FFh
		invoke SendDlgItemMessage,hWin,IDC_UDNPWM4,UDM_SETPOS,0,0000h
		invoke SendDlgItemMessage,hWin,IDC_UDNPWM1MAX,UDM_SETRANGE,0,000000FFh
		invoke SendDlgItemMessage,hWin,IDC_UDNPWM1MAX,UDM_SETPOS,0,00FFh
		invoke SendDlgItemMessage,hWin,IDC_UDNPWM2MAX,UDM_SETRANGE,0,000000FFh
		invoke SendDlgItemMessage,hWin,IDC_UDNPWM2MAX,UDM_SETPOS,0,00FFh
		invoke GetLocalTime,addr systime
		movzx	eax,systime.wHour
		mov		lasthour,eax
		shr		eax,1
		.if eax<2
			mov		xofs,0
			invoke SendDlgItemMessage,hWin,IDC_UDNOFS,UDM_SETPOS,0,0000h
		.else
			sub		eax,2
			push	eax
			invoke SendDlgItemMessage,hWin,IDC_UDNOFS,UDM_SETPOS,0,eax
			pop		eax
			mov		edx,GRPXST
			mul		edx
			mov		xofs,eax
		.endif
	.elseif eax==WM_HSCROLL
		invoke SendDlgItemMessage,hWin,IDC_UDNOFS,UDM_GETPOS,0,0
		movzx	eax,ax
		mov		edx,GRPXST
		mul		edx
		mov		xofs,eax

		invoke SendDlgItemMessage,hWin,IDC_UDNPWM3,UDM_GETPOS,0,0
		sub		eax,255
		neg		eax
		mov		lenr.Pwm3,ax
		invoke SendDlgItemMessage,hWin,IDC_UDNPWM4,UDM_GETPOS,0,0
		sub		eax,255
		neg		eax
		mov		lenr.Pwm4,ax
		invoke GetDlgItem,hWin,IDC_GRAPH
		invoke InvalidateRect,eax,NULL,TRUE
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDM_FILE_EXIT
				invoke SendMessage,hWin,WM_CLOSE,0,0
			.elseif eax==IDM_FILE_OPEN
				;Zero out the ofn struct
				invoke RtlZeroMemory,addr ofn,sizeof ofn
				;Setup the ofn struct
				mov		ofn.lStructSize,sizeof ofn
				push	hWin
				pop		ofn.hwndOwner
				push	hInstance
				pop		ofn.hInstance
				mov		ofn.lpstrFilter,offset szLOGFilterString
				mov		buffer[0],0
				lea		eax,buffer
				mov		ofn.lpstrFile,eax
				mov		ofn.nMaxFile,sizeof buffer
				mov		ofn.lpstrDefExt,NULL
				mov		ofn.Flags,OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_PATHMUSTEXIST
				;Show the Open dialog
				invoke GetOpenFileName,addr ofn
				.if eax
					invoke ReadTheFile,addr buffer,FALSE
					.if !eax
						mov		fileshow,1
						invoke GetDlgItem,hWin,IDC_GRAPH
						invoke InvalidateRect,eax,NULL,TRUE
					.endif
				.endif
			.elseif eax==IDM_FILE_CLOSE
				mov		fileshow,0
				invoke GetDlgItem,hWin,IDC_GRAPH
				invoke InvalidateRect,eax,NULL,TRUE
			.elseif eax==IDM_FILE_SAVE
				invoke GetLocalTime,addr systime
				movzx	eax,systime.wYear
				movzx	ecx,systime.wMonth
				movzx	edx,systime.wDay
				invoke wsprintf,addr buffer,addr szFmtFile,addr apppath,eax,ecx,edx
				invoke WriteTheFile,addr buffer
			.elseif eax==IDM_HELP_ABOUT
				invoke ShellAbout,hWin,addr AppName,addr AboutMsg,NULL
			.elseif eax>=IDC_RBNVOLTAGE && eax<=IDC_RBNAMB
				mov		graph,eax
				invoke GetDlgItem,hWin,IDC_GRAPH
				invoke InvalidateRect,eax,NULL,TRUE
				invoke GetDlgItem,hWin,IDC_DISPLAY
				invoke InvalidateRect,eax,NULL,TRUE
			.endif
		.endif
	.elseif	eax==WM_TIMER
		invoke KillTimer,hWin,1000
		.if connected
			;Read 4 bytes from STM32 ram and store it in res.
			invoke STLinkRead,hWin,20000000h,addr res,DWORD
			.if eax && eax!=IDIGNORE && eax!=IDABORT
				mov		eax,res
				.if eax!=lenr.SecCount
					mov		lenr.SecCount,eax
					;Scroll the adc readings
					mov		ecx,(AVGCOUNT-1)*sizeof LOG
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
					;Read adc values
					invoke STLinkRead,hWin,2000000Ch,addr lenr.log.Volt,sizeof LOG
					.if eax && eax!=IDIGNORE && eax!=IDABORT
						;Convert values
						shr		lenr.log.Volt,1
						shr		lenr.log.Amp,3

						movzx	eax,lenr.log.Temp1
						sub		eax,687
						.if sdword ptr eax<0
							xor		eax,eax
						.endif
						mov		ecx,2500
						imul	ecx
						mov		ecx,1055-687
						idiv	ecx
						mov		lenr.log.Temp1,ax

						movzx	eax,lenr.log.Temp2
						sub		eax,687
						.if sdword ptr eax<0
							xor		eax,eax
						.endif
						mov		ecx,2500
						imul	ecx
						mov		ecx,1055-687
						idiv	ecx

						mov		lenr.log.Temp2,ax
						invoke GetDlgItem,hWin,IDC_DISPLAY
						invoke InvalidateRect,eax,NULL,TRUE
						;Update pwm1, pwm2, pwm3 and pwm4
						invoke STLinkWrite,hWin,20000004h,addr lenr.Pwm1,WORD*4
					.else
						mov		connected,FALSE
					.endif
				.endif
			.else
				mov		connected,FALSE
			.endif
		.else
			;Scroll the adc readings
			mov		ecx,(AVGCOUNT-1)*sizeof LOG
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
			mov		eax,2000
			mov		lenr.log.Volt,ax
			mov		lenr.log.Amp,ax
			mov		lenr.log.Temp1,ax
			mov		lenr.log.Temp2,ax
			;Convert values
			shr		lenr.log.Volt,1
			shr		lenr.log.Amp,3
			shl		lenr.log.Temp1,2
			shl		lenr.log.Temp2,0
			invoke GetDlgItem,hWin,IDC_DISPLAY
			invoke InvalidateRect,eax,NULL,TRUE
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
			;Update log every 25 seconds
			mov		eax,ebx
			mov		ecx,25
			xor		edx,edx
			div		ecx
			.if !edx
				mov		logpos,eax
				mov		ecx,sizeof LOG
				mul		ecx
				mov		ebx,eax
				;Average AVGCOUNT voltage readings
				xor		ecx,ecx
				xor		edi,edi
				.while ecx<AVGCOUNT
					mov		eax,sizeof LOG
					mul		ecx
					movzx	eax,lenr.log.Volt[eax]
					add		edi,eax
					inc		ecx
				.endw
				mov		eax,edi
				mov		ecx,AVGCOUNT
				xor		edx,edx
				div		ecx
				mov		log.Volt[ebx],ax
				;Average AVGCOUNT current readings
				xor		ecx,ecx
				xor		edi,edi
				.while ecx<AVGCOUNT
					mov		eax,sizeof LOG
					mul		ecx
					movzx	eax,lenr.log.Amp[eax]
					add		edi,eax
					inc		ecx
				.endw
				mov		eax,edi
				mov		ecx,AVGCOUNT
				xor		edx,edx
				div		ecx
				mov		log.Amp[ebx],ax
				;Average AVGCOUNT cell temp readings
				xor		ecx,ecx
				xor		edi,edi
				.while ecx<AVGCOUNT
					mov		eax,sizeof LOG
					mul		ecx
					movzx	eax,lenr.log.Temp1[eax]
					add		edi,eax
					inc		ecx
				.endw
				mov		eax,edi
				mov		ecx,AVGCOUNT
				xor		edx,edx
				div		ecx
				mov		log.Temp1[ebx],ax
				;Average AVGCOUNT ambient temp readings
				xor		ecx,ecx
				xor		edi,edi
				.while ecx<AVGCOUNT
					mov		eax,sizeof LOG
					mul		ecx
					movzx	eax,lenr.log.Temp2[eax]
					add		edi,eax
					inc		ecx
				.endw
				mov		eax,edi
				mov		ecx,AVGCOUNT
				xor		edx,edx
				div		ecx
				mov		log.Temp2[ebx],ax
			.endif
			movzx	eax,lenr.log.Temp2
			add		sumamb,eax
			movzx	eax,systime.wSecond
			xor		edx,edx
			mov		ecx,5
			div		ecx
			.if !edx
				;Adjust power for cell heater
				invoke GetDlgItemInt,hWin,IDC_EDTPWM1MAX,NULL,FALSE
				sub		eax,255
				neg		eax
				push	eax
				invoke GetDlgItemInt,hWin,IDC_EDTCELLTEMP,NULL,FALSE
				.if eax
					mov		edx,100
					mul		edx
					mov		ebx,eax
					movzx	eax,lenr.log.Temp1
					pop		edx
					push	edx
					.if eax>ebx
						;Decrement cell heater power
						.if lenr.Pwm1<255
							inc		lenr.Pwm1
						.endif
					.elseif eax<ebx
						;Increment cell heater power
						.if lenr.Pwm1>dx
							dec		lenr.Pwm1
						.elseif lenr.Pwm1<dx
							inc		lenr.Pwm1
						.endif
					.endif
				.endif
				pop		eax
				mov		eax,sumamb
				xor		edx,edx
				mov		ecx,5
				div		ecx
				mov		sumamb,eax
				;Adjust power for ambient temprature heater
				invoke GetDlgItemInt,hWin,IDC_EDTAMBTEMP,NULL,FALSE
				mov		edx,100
				mul		edx
				mov		ebx,eax
				invoke GetDlgItemInt,hWin,IDC_EDTPWM2MAX,NULL,FALSE
				sub		eax,255
				neg		eax
				mov		edx,eax
				mov		eax,sumamb
				mov		sumamb,0
				.if eax>ebx
					;Decrement ambient heater power
					.if lenr.Pwm2<255
						inc		lenr.Pwm2
					.endif
				.elseif eax<ebx
					;Increment ambient heater power
					.if lenr.Pwm2>dx
						dec		lenr.Pwm2
					.elseif lenr.Pwm2<dx
						inc		lenr.Pwm2
					.endif
				.endif
			.endif
			.if systime.wSecond==59
				;Save log file
				movzx	eax,systime.wYear
				movzx	ecx,systime.wMonth
				movzx	edx,systime.wDay
				invoke wsprintf,addr buffer,addr szFmtFile,addr apppath,eax,ecx,edx
				invoke WriteTheFile,addr buffer
			.endif
			movzx	eax,systime.wHour
			.if eax!=lasthour
				mov		lasthour,eax
				shr		eax,1
				.if eax<2
					mov		xofs,0
					invoke SendDlgItemMessage,hWin,IDC_UDNOFS,UDM_SETPOS,0,0000h
				.else
					sub		eax,2
					push	eax
					invoke SendDlgItemMessage,hWin,IDC_UDNOFS,UDM_SETPOS,0,eax
					pop		eax
					mov		edx,GRPXST
					mul		edx
					mov		xofs,eax
				.endif
			.endif
			invoke GetDlgItem,hWin,IDC_GRAPH
			invoke InvalidateRect,eax,NULL,TRUE
		.endif
		invoke SetTimer,hWin,1000,100,NULL
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
	invoke GetModuleFileName,hInstance,addr apppath,sizeof apppath
	.while apppath[eax]!='\' && eax
		dec		eax
	.endw
	mov		apppath[eax],0
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
	mov		CommandLine,eax
	invoke InitCommonControls
	invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
	invoke ExitProcess,eax

end start
