.386
.model flat, stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include STM32_Compass.inc

; HMC5883L Compass
.code

;########################################################################

DecToBin proc uses ebx esi,lpStr:DWORD
	LOCAL	fNeg:DWORD

    mov     esi,lpStr
    mov		fNeg,FALSE
    mov		al,[esi]
    .if al=='-'
		inc		esi
		mov		fNeg,TRUE
    .endif
    xor     eax,eax
  @@:
    cmp     byte ptr [esi],30h
    jb      @f
    cmp     byte ptr [esi],3Ah
    jnb     @f
    mov     ebx,eax
    shl     eax,2
    add     eax,ebx
    shl     eax,1
    xor     ebx,ebx
    mov     bl,[esi]
    sub     bl,30h
    add     eax,ebx
    inc     esi
    jmp     @b
  @@:
	.if fNeg
		neg		eax
	.endif
    ret

DecToBin endp

BinToDec proc dwVal:DWORD,lpAscii:DWORD
	LOCAL	buffer[8]:BYTE

	mov		dword ptr buffer,'d%'
	invoke wsprintf,lpAscii,addr buffer,dwVal
	ret

BinToDec endp

GetItemInt proc uses esi edi,lpBuff:DWORD,nDefVal:DWORD

	mov		esi,lpBuff
	.if byte ptr [esi]
		mov		edi,esi
		invoke DecToBin,edi
		.while byte ptr [esi] && byte ptr [esi]!=','
			inc		esi
		.endw
		.if byte ptr [esi]==','
			inc		esi
		.endif
		push	eax
		invoke lstrcpy,edi,esi
		pop		eax
	.else
		mov		eax,nDefVal
	.endif
	ret

GetItemInt endp

PutItemInt proc uses esi edi,lpBuff:DWORD,nVal:DWORD

	mov		esi,lpBuff
	invoke lstrlen,esi
	mov		byte ptr [esi+eax],','
	invoke BinToDec,nVal,addr [esi+eax+1]
	ret

PutItemInt endp

ReadFromIni proc
	LOCAL	buffer[256]:BYTE

	invoke GetPrivateProfileString,offset szIniCompass,offset szIniCompass,NULL,addr buffer,sizeof buffer,offset IniFile
PrintDec eax
	;Temprature compensation
	invoke GetItemInt,addr buffer,763
	mov		compass.tcxrt,eax
	mov		compass.tcxct,eax
	invoke GetItemInt,addr buffer,701
	mov		compass.tcyrt,eax
	mov		compass.tcyct,eax
	invoke GetItemInt,addr buffer,712
	mov		compass.tczrt,eax
	mov		compass.tczct,eax
	;Offset compensation
	invoke GetItemInt,addr buffer,-254
	mov		compass.xmin,eax
	invoke GetItemInt,addr buffer,93
	mov		compass.xmax,eax
	invoke GetItemInt,addr buffer,347
	mov		compass.xscale,eax
	invoke GetItemInt,addr buffer,-373
	mov		compass.ymin,eax
	invoke GetItemInt,addr buffer,-20
	mov		compass.ymax,eax
	invoke GetItemInt,addr buffer,353
	mov		compass.yscale,eax
	ret

ReadFromIni endp

WriteToIni proc
	LOCAL	buffer[256]:BYTE

	mov		buffer,0
	;Temprature compensation
	invoke PutItemInt,addr buffer,compass.tcxrt
	invoke PutItemInt,addr buffer,compass.tcyrt
	invoke PutItemInt,addr buffer,compass.tczrt
	;Offset compensation
	invoke PutItemInt,addr buffer,compass.xmin
	invoke PutItemInt,addr buffer,compass.xmax
	invoke PutItemInt,addr buffer,compass.xscale
	invoke PutItemInt,addr buffer,compass.ymin
	invoke PutItemInt,addr buffer,compass.ymax
	invoke PutItemInt,addr buffer,compass.yscale
	invoke WritePrivateProfileString,offset szIniCompass,offset szIniCompass,addr buffer[1],offset IniFile
	ret

WriteToIni endp

GetPointOnCircle proc uses edi,radius:DWORD,angle:DWORD,lpPoint:ptr POINT
	LOCAL	r:QWORD

	mov		edi,lpPoint
	fild    DWORD ptr [angle]
	fmul	REAL8 ptr [deg2rad]
	fst		REAL8 ptr [r]
	fcos
	fild    DWORD ptr [radius]
	fmulp	st(1),st(0)
	fistp	DWORD ptr [edi].POINT.x
	fld		REAL8 ptr [r]
	fsin
	fild    DWORD ptr [radius]
	fmulp	st(1),st(0)
	fistp	DWORD ptr [edi].POINT.y
	ret

GetPointOnCircle endp

CompassProc proc uses ebx esi edi, hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	ps:PAINTSTRUCT
	LOCAL	rect:RECT
	LOCAL	radius:DWORD
	LOCAL	mDC:HDC
	LOCAL	pt:POINT
	LOCAL	ptcenter:POINT

	mov		eax,uMsg
	.if eax==WM_PAINT
		invoke GetClientRect,hWin,addr rect
		invoke BeginPaint,hWin,addr ps
		invoke CreateCompatibleDC,ps.hdc
		mov		mDC,eax
		invoke CreateCompatibleBitmap,ps.hdc,rect.right,rect.bottom
		invoke SelectObject,mDC,eax
		push	eax
		invoke GetStockObject,WHITE_BRUSH
		invoke FillRect,mDC,addr rect,eax
		mov		eax,30
		add		rect.left,eax
		add		rect.top,eax
		sub		rect.right,eax
		sub		rect.bottom,eax
		invoke Ellipse,mDC,rect.left,rect.top,rect.right,rect.bottom
		mov		ebx,rect.bottom
		sub		ebx,rect.top
		shr		ebx,1
		add		ebx,rect.top
		mov		ptcenter.y,ebx
		invoke MoveToEx,mDC,rect.left,ebx,NULL
		invoke LineTo,mDC,rect.right,ebx
		mov		ebx,rect.right
		sub		ebx,rect.left
		shr		ebx,1
		mov		radius,ebx
		add		ebx,rect.left
		mov		ptcenter.x,ebx
		invoke MoveToEx,mDC,ebx,rect.top,NULL
		invoke LineTo,mDC,ebx,rect.bottom
		mov		ecx,rect.left
		add		ecx,32
		mov		edx,rect.top
		add		edx,32
		invoke MoveToEx,mDC,ecx,edx,NULL
		mov		ecx,rect.right
		sub		ecx,32
		mov		edx,rect.bottom
		sub		edx,32
		invoke LineTo,mDC,ecx,edx
		mov		ecx,rect.right
		sub		ecx,32
		mov		edx,rect.top
		add		edx,32
		invoke MoveToEx,mDC,ecx,edx,NULL
		mov		ecx,rect.left
		add		ecx,32
		mov		edx,rect.bottom
		sub		edx,32
		invoke LineTo,mDC,ecx,edx
		invoke SelectObject,mDC,hFont
		push	eax
		invoke SetBkMode,mDC,TRANSPARENT
		mov		ebx,ptcenter.x
		sub		ebx,8
		invoke TextOut,mDC,ebx,-5,offset szNorth,1
		mov		eax,rect.bottom
		sub		eax,5
		invoke TextOut,mDC,ebx,eax,offset szSouth,1
		mov		ebx,ptcenter.y
		sub		ebx,18
		invoke TextOut,mDC,0,ebx,offset szWest,1
		mov		eax,rect.right
		add		eax,5
		invoke TextOut,mDC,eax,ebx,offset szEast,1
		.if mode==MODE_NORMAL
			invoke CreatePen,PS_SOLID,4,0000FFh
			invoke SelectObject,mDC,eax
			push	eax
			; North is 0 deg, sub 90 deg
			mov		edx,compass.ideg
			sub		edx,90
			invoke GetPointOnCircle,radius,edx,addr pt
			mov		eax,ptcenter.x
			add		pt.x,eax
			mov		eax,ptcenter.y
			add		pt.y,eax
			invoke MoveToEx,mDC,ptcenter.x,ptcenter.y,NULL
			invoke LineTo,mDC,pt.x,pt.y
			pop		eax
			invoke SelectObject,mDC,eax
			invoke DeleteObject,eax
		.elseif mode==MODE_CALIBRATE
			xor		ebx,ebx
			.while ebx<calinx
				movsx	eax,calibration.x[ebx*(2*WORD)]
				cdq
				mov		ecx,4
				idiv	ecx
				add		eax,ptcenter.x
				mov		esi,eax
				movsx	eax,calibration.y[ebx*(2*WORD)]
				cdq
				mov		ecx,4
				idiv	ecx
				add		eax,ptcenter.y
				mov		edi,eax
				invoke SetPixel,mDC,esi,edi,0FF0000h
				inc		ebx
			.endw
		.endif
		invoke GetClientRect,hWin,addr rect
		invoke BitBlt,ps.hdc,0,0,rect.right,rect.bottom,mDC,0,0,SRCCOPY
		pop		eax
		invoke SelectObject,mDC,eax
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

CompassProc endp

DlgProc	proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	buffer[256]:BYTE
	LOCAL	x:DWORD
	LOCAL	y:DWORD
	LOCAL	z:DWORD

	mov		eax,uMsg
	.if	eax==WM_INITDIALOG
		mov		eax,hWin
		mov		hWnd,eax
		invoke CreateFontIndirect,addr Tahoma_72
		mov		hFont,eax
		invoke SendDlgItemMessage,hWin,IDC_STC1,WM_SETFONT,hFont,FALSE
		invoke SendDlgItemMessage,hWin,IDC_STC2,WM_SETFONT,hFont,FALSE
		invoke SendDlgItemMessage,hWin,IDC_STC3,WM_SETFONT,hFont,FALSE
		invoke SendDlgItemMessage,hWin,IDC_STC4,WM_SETFONT,hFont,FALSE
		invoke GetDlgItem,hWin,IDC_UDCCOMPASS
		mov		hCompass,eax
		invoke ReadFromIni
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
						mov		mode,MODE_NORMAL
						;Create a timer. The event will read the compass axis
						invoke SetTimer,hWin,1000,150,NULL
					.endif
				.endif
			.elseif eax==IDC_BTNCOMP
				.if connected && mode==MODE_NORMAL
					mov		compass.tcxct,0
					mov		compass.tcyct,0
					mov		compass.tczct,0
					mov		countdown,32+4
					mov		mode,MODE_COMPENSATE
				.endif
			.elseif eax==IDC_BTNCALIBRATE
				.if connected && mode==MODE_NORMAL
					mov		calinx,0
					mov		countdown,1024+40
					mov		mode,MODE_CALIBRATE
				.endif
			.elseif eax==IDC_BTNSAVE
				invoke WriteToIni
				invoke GetDlgItem,hWin,IDC_BTNSAVE
				invoke EnableWindow,eax,FALSE
			.elseif eax==IDCANCEL
				invoke	SendMessage,hWin,WM_CLOSE,NULL,NULL
			.endif
		.endif
	.elseif	eax==WM_TIMER
		invoke KillTimer,hWin,1000
		mov		eax,mode
		mov		compass.flag,ax
		;Write 4  bytes to STM32F100 ram
		invoke STLinkWrite,hWin,20000000h,offset compass,4
		.if eax && eax!=IDIGNORE && eax!=IDABORT
			invoke Sleep,50
			.while TRUE
				;Read 12 bytes from STM32F100 ram and store it in compass.
				invoke STLinkRead,hWin,20000000h,offset compass,12
				.if eax && eax!=IDIGNORE && eax!=IDABORT
					.if !compass.flag
						movsx	eax,compass.x
						invoke wsprintf,addr buffer,addr szFmtAxis,offset xAxis,eax
						invoke SetDlgItemText,hWin,IDC_STC1,addr buffer
						movsx	eax,compass.y
						invoke wsprintf,addr buffer,addr szFmtAxis,offset yAxis,eax
						invoke SetDlgItemText,hWin,IDC_STC2,addr buffer
						movsx	eax,compass.z
						invoke wsprintf,addr buffer,addr szFmtAxis,offset zAxis,eax
						invoke SetDlgItemText,hWin,IDC_STC3,addr buffer
						.if mode==MODE_NORMAL
							;Temprature compensation
							call	TempComp
							;X / Y Scale compensation
							call	ScaleComp
							;Offset compensation
							mov		eax,x
							mov		ecx,compass.xmin
							add		ecx,compass.xmax
							.if sdword ptr ecx<0
								neg		ecx
								shr		ecx,1
								neg		ecx
							.else
								shr		ecx,1
							.endif
							sub		eax,ecx
							mov		x,eax
							mov		eax,y
							mov		ecx,compass.ymin
							add		ecx,compass.ymax
							.if sdword ptr ecx<0
								neg		ecx
								shr		ecx,1
								neg		ecx
							.else
								shr		ecx,1
							.endif
							sub		eax,ecx
							mov		y,eax
							;Find the angle. North is 0 deg
							fild	x
							.if y
								fild	y
								fdivp	st(1),st
							.endif
							fld1
							fpatan
							fld		REAL8 ptr [rad2deg]
							fmulp	st(1),st
							fistp	compass.ideg
							mov		eax,x
							mov		ecx,y
							mov		edx,z
							.if sdword ptr eax<=0 && sdword ptr ecx>=0
								;0 - 90
								neg		compass.ideg
							.elseif sdword ptr eax>=0 && sdword ptr ecx>=0
								;90 - 180
								sub		compass.ideg,360
								neg		compass.ideg
							.elseif sdword ptr eax<=0 && sdword ptr ecx<0
								;180 - 270
								sub		compass.ideg,180
								neg		compass.ideg
							.elseif sdword ptr eax>=0 && sdword ptr ecx<0
								;270 - 360
								neg		compass.ideg
								add		compass.ideg,180
							.endif
							.if compass.ideg>=360
								sub		compass.ideg,360
							.endif
							invoke SetDlgItemInt,hWin,IDC_STC4,compass.ideg,TRUE
						.elseif mode==MODE_COMPENSATE
							invoke SetDlgItemInt,hWin,IDC_STC4,countdown,FALSE
							dec		countdown
							.if ZERO?
								;Get temprature compensation for x, y and z
								mov		compass.flag,MODE_COMPENSATEOFF
								;Write 4  bytes to STM32F100 ram
								invoke STLinkWrite,hWin,20000000h,offset compass,4
								.if eax && eax!=IDIGNORE && eax!=IDABORT
									shr		compass.tcxct,5
									shr		compass.tcyct,5
									shr		compass.tczct,5
									invoke wsprintf,addr buffer,addr szFmtCompensate,compass.tcxct,compass.tcyct,compass.tczct
									invoke SetDlgItemText,hWin,IDC_EDTRESULT,addr buffer
									invoke GetDlgItem,hWin,IDC_BTNSAVE
									invoke EnableWindow,eax,TRUE
									mov		mode,MODE_NORMAL
								.else
									mov		connected,FALSE
									.break
								.endif
							.elseif countdown<=32
								movsx	eax,compass.x
								add		compass.tcxct,eax
								movsx	eax,compass.y
								add		compass.tcyct,eax
								movsx	eax,compass.z
								add		compass.tczct,eax
							.endif
						.elseif mode==MODE_CALIBRATE
							invoke SetDlgItemInt,hWin,IDC_STC4,countdown,FALSE
							mov		ebx,calinx
							.if ebx<1024
								call	TempComp
								mov		eax,x
								mov		calibration.x[ebx*(2*WORD)],ax
								mov		eax,y
								mov		calibration.y[ebx*(2*WORD)],ax
								inc		calinx
							.endif
							dec		countdown
							.if ZERO?
								;Get min and max x and y
								mov		compass.xmin,2040
								mov		compass.xmax,-2048
								mov		compass.ymin,2048
								mov		compass.ymax,-2048
								xor		ebx,ebx
								.while ebx<1024
									movsx	eax,calibration.x[ebx*(2*WORD)]
									.if sdword ptr eax<compass.xmin
										mov		compass.xmin,eax
									.endif
									.if sdword ptr eax>compass.xmax
										mov		compass.xmax,eax
									.endif
									movsx	eax,calibration.y[ebx*(2*WORD)]
									.if sdword ptr eax<compass.ymin
										mov		compass.ymin,eax
									.endif
									.if sdword ptr eax>compass.ymax
										mov		compass.ymax,eax
									.endif
									inc		ebx
								.endw
								mov		eax,compass.xmax
								sub		eax,compass.xmin
								mov		compass.xscale,eax
								mov		eax,compass.ymax
								sub		eax,compass.ymin
								mov		compass.yscale,eax
								invoke wsprintf,addr buffer,addr szFmpCalibrate,compass.xmin,compass.xmax,compass.xscale,compass.ymin,compass.ymax,compass.yscale
								invoke SetDlgItemText,hWin,IDC_EDTRESULT,addr buffer
								invoke GetDlgItem,hWin,IDC_BTNSAVE
								invoke EnableWindow,eax,TRUE
								mov		mode,MODE_NORMAL
							.endif
						.endif
						invoke InvalidateRect,hCompass,NULL,TRUE
						invoke SetTimer,hWin,1000,150,NULL
						.break
					.endif
				.else
					mov		connected,FALSE
					.break
				.endif
			.endw
		.else
			mov		connected,FALSE
		.endif
		.if !connected
			invoke STLinkDisconnect,hWin
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

TempComp:
	;Temprature compensation
	movsx	eax,compass.x
	cdq
	mov		ecx,compass.tcxrt
	imul	ecx
	cdq
	mov		ecx,compass.tcxct
	idiv	ecx
	mov		x,eax
	movsx	eax,compass.y
	cdq
	mov		ecx,compass.tcyrt
	imul	ecx
	cdq
	mov		ecx,compass.tcyct
	idiv	ecx
	mov		y,eax
	movsx	eax,compass.z
	cdq
	mov		ecx,compass.tczrt
	imul	ecx
	cdq
	mov		ecx,compass.tczct
	idiv	ecx
	mov		z,eax
	retn

ScaleComp:
	mov		eax,compass.xscale
	.if eax>compass.yscale
		;Scale y-axis to x-axis
		mov		eax,y
		mov		ecx,compass.xscale
		imul	ecx
		mov		ecx,compass.yscale
		idiv	ecx
		mov		y,eax
	.elseif eax<compass.yscale
		;Scale x-axis to y-axis
		mov		eax,x
		mov		ecx,compass.yscale
		imul	ecx
		mov		ecx,compass.xscale
		idiv	ecx
		mov		x,eax
	.endif
	retn

DlgProc endp

start:
	invoke	GetModuleHandle,NULL
	mov		hInstance,eax
	invoke	InitCommonControls
	invoke GetModuleFileName,hInstance,offset IniFile,sizeof IniFile
	invoke lstrlen,offset IniFile
	.while IniFile[eax]!='\'
		dec		eax
	.endw
	mov		IniFile[eax],0
	invoke lstrcat,offset IniFile,offset szIniFile
	mov		wc.cbSize,sizeof WNDCLASSEX
	mov		wc.style,CS_HREDRAW or CS_VREDRAW
	mov		wc.lpfnWndProc,offset CompassProc
	mov		wc.lpszClassName,offset szCOMPASSCLASS
	mov		wc.cbClsExtra,0
	mov		wc.cbWndExtra,0
	mov		eax,hInstance
	mov		wc.hInstance,eax
	mov		wc.hIcon,NULL
	mov		wc.hIconSm,NULL
	invoke LoadCursor,0,IDC_ARROW
	mov		wc.hCursor,eax
	mov		wc.hbrBackground,NULL
	invoke RegisterClassEx,addr wc
	invoke	DialogBoxParam,hInstance,IDD_MAIN,NULL,addr DlgProc,NULL
	invoke	ExitProcess,0

end start
