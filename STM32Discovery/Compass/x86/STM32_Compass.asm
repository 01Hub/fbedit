.386
.model flat, stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include STM32_Compass.inc

; HMC5883L Compass
.code

;########################################################################

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
		mov		eax,20
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
		invoke CreatePen,PS_SOLID,4,0000FFh
		invoke SelectObject,mDC,eax
		push	eax
		; North is 0 deg, sub 90 deg
		mov		edx,ideg
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
		invoke GetClientRect,hWin,addr rect
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

CompassProc endp

DlgProc	proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	buffer[32]:BYTE
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
						;Create a timer. The event will read the ADCConvertedValue, format it and display the result
						invoke SetTimer,hWin,1000,500,NULL
					.endif
				.endif
			.elseif eax==IDCANCEL
				invoke	SendMessage,hWin,WM_CLOSE,NULL,NULL
			.endif
		.endif
	.elseif	eax==WM_TIMER
		;Read 12 bytes from STM32F100 ram and store it in adcres.
		invoke STLinkRead,hWin,20000000h,offset compass,12
		.if eax
			movsx	eax,compass.x
			invoke wsprintf,addr buffer,addr szFmtAxis,offset xAxis,eax
			invoke SetDlgItemText,hWin,IDC_STC1,addr buffer
			movsx	eax,compass.y
			invoke wsprintf,addr buffer,addr szFmtAxis,offset yAxis,eax
			invoke SetDlgItemText,hWin,IDC_STC2,addr buffer
			movsx	eax,compass.z
			invoke wsprintf,addr buffer,addr szFmtAxis,offset zAxis,eax
			invoke SetDlgItemText,hWin,IDC_STC3,addr buffer
PrintDec compass.count
			movsx	eax,compass.x
			mov		x,eax
			movsx	ecx,compass.y
			add		ecx,(526-96)/2
			mov		y,ecx
			movsx	edx,compass.z
			mov		z,edx
			.if ecx
				fild	x
				fild	y
				fdivp	st(1),st
				fld1
				fpatan
				fld		REAL8 ptr [rad2deg]
				fmulp	st(1),st
				fistp	ideg
			.endif
			.if sdword ptr eax<=0 && sdword ptr ecx>0
				;0 - 90
				neg		ideg
			.elseif sdword ptr eax>=0 && sdword ptr ecx>0
				;90 - 180
				sub		ideg,360
				neg		ideg
			.elseif sdword ptr eax<=0 && sdword ptr ecx<0
				;180 - 270
				sub		ideg,180
				neg		ideg
			.elseif sdword ptr eax>=0 && sdword ptr ecx<0
				;270 - 360
				neg		ideg
				add		ideg,180
			.endif
			invoke SetDlgItemInt,hWin,IDC_STC4,ideg,TRUE
			invoke InvalidateRect,hCompass,NULL,TRUE
		.else
			invoke KillTimer,hWin,1000
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
