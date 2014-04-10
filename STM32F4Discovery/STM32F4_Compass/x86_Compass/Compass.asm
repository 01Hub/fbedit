.386
.model flat, stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include Compass.inc
include Math.asm

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
	mov		buffer[eax],0
	;Compass Temprature compensation
	invoke GetItemInt,addr buffer,758
	mov		compass.tcxrt,eax
	mov		compass.tcxct,eax
	invoke GetItemInt,addr buffer,702
	mov		compass.tcyrt,eax
	mov		compass.tcyct,eax
	invoke GetItemInt,addr buffer,710
	mov		compass.tczrt,eax
	mov		compass.tczct,eax
	;Compass Offset compensation
	invoke GetItemInt,addr buffer,-254
	mov		compass.mminx,eax
	invoke GetItemInt,addr buffer,93
	mov		compass.mmaxx,eax
	invoke GetItemInt,addr buffer,347
	mov		compass.xscale,eax
	invoke GetItemInt,addr buffer,-373
	mov		compass.mminy,eax
	invoke GetItemInt,addr buffer,-20
	mov		compass.mmaxy,eax
	invoke GetItemInt,addr buffer,353
	mov		compass.yscale,eax
	invoke GetItemInt,addr buffer,-20
	mov		compass.mminz,eax
	invoke GetItemInt,addr buffer,-20
	mov		compass.mmaxz,eax
	invoke GetItemInt,addr buffer,353
	mov		compass.zscale,eax
	invoke GetItemInt,addr buffer,0
	mov		compass.declin,eax
	;Accelerometer min / max
	invoke GetItemInt,addr buffer,-56
	mov		compass.aminx,eax
	invoke GetItemInt,addr buffer,56
	mov		compass.amaxx,eax
	invoke GetItemInt,addr buffer,-56
	mov		compass.aminy,eax
	invoke GetItemInt,addr buffer,56
	mov		compass.amaxy,eax
	invoke GetItemInt,addr buffer,-56
	mov		compass.aminz,eax
	invoke GetItemInt,addr buffer,56
	mov		compass.amaxz,eax
	ret

ReadFromIni endp

WriteToIni proc
	LOCAL	buffer[256]:BYTE

	mov		eax,compass.mmaxx
	sub		eax,compass.mminx
	mov		compass.xscale,eax
	mov		eax,compass.mmaxy
	sub		eax,compass.mminy
	mov		compass.yscale,eax
	mov		eax,compass.mmaxz
	sub		eax,compass.mminz
	mov		compass.zscale,eax
	mov		buffer,0
	;Compass Temprature compensation
	invoke PutItemInt,addr buffer,compass.tcxrt
	invoke PutItemInt,addr buffer,compass.tcyrt
	invoke PutItemInt,addr buffer,compass.tczrt
	;Compass Offset compensation
	invoke PutItemInt,addr buffer,compass.mminx
	invoke PutItemInt,addr buffer,compass.mmaxx
	invoke PutItemInt,addr buffer,compass.xscale
	invoke PutItemInt,addr buffer,compass.mminy
	invoke PutItemInt,addr buffer,compass.mmaxy
	invoke PutItemInt,addr buffer,compass.yscale
	invoke PutItemInt,addr buffer,compass.mminz
	invoke PutItemInt,addr buffer,compass.mmaxz
	invoke PutItemInt,addr buffer,compass.zscale
	invoke PutItemInt,addr buffer,compass.declin
	;Accelerometer min / max
	invoke PutItemInt,addr buffer,compass.aminx
	invoke PutItemInt,addr buffer,compass.amaxx
	invoke PutItemInt,addr buffer,compass.aminy
	invoke PutItemInt,addr buffer,compass.amaxy
	invoke PutItemInt,addr buffer,compass.aminz
	invoke PutItemInt,addr buffer,compass.amaxz
	invoke WritePrivateProfileString,offset szIniCompass,offset szIniCompass,addr buffer[1],offset IniFile
	ret

WriteToIni endp

GetPointOnCircle proc uses edi,radius:DWORD,angle:DWORD,lpPoint:DWORD
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

CompassProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	ps:PAINTSTRUCT
	LOCAL	rect:RECT
	LOCAL	radius:DWORD
	LOCAL	mDC:HDC
	LOCAL	pt:POINT
	LOCAL	pt1:POINT
	LOCAL	pt2:POINT
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
		.if mode==MODE_NORMAL && ShowMode==0

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
			pop		eax
			invoke SelectObject,mDC,eax

			;Find points to draw an arrow
			mov		edx,compass.ideg
			sub		edx,180
			invoke GetPointOnCircle,3,edx,addr pt1
			mov		eax,ptcenter.x
			add		pt1.x,eax
			mov		eax,ptcenter.y
			add		pt1.y,eax
			mov		edx,compass.ideg
			invoke GetPointOnCircle,3,edx,addr pt2
			mov		eax,ptcenter.x
			add		pt2.x,eax
			mov		eax,ptcenter.y
			add		pt2.y,eax
			;Draw arrow opposite of heading
			invoke CreatePen,PS_SOLID,3,0FF0000h
			invoke SelectObject,mDC,eax
			push	eax
			; North is 0 deg, add 90 deg
			mov		edx,compass.ideg
			add		edx,90
			invoke GetPointOnCircle,radius,edx,addr pt
			mov		eax,ptcenter.x
			add		pt.x,eax
			mov		eax,ptcenter.y
			add		pt.y,eax
			invoke MoveToEx,mDC,pt1.x,pt1.y,NULL
			invoke LineTo,mDC,pt.x,pt.y
			invoke MoveToEx,mDC,ptcenter.x,ptcenter.y,NULL
			invoke LineTo,mDC,pt.x,pt.y
			invoke MoveToEx,mDC,pt2.x,pt2.y,NULL
			invoke LineTo,mDC,pt.x,pt.y
			pop		eax
			invoke SelectObject,mDC,eax
			invoke DeleteObject,eax
			;Draw heading arrow
			invoke CreatePen,PS_SOLID,3,0000FFh
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
			invoke MoveToEx,mDC,pt1.x,pt1.y,NULL
			invoke LineTo,mDC,pt.x,pt.y
			invoke MoveToEx,mDC,ptcenter.x,ptcenter.y,NULL
			invoke LineTo,mDC,pt.x,pt.y
			invoke MoveToEx,mDC,pt2.x,pt2.y,NULL
			invoke LineTo,mDC,pt.x,pt.y
			pop		eax
			invoke SelectObject,mDC,eax
			invoke DeleteObject,eax
		.elseif mode==MODE_CALIBRATE
			xor		ebx,ebx
			.while ebx<calinx
				movsx	eax,calibration.x[ebx*(2*WORD)]
				cdq
				mov		ecx,5
				idiv	ecx
				add		eax,ptcenter.x
				mov		esi,eax
				movsx	eax,calibration.y[ebx*(2*WORD)]
				cdq
				mov		ecx,5
				idiv	ecx
				add		eax,ptcenter.y
				mov		edi,eax
				invoke SetPixel,mDC,esi,edi,0FF0000h
				inc		ebx
			.endw
		.elseif mode==MODE_MINMAXX || ShowMode==1
			invoke CreatePen,PS_SOLID,5,0FF0000h
			invoke SelectObject,mDC,eax
			push	eax

			mov		edx,compass.ipitch
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
		.elseif mode==MODE_MINMAXY || ShowMode==2
			invoke CreatePen,PS_SOLID,5,0000FFh
			invoke SelectObject,mDC,eax
			push	eax

			mov		edx,compass.iroll
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
		.elseif mode==MODE_MINMAXZ || ShowMode==3
			invoke CreatePen,PS_SOLID,5,0FF0000h
			invoke SelectObject,mDC,eax
			push	eax

			mov		edx,compass.ipitch
			sub		edx,90
			invoke GetPointOnCircle,radius,edx,addr pt
			mov		eax,ptcenter.x
			add		pt.x,eax
			mov		eax,ptcenter.y
			add		pt.y,eax
			invoke MoveToEx,mDC,ptcenter.x,ptcenter.y,NULL
			invoke LineTo,mDC,pt.x,pt.y

			mov		edx,compass.iroll
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
		.endif
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

DlgProc	proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	buffer[256]:BYTE
	LOCAL	x:DWORD
	LOCAL	y:DWORD
	LOCAL	z:DWORD
	LOCAL	aclx:DWORD
	LOCAL	acly:DWORD
	LOCAL	aclz:DWORD
	LOCAL	xh:DWORD
	LOCAL	yh:DWORD
	LOCAL	wmx:DWORD
	LOCAL	wmy:DWORD
	LOCAL	wmz:DWORD

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
		invoke SendDlgItemMessage,hWin,IDC_STC5,WM_SETFONT,hFont,FALSE
		invoke SendDlgItemMessage,hWin,IDC_STC6,WM_SETFONT,hFont,FALSE
		invoke SendDlgItemMessage,hWin,IDC_STC7,WM_SETFONT,hFont,FALSE
		invoke GetDlgItem,hWin,IDC_UDCCOMPASS
		mov		hCompass,eax
		invoke ReadFromIni
		invoke SetDlgItemInt,hWin,IDC_EDTDEC,compass.declin,TRUE
		invoke CheckDlgButton,hWin,IDC_RBN1,BST_CHECKED
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
						invoke SetTimer,hWin,1000,100,NULL
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
			.elseif eax>=IDC_RBN1 && eax<=IDC_RBN4
				sub		eax,IDC_RBN1
				mov		ShowMode,eax
			.elseif eax==IDC_BTNMINMAXX
				.if mode!=MODE_MINMAXX
					invoke CheckDlgButton,hWin,IDC_RBN2,BST_CHECKED
					invoke CheckDlgButton,hWin,IDC_RBN1,BST_UNCHECKED
					invoke CheckDlgButton,hWin,IDC_RBN3,BST_UNCHECKED
					invoke CheckDlgButton,hWin,IDC_RBN4,BST_UNCHECKED
					mov		ShowMode,1
					mov		mode,MODE_MINMAXX
					mov		compass.mminx,2048
					mov		compass.mmaxx,-2048
					mov		compass.aminx,2048
					mov		compass.amaxx,-2048
				.else
					invoke CheckDlgButton,hWin,IDC_RBN1,BST_CHECKED
					invoke CheckDlgButton,hWin,IDC_RBN2,BST_UNCHECKED
					invoke CheckDlgButton,hWin,IDC_RBN3,BST_UNCHECKED
					invoke CheckDlgButton,hWin,IDC_RBN4,BST_UNCHECKED
					mov		ShowMode,0
					mov		mode,MODE_NORMAL
					invoke wsprintf,addr buffer,addr szFmtaXCalibrate,compass.aminx,compass.amaxx
					invoke SetDlgItemText,hWin,IDC_EDTRESULT,addr buffer
					invoke GetDlgItem,hWin,IDC_BTNSAVE
					invoke EnableWindow,eax,TRUE
				.endif
			.elseif eax==IDC_BTNMINMAXY
				.if mode!=MODE_MINMAXY
					invoke CheckDlgButton,hWin,IDC_RBN3,BST_CHECKED
					invoke CheckDlgButton,hWin,IDC_RBN1,BST_UNCHECKED
					invoke CheckDlgButton,hWin,IDC_RBN2,BST_UNCHECKED
					invoke CheckDlgButton,hWin,IDC_RBN4,BST_UNCHECKED
					mov		ShowMode,2
					mov		mode,MODE_MINMAXY
					mov		compass.mminy,2048
					mov		compass.mmaxy,-2048
					mov		compass.aminy,2048
					mov		compass.amaxy,-2048
				.else
					invoke CheckDlgButton,hWin,IDC_RBN1,BST_CHECKED
					invoke CheckDlgButton,hWin,IDC_RBN2,BST_UNCHECKED
					invoke CheckDlgButton,hWin,IDC_RBN3,BST_UNCHECKED
					invoke CheckDlgButton,hWin,IDC_RBN4,BST_UNCHECKED
					mov		ShowMode,0
					mov		mode,MODE_NORMAL
					invoke wsprintf,addr buffer,addr szFmtaYCalibrate,compass.aminy,compass.amaxy
					invoke SetDlgItemText,hWin,IDC_EDTRESULT,addr buffer
					invoke GetDlgItem,hWin,IDC_BTNSAVE
					invoke EnableWindow,eax,TRUE
				.endif
			.elseif eax==IDC_BTNMINMAXZ
				.if mode!=MODE_MINMAXZ
					invoke CheckDlgButton,hWin,IDC_RBN4,BST_CHECKED
					invoke CheckDlgButton,hWin,IDC_RBN1,BST_UNCHECKED
					invoke CheckDlgButton,hWin,IDC_RBN2,BST_UNCHECKED
					invoke CheckDlgButton,hWin,IDC_RBN3,BST_UNCHECKED
					mov		ShowMode,3
					mov		mode,MODE_MINMAXZ
					mov		compass.mminz,2048
					mov		compass.mmaxz,-2048
					mov		compass.aminz,2048
					mov		compass.amaxz,-2048
				.else
					invoke CheckDlgButton,hWin,IDC_RBN1,BST_CHECKED
					invoke CheckDlgButton,hWin,IDC_RBN2,BST_UNCHECKED
					invoke CheckDlgButton,hWin,IDC_RBN3,BST_UNCHECKED
					invoke CheckDlgButton,hWin,IDC_RBN4,BST_UNCHECKED
					mov		ShowMode,0
					mov		mode,MODE_NORMAL
					invoke wsprintf,addr buffer,addr szFmtaZCalibrate,compass.aminz,compass.amaxz
					invoke SetDlgItemText,hWin,IDC_EDTRESULT,addr buffer
					invoke GetDlgItem,hWin,IDC_BTNSAVE
					invoke EnableWindow,eax,TRUE
				.endif
			.elseif eax==IDC_CHKTILT
				xor		compass.ftilt,1
			.elseif eax==IDCANCEL
				invoke	SendMessage,hWin,WM_CLOSE,NULL,NULL
			.endif
		.elseif edx==EN_KILLFOCUS
			.if eax==IDC_EDTDEC
				invoke GetDlgItemInt,hWin,IDC_EDTDEC,NULL,TRUE
				mov		compass.declin,eax
			.endif
		.endif
	.elseif	eax==WM_TIMER
		invoke KillTimer,hWin,1000
		mov		eax,mode
		and		eax,7
		mov		compass.flag,ax
		;Write 4  bytes to STM32F100 ram
		invoke STLinkWrite,hWin,STM32_ADDRESS,offset compass,4
		.if eax && eax!=IDIGNORE && eax!=IDABORT
			invoke Sleep,10
			.while TRUE
				;Read 16 bytes from STM32F100 ram and store it in compass.
				invoke STLinkRead,hWin,STM32_ADDRESS,offset compass,16
				.if eax && eax!=IDIGNORE && eax!=IDABORT
					.if !compass.flag
						movsx	eax,compass.x
						invoke wsprintf,addr buffer,addr szFmtAxis,offset magxAxis,eax
						invoke SetDlgItemText,hWin,IDC_STC1,addr buffer
						movsx	eax,compass.y
						invoke wsprintf,addr buffer,addr szFmtAxis,offset magyAxis,eax
						invoke SetDlgItemText,hWin,IDC_STC2,addr buffer
						movsx	eax,compass.z
						invoke wsprintf,addr buffer,addr szFmtAxis,offset magzAxis,eax
						invoke SetDlgItemText,hWin,IDC_STC3,addr buffer

						movsx	eax,compass.buffer[0]
						invoke wsprintf,addr buffer,addr szFmtAxis,offset aclxAxis,eax
						invoke SetDlgItemText,hWin,IDC_STC5,addr buffer
						movsx	eax,compass.buffer[2]
						invoke wsprintf,addr buffer,addr szFmtAxis,offset aclyAxis,eax
						invoke SetDlgItemText,hWin,IDC_STC6,addr buffer
						movsx	eax,compass.buffer[4]
						invoke wsprintf,addr buffer,addr szFmtAxis,offset aclzAxis,eax
						invoke SetDlgItemText,hWin,IDC_STC7,addr buffer

						.if mode==MODE_NORMAL
							;Temprature compensation
							call	TempComp
							;X / Y Scale compensation
							call	ScaleComp
							;Offset compensation
							call	OffsetComp
							;Get accelerometer pitch and roll
							call	GetPitchRoll
							;Get heading
							call	GetHeading
							invoke SetDlgItemInt,hWin,IDC_STC4,compass.ideg,TRUE
						.elseif mode==MODE_COMPENSATE
							invoke SetDlgItemInt,hWin,IDC_STC4,countdown,FALSE
							dec		countdown
							.if ZERO?
								;Get temprature compensation for x, y and z
								mov		compass.flag,MODE_COMPENSATEOFF
								;Write 4  bytes to STM32F100 ram
								invoke STLinkWrite,hWin,STM32_ADDRESS,offset compass,4
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
								mov		compass.mminx,2048
								mov		compass.mmaxx,-2048
								mov		compass.mminy,2048
								mov		compass.mmaxy,-2048
								xor		ebx,ebx
								.while ebx<1024
									movsx	eax,calibration.x[ebx*(2*WORD)]
									.if sdword ptr eax<compass.mminx
										mov		compass.mminx,eax
									.endif
									.if sdword ptr eax>compass.mmaxx
										mov		compass.mmaxx,eax
									.endif
									movsx	eax,calibration.y[ebx*(2*WORD)]
									.if sdword ptr eax<compass.mminy
										mov		compass.mminy,eax
									.endif
									.if sdword ptr eax>compass.mmaxy
										mov		compass.mmaxy,eax
									.endif
									inc		ebx
								.endw
								mov		eax,compass.mmaxx
								sub		eax,compass.mminx
								mov		compass.xscale,eax
								mov		eax,compass.mmaxy
								sub		eax,compass.mminy
								mov		compass.yscale,eax
								invoke wsprintf,addr buffer,addr szFmpCalibrate,compass.mminx,compass.mmaxx,compass.xscale,compass.mminy,compass.mmaxy,compass.yscale
								invoke SetDlgItemText,hWin,IDC_EDTRESULT,addr buffer
								invoke GetDlgItem,hWin,IDC_BTNSAVE
								invoke EnableWindow,eax,TRUE
								mov		mode,MODE_NORMAL
							.endif
						.elseif mode==MODE_MINMAXX
							movsx	eax,compass.x
							.if sdword ptr eax<compass.mminx
								mov		compass.mminx,eax
							.endif
							.if sdword ptr eax>compass.mmaxx
								mov		compass.mmaxx,eax
							.endif
							movsx	eax,compass.buffer[0]
							.if sdword ptr eax<compass.aminx
								mov		compass.aminx,eax
							.endif
							.if sdword ptr eax>compass.amaxx
								mov		compass.amaxx,eax
							.endif
							call	GetPitchRoll
							invoke wsprintf,addr buffer,offset szFmtMinMax,compass.mminx,compass.mmaxx
							invoke SetDlgItemText,hWin,IDC_STCMAGMINMAX,addr buffer
							invoke wsprintf,addr buffer,offset szFmtMinMax,compass.aminx,compass.amaxx
							invoke SetDlgItemText,hWin,IDC_STCACLMINMAX,addr buffer
						.elseif mode==MODE_MINMAXY
							movsx	eax,compass.y
							.if sdword ptr eax<compass.mminy
								mov		compass.mminy,eax
							.endif
							.if sdword ptr eax>compass.mmaxy
								mov		compass.mmaxy,eax
							.endif
							movsx	eax,compass.buffer[2]
							.if sdword ptr eax<compass.aminy
								mov		compass.aminy,eax
							.endif
							.if sdword ptr eax>compass.amaxy
								mov		compass.amaxy,eax
							.endif
							call	GetPitchRoll
							invoke wsprintf,addr buffer,offset szFmtMinMax,compass.mminy,compass.mmaxy
							invoke SetDlgItemText,hWin,IDC_STCMAGMINMAX,addr buffer
							invoke wsprintf,addr buffer,offset szFmtMinMax,compass.aminy,compass.amaxy
							invoke SetDlgItemText,hWin,IDC_STCACLMINMAX,addr buffer
						.elseif mode==MODE_MINMAXZ
							movsx	eax,compass.z
							.if sdword ptr eax<compass.mminz
								mov		compass.mminz,eax
							.endif
							.if sdword ptr eax>compass.mmaxz
								mov		compass.mmaxz,eax
							.endif
							movsx	eax,compass.buffer[4]
							.if sdword ptr eax<compass.aminz
								mov		compass.aminz,eax
							.endif
							.if sdword ptr eax>compass.amaxz
								mov		compass.amaxz,eax
							.endif
							call	GetPitchRoll
							invoke wsprintf,addr buffer,offset szFmtMinMax,compass.mminz,compass.mmaxz
							invoke SetDlgItemText,hWin,IDC_STCMAGMINMAX,addr buffer
							invoke wsprintf,addr buffer,offset szFmtMinMax,compass.aminz,compass.amaxz
							invoke SetDlgItemText,hWin,IDC_STCACLMINMAX,addr buffer
						.endif
						invoke InvalidateRect,hCompass,NULL,TRUE
						invoke SetTimer,hWin,1000,50,NULL
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
	;Select largest
	mov		ebx,compass.xscale
	.if ebx<compass.yscale
		mov		ebx,compass.yscale
	.endif
;	.if ebx<compass.zscale
;		mov		ebx,compass.zscale
;	.endif
	mov		ecx,compass.xscale
	mov		eax,x
	imul	ebx
	idiv	ecx
	mov		x,eax
	mov		ecx,compass.yscale
	mov		eax,y
	imul	ebx
	idiv	ecx
	mov		y,eax
	mov		ecx,compass.zscale
	mov		eax,z
	imul	ebx
	idiv	ecx
	mov		z,eax
	retn

OffsetComp:
	mov		eax,x
	mov		ecx,compass.mminx
	add		ecx,compass.mmaxx
	sar		ecx,1
	sub		eax,ecx
	mov		x,eax
	mov		eax,y
	mov		ecx,compass.mminy
	add		ecx,compass.mmaxy
	sar		ecx,1
	sub		eax,ecx
	mov		y,eax
	mov		eax,z
	mov		ecx,compass.mminz
	add		ecx,compass.mmaxz
	sar		ecx,1
	sub		eax,ecx
	mov		z,eax
	retn

GetHeading:
	.if compass.ftilt
		;xh = x*cos(pitch) + y*sin(roll) - z*cos(pitch)*sin(pitch)
		fild	x
		fld		compass.pitch
		fcos
		fmulp	st(1),st
		fild	y
		fld		compass.roll
		fsin
		fmulp	st(1),st
		faddp	st(1),st
		fild	z
		fld		compass.pitch
		fcos
		fmulp	st(1),st
		fld		compass.pitch
		fsin
		fmulp	st(1),st
		fsubp	st(1),st
		fistp	xh
		;yh = y*cos(roll) + z*sin(roll)
		fild	y
		fld		compass.roll
		fcos
		fmulp	st(1),st
		fild	z
		fld		compass.roll
		fsin
		fmulp	st(1),st
		faddp	st(1),st
		fistp	yh
	.else
		mov		eax,x
		mov		xh,eax
		mov		eax,y
		mov		yh,eax
	.endif
	;Find the angle. North is 0 deg
	fild	yh
	.if xh
		fild	xh
		fdivp	st(1),st
	.endif
	fld1
	fpatan
	fld		REAL8 ptr [rad2deg]
	fmulp	st(1),st
	fistp	compass.ideg
	mov		eax,xh
	mov		ecx,yh
	.if sdword ptr eax<0 && sdword ptr ecx>=0
		sub		compass.ideg,180
	.elseif sdword ptr eax<0 && sdword ptr ecx<0
		add		compass.ideg,180
	.endif
	;Magnetic declination
	mov		eax,compass.declin
	add		compass.ideg,eax
	.if sdword ptr compass.ideg>=360
		sub		compass.ideg,360
	.elseif sdword ptr compass.ideg<0
		add		compass.ideg,360
	.endif
	retn

GetPitchRoll:
	;Offset adjust axis
	mov		ecx,compass.amaxx
	add		ecx,compass.aminx
	sar		ecx,1
	movsx	eax,compass.buffer[0]
	sub		eax,ecx
	mov		aclx,eax
	mov		ecx,compass.amaxy
	add		ecx,compass.aminy
	sar		ecx,1
	movsx	eax,compass.buffer[2]
	sub		eax,ecx
	;Y axis points to left on accelerometer, right on magnetometer
	neg		eax
	mov		acly,eax
	movsx	eax,compass.buffer[4]
	mov		ecx,compass.amaxz
	add		ecx,compass.aminz
	sar		ecx,1
	sub		eax,ecx
	mov		aclz,eax
	;pitch = arctan(Ax / sqrt(Ay^2+Az^2))
	fild	aclx
	fild	acly
	fild	acly
	fmulp	st(1),st
	fild	aclz
	fild	aclz
	fmulp	st(1),st
	faddp	st(1),st
	fsqrt
	fdivp	st(1),st
	fld1
	fpatan
	fst		compass.pitch
	fld		rad2deg
	fmulp	st(1),st
	fistp	compass.ipitch
	;roll  = arctan(Ay / sqrt(Ax^2+Az^2))
	fild	acly
	fild	aclx
	fild	aclx
	fmulp	st(1),st
	fild	aclz
	fild	aclz
	fmulp	st(1),st
	faddp	st(1),st
	fsqrt
	fdivp	st(1),st
	fld1
	fpatan
	fst		compass.roll
	fld		rad2deg
	fmulp	st(1),st
	fistp	compass.iroll
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
